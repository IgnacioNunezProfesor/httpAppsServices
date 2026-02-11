Param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFile
)

Import-Module .\scripts\mods\env.ps1
$envVars = Get-EnvVarsFromFile -envFile $EnvFile

$Dockerfile = $envVars['DOCKERFILE']
$Tag = $envVars['IMAGE_NAME']

# Filtrar solo las variables que empiezan por BUILD_
$buildVars = $envVars.GetEnumerator() | Where-Object { $_.Key -like "BUILD_*" }

$buildArgsArray = @()
if ($buildVars.Count -eq 0) {
    Write-Warning "No se encontró ninguna variable que empiece por 'BUILD_'."
}
else {
    # Construir los argumentos --build-arg
    foreach ($item in $buildVars) {
        $buildArgsArray += "--build-arg" + " $($item.Key)=$($item.Value)"
    }
}

# Parámetros finales para docker
$dockerParamsStr = @(
    'build'
) + $buildArgsArray + @(
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
