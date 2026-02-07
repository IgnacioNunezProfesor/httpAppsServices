# Define parameters with default values
param(
    [string]$envFile = ".\env\dev.mariadb.env"
)
$envVars = @{}

if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
} 
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

$containerName = $envVars['DB_CONTAINER_NAME']

$dbServerDataDir = $envVars['DB_SERVER_DATA_DIR']
$dbLocalDataDir = $envVars['DB_LOCAL_DATA_DIR']

$dbServerLog = $envVars['DB_SERVER_LOG']
$dbLocalLog = $envVars['DB_LOCAL_LOG']

$dbport = $envVars['DB_PORT'] 
$imageName = $envVars['DB_IMAGE_NAME']
$networkName = $envVars['DB_NETWORK_NAME']
$ip = $envVars["DB_IP"]

if ($envVars['DB_NETWORK_NAME'] -and $envVars['DB_NETWORK_SUBNET'] -and $envVars['DB_NETWORK_SUBNET_GATEWAY'] ) {
    $networkName = $envVars['DB_NETWORK_NAME']
    $networksubnet = $envVars['DB_NETWORK_SUBNET']
    $networksubnetgateway = $envVars['DB_NETWORK_SUBNET_GATEWAY']
    $networkdriver = $envVars['DB_NETWORK_DRIVER']

    Write-Host "Creando red: $networkName"
    .\scripts\create_network.ps1 -networkName $networkName -subnet $networksubnet -gateway $networksubnetgateway -driver $networkDriver    
}
else {
    Write-Warning "La red Docker ya existe o no se proporcionaron todos los parámetros necesarios."
}

# Eliminar contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Eliminar directorios de datos y logs si existen
if (Test-Path $dbLocalDataDir) {
    Write-Host "Eliminando directorio de datos: $dbLocalDataDir"

    try {
        Remove-Item -Path $dbLocalDataDir -Recurse -Force -ErrorAction Stop
        Write-Host "Directorio eliminado correctamente."
    }
    catch {
        Write-Host "ERROR: No se pudo eliminar el directorio."
        Write-Host "Detalle: $($_.Exception.Message)"
    }

    if (Test-Path $dbLocalDataDir) {
        Write-Host "ADVERTENCIA: El directorio sigue existiendo después del intento de borrado."
    }
    else {
        Write-Host "Verificación OK: el directorio ya no existe."
    }
}
else {
    Write-Host "El directorio no existe: $dbLocalDataDir"
}
# Eliminar directorios de datos y logs si existen
if (Test-Path $dbLocalLog) {
    Write-Host "Eliminando directorio de logs: $dbLocalLog"

    try {
        Remove-Item -Path $dbLocalLog -Recurse -Force -ErrorAction Stop
        Write-Host "Directorio eliminado correctamente."
    }
    catch {
        Write-Host "ERROR: No se pudo eliminar el directorio."
        Write-Host "Detalle: $($_.Exception.Message)"
    }

    if (Test-Path $dbLocalLog) {
        Write-Host "ADVERTENCIA: El directorio sigue existiendo después del intento de borrado."
    }
    else {
        Write-Host "Verificación OK: el directorio ya no existe."
    }
}
else {
    Write-Host "El directorio no existe: $dbLocalLog"
}

# Construir y ejecutar comando docker
$dockerCmd = @(
    "docker run -d",
    "--name $containerName",
    "-p ${dbport}:${dbport}",
    "-v ${dbLocalDataDir}:${dbServerDataDir}",
    "-v ${dbLocalLog}:${dbServerLog}",
    "--env-file $envFile",
    "--hostname $containerName",
    "--network $networkName",
    "--ip $ip"
    $imageName
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd