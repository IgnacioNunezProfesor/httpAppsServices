Param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFile = ".\env\dev.apache.env"
)

Import-Module .\scripts\mods\env.ps1

# Cargar variables del archivo .env
$envVars = Get-EnvVarsFromFile -envFile $EnvFile

# Variables obligatorias
$Dockerfile = $envVars['DOCKERFILE']
$Tag = $envVars['IMAGE_NAME']

if (-not $Dockerfile) {
    Write-Error "Falta DOCKERFILE en $EnvFile"
    exit 1
}

if (-not $Tag) {
    Write-Error "Falta IMAGE_NAME en $EnvFile"
    exit 1
}

# Filtrar variables BUILD_*
$buildVars = Get-EnvVarsByPrefix -envVars $envVars -prefix "BUILD_"
if ($buildVars.Count -eq 0) {
    $buildVars = @{}
}

# Convertirlas a --build-arg
$buildArgs = EnvVarsToBuildArgs -envVars $buildVars

# Construir parámetros docker
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

