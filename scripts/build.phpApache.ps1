Param(
    [string]$EnvFile = ".\env\dev.phpapache.env",
    [string]$Dockerfile = "docker/phpapache.dev.dockerfile",
    [string]$Tag = "phpapache:dev"
)

Import-Module .\scripts\mods\env.ps1
$envVars = Get-EnvVarsFromFile -envFile $EnvFile

$buildArgs = $envVars.GetEnumerator() | ForEach-Object { "--build-arg $($_.Key)=$($_.Value)" }

$argsSTR = @(
    'build', 
    '--no-cache', 
    '-f', $Dockerfile, 
    '-t', $Tag
) + $buildArgs + '.'

Write-Host "Ejecutando: docker $($argsSTR -join ' ')" & docker @argsSTR
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}