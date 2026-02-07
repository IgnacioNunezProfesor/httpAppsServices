# CrearRedDocker.ps1
# Script para crear una red en Docker usando PowerShell con detección de solapamiento

<#
.SYNOPSIS
    Crea una red en Docker con configuración personalizable y validación de solapamiento.
.EXAMPLE
    .\CrearRedDocker.ps1
    .\CrearRedDocker.ps1 -NetworkName "MyNetwork" -Driver "bridge"
    .\CrearRedDocker.ps1 -NetworkName "MyNetwork" -Subnet "192.168.0.0/16" -Gateway "192.168.0.1"
#>

param(
    [string]$NetworkName,
    [string]$Driver,
    [string]$Subnet,
    [string]$Gateway,
    
    [string]$envFile = ".\env\dev.network.env"
)

# Cargar variables de entorno desde el archivo
$envVars = @{}

if (-not (Test-Path $envFile)) {
    Write-Error "Archivo de entorno '$envFile' no encontrado."
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# -------------------------------
# LÓGICA DE ENTRADA DE DATOS
# -------------------------------

if (-not $NetworkName) { $NetworkName = $envVars["NETWORK_NAME"] }
if (-not $Driver) { $Driver = $envVars["NETWORK_DRIVER"] }
if (-not $Subnet) { $Subnet = $envVars["NETWORK_SUBNET"] }
if (-not $Gateway) { $Gateway = $envVars["NETWORK_SUBNET_GATEWAY"] }

if (-not $NetworkName -or -not $Driver -or -not $Subnet -or -not $Gateway) {
    Write-Error "Faltan parámetros y no existen valores en el archivo $envFile para completarlos."
    exit 1
}

Write-Host "`n=== Validando red Docker antes de crearla ===" -ForegroundColor Cyan

# -------------------------------
# FUNCIONES AUXILIARES
# -------------------------------

function Convert-CIDRToRange {
    param([string]$cidr)

    $parts = $cidr.Split("/")
    $ip = [System.Net.IPAddress]::Parse($parts[0])
    $prefix = [int]$parts[1]

    $ipBytes = $ip.GetAddressBytes()
    [array]::Reverse($ipBytes)
    $ipInt = [BitConverter]::ToUInt32($ipBytes, 0)

    $mask = [uint32]::MaxValue -shl (32 - $prefix)
    $network = $ipInt -band $mask
    $broadcast = $network + ([uint32]::MaxValue - $mask)

    return @{
        Network   = $network
        Broadcast = $broadcast
        CIDR      = $cidr
    }
}

function Test-NetworkOverlap {
    param([string]$newCIDR)

    $newRange = Convert-CIDRToRange $newCIDR

    $dockerNetworks = docker network inspect $(docker network ls -q) --format '{{json .IPAM.Config}}' |
    ConvertFrom-Json |
    Where-Object { $null -ne $_.Subnet }

    foreach ($net in $dockerNetworks) {
        foreach ($subnet in $net.Subnet) {
            $existingRange = Convert-CIDRToRange $subnet

            $overlap = -not (
                $newRange.Broadcast -lt $existingRange.Network -or
                $newRange.Network -gt $existingRange.Broadcast
            )

            if ($overlap) {
                return @{
                    Overlap  = $true
                    Existing = $existingRange.CIDR
                }
            }
        }
    }

    return @{ Overlap = $false }
}

# -------------------------------
# VALIDACIÓN DE SOLAPAMIENTO
# -------------------------------

$result = Test-NetworkOverlap -newCIDR $Subnet



# -------------------------------
# VALIDACIÓN DE EXISTENCIA DE RED
# -------------------------------

$existingNetworkId = docker network ls --format "{{.ID}} {{.Name}}" |
Where-Object { $_ -match "^\S+\s+$NetworkName$" } |
ForEach-Object { ($_ -split " ")[0] }

if ($existingNetworkId) {
    Write-Host "`n=== La red '$NetworkName' ya existe. Validando subred... ===" -ForegroundColor Cyan

    $existingConfig = docker network inspect $existingNetworkId --format "{{json .IPAM.Config}}" | ConvertFrom-Json
    $existingSubnet = $existingConfig.Subnet

    if ($existingSubnet -eq $Subnet) {
        Write-Host "La red '$NetworkName' ya existe con la misma subred ($Subnet). No se realizará ninguna acción." -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "La red '$NetworkName' existe pero con subred diferente ($existingSubnet). Será eliminada." -ForegroundColor Yellow
        docker network rm $existingNetworkId

        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: No se pudo eliminar la red existente." -ForegroundColor Red
            exit 1
        }

        Write-Host "Red eliminada correctamente. Se procederá a crear la nueva." -ForegroundColor Green
    }
}

# -------------------------------
# CREACIÓN DE LA RED
# -------------------------------

Write-Host "`n=== Creando red Docker: $NetworkName ===" -ForegroundColor Cyan

$command = "docker network create --driver $Driver"

if ($Subnet -and $Gateway) {
    $command += " --subnet=$Subnet --gateway=$Gateway"
}

$command += " $NetworkName"

Write-Host "Ejecutando comando: $command" -ForegroundColor Yellow

Invoke-Expression $command

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo crear la red Docker." -ForegroundColor Red
    exit 1
}

Write-Host "Red creada correctamente." -ForegroundColor Green

Write-Host "`n=== Redes disponibles ===" -ForegroundColor Cyan
docker network ls
