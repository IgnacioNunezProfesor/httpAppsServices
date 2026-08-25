Param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFile
)

# --- Cargar módulo env.psm1 ---
if (Get-Module 'env') {
    Remove-Module 'env' -Force
}
Import-Module .\scripts\ps1\mods\env.psm1 -Force

Write-Host "📄 Cargando variables desde: $EnvFile"
$envVars = Get-EnvVarsFromFile -envFile $EnvFile

if (-not $envVars) {
    Write-Error "❌ No se pudieron cargar variables desde $EnvFile"
    exit 1
}

# --- Variables obligatorias ---
$requiredVars = @(
    "CONTAINER_NAME",
    "IMAGE_NAME",
    "LOCAL_PORT",
    "SERVER_PORT",
    "APP_LOCAL_ROOT_PATH",
    "APP_SERVER_ROOT_PATH",
    "LOCAL_LOG_PATH",
    "SERVER_LOG_PATH",
    "SERVER_NAME",
    "NETWORK_NAME",
    "NETWORK_DRIVER",
    "NETWORK_SUBNET",
    "NETWORK_GATEWAY",
    "IP",
    "DOCKERFILE"
)

Write-Host "🔍 Validando variables obligatorias..."

$missing = @()

foreach ($var in $requiredVars) {
    if (-not $envVars.ContainsKey($var) -or [string]::IsNullOrWhiteSpace($envVars[$var])) {
        $missing += $var
    }
}

if ($missing.Count -gt 0) {
    Write-Error "❌ Faltan variables obligatorias:"
    $missing | ForEach-Object { Write-Host "   - $_" }
    exit 1
}

Write-Host "✔ Todas las variables obligatorias están definidas."

# ============================================================
# 🔵 1. Comprobar si la red existe, si no → crearla
# ============================================================

$networkName = $envVars["NETWORK_NAME"]

Write-Host "🔍 Comprobando si la red '$networkName' existe..."

$networkExists = docker network ls --format "{{.Name}}" | Select-String -Pattern "^$networkName$"

if (-not $networkExists) {
    Write-Host "⚠ La red '$networkName' no existe. Creándola..."

    docker network create `
        --driver $envVars["NETWORK_DRIVER"] `
        --subnet $envVars["NETWORK_SUBNET"] `
        --gateway $envVars["NETWORK_GATEWAY"] `
        $networkName

    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Error al crear la red '$networkName'"
        exit 1
    }

    Write-Host "✔ Red '$networkName' creada correctamente."
}
else {
    Write-Host "✔ La red '$networkName' ya existe."
}

# ============================================================
# 🔵 2. Comprobar si la imagen existe, si no → construirla
# ============================================================

$imageName = $envVars["IMAGE_NAME"]

Write-Host "🔍 Comprobando si la imagen '$imageName' existe..."

$imageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "^$imageName$"

if (-not $imageExists) {
    Write-Host "⚠ La imagen '$imageName' no existe. Procediendo a construirla..."

    $dockerfile = $envVars["DOCKERFILE"]

    docker build `
        --no-cache `
        -f "$dockerfile" `
        -t "$imageName" `
        --build-arg APP_LOCAL_HTTPCONF_PATH="$($envVars.APP_LOCAL_HTTPCONF_PATH)" `
        --build-arg APP_SERVER_HTTPCONF_PATH="$($envVars.APP_SERVER_HTTPCONF_PATH)" `
        --build-arg APP_LOCAL_HTTPCONFD_PATH="$($envVars.APP_LOCAL_HTTPCONFD_PATH)" `
        --build-arg APP_SERVER_HTTPCONFD_PATH="$($envVars.APP_SERVER_HTTPCONFD_PATH)" `
        --build-arg APP_LOCAL_ENTRYPOINT_PATH="$($envVars.APP_LOCAL_ENTRYPOINT_PATH)" `
        --build-arg APP_SERVER_ENTRYPOINT_PATH="$($envVars.APP_SERVER_ENTRYPOINT_PATH)" `
        .

    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Error al construir la imagen."
        exit 1
    }

    Write-Host "✔ Imagen '$imageName' creada correctamente."
}
else {
    Write-Host "✔ La imagen '$imageName' ya existe."
}

# ============================================================
# 🔵 3. Lanzar el contenedor
# ============================================================

$dockerRunArgs = @(
    "run",
    "-d",
    "--name", $envVars.CONTAINER_NAME,
    "-p", "$($envVars.LOCAL_PORT):$($envVars.SERVER_PORT)",
    "-v", "$($envVars.APP_LOCAL_ROOT_PATH):$($envVars.APP_SERVER_ROOT_PATH)",
    "-v", "$($envVars.LOCAL_LOG_PATH):$($envVars.SERVER_LOG_PATH)",
    "--env-file", $EnvFile,
    "--hostname", $envVars.SERVER_NAME,
    "--network", $envVars.NETWORK_NAME,
    "--ip", $envVars.IP,
    $imageName
)

Write-Host "🚀 Lanzando contenedor:"
Write-Host "docker $($dockerRunArgs -join ' ')"

docker @dockerRunArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ docker run falló."
    exit 1
}

Write-Host "🎉 Contenedor iniciado correctamente."
