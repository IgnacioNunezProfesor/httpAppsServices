Param(
    [Parameter(Mandatory = $true)]
    [string]$envFile
)

# Recargar módulos
if (Get-Module 'env') { Remove-Module 'env' -Force }
Import-Module .\scripts\mods\env.psm1 -Force

if (Get-Module 'networks') { Remove-Module 'networks' -Force }
Import-Module .\scripts\mods\networks.psm1 -Force

# Cargar variables de entorno
$envVars = Get-EnvVarsFromFile -envFile $EnvFile
if (-not $envVars) {
    Write-Error "No se pudieron cargar las variables de entorno desde $EnvFile"
    exit 1
}

# Registrar aplicación
.\scripts\AdminApp.ps1 -add `
    -Name $envVars.APP_NAME `
    -Url $envVars.APP_GITHUB_URL `
    -Path $envVars.APP_LOCAL_PATH

# Check if image exists locally, if not build it
Write-Host "Checking if image $($envVars.HTTP_IMAGE_NAME) exists locally..."
$imageExists = @(docker images -q $envVars.HTTP_IMAGE_NAME 2>$null)
if ($imageExists.Count -eq 0) {
    Write-Host "Image $($envVars.HTTP_IMAGE_NAME) not found locally. Building image..."
    .\scripts\buildEnvFile.ps1 -EnvFile $EnvFile
    if (-not $?) {
        Write-Error "Failed to build image $($envVars.HTTP_IMAGE_NAME)"
        exit 1
    }
    Write-Host "Image built successfully."
} else {
    Write-Host "Image $($envVars.HTTP_IMAGE_NAME) already exists locally."
}

# Levantar contenedor
docker compose -f $envVars.APP_COMPOSER_PATH --env-file $EnvFile up -d

# Get container name (by service)
$containerName = $envVars.HTTP_CONTAINER_NAME
Write-Host "Searching for container: $containerName"

# Use exact match with regex anchor (^ and $)
$containerIds = @(docker ps --filter "name=^$containerName`$" --format "{{.ID}}")
$containerCount = $containerIds.Count

Write-Host "Found $containerCount container(s)"

if ($containerCount -gt 1) {
    Write-Error "Multiple containers found for service $containerName`:"
    foreach ($id in $containerIds) {
        $name = docker ps --filter "id=$id" --format "{{.Names}}"
        Write-Error "  - $name (ID: $id)"
    }
    exit 1
}

if ($containerCount -eq 0) {
    Write-Error "No container found for service $containerName"
    exit 1
}

$containerId = $containerIds[0]
Write-Host "Container detected: $containerName ($containerId)"
# Wait for container health (if available) or for it to be running
Write-Host "Waiting for container health status..."
$maxWaitSeconds = 60
$elapsed = 0
$sleepInterval = 2
$healthSupported = $true
while ($elapsed -lt $maxWaitSeconds) {
    try {
        $health = docker inspect --format '{{.State.Health.Status}}' $containerId 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($health)) {
            # Health not configured; fall back to checking .State.Status
            $healthSupported = $false
            $state = docker inspect --format '{{.State.Status}}' $containerId 2>$null
            if ($state -eq 'running') { break }
        } else {
            if ($health -eq 'healthy') { break }
            if ($health -eq 'unhealthy') {
                Write-Error "Container reported unhealthy"
                exit 1
            }
        }
    } catch {
        # ignore and retry
    }
    Start-Sleep -Seconds $sleepInterval
    $elapsed += $sleepInterval
}
if ($elapsed -ge $maxWaitSeconds) {
    if ($healthSupported) {
        Write-Error "Timed out waiting for container to become healthy"
    } else {
        Write-Error "Timed out waiting for container to be running"
    }
    exit 1
}

# Copy entrypoint to container
Write-Host "Copying entrypoint $($envVars.APP_ENTRYPOINT_LOCAL_PATH) to container..."
# Copy to container
docker cp $envVars.APP_ENTRYPOINT_LOCAL_PATH "${containerId}:$($envVars.APP_ENTRYPOINT_SERVER_PATH)" 2>&1
if ( -not $?) {
    Write-Error "Failed to copy entrypoint to container"
    exit 1
}
Write-Host "Entrypoint copied successfully."
# Set execute permissions
Write-Host "Setting execute permissions for $($envVars.APP_ENTRYPOINT_SERVER_PATH)..."
docker exec $containerId dos2unix $envVars.APP_ENTRYPOINT_SERVER_PATH 2>&1
if ( -not $?) {
    Write-Error "Failed to convert $envVars.APP_ENTRYPOINT_SERVER_PATH to Unix format"
    exit 1
} 
Write-Host "Converted to Unix format successfully."

docker exec $containerId chmod +x $envVars.APP_ENTRYPOINT_SERVER_PATH 2>&1
if (-not $?) {
    Write-Error "Failed to change permissions for $envVars.APP_ENTRYPOINT_SERVER_PATH"
    exit 1
}
Write-Host "Permissions changed successfully."

Write-Host "Executing entrypoint in container..."
docker exec $containerId sh $envVars.APP_ENTRYPOINT_SERVER_PATH 2>&1
if ( -not $?) {
    Write-Error "Failed to execute entrypoint in container"
    exit 1
} 
Write-Host "Entrypoint executed successfully."