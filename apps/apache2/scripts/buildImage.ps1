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
    "APP_LOCAL_HTTPCONF_PATH",
    "APP_SERVER_HTTPCONF_PATH",
    "APP_LOCAL_HTTPCONFD_PATH",
    "APP_SERVER_HTTPCONFD_PATH",
    "APP_LOCAL_ENTRYPOINT_PATH",
    "APP_SERVER_ENTRYPOINT_PATH",
    "IMAGE_NAME",
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

# --- Construcción de parámetros para docker build ---
$dockerfile = $envVars["DOCKERFILE"]
$imageName  = $envVars["IMAGE_NAME"]

$dockerParams = @(
    "--no-cache",
    "-f", $dockerfile,
    "-t", $imageName,
    "--build-arg", "APP_LOCAL_HTTPCONF_PATH=$($envVars["APP_LOCAL_HTTPCONF_PATH"])",
    "--build-arg", "APP_SERVER_HTTPCONF_PATH=$($envVars["APP_SERVER_HTTPCONF_PATH"])",
    "--build-arg", "APP_LOCAL_HTTPCONFD_PATH=$($envVars["APP_LOCAL_HTTPCONFD_PATH"])",
    "--build-arg", "APP_SERVER_HTTPCONFD_PATH=$($envVars["APP_SERVER_HTTPCONFD_PATH"])",
    "--build-arg", "APP_LOCAL_ENTRYPOINT_PATH=$($envVars["APP_LOCAL_ENTRYPOINT_PATH"])",
    "--build-arg", "APP_SERVER_ENTRYPOINT_PATH=$($envVars["APP_SERVER_ENTRYPOINT_PATH"])",
    "."
)

$dockerParamsStr = $dockerParams -join " "

Write-Host "🚀 Ejecutando build:"
Write-Host "docker build $dockerParamsStr"

docker build @dockerParams
$code = $LASTEXITCODE

if ($code -ne 0) {
    Write-Error "❌ docker build falló con código $code"
    exit $code
}

Write-Host "🎉 Build completado exitosamente."
