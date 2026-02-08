Param(
    [string]$EnvFile = ".\env\dev.apache.env",
    [string]$Dockerfile = "docker/apache.dev.dockerfile",
    [string]$Tag = "apache:dev"
)

Import-Module .\scripts\mods\env.ps1

$buildArgs = Get-EnvVarsFromFile -envFile $envFile
$buildArgs = $buildArgs.GetEnumerator() | ForEach-Object { "--build-arg $($_.Key)=$($_.Value)" }

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