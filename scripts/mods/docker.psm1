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

    $output = Invoke-Expression "docker $Command 2>&1"
    
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
