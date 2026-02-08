Param(
    [string]$EnvFile = ".\env\dev.wordpress.env"
)
$envVars = @{}

if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
} 
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Comprobar si existe la imagen phpapache:dev
$image = docker images -q $envVars['IMAGE_NAME']

if (-not $image) {
    Write-Host "La imagen $( $envVars['IMAGE_NAME'] ) NO existe. Lanzando build..."
    ./scripts/build.phpApache.ps1 $envFile "./docker/phpapache.dev.dockerfile" $($envVars['IMAGE_NAME'])    
} 

$image = docker images -q $envVars['IMAGE_NAME']

if ($image) {
    Write-Host "La imagen $envVars['IMAGE_NAME'] existe. Lanzando run..."
    ./scripts/run.phpapache.ps1 $envFile
}
