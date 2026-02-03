Param(
    [string]$envFile = ".\env\dev.phpapache.env"
)
# Cargar variables de entorno desde el archivo
$envVars = @{}

if (-not (Test-Path $envFile)) {
    Write-Error "Archivo de entorno '$envFile' no encontrado."
    exit 1
}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

$imagename = $envVars['IMAGE_NAME']
$containername = $envVars['CONTAINER_NAME']
$servername = $envVars['SERVER_NAME']
$serverport = $envVars['SERVER_PORT']
$localrootpath = $envVars['LOCAL_ROOT_PATH']
$serverrootpath = $envVars['SERVER_ROOT_PATH']
$locallogpath = $envVars['LOCAL_LOG_PATH']
$serverlogpath = $envVars['SERVER_LOG_PATH']
$serverip = $envVars['SERVER_IP']
$networkdriver = $envVars['NETWORK_DRIVER']
$networkname = $envVars['NETWORK_NAME']
$networksubnet = $envVars['NETWORK_SUBNET']
$networksubnetgateway = $envVars['NETWORK_SUBNET_GATEWAY']

if ($networkname -and $networksubnet -and $networksubnetgateway) {
    .\scripts\create_network.ps1 -networkName $networkname -subnet $networksubnet -gateway $networksubnetgateway -driver $networkdriver        
}
else {
    Write-Warning "La red Docker ya existe o no se proporcionaron todos los parámetros necesarios."
}

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
    "-v .\phpinfo:/var/www/phpinfo",
    "--env-file $envFile",
    "--hostname $containername",
    "--network $networkname",
    "--ip $serverip",
    $imagename
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd
