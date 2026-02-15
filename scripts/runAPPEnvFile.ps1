Param(
    [Parameter(Mandatory = $true)]
    [string]$envFile
)

if (Get-Module 'env') { 
    Remove-Module 'env' -Force 
}
Import-Module .\scripts\mods\env.psm1 -Force

if (Get-Module 'networks') { 
    Remove-Module 'networks' -Force 
} 
Import-Module .\scripts\mods\networks.psm1 -Force


$envVars = Get-EnvVarsFromFile -envFile $EnvFile
if (-not $envVars) { 
    Write-Error "No se pudieron cargar las variables de entorno desde $EnvFile" 
    exit 1 
} 

if (-not (Test-AppExists -SubmoduleName $envVars.APP_NAME)) {
    Write-Host "Git module not found at $gitModulePath. Cloning from $($envVars.APP_GITHUB_URL)..."
    .\scripts\AdminApp.ps1 -action clone -repoUrl $envVars.APP_GITHUB_URL -destinationPath $gitModulePath
}
else {
    Write-Host "Git module found at $gitModulePath"
}


docker compose -f $envVars.APP_COMPOSER_PATH --env-file $EnvFile up -d