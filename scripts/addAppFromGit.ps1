param(
    [Parameter(Mandatory=$true)]
    [string]$SubmoduleName,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath
)

try {
    Write-Host "Adding submodule: $SubmoduleName"
    Write-Host "From: $GitHubUrl"
    Write-Host "To: $DestinationPath"
    
    git submodule add $GitHubUrl $DestinationPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Submodule added successfully!" -ForegroundColor Green
    } else {
        Write-Host "Error adding submodule" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Exception: $_" -ForegroundColor Red
    exit 1
}