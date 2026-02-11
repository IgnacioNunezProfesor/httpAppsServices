Param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFile
)

Import-Module .\scripts\mods\env.ps1
$envVars = Get-EnvVarsFromFile -envFile $EnvFile

$Dockerfile = $envVars['DOCKERFILE']
$Tag = $envVars['IMAGE_NAME']

# Filtrar solo las variables que empiezan por BUILD_
$buildVars = Get-EnvVarsByPrefix -envVars $envVars -prefix "BUILD_";

$buildArgs = EnvVarsToBuildArgs -envVars $buildVars

# Parámetros finales para docker
$dockerParamsStr = @(
    'build',
    $buildArgs,
    '--no-cache',
    '-f', $Dockerfile,
    '-t', $Tag,
    '.'
)

Write-Host "Ejecutando: docker $($dockerParamsStr -join ' ')"

docker $dockerParamsStr

$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
