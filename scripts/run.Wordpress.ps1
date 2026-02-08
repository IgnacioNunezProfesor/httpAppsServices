Param(
    [string]$EnvFile = ".\env\dev.wordpress.env"
)

Import-Module .\scripts\mods\env.ps1

$envVars = Get-EnvVarsFromFile -envFile $EnvFile


# Comprobar si existe la imagen phpapache:dev
$image = docker images -q $envVars['IMAGE_NAME']

if (-not $image) {
    Write-Host "La imagen $( $envVars['IMAGE_NAME'] ) NO existe. Lanzando build..."
    ./scripts/build.phpApache.ps1 $envFile $($envVars['IMAGE_NAME'])  $($envVars['IMAGE_NAME'])    
} 

$image = docker images -q $envVars['IMAGE_NAME']

if ($image) {
    Write-Host "La imagen $envVars['IMAGE_NAME'] existe. Lanzando run..."
    ./scripts/run.phpapache.ps1 $envFile
}
