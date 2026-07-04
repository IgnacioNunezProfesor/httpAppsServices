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

# Levantar contenedor
docker compose -f $envVars.APP_COMPOSER_PATH --env-file $EnvFile up -d

# Esperar a que el contenedor esté listo
Start-Sleep -Seconds 3

# Get container name (by service)
$containerName = $envVars.HTTP_CONTAINER_NAME
Write-Host "Searching for container: $containerName"

# Use exact match with regex anchor (^ and $)
$containerIds = @(docker ps --filter "name=^$containerName`$" --format "{{.ID}}")
$containerCount = $containerIds.Count

Write-Host "Found $containerCount container(s)"

if ($containerCount -eq 0) {
    Write-Error "No container found for service $containerName"
    exit 1
}
elseif ($containerCount -gt 1) {
    Write-Error "Multiple containers found for service $containerName`:"
    foreach ($id in $containerIds) {
        $name = docker ps --filter "id=$id" --format "{{.Names}}"
        Write-Error "  - $name (ID: $id)"
    }
    exit 1
}

$containerId = $containerIds[0]
Write-Host "Container detected: $containerId"
# Copy entrypoint to container
Write-Host "Copying entrypoint $($envVars.APP_ENTRYPOINT) to container..."
# Copy to container
docker cp $envVars.APP_ENTRYPOINT_PATH "${containerId}:/entrypoint-app.sh"
# Set execute permissions
Write-Host "Setting execute permissions for $($envVars.APP_ENTRYPOINT)..."

docker exec $containerId chmod +x /entrypoint-app.sh
docker exec $containerId dos2unix /entrypoint-app.sh
Write-Host "Executing entrypoint in container..."
docker exec -it $containerId /entrypoint-app.sh