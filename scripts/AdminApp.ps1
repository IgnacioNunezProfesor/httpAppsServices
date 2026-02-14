if (Get-Module 'AppFromGit') { 
    Remove-Module 'AppFromGit' -Force 
} 
Import-Module .\scripts\mods\AppFromGit.psm1 -Force
function Main {
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

Main
