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

   $filteredVars= $envVars.GetEnumerator() | Where-Object { $_.Key -like "$prefix*" }
    if ($filteredVars.Count -eq 0) {
        filteredVars = @{}
    }
    return $filteredVars
}

function EnvVarsToBuildArgs {
    param(
        [Parameter(Mandatory)]
        [hashtable]$envVars
    )

    $buildArgsString = ""
    foreach ($item in $envVars) {
        $buildArgsString += "--build-arg $($item.Key)=$($item.Value) "
    }
    return $buildArgsString.Trim()
}

