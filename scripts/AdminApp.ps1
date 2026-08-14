param(
    [switch]$Add,
    [switch]$Remove,
    [switch]$RemoveAll,
    [switch]$Update,
    [switch]$Help,
    [switch]$Purge,

    [switch]$Download,
    [string]$DownloadUrl,
    [string]$Version,
    [string]$Destination,

    [string]$Name,
    [string]$Url,
    [string]$Path,
    [string]$Branch,
    [string]$Target
)


# Recargar módulo
if (Get-Module 'AppFromGit') {
    Remove-Module 'AppFromGit' -Force
}
Import-Module .\scripts\mods\AppFromGit.psm1 -Force

function Show-Help {
    Write-Host "============================="
    Write-Host " AYUDA - Gestión de Submódulos"
    Write-Host "============================="
    Write-Host "USO:"
    Write-Host ""
    Write-Host "Modo interactivo:"
    Write-Host " .\AdminApp.ps1"
    Write-Host ""
    Write-Host "Modo directo con parámetros:"
    Write-Host ""
    Write-Host " Añadir submódulo:"
    Write-Host " .\AdminApp.ps1 -Add -Name <nombre> -Url <url> -Path <ruta> -Branch <rama>"
    Write-Host ""
    Write-Host " Eliminar submódulo:"
    Write-Host " .\AdminApp.ps1 -Remove -Path <ruta>"
    Write-Host ""
    Write-Host " Eliminar todos los submódulos:"
    Write-Host " .\AdminApp.ps1 -RemoveAll"
    Write-Host ""
    Write-Host " Actualizar submódulos:"
    Write-Host " .\AdminApp.ps1 -Update -Target all"
    Write-Host " .\AdminApp.ps1 -Update -Target <ruta>"
    Write-Host " Descargar aplicación desde URL:"
    Write-Host " .\AdminApp.ps1 -Download -DownloadUrl <url> -Version <versión> -Destination <carpeta>"
    Write-Host ""
    Write-Host " PURGA COMPLETA DEL SISTEMA:"
    Write-Host " (Elimina contenedores, imágenes, carpetas locales y todas las apps)"
    Write-Host " .\AdminApp.ps1 -Purge"
    Write-Host ""
    Write-Host "============================="
}


function MainMenu {
    Write-Host "============================="
    Write-Host "   Gestión de Submódulos"
    Write-Host "============================="
    Write-Host "1. Añadir submódulo"
    Write-Host "2. Eliminar un submódulo"
    Write-Host "3. Eliminar TODOS los submódulos"
    Write-Host "4. Actualizar submódulos"
    Write-Host "5. Purga completa del sistema"
    Write-Host "6. Descargar nueva aplicación desde URL"
    Write-Host "?. Ayuda"
    Write-Host "0. Salir"
    Write-Host "============================="

    $choice = Read-Host "Selecciona una opción"

    switch ($choice) {
        "1" {
            $name = Read-Host "Nombre del submódulo"
            $url = Read-Host "URL del repositorio GitHub"
            $path = Read-Host "Ruta destino"
            $branch = Read-Host "Rama del repositorio"
            Add-AppFromGit -SubmoduleName $name -GitHubUrl $url -DestinationPath $path -Branch $branch
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
            Write-Host "1. Actualizar TODOS los submódulos"
            Write-Host "2. Actualizar un submódulo específico"
            $opt = Read-Host "Selecciona una opción"

            switch ($opt) {
                "1" {
                    Update-App -Target "all"
                }
                "2" {
                    $target = Read-Host "Ruta del submódulo a actualizar"
                    Update-App -Target $target
                }
                default {
                    Write-Host "Opción no válida." -ForegroundColor Red
                }
            }
            MainMenu
        }
        "5" {
            Clear-All
            MainMenu
        }
        "6" {
            $url = Read-Host "URL de descarga"
            $version = Read-Host "Versión"
            $dest = Read-Host "Carpeta destino"
            Add-FromUrl -UrlDescarga $url -Version $version -CarpetaDestino $dest
            MainMenu
        }
        "?" {
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

function Clear-All {
    Write-Host "============================="
    Write-Host " PURGA COMPLETA DEL SISTEMA"
    Write-Host "============================="

    Write-Host "Deteniendo y eliminando contenedores..." -ForegroundColor Yellow
    docker stop $(docker ps -aq) 2>$null
    docker rm $(docker ps -aq) 2>$null

    Write-Host "Eliminando todas las imágenes..." -ForegroundColor Yellow
    docker rmi $(docker images -q) -f 2>$null

    # Eliminar redes Docker personales (no eliminar redes por defecto: bridge, host, none)
    Write-Host "Eliminando redes Docker personales..." -ForegroundColor Yellow
    try {
        $defaultNets = @('bridge','host','none')
        $allNets = docker network ls --format '{{.Name}}' 2>$null
        if ($allNets) {
            foreach ($net in $allNets) {
                if ($defaultNets -notcontains $net) {
                    docker network rm $net 2>$null
                    Write-Host "Red eliminada: $net"
                }
            }
        } else {
            Write-Host "No se encontraron redes Docker adicionales."
        }
    } catch {
        Write-Host "Error al eliminar redes Docker: $_" -ForegroundColor Red
    }

    Write-Host "Eliminando carpetas locales..." -ForegroundColor Yellow
    $folders = @(".\data", ".\logs")
    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            Remove-Item $folder -Recurse -Force
            Write-Host "Carpeta eliminada: $folder"
        } else {
            Write-Host "Carpeta no encontrada: $folder"
        }
    }
    
  
    Write-Host "Eliminando todas las aplicaciones..." -ForegroundColor Yellow
    Remove-AllApps

    Write-Host "============================="
    Write-Host " PURGA COMPLETA FINALIZADA"
    Write-Host "============================="
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
    Add-AppFromGit -SubmoduleName $Name -GitHubUrl $Url -DestinationPath $Path -Branch $Branch
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

if ($Purge) {
    Clear-All
    exit
}

if ($Update) {
    if (-not $Target) {
        Write-Host "Falta parámetro: -Target (all o ruta)" -ForegroundColor Red
        exit 1
    }
    Update-App -Target $Target
    exit
}
if ($Download) {
    if (-not $DownloadUrl -or -not $Version -or -not $Destination) {
        Write-Host "Faltan parámetros: -DownloadUrl -Version -Destination" -ForegroundColor Red
        Write-Host "Usa: .\AdminApp.ps1 -Help" -ForegroundColor Yellow
        exit 1
    }

    Add-FromUrl -UrlDescarga $DownloadUrl -Version $Version -CarpetaDestino $Destination
    exit
}


# Si no hay parámetros → mostrar menú
MainMenu
