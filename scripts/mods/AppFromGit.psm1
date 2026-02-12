function Add-AppFromGit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubmoduleName,
    
        [Parameter(Mandatory = $true)]
        [string]$GitHubUrl,
    
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    try {
        Write-Host "Adding submodule: $SubmoduleName"
        Write-Host "From: $GitHubUrl"
        Write-Host "To: $DestinationPath"
    
        git submodule add $GitHubUrl $DestinationPath
    
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Submodule added successfully!" -ForegroundColor Green
        }
        else {
            Write-Host "Error adding submodule" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "Exception: $_" -ForegroundColor Red
        exit 1
    }
}


function removeAppFromProject() {
    # Elimina TODOS los submódulos de un repositorio Git
    # Ignacio: este script limpia .gitmodules, .git/config, .git/modules y el working tree

    Write-Host "Detectando submódulos..." -ForegroundColor Cyan

    # 1. Obtener lista de submódulos desde .gitmodules
    $gitmodules = ".gitmodules"

    if (!(Test-Path $gitmodules)) {
        Write-Host "No existe .gitmodules. No hay submódulos que eliminar." -ForegroundColor Yellow
        exit
    }

    # Leer rutas de submódulos
    $submodules = Select-String -Path $gitmodules -Pattern "path = " | ForEach-Object {
        ($_ -split "path = ")[1].Trim()
    }

    if ($submodules.Count -eq 0) {
        Write-Host "No se encontraron submódulos en .gitmodules." -ForegroundColor Yellow
        exit
    }

    Write-Host "Submódulos detectados:" -ForegroundColor Green
    $submodules | ForEach-Object { Write-Host " - $_" }

    # 2. Eliminar cada submódulo
    foreach ($sub in $submodules) {

        Write-Host "`nEliminando submódulo: $sub" -ForegroundColor Cyan

        # Deinit
        git submodule deinit -f $sub | Out-Null

        # Eliminar del índice
        git rm -f $sub | Out-Null

        # Eliminar carpeta física
        if (Test-Path $sub) {
            Remove-Item -Recurse -Force $sub
            Write-Host "Carpeta eliminada: $sub"
        }

        # Eliminar carpeta interna en .git/modules
        $modulePath = ".git/modules/$sub"
        if (Test-Path $modulePath) {
            Remove-Item -Recurse -Force $modulePath
            Write-Host "Carpeta interna eliminada: $modulePath"
        }
    }

    # 3. Eliminar archivo .gitmodules
    Remove-Item -Force ".gitmodules"
    Write-Host "`nArchivo .gitmodules eliminado." -ForegroundColor Green

    # 4. Commit final
    git add -A
    git commit -m "Remove all submodules" | Out-Null

    Write-Host "`n✅ Todos los submódulos han sido eliminados completamente." -ForegroundColor Green

}