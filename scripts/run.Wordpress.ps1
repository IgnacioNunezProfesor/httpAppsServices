Param(
    [string]$EnvFile = ".\env\dev.wordpress.env"
)

function Get-EnvVarsFromFile {
    param(
        [Parameter(Mandatory)]
        [string]$envFile
    )

    if (-not (Test-Path $envFile)) {
        Write-Error "Env file '$envFile' not found."
        exit 1
    }

    $envVars = @{}

    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^=]+)=(.*)$') {
            $envVars[$matches[1]] = $matches[2]
        }
    }

    return $envVars
}

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
