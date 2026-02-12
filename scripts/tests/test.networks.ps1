# ================================
#  PRUEBAS MANUALES DE Test-IpInSubnet
# ================================

if (Get-Module 'networks') { 
    Remove-Module 'networks' -Force 
} 
Import-Module .\scripts\mods\networks.psm1 -Force


# Función auxiliar para mostrar resultados
function Show-TestResult {
    param(
        [string]$Name,
        [bool]$Result,
        [bool]$Expected
    )

    if ($Result -eq $Expected) {
        Write-Host "[OK]   $Name" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[FAIL] $Name (Resultado: $Result, Esperado: $Expected)" -ForegroundColor Red
        return $false
    }
}

# Contadores
$passed = 0
$failed = 0

function runTest {
    param(
        [string]$Name,
        [scriptblock]$Code,
        [bool]$Expected
    )

    try {
        $result = & $Code
        if (Show-TestResult -Name $Name -Result $result -Expected $Expected) {
            $script:passed++
        } else {
            $script:failed++
        }
    }
    catch {
        Write-Host "[ERROR] $Name lanzó una excepción: $($_.Exception.Message)" -ForegroundColor Yellow
        $script:failed++
    }
}

Write-Host "==============================="
Write-Host " Ejecutando pruebas de red"
Write-Host "==============================="

# ================================
# PRUEBAS QUE DEBEN DAR TRUE
# ================================
runTest "192.168.1.10 ∈ 192.168.1.0/24" { Test-IpInSubnet "192.168.1.10" "192.168.1.0/24" } $true
runTest "10.0.0.5 ∈ 10.0.0.0/29" { Test-IpInSubnet "10.0.0.5" "10.0.0.0/29" } $true
runTest "IP de red incluida" { Test-IpInSubnet "192.168.50.0" "192.168.50.0/24" } $true
runTest "Broadcast incluido" { Test-IpInSubnet "192.168.50.255" "192.168.50.0/24" } $true
runTest "/32 coincide solo con sí misma" { Test-IpInSubnet "10.0.0.1" "10.0.0.1/32" } $true
runTest "/0 acepta cualquier IP" { Test-IpInSubnet "123.45.67.89" "0.0.0.0/0" } $true

# ================================
# PRUEBAS QUE DEBEN DAR FALSE
# ================================
runTest "192.168.2.10 ∉ 192.168.1.0/24" { Test-IpInSubnet "192.168.2.10" "192.168.1.0/24" } $false
runTest "10.0.0.10 ∉ 10.0.0.0/29" { Test-IpInSubnet "10.0.0.10" "10.0.0.0/29" } $false
runTest "IP menor que la red" { Test-IpInSubnet "192.168.0.255" "192.168.1.0/24" } $false
runTest "IP distinta en /32" { Test-IpInSubnet "10.0.0.2" "10.0.0.1/32" } $false

# ================================
# PRUEBAS QUE DEBEN DAR ERROR
# ================================
function runErrorTest {
    param(
        [string]$Name,
        [scriptblock]$Code
    )

    try {
        & $Code
        Write-Host "[FAIL] $Name (No lanzó error)" -ForegroundColor Red
        $script:failed++
    }
    catch {
        Write-Host "[OK]   $Name (Error detectado)" -ForegroundColor Green
        $script:passed++
    }
}

runErrorTest "Formato sin CIDR" { Test-IpInSubnet "192.168.1.10" "192.168.1.0" }
runErrorTest "IP inválida" { Test-IpInSubnet "999.999.999.999" "192.168.1.0/24" }
runErrorTest "Subred inválida" { Test-IpInSubnet "192.168.1.10" "999.999.999.0/24" }
runErrorTest "IPv6 no soportado" { Test-IpInSubnet "2001:db8::1" "2001:db8::/64" }

# ================================
# RESUMEN FINAL
# ================================
Write-Host "==============================="
Write-Host " Resultados finales"
Write-Host "==============================="
Write-Host "Pasados: $passed" -ForegroundColor Green
Write-Host "Fallados: $failed" -ForegroundColor Red
Write-Host "==============================="
