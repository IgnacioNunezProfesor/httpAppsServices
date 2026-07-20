# Helper functions for Docker command execution with error handling

function Invoke-DockerCommand {
    <#
    .SYNOPSIS
    Executes a Docker command and captures both stdout and stderr. Throws on failure.
    
    .PARAMETER Command
    The Docker command to execute (without the 'docker' prefix).
    
    .PARAMETER ErrorMessage
    Custom error message prefix to display if the command fails.
    
    .EXAMPLE
    $output = Invoke-DockerCommand -Command "ps -a" -ErrorMessage "Failed to list containers"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        
        [Parameter(Mandatory)]
        [string]$ErrorMessage
    )

    write-Host "Executing Docker command: docker $Command" -ForegroundColor Yellow

    $output = Invoke-Expression "docker $Command 2>&1"

    # If output is an array, join into a single well-formatted string for display
    if ($output -is [System.Array]) {
        $formattedOutput = $output -join "`n"
    } else {
        $formattedOutput = $output
    }

    write-Host "Docker command output:`n$formattedOutput" -ForegroundColor Cyan
    
    if (-not $?) {
        throw "${ErrorMessage}:`n$output"
    }
    
    return $output
}

function Invoke-DockerExecCommand {
    <#
    .SYNOPSIS
    Executes a command inside a running container. Captures both stdout and stderr. Throws on failure.
    
    .PARAMETER ContainerId
    The container ID or name.
    
    .PARAMETER Command
    The command to execute inside the container.
    
    .PARAMETER ErrorMessage
    Custom error message prefix to display if the command fails.
    
    .EXAMPLE
    Invoke-DockerExecCommand -ContainerId "abc123" -Command "ls -la /app" -ErrorMessage "Failed to list files"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ContainerId,
        
        [Parameter(Mandatory)]
        [string]$Command,
        
        [Parameter(Mandatory)]
        [string]$ErrorMessage
    )

    $output = Invoke-Expression "docker exec $ContainerId $Command 2>&1"
    
     # If output is an array, join into a single well-formatted string for display
    if ($output -is [System.Array]) {
        $formattedOutput = $output -join "`n"
    } else {
        $formattedOutput = $output
    }

    write-Host "Docker command output:`n$formattedOutput" -ForegroundColor Cyan
    
    if (-not $?) {
        throw "${ErrorMessage}:`n$output"
    }
    
    return $output
}

function Get-ContainerLogs {
    <#
    .SYNOPSIS
    Retrieves container logs for debugging. Does not throw on failure.
    
    .PARAMETER ContainerId
    The container ID or name.
    
    .EXAMPLE
    $logs = Get-ContainerLogs -ContainerId "abc123"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ContainerId
    )

    $logs = docker logs $ContainerId 2>&1
    return $logs
}

function Clear-Containers {
    param(
        [string]$reason = "Script termination"
    )

    if ($script:containerId) {
        Write-Host "Cleaning up container: $script:containerName ($script:containerId)"
        Write-Host "Reason: $reason"
        
        # Try to stop the container
        Write-Host "Stopping container..."
        $stopOutput = docker stop $script:containerId 2>&1
        if (-not $?) {
            Write-Warning "Failed to stop container: $stopOutput"
        } else {
            Write-Host "Container stopped."
        }

        # Wait a moment, then remove it
        Start-Sleep -Seconds 2

        Write-Host "Removing container..."
        $rmOutput = docker rm $script:containerId 2>&1
        if (-not $?) {
            Write-Warning "Failed to remove container: $rmOutput"
        } else {
            Write-Host "Container removed."
        }
    }

    # Clean up the network if needed
    if ($script:networkName) {
        Write-Host "Cleaning up network: $script:networkName"
        $netRmOutput = docker network rm $script:networkName 2>&1
        if (-not $?) {
            Write-Warning "Failed to remove network (may still be in use): $netRmOutput"
        } else {
            Write-Host "Network removed."
        }
    }
}
