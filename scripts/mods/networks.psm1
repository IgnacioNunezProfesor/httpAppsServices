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

    # 1. Separar la red del CIDR (ej: 192.168.1.0/24)
    $parts = $Subnet.Split('/')
    if ($parts.Count -ne 2) {
        Write-Error "El formato del rango debe ser 'IP/Máscara' (ej: 10.0.0.0/24)"
        return $false
    }

    $networkIp = [System.Net.IPAddress]::Parse($parts[0])
    $cidr = [int]$parts[1]
    $targetIp = [System.Net.IPAddress]::Parse($IP)

    # 2. Convertir IP a bytes (Big Endian)
    $networkBytes = $networkIp.GetAddressBytes()
    $targetBytes = $targetIp.GetAddressBytes()

    # Solo soportamos IPv4 para este ejemplo simple
    if ($networkBytes.Count -ne 4) {
        Write-Error "Esta función solo soporta IPv4."
        return $false
    }

    # 3. Calcular la máscara de red en formato binario
    # Si cidr es 24, creamos un entero con 24 unos seguidos de 8 ceros
    $mask = [uint32]0xFFFFFFFF
    if ($cidr -lt 32) {
        $mask = [uint32]($mask -shl (32 - $cidr))
    }

    # 4. Convertir los bytes de las IPs a enteros de 32 bits (Big Endian)
    # Invertimos los bytes si estamos en arquitectura Little Endian (común en Windows)
    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($networkBytes)
        [Array]::Reverse($targetBytes)
    }

    $networkInt = [BitConverter]::ToUInt32($networkBytes, 0)
    $targetInt = [BitConverter]::ToUInt32($targetBytes, 0)

    # 5. Comparar usando operaciones Bitwise (AND)
    # Una IP está en el rango si (IP AND MASK) == (NETWORK AND MASK)
    return ($targetInt -band $mask) -eq ($networkInt -band $mask)
}