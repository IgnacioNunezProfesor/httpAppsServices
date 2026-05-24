param(
    [string]$EnvFile=".\env\dev.securityanalyzer.env"
)

# Validar que el archivo .env existe
if (-not (Test-Path $EnvFile)) {
    Write-Host "[-] Error: Archivo .env no encontrado: $EnvFile"
    exit 1
}

if (Get-Module 'env') { 
    Remove-Module 'env' -Force 
} 
Import-Module .\scripts\mods\env.psm1 -Force

$envVars = Get-EnvVarsFromFile -envFile $EnvFile

# Validar que todas las variables requeridas están presentes
if ([string]::IsNullOrEmpty($envVars.DOCKERFILE_PATH) -or [string]::IsNullOrEmpty($envVars.CONTAINER_NAME) -or 
    [string]::IsNullOrEmpty($envVars.TARGET_URL) -or [string]::IsNullOrEmpty($envVars.RESULTS_FILE_PATH)) {
    Write-Host "[-] Error: Variables requeridas faltantes en el archivo .env"
    exit 1
}

Write-Host "[+] Variables cargadas desde $EnvFile"
$envVars.GetEnumerator() | 
    ForEach-Object { Write-Host "    $($_.Key): $($_.Value)" }
Write-Host ""

# Extraer el nombre de la imagen del Dockerfile
$imageName = $envVars.CONTAINER_NAME

Write-Host "[+] Comprobando si la imagen existe..."

# Construir imagen si no existe
$imageExists = docker images -q $imageName
if (-not $imageExists) {
    Write-Host "[+] Imagen no encontrada. Construyendo desde $envVars.DOCKERFILE_PATH..."
    Write-Host "[+] Lanzando docker build -f $envVars.DOCKERFILE_PATH -t $imageName ."
    
    docker build -f $envVars.DOCKERFILE_PATH -t $imageName .
    # Comprobar si el comando docker build se ejecutó correctamente
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[-] Error: Falló la construcción de la imagen. Código de salida: $LASTEXITCODE"
        exit 1
    }
}

Write-Host "[+] Comprobando que $envVars.RESULTS_FILE_PATH existe"
# Crear carpeta de resultados si no existe
if (-not (Test-Path $envVars.RESULTS_FILE_PATH)) {
    Write-Host "Creando $envVars.RESULTS_FILE_PATH"
    New-Item -ItemType Directory -Path $envVars.RESULTS_FILE_PATH | Out-Null
}

Write-Host "[+] Ejecutando contenedor..."

$dockerfileDir = Split-Path -Parent $envVars.DOCKERFILE_PATH        
$hostScriptPath = Join-Path $dockerfileDir "run-analysis.sh"
$scriptVolume = ""  

if (Test-Path $hostScriptPath) {
    Write-Host "[+] Montando script local de análisis: $hostScriptPath"
    $scriptVolume = "-v", "$((Resolve-Path $hostScriptPath).Path):/analysis/run-analysis.sh"
}
else {
    Write-Host "[!] Aviso: run-analysis.sh no encontrado en $dockerfileDir. Se usará la versión de la imagen si existe."
}

$dockerArgs = @(
    "run", "--rm",
    "-v", "$((Resolve-Path $envVars.RESULTS_FILE_PATH).Path):/analysis/results"
)
if ($scriptVolume) { $dockerArgs += $scriptVolume }
$dockerArgs += @(
    "--name", $envVars.CONTAINER_NAME,
    $imageName,
    "bash", "-c", "/analysis/run-analysis.sh -t $($envVars.TARGET_URL) $($envVars.EXECUTION_PARAMS)"
)

docker @dockerArgs

Write-Host "[+] Análisis completado. Resultados en $envVars.RESULTS_FILE_PATH"
