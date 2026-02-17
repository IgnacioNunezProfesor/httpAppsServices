function Add-AppFromGit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubmoduleName,
    
        [Parameter(Mandatory = $true)]
        [string]$GitHubUrl,
    
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    # Verificar si el submódulo ya existe
    if (Test-AppExists -SubmoduleName $SubmoduleName) {
        Write-Host "El submódulo '$SubmoduleName' ya existe. No se realiza ninguna acción." -ForegroundColor Yellow
        return
    }

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
function   Remove-AllApps() {
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
        git rm -rf --cached$sub | Out-Null

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
function Remove-App {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubmodulePath
    )

    if (!(Test-Path ".gitmodules")) {
        Write-Host "No existe .gitmodules. No hay submódulos que eliminar." -ForegroundColor Yellow
        exit
    }

    # Verificar que el submódulo existe en .gitmodules
    $exists = Select-String -Path ".gitmodules" -Pattern "path = $SubmodulePath"

    if (-not $exists) {
        Write-Host "El submódulo '$SubmodulePath' no existe." -ForegroundColor Red
        exit
    }

    Write-Host "Eliminando submódulo: $SubmodulePath" -ForegroundColor Cyan

    git submodule deinit -f $SubmodulePath | Out-Null
    git rm -f $SubmodulePath | Out-Null

    if (Test-Path $SubmodulePath) {
        Remove-Item -Recurse -Force $SubmodulePath
        Write-Host "Carpeta eliminada: $SubmodulePath"
    }

    $modulePath = ".git/modules/$SubmodulePath"
    if (Test-Path $modulePath) {
        Remove-Item -Recurse -Force $modulePath
        Write-Host "Carpeta interna eliminada: $modulePath"
    }

    git add -A
    git commit -m "Remove submodule $SubmodulePath" | Out-Null

    Write-Host "Submódulo eliminado correctamente." -ForegroundColor Green
}

function Test-AppExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubmoduleName
    )

    if (!(Test-Path ".gitmodules")) {
        return $false
    }

    $exists = Select-String -Path ".gitmodules" -Pattern "path = $SubmoduleName" -ErrorAction SilentlyContinue
    return $null -ne $exists
}

function Update-App {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    if (!(Test-Path ".gitmodules")) {
        Write-Host "No existe .gitmodules. No hay submódulos que actualizar." -ForegroundColor Yellow
        return
    }

    # Obtener lista de submódulos
    $submodules = Select-String -Path ".gitmodules" -Pattern "path = " |
    ForEach-Object { ($_ -split "path = ")[1].Trim() }

    if ($submodules.Count -eq 0) {
        Write-Host "No se encontraron submódulos en .gitmodules." -ForegroundColor Yellow
        return
    }

    if ($Target -eq "all") {
        Write-Host "Actualizando TODOS los submódulos..." -ForegroundColor Cyan
        git submodule update --remote --merge

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Todos los submódulos han sido actualizados correctamente." -ForegroundColor Green
        }
        else {
            Write-Host "Error al actualizar los submódulos." -ForegroundColor Red
        }
        return
    }

    # Actualizar un submódulo específico
    if ($submodules -notcontains $Target) {
        Write-Host "El submódulo '$Target' no existe." -ForegroundColor Red
        return
    }

    Write-Host "Actualizando submódulo: $Target" -ForegroundColor Cyan
    git submodule update --remote --merge $Target

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Submódulo '$Target' actualizado correctamente." -ForegroundColor Green
    }
    else {
        Write-Host "Error al actualizar el submódulo '$Target'." -ForegroundColor Red
    }
}
