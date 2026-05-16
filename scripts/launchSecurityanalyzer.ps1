param(
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [string]$Params = "",
    [string]$ImageName = "auditoria-web",
    [string]$ContainerName = "auditoria-web-container",
    [string]$ResultsDir = "./results"
)

Write-Host "[+] Comprobando si la imagen existe..."

# Construir imagen si no existe
$imageExists = docker images -q $ImageName
if (-not $imageExists) {
    Write-Host "[+] Imagen no encontrada. Construyendo..."
    docker build -t $ImageName .
}

# Crear carpeta de resultados
if (-not (Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir | Out-Null
}

Write-Host "[+] Ejecutando contenedor..."

docker run --rm `
    -v "$(Resolve-Path $ResultsDir):/analysis/results" `
    --name $ContainerName `
    $ImageName `
    bash -c "./run-analysis.sh -t $Target $Params"

Write-Host "[+] Análisis completado. Resultados en $ResultsDir"
