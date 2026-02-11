Param(
    [string]$EnvFile = ".\env\dev.apache.env",
    [string]$Dockerfile = "docker/apache.dev.dockerfile",
    [string]$Tag = "apache:dev"
)

Import-Module .\scripts\mods\env.ps1

$envVars = Get-EnvVarsFromFile -envFile $EnvFile

$buildArgs = $envVars.GetEnumerator() | ForEach-Object {
    @("--build-arg", "$($_.Key)=$($_.Value)") -join ' '
}

$argsArray = @(
    'build',
    '--no-cache',
    $buildArgs -join ' ',
    '-f', $Dockerfile,
    '-t', $Tag,
    "."
)

Write-Host "Ejecutando: docker $($argsArray -join ' ')"
& docker @argsArray

$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
