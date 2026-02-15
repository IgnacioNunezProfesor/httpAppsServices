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


.\scripts\AdminApp.ps1 -add -Name $envVars.APP_NAME -Url $envVars.APP_GITHUB_URL -Path $envVars.APP_LOCAL_PATH



docker compose -f $envVars.APP_COMPOSER_PATH --env-file $EnvFile up -d