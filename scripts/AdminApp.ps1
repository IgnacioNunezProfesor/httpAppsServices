param(
    [switch]$Add,
    [switch]$Remove,
    [switch]$RemoveAll,
    [string]$Name,
    [string]$Url,
    [string]$Path
)

# Recargar módulo
if (Get-Module 'AppFromGit') {
    Remove-Module 'AppFromGit' -Force
}
Import-Module .\scripts\mods\AppFromGit.psm1 -Force

function MainMenu {
    Write-Host "============================="
    Write-Host "   Gestión de Submódulos"
    Write-Host "============================="
    Write-Host "1. Añadir submódulo"
    Write-Host "2. Eliminar un submódulo"
    Write-Host "3. Eliminar TODOS los submódulos"
    Write-Host "0. Salir"
    Write-Host "============================="

    $choice = Read-Host "Selecciona una opción"

    switch ($choice) {
        "1" {
            $name = Read-Host "Nombre del submódulo"
            $url = Read-Host "URL del repositorio GitHub"
            $path = Read-Host "Ruta destino"
            Add-AppFromGit -SubmoduleName $name -GitHubUrl $url -DestinationPath $path
        }
        "2" {
            $path = Read-Host "Ruta del submódulo a eliminar"
            Remove-App -SubmodulePath $path
        }
        "3" {
            Remove-AllApps
        }
        "0" {
            Write-Host "Saliendo..."
            exit
        }
        default {
            Write-Host "Opción no válida." -ForegroundColor Red
        }
    }
}

# --- LÓGICA PRINCIPAL ---

# Si el usuario pasa parámetros, ejecutamos directamente
if ($Add) {
    if (-not $Name -or -not $Url -or -not $Path) {
        Write-Host "Faltan parámetros: -Name -Url -Path" -ForegroundColor Red
        exit 1
    }
    Add-AppFromGit -SubmoduleName $Name -GitHubUrl $Url -DestinationPath $Path
    exit
}

if ($Remove) {
    if (-not $Path) {
        Write-Host "Falta parámetro: -Path" -ForegroundColor Red
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