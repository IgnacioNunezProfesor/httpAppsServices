# Define parameters with default values
param(
    [string]$envFile = ".\env\dev.mariadb.env"
)
Import-Module .\scripts\mods\env.ps1

$envVars = Get-EnvVarsFromFile -envFile $envFile

$Dockerfile = $envVars['DB_DOCKERFILE']
$Tag = $envVars['DB_IMAGE_NAME']
$buildArgsSTR = @(
    "--build-arg DB_UNIX_USER=" + $envVars['DB_UNIX_USER'],
    "--build-arg DB_SERVER_DATADIR=" + $envVars['DB_SERVER_DATADIR'],
    "--build-arg DB_SERVER_LOG=" + $envVars['DB_SERVER_LOG']
) -join ' '

$cmddockerSTR = @(
    'docker build', 
    '--no-cache', 
    '-f', $Dockerfile, 
    '-t', $Tag, 
    $buildArgsSTR, 
    '.'
) -join ' '


Write-Host "Ejecutando: docker $cmddockerSTR" 
Invoke-Expression $cmddockerSTR
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}