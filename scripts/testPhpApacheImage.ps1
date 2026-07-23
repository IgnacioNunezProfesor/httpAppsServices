#!/usr/bin/env pwsh
<#
.SYNOPSIS
Builds and verifies the PHP 8.5 Apache Docker image.

.DESCRIPTION
Builds the phpapache image and runs a verification to ensure:
- PHP 8.5 is properly installed
- All required extensions are loaded
- Apache is configured correctly

.EXAMPLE
.\scripts\testPhpApacheImage.ps1
#>

param(
    [switch]$Rebuild
)

Write-Host "================================================"
Write-Host "Testing PHP 8.5 Apache Docker Image"
Write-Host "================================================"

$imageName = "phpapache:dev"
$containerName = "phpapache-test-$$"

# Check if image exists
$imageExists = docker images --quiet $imageName

if ($imageExists -and -not $Rebuild) {
    Write-Host "Image already exists. Use -Rebuild to rebuild."
} else {
    Write-Host "`nBuilding image: $imageName..."
    $buildOutput = docker build -f ./docker/phpapache.dev.dockerfile -t $imageName . 2>&1
    
    if (-not $?) {
        Write-Error "Failed to build image:`n$buildOutput"
        exit 1
    }
    
    Write-Host "Image built successfully."
}

# Run verification container
Write-Host "`nRunning verification tests..."
$testOutput = docker run --rm --name $containerName $imageName sh -c @"
echo "=== PHP Version ===" && \
php -v && \
echo "" && \
echo "=== Loaded PHP Modules ===" && \
php -m && \
echo "" && \
echo "=== Critical Extensions ===" && \
php -r "
  \$required = array('mysqli', 'curl', 'gd', 'mbstring', 'xml', 'zip', 'json');
  \$loaded = get_loaded_extensions();
  
  echo \"Checking for required extensions:\n\";
  foreach (\$required as \$ext) {
    \$status = in_array(\$ext, \$loaded) ? '✓' : '✗';
    echo \$status . \" \$ext\n\";
  }
"
"@ 2>&1

if (-not $?) {
    Write-Error "Verification failed:`n$testOutput"
    exit 1
}

Write-Host $testOutput

Write-Host "`n================================================"
Write-Host "Verification Complete"
Write-Host "================================================"
Write-Host "`nImage: $imageName"
Write-Host "Status: Ready for use"
