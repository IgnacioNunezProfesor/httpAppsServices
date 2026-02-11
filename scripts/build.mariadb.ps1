# Define parameters with default values
param(
    [string]$envFile = ".\env\dev.mariadb.env"
)
Import-Module .\scripts\mods\env.ps1

$envVars = Get-EnvVarsFromFile -envFile $envFile

$Dockerfile = $envVars['DB_DOCKERFILE']
$Tag = $envVars['DB_IMAGE_NAME']

# Filtrar solo las variables que empiezan por BUILD_
$buildVars = $envVars.GetEnumerator() | Where-Object { $_.Key -like "BUILD_*" }

if ($buildVars.Count -eq 0) {
    Write-Warning "No se encontró ninguna variable que empiece por 'BUILD_'."
}

# Construir los argumentos --build-arg
$buildArgsArray = @()
foreach ($item in $buildVars) {
    $buildArgsArray += "--build-arg"
    $buildArgsArray += "$($item.Key)=$($item.Value)"
}

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