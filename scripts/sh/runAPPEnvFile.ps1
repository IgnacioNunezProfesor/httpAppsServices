Param(
    [Parameter(Mandatory = $true)]
    [string]$envFile
)

# ============================================================================
# Cleanup Handler
# ============================================================================
$script:containerId = $null
$script:containerName = $null
$script:cleanupOnExit = $false

# Set up trap to catch any unhandled exceptions or script termination
trap {
    Write-Error "Unexpected error occurred: $_"
    Clear-Containers -reason "Trap caught exception: $_"
    exit 1
}

# ============================================================================
# Module Loading
# ============================================================================
Write-Host "Loading modules..."

if (Get-Module 'env') { Remove-Module 'env' -Force }
Import-Module .\scripts\mods\env.psm1 -Force

if (Get-Module 'networks') { Remove-Module 'networks' -Force }
Import-Module .\scripts\mods\networks.psm1 -Force

if (Get-Module 'docker') { Remove-Module 'docker' -Force }
Import-Module .\scripts\mods\docker.psm1 -Force

# ============================================================================
# Load and Validate Environment
# ============================================================================
Write-Host "Loading environment variables from: $envFile"
$envVars = Get-EnvVarsFromFile -envFile $EnvFile
if (-not $envVars) {
    Write-Error "No se pudieron cargar las variables de entorno desde $EnvFile"
    exit 1
}

$requiredVars = @(
    'APP_NAME',
    'APP_GITHUB_URL',
    'APP_LOCAL_PATH',
    'APP_COMPOSE_PATH',
    'APP_ENTRYPOINT_LOCAL_PATH',
    'APP_ENTRYPOINT_SERVER_PATH',
    'HTTP_CONTAINER_NAME',
    'DB_IMAGE_NAME',
    'DB_CONTAINER_NAME',
    'DB_DOCKERFILE_PATH',
    'HTTP_IMAGE_NAME',
    'HTTP_DOCKERFILE_PATH',
    'HTTP_SERVER_PORT',
    'HTTP_LOCAL_PORT',
    'DB_SERVER_PORT',
    'DB_LOCAL_PORT',
    'DB_NAME',
    'DB_USER',
    'DB_PASS',
    'NETWORK_NAME',
    'NETWORK_ALIAS',
    'NETWORK_DRIVER',
    'NETWORK_SUBNET',
    'NETWORK_SUBNET_GATEWAY'
)

if (-not (Test-EnvVars -envVars $envVars -requiredVars $requiredVars)) {
    Write-Error "Validation failed. Please check your environment file and try again."
    exit 1
}

Write-Host "Environment variables validated successfully."

# Store container/network info for cleanup
$script:containerName = $envVars.HTTP_CONTAINER_NAME
$script:networkName = $envVars.NETWORK_NAME

try {
    # ============================================================================
    # Register Application
    # ============================================================================
Write-Host "Registering application: $($envVars.APP_NAME)..."

# ============================================================
# 1. Si existe APP_DOWNLOAD_URL → descarga desde URL
# ============================================================
if ($envVars.APP_DOWNLOAD_URL) {
    Write-Host "APP_DOWNLOAD_URL detected → downloading application..." -ForegroundColor Cyan

    & .\scripts\AdminApp.ps1 -Download `
        -DownloadUrl $envVars.APP_DOWNLOAD_URL `
        -Destination Join-Path $envVars.APP_WWWROOT $envVars.APP_LOCAL_PATH
    if (-not $?) {
        Write-Error "Failed to download application from URL"
        Clear-Containers -reason "Application download failed"
        exit 1
    }

    Write-Host "Application downloaded successfully." -ForegroundColor Green
}

# ============================================================
# 2. Si NO existe APP_DOWNLOAD_URL → debe existir APP_GITHUB_URL
# ============================================================
elseif ($envVars.APP_GITHUB_URL) {
    Write-Host "APP_GITHUB_URL detected → registering Git submodule..." -ForegroundColor Cyan

    & .\scripts\AdminApp.ps1 -add `
        -Name $envVars.APP_NAME `
        -Url $envVars.APP_GITHUB_URL `
        -Path $envVars.APP_LOCAL_PATH `
        -Branch $envVars.APP_GITHUB_BRANCH

    if (-not $?) {
        Write-Error "Failed to register application from GitHub"
        Clear-Containers -reason "Application registration failed"
        exit 1
    }

    Write-Host "Application registered successfully via Git." -ForegroundColor Green
}

# ============================================================
# 3. Si no existe ninguna → error
# ============================================================
else {
    Write-Error "No APP_DOWNLOAD_URL or APP_GITHUB_URL provided. Cannot deploy application."
    exit 1
}


    # ============================================================================
    # Start Docker Containers
    # ============================================================================
    Write-Host "Starting Docker containers..." -ForegroundColor Green

    # ============================================================================
    # Validate Docker Compose File
    # ============================================================================
    Write-Host "Validating docker-compose file: $($envVars.APP_COMPOSE_PATH)" -ForegroundColor Yellow

    $composeCheck = Invoke-DockerCommand `
        -Command "compose -f `"$($envVars.APP_COMPOSE_PATH)`" --env-file `"$EnvFile`" config" `
        -ErrorMessage "Docker Compose validation failed"

    if (-not $composeCheck) {
        Write-Error "Docker Compose validation returned empty output. Please check your compose file."
        Clear-Containers -reason "Invalid docker-compose.yml"
        exit 1
    }

    Write-Host "Docker Compose file validated successfully." -ForegroundColor Green


    Invoke-DockerCommand -Command "compose -f `"$($envVars.APP_COMPOSE_PATH)`" --env-file `"$EnvFile`" up -d --build" `
        -ErrorMessage "Failed to start Docker containers"

    Write-Host "Containers started successfully." -ForegroundColor Green
    $script:cleanupOnExit = $true  # Mark that we have containers to clean up

    # ============================================================================
    # Find Container
    # ============================================================================
    $containerName = $envVars.HTTP_CONTAINER_NAME
    Write-Host "Searching for container: $containerName"

    $psOutput = Invoke-DockerCommand -Command "ps --filter `"name=^$containerName`$`" --format `"{{.ID}}`"" `
        -ErrorMessage "Failed to query Docker containers"

    $containerIds = @($psOutput | Where-Object { $_ })
    $containerCount = $containerIds.Count

    Write-Host "Found $containerCount container(s)"

    if ($containerCount -gt 1) {
        Write-Error "Multiple containers found for service $containerName"
        Clear-Containers -reason "Multiple containers found"
        exit 1
    }

    if (
        $containerCount -eq 0) {
        Write-Error "No container found for service $containerName"
        Clear-Containers -reason "Container not found"
        exit 1
    }

    $script:containerId = $containerIds[0]
    Write-Host "Container detected: $containerName ($script:containerId)"

    # ============================================================================
    # Copy Apache configuration files if provided
    # ============================================================================
    if ($envVars.APP_APACHE_CONFIG_PATH -and (Test-Path $envVars.APP_APACHE_CONFIG_PATH)) {
        $apacheConfigFiles = Get-ChildItem -Path $envVars.APP_APACHE_CONFIG_PATH -Filter *.conf -File

        if ($apacheConfigFiles.Count -gt 0) {
            Write-Host "Copying Apache configuration files from $($envVars.APP_APACHE_CONFIG_PATH) to /etc/apache2/conf.d/..."

            foreach ($apacheConfigFile in $apacheConfigFiles) {
                Invoke-DockerCommand -Command "cp `"$($apacheConfigFile.FullName)`" `"${script:containerId}:/etc/apache2/conf.d/`"" `
                    -ErrorMessage "Failed to copy Apache config file $($apacheConfigFile.Name)"
            }
        }
        else {
            Write-Host "No Apache config files (*.conf) found in $($envVars.APP_APACHE_CONFIG_PATH)."
        }
    }

    # ============================================================================
    # Copy and Execute Entrypoint
    # ============================================================================
    Write-Host "Copying entrypoint to container..."
    Invoke-DockerCommand -Command "cp `"$($envVars.APP_ENTRYPOINT_LOCAL_PATH)`" `"${script:containerId}:$($envVars.APP_ENTRYPOINT_SERVER_PATH)`"" `
        -ErrorMessage "Failed to copy entrypoint to container"  
    
  
    Write-Host "Converting line endings to Unix format..."
    Invoke-DockerExecCommand -ContainerId $script:containerId `
        -Command "dos2unix $($envVars.APP_ENTRYPOINT_SERVER_PATH)" `
        -ErrorMessage "Failed to convert to Unix format"
    
    Write-Host "Setting execute permissions..."
    Invoke-DockerExecCommand -ContainerId $script:containerId `
        -Command "chmod +x $($envVars.APP_ENTRYPOINT_SERVER_PATH)" `
        -ErrorMessage "Failed to set execute permissions"
    
    Write-Host "Executing entrypoint in container..."
    Invoke-DockerExecCommand -ContainerId $script:containerId `
        -Command "sh $($envVars.APP_ENTRYPOINT_SERVER_PATH)" `
        -ErrorMessage "Failed to execute entrypoint"
    Write-Host "Application deployment completed successfully."
    $script:cleanupOnExit = $false  # Success: don't clean up

} catch {
    Write-Error "Critical error during deployment: $_"
    Clear-Containers -reason "Critical exception: $_"
    exit 1
} finally {
    # Final cleanup if script exits unexpectedly
    if ($script:cleanupOnExit) {
        Write-Host "Performing cleanup due to script exit..."
        Clear-Containers -reason "Script exit"
    }
}