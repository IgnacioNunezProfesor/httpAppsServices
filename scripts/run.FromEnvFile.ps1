Param(
    [Parameter(Mandatory = $true)]
    [string]$envFile = ".\env\dev.apache.env",

    [Parameter(Mandatory = $true)]
    [string]$networkFile = ".\env\dev.network.env"
)

if (Get-Module 'env') { 
    Remove-Module 'env' -Force 
}
Import-Module .\scripts\mods\env.psm1 -Force

if (Get-Module 'networks') { 
    Remove-Module 'networks' -Force 
} 
Import-Module .\scripts\mods\networks.psm1 -Force


$envVars = Get-EnvVarsFromFile -envFile $EnvFile
if (-not $envVars) { 
    Write-Error "No se pudieron cargar las variables de entorno desde $EnvFile" 
    exit 1 
} 
$networkVars = Get-EnvVarsFromFile -envFile $networkFile 
if (-not $networkVars) { 
    Write-Error "No se pudieron cargar las variables de entorno desde $networkFile" 
    exit 1 
} 
$containername = $envVars['CONTAINER_NAME'] 
$serverport = $envVars['SERVER_PORT'] 
$localrootpath = $envVars['LOCAL_ROOT_PATH'] 
$serverrootpath = $envVars['SERVER_ROOT_PATH'] 
$locallogpath = $envVars['LOCAL_LOG_PATH'] 
$serverlogpath = $envVars['SERVER_LOG_PATH'] 
$imagename = $envVars['IMAGE_NAME'] 
$serverip = $envVars['SERVER_IP'] 

$networkname = $networkVars["NETWORK_NAME"] 
$networkdriver = $networkVars["NETWORK_DRIVER"] 
$networksubnet = $networkVars["NETWORK_SUBNET"] 
$networksubnetgateway = $networkVars["NETWORK_SUBNET_GATEWAY"]

$overlapResult = Test-NetworkOverlap -newCIDR $networksubnet 
if ($overlapResult.Overlaps) { 
    Write-Error "La subred $networksubnet se solapa con la red Docker '
    $($overlapResult.OverlappingNetwork)' (ID: $($overlapResult.OverlappingNetworkId)). Por favor, elija una subred diferente." 
    exit 1 
}

$InRangeIpResult = Test-IpInSubnet -IP $serverip -Subnet $networksubnet

if (-not $InRangeIpResult.InRange ) {
    Write-Error "La IP $serverip no está dentro de la subred $networksubnet. Por favor, elija una IP que esté dentro de la subred." 
    exit 1 
} 

createNetwork -networkName $networkname -subnet $networksubnet -gateway $networksubnetgateway -driver $networkdriver        


if (docker ps -a --filter "name=^$containername$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containername"
    docker stop $containername 2>$null
    docker rm $containername 2>$null
}

if (Test-Path $locallogpath) {
    Write-Host "Limpiando contenido de: $locallogpath"
    Remove-Item "$locallogpath\*" -Force -Recurse
}

$dockerCmd = @(
    "docker run -d",
    "--name $containername",
    "-p ${serverport}:${serverport}",
    "-v ${localrootpath}:${serverrootpath}",
    "-v ${locallogpath}:${serverlogpath}",
    "--env-file $envFile",
    "--hostname $containername",
    "--network $networkname",
    "--ip $serverip",
    $imagename
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd
