Param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFile,

    [Parameter(Mandatory = $true)]
    [string]$NetworkFile
)

# Recargar módulos
if (Get-Module 'env') { 
    Remove-Module 'env' -Force 
}
Import-Module .\scripts\mods\env.psm1 -Force

if (Get-Module 'networks') { 
    Remove-Module 'networks' -Force 
} 
Import-Module .\scripts\mods\networks.psm1 -Force

# Cargar variables
$envVars = Get-EnvVarsFromFile -envFile $EnvFile
if (-not $envVars) { 
    Write-Error "No se pudieron cargar las variables de entorno desde $EnvFile" 
    exit 1 
} 

$networkVars = Get-EnvVarsFromFile -envFile $NetworkFile 
if (-not $networkVars) { 
    Write-Error "No se pudieron cargar las variables de entorno desde $NetworkFile" 
    exit 1 
} 

# Validar solapamiento de redes
$overlapResult = Test-NetworkOverlap -newCIDR $networkVars['NETWORK_SUBNET']
if ($overlapResult.Overlaps) { 
    Write-Error "La subred ${networkVars['NETWORK_SUBNET']} se solapa con la red Docker '$($overlapResult.OverlappingNetwork)' (ID: $($overlapResult.OverlappingNetworkId)). Por favor, elija una subred diferente." 
    exit 1 
}

# Validar IP dentro de la subred
$InRangeIpResult = Test-IpInSubnet -IP $envVars['IP'] -Subnet $networkVars['NETWORK_SUBNET']
if (-not $InRangeIpResult ) {
    Write-Error "La IP ${envVars['IP']} no está dentro de la subred ${networkVars['NETWORK_SUBNET']} . Por favor, elija una IP que esté dentro de la subred." 
    exit 1 
} 

# Crear red Docker
createNetwork `
    -NetworkName $networkVars['NETWORK_NAME'] `
    -Driver $networkVars['NETWORK_DRIVER'] `
    -Subnet $networkVars['NETWORK_SUBNET'] `
    -Gateway $networkVars['NETWORK_SUBNET_GATEWAY']

# Eliminar contenedor previo
if (docker ps -a --filter "name=^$($envVars['CONTAINER_NAME'])$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $($envVars['CONTAINER_NAME'])"
    docker stop $envVars['CONTAINER_NAME'] 2>$null
    docker rm $envVars['CONTAINER_NAME'] 2>$null
}

# Limpiar logs
if (Test-Path $envVars['LOCAL_LOG_PATH']) {
    Write-Host "Limpiando contenido de: $($envVars['LOCAL_LOG_PATH'])"
    Remove-Item "$($envVars['LOCAL_LOG_PATH'])\*" -Force -Recurse
}

# Construcción correcta del comando Docker (añadir líneas solo si existen las variables)
$parts = @()
$parts += 'docker run -d'
if (-not $envVars['CONTAINER_NAME']) {
    Write-Error "La variable CONTAINER_NAME es obligatoria para nombrar el contenedor."
    exit 1
}
$parts += "--name $($envVars['CONTAINER_NAME'])"
# Puerto
if ( -not ($envVars['LOCAL_PORT'] -and $envVars['SERVER_PORT'])) {
    Write-Error "Las variables LOCAL_PORT y SERVER_PORT son obligatorias para exponer puertos."
    exit 1
}

$parts += "-p $($envVars['LOCAL_PORT']):$($envVars['SERVER_PORT'])"

if ( -not ($envVars['LOCAL_LOG_PATH'] -and $envVars['SERVER_LOG_PATH'])) {
    Write-Error "Las variables LOCAL_LOG_PATH y SERVER_LOG_PATH son obligatorias para montar el volumen de logs."
    exit 1
}
$parts += "-v $($envVars['LOCAL_LOG_PATH']):$($envVars['SERVER_LOG_PATH'])"


# Volúmenes (agregar solo si existen)
if ($envVars['LOCAL_DATA_DIR'] -and $envVars['SERVER_DATA_DIR']) {
    $parts += "-v $($envVars['LOCAL_DATA_DIR']):$($envVars['SERVER_DATA_DIR'])"
}
if ($envVars['LOCAL_INFO_PATH'] -and $envVars['SERVER_INFO_PATH']) {
    $parts += "-v $($envVars['LOCAL_INFO_PATH']):$($envVars['SERVER_INFO_PATH'])"
}
if ($envVars['LOCAL_ROOT_PATH'] -and $envVars['SERVER_ROOT_PATH']) {
    $parts += "-v $($envVars['LOCAL_ROOT_PATH']):$($envVars['SERVER_ROOT_PATH'])"
}

# Archivo de entorno
if (-not $EnvFile) {
    Write-Host "Advertencia: No se ha definido la ruta de las variables de entorno." ;
    exit 1
}
$parts += "--env-file `"$EnvFile`""

# Otros parámetros opcionales
if ( -not $envVars['SERVER_NAME']) { 
    Write-Host "Advertencia: SERVER_NAME no está definido. Se usará el nombre del contenedor como hostname." 
}
$parts += "--hostname $($envVars['SERVER_NAME'])" 

if ( -not $envVars['NETWORK_NAME']) { 
    Write-Error "NETWORK_NAME es obligatorio para conectar el contenedor a la red." ; 
    exit 1 
}
$parts += "--network $($envVars['NETWORK_NAME'])" 

if ( -not $envVars['IP']) { 
    Write-Error "IP es obligatorio para asignar una dirección IP específica al contenedor." ; 
    exit 1 
}
$parts += "--ip $($envVars['IP'])" 

# Imagen (obligatorio)
if (-not $envVars['IMAGE_NAME']) {
    Write-Error "IMAGE_NAME es obligatorio para especificar la imagen de Docker a usar."
    exit 1
}
$parts += $envVars['IMAGE_NAME']

$dockerCmd = $parts -join ' '

Write-Host "Ejecutando: $dockerCmd"
$dockerResult = Invoke-Expression $dockerCmd 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Operación exitosa. Resultado: $dockerResult"
} else {
    Write-Error "Error al ejecutar Docker. Código: $LASTEXITCODE. Detalle: $dockerResult"
    exit $LASTEXITCODE
}
