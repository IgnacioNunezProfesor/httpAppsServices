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

