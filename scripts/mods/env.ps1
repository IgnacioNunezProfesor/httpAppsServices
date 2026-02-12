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

function Get-EnvVarsByPrefix {
    param(
        [Parameter(Mandatory)]
        [hashtable]$envVars,
        [Parameter(Mandatory)]
        [string]$prefix
    )

    $filtered = @{}

    foreach ($item in $envVars.GetEnumerator()) {
        if ($item.Key -like "$prefix*") {
            $filtered[$item.Key] = $item.Value
        }
    }

    return $filtered
}



function EnvVarsToBuildArgs {
    param(
        [Parameter(Mandatory)]
        [hashtable]$envVars
    )

    [string]$argString = ""
    foreach ($key in $envVars.Keys) {
        $argString += "--build-arg $key=$($envVars[$key]) "
    }

    return $argString.Trim()
}