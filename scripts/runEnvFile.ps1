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

# Construcción correcta del comando Docker
$dockerCmd = @(
    "docker run -d",
    "--name $($envVars['CONTAINER_NAME'])",
    "-p $($envVars['LOCAL_PORT']):$($envVars['SERVER_PORT'])",
    "-v $($envVars['LOCAL_DATA_DIR']):$($envVars['SERVER_DATA_DIR'])",
    "-v $($envVars['LOCAL_LOG_PATH']):$($envVars['SERVER_LOG_PATH'])",
    "--env-file `"$EnvFile`"",
    "--hostname $($envVars['SERVER_NAME'])",
    "--network $($envVars['NETWORK_NAME'])",
    "--ip $($envVars['IP'])",
    $envVars['IMAGE_NAME']
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd
