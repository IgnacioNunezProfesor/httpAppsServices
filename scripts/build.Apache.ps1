Param(
    [string]$EnvFile = ".\env\dev.apache.env",
    [string]$Dockerfile = "docker/apache.dev.dockerfile",
    [string]$Tag = "apache:dev"
)

if (-not (Test-Path $EnvFile)) {
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}

$lines = Get-Content $EnvFile -ErrorAction Stop
$buildArgs = @()

foreach ($line in $lines) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    if ($line -notmatch '=') { continue }
    $parts = $line -split '=', 2
    $k = $parts[0].Trim()
    $v = $parts[1].Trim()
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }
    $buildArgs += '--build-arg'
    $buildArgs += "$k=$v"
}

$argsSTR = @(
    'build', 
    '--no-cache', 
    '-f', $Dockerfile, 
    '-t', $Tag
) + $buildArgs + '.'

Write-Host "Ejecutando: docker $($argsSTR -join ' ')" & docker @argsSTR
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}