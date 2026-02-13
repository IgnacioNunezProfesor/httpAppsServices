if (Get-Module 'env') { 
    Remove-Module 'env' -Force 
} 
Import-Module .\scripts\mods\env.psm1 -Force

function createNetwork {
    param(
        [string]$NetworkName,
        [string]$Driver,
        [string]$Subnet,
        [string]$Gateway,
    
        [string]$envFile = ".\env\dev.network.env"
    )

    # Cargar variables de entorno desde el archivo
    if ($envFile) {
        $envVars = Get-EnvVarsFromFile -envFile $envFile
    }
    
    # -------------------------------
    # LÓGICA DE ENTRADA DE DATOS
    # -------------------------------

    if (-not $NetworkName) { $NetworkName = $envVars["NETWORK_NAME"] }
    if (-not $Driver) { $Driver = $envVars["NETWORK_DRIVER"] }
    if (-not $Subnet) { $Subnet = $envVars["NETWORK_SUBNET"] }
    if (-not $Gateway) { $Gateway = $envVars["NETWORK_SUBNET_GATEWAY"] }

    if (-not $NetworkName -or -not $Driver -or -not $Subnet -or -not $Gateway -or -not $envFile) {
        Write-Error "Faltan parámetros y no existen valores en el archivo $envFile para completarlos."
        exit 1
    }

    Write-Host "`n=== Validando red Docker antes de crearla ===" -ForegroundColor Cyan



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
            return}
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
}
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

function Test-IpInSubnet {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IP,

        [Parameter(Mandatory = $true)]
        [string]$Subnet
    )

    # 1. Separar red y CIDR
    $parts = $Subnet.Split('/')
    if ($parts.Count -ne 2) {
        Write-Error "El formato debe ser IP/CIDR (ej: 192.168.1.0/24)"
        return $false
    }

    $networkIp = [System.Net.IPAddress]::Parse($parts[0])
    $cidr      = [int]$parts[1]
    $targetIp  = [System.Net.IPAddress]::Parse($IP)

    # Solo IPv4
    if ($networkIp.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
        Write-Error "Solo se soporta IPv4."
        return $false
    }

    if ($cidr -lt 0 -or $cidr -gt 32) {
        Write-Error "El CIDR debe estar entre 0 y 32."
        return $false
    }

    # 2. Bytes de red y destino
    $networkBytes = $networkIp.GetAddressBytes()
    $targetBytes  = $targetIp.GetAddressBytes()

    # 3. Construir máscara como 4 bytes
    $maskBytes = [byte[]](0,0,0,0)
    for ($i = 0; $i -lt $cidr; $i++) {
        $byteIndex = [math]::Floor($i / 8)
        $bitIndex  = 7 - ($i % 8)
        $maskBytes[$byteIndex] = $maskBytes[$byteIndex] -bor (1 -shl $bitIndex)
    }

    # 4. Aplicar AND byte a byte y comparar
    for ($i = 0; $i -lt 4; $i++) {
        $netMasked   = $networkBytes[$i] -band $maskBytes[$i]
        $targetMasked = $targetBytes[$i] -band $maskBytes[$i]
        if ($netMasked -ne $targetMasked) {
            return $false
        }
    }

    return $true
}



