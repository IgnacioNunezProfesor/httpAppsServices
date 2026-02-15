param(
    [switch]$Add,
    [switch]$Remove,
    [switch]$RemoveAll,
    [switch]$Help,
    [string]$Name,
    [string]$Url,
    [string]$Path
)

# Recargar módulo
if (Get-Module 'AppFromGit') {
    Remove-Module 'AppFromGit' -Force
}
Import-Module .\scripts\mods\AppFromGit.psm1 -Force

function Show-Help {
    Write-Host "============================="
    Write-Host "   AYUDA - Gestión de Submódulos"
    Write-Host "============================="
    Write-Host "USO:"
    Write-Host ""
    Write-Host "Modo interactivo:"
    Write-Host "  .\AdminApp.ps1"
    Write-Host ""
    Write-Host "Modo directo con parámetros:"
    Write-Host ""
    Write-Host "  Añadir submódulo:"
    Write-Host "  .\AdminApp.ps1 -Add -Name <nombre> -Url <url> -Path <ruta>"
    Write-Host ""
    Write-Host "  Eliminar submódulo:"
    Write-Host "  .\AdminApp.ps1 -Remove -Path <ruta>"
    Write-Host ""
    Write-Host "  Eliminar todos:"
    Write-Host "  .\AdminApp.ps1 -RemoveAll"
    Write-Host ""
    Write-Host "EJEMPLOS:"
    Write-Host "  .\AdminApp.ps1 -Add -Name MyApp -Url https://github.com/user/repo -Path ./apps"
    Write-Host "  .\AdminApp.ps1 -Remove -Path ./apps/MyApp"
    Write-Host "  .\AdminApp.ps1 -RemoveAll"
    Write-Host "============================="
}

function MainMenu {
    Write-Host "============================="
    Write-Host "   Gestión de Submódulos"
    Write-Host "============================="
    Write-Host "1. Añadir submódulo"
    Write-Host "2. Eliminar un submódulo"
    Write-Host "3. Eliminar TODOS los submódulos"
    Write-Host "4. Ayuda"
    Write-Host "0. Salir"
    Write-Host "============================="

    $choice = Read-Host "Selecciona una opción"

    switch ($choice) {
        "1" {
            $name = Read-Host "Nombre del submódulo"
            $url = Read-Host "URL del repositorio GitHub"
            $path = Read-Host "Ruta destino"
            Add-AppFromGit -SubmoduleName $name -GitHubUrl $url -DestinationPath $path
            MainMenu
        }
        "2" {
            $path = Read-Host "Ruta del submódulo a eliminar"
            Remove-App -SubmodulePath $path
            MainMenu
        }
        "3" {
            Remove-AllApps
            MainMenu
        }
        "4" {
            Show-Help
            MainMenu
        }
        "0" {
            Write-Host "Saliendo..."
            exit
        }
        default {
            Write-Host "Opción no válida." -ForegroundColor Red
            MainMenu
        }
    }
}

# --- LÓGICA PRINCIPAL ---

if ($Help) {
    Show-Help
    exit
}

if ($Add) {
    if (-not $Name -or -not $Url -or -not $Path) {
        Write-Host "Faltan parámetros: -Name -Url -Path" -ForegroundColor Red
        Write-Host "Usa: .\AdminApp.ps1 -Help" -ForegroundColor Yellow
        exit 1
    }
    Add-AppFromGit -SubmoduleName $Name -GitHubUrl $Url -DestinationPath $Path
    exit
}

if ($Remove) {
    if (-not $Path) {
        Write-Host "Falta parámetro: -Path" -ForegroundColor Red
        Write-Host "Usa: .\AdminApp.ps1 -Help" -ForegroundColor Yellow
        exit 1
    }
    Remove-App -SubmodulePath $Path
    exit
}

if ($RemoveAll) {
    Remove-AllApps
    exit
}

# Si no hay parámetros → mostrar menú
MainMenu
