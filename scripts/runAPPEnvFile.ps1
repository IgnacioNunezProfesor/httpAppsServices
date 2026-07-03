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

# Obtener nombre del contenedor (por servicio)
$containerName = docker compose -f $envVars.APP_COMPOSER_PATH ps --services | Select-Object -First 1
$containerId = docker ps --filter "name=$containerName" --format "{{.ID}}"

if (-not $containerId) {
    Write-Error "No se encontró el contenedor del servicio $containerName"
    exit 1
}

Write-Host "Contenedor detectado: $containerId"

# Copiar entrypoint dentro del contenedor
Write-Host "Copiando entrypoint $($envVars.APP_ENTRYPOINT) dentro del contenedor..."
docker cp $envVars.APP_ENTRYPOINT_PATH "${containerId}:/$envVars.APP_ENTRYPOINT"

# Dar permisos de ejecución
docker exec $containerId chmod +x /entrypoint.sh

# Ejecutar entrypoint dentro del contenedor
Write-Host "Ejecutando entrypoint dentro del contenedor..."
docker exec -it $containerId /entrypoint.sh