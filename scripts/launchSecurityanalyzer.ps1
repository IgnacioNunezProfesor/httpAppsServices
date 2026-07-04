param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFile
)

# Validar que el archivo .env existe
if (-not (Test-Path $EnvFile)) {
    Write-Host "[-] Error: Archivo .env no encontrado: $EnvFile"
    exit 1
}

# Leer el archivo .env y asignar las variables
$envContent = Get-Content $EnvFile
$dockerfilePath = ""
$containerName = ""
$targetUrl = ""
$resultsFilePath = ""
$executionParams = ""

foreach ($line in $envContent) {
    $line = $line.Trim()
    
    # Saltar líneas vacías y comentarios
    if ([string]::IsNullOrEmpty($line) -or $line.StartsWith("#")) {
        continue
    }
    
    # Parsear variables del archivo .env
    if ($line -match "^DOCKERFILE_PATH=(.*)$") {
        $dockerfilePath = $matches[1].Trim('"')
    }
    elseif ($line -match "^CONTAINER_NAME=(.*)$") {
        $containerName = $matches[1].Trim('"')
    }
    elseif ($line -match "^TARGET_URL=(.*)$") {
        $targetUrl = $matches[1].Trim('"')
    }
    elseif ($line -match "^RESULTS_FILE_PATH=(.*)$") {
        $resultsFilePath = $matches[1].Trim('"')
    }
    elseif ($line -match "^EXECUTION_PARAMS=(.*)$") {
        $executionParams = $matches[1].Trim('"')
    }
}

# Validar que todas las variables requeridas están presentes
if ([string]::IsNullOrEmpty($dockerfilePath) -or [string]::IsNullOrEmpty($containerName) -or 
    [string]::IsNullOrEmpty($targetUrl) -or [string]::IsNullOrEmpty($resultsFilePath)) {
    Write-Host "[-] Error: Variables requeridas faltantes en el archivo .env"
    exit 1
}

Write-Host "[+] Variables cargadas desde $EnvFile"
Write-Host "    DOCKERFILE_PATH: $dockerfilePath"
Write-Host "    CONTAINER_NAME: $containerName"
Write-Host "    TARGET_URL: $targetUrl"
Write-Host "    RESULTS_FILE_PATH: $resultsFilePath"
Write-Host "    EXECUTION_PARAMS: $executionParams"

# Extraer el nombre de la imagen del Dockerfile
$imageName = $containerName

Write-Host "[+] Comprobando si la imagen existe..."

# Construir imagen si no existe
$imageExists = docker images -q $imageName
if (-not $imageExists) {
    Write-Host "[+] Imagen no encontrada. Construyendo desde $dockerfilePath..."
    Write-Host "[+] Lanzando docker build -f $dockerfilePath -t $imageName ."
    
    docker build -f $dockerfilePath -t $imageName .
    # Comprobar si el comando docker build se ejecutó correctamente
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[-] Error: Falló la construcción de la imagen. Código de salida: $LASTEXITCODE"
        exit 1
    }
}

Write-Host "[+] Comprobando que $resultsFilePath existe"
# Crear carpeta de resultados si no existe
if (-not (Test-Path $resultsFilePath)) {
    Write-Host "Creando $resultsFilePath"
    New-Item -ItemType Directory -Path $resultsFilePath | Out-Null
}

Write-Host "[+] Ejecutando contenedor..."
$output = docker run --rm `
    -v "$(Resolve-Path $resultsFilePath):/analysis/results" `
    --name $containerName `
    $imageName `
    bash -c "if [ -f /analysis/run-analysis.sh ]; then /analysis/run-analysis.sh -t $targetUrl $executionParams; else echo '[-] Error: /analysis/run-analysis.sh no encontrado dentro del contenedor'; ls -la /analysis; exit 1; fi" 2>&1

$output
Write-Host "[+] Análisis completado. Resultados en $resultsFilePath"
