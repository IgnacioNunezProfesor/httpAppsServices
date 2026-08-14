function Add-AppFromGit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubmoduleName,
    
        [Parameter(Mandatory = $true)]
        [string]$GitHubUrl,
    
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [string]$Branch = "main"
    )

    # Verificar si el submódulo ya existe
    if (Test-AppExists -SubmoduleName $SubmoduleName) {
        Write-Host "El submódulo '$SubmoduleName' ya existe. No se realiza ninguna acción." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Adding submodule: $SubmoduleName"
        Write-Host "From: $GitHubUrl"
        $absoluteDestination = [System.IO.Path]::GetFullPath($DestinationPath)
        Write-Host "To (absolute): $DestinationPath --> $absoluteDestination"
    
        git submodule add -b $Branch $GitHubUrl $DestinationPath 
        Set-Location $absoluteDestination
        git submodule update --remote
        Set-Location ..

    
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

function Add-FromUrl {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UrlDescarga,

        [Parameter(Mandatory=$true)]
        [string]$Version,

        [Parameter(Mandatory=$true)]
        [string]$CarpetaDestino
    )

    # Crear carpeta destino si no existe
    if (-not (Test-Path $CarpetaDestino)) {
        New-Item -ItemType Directory -Path $CarpetaDestino | Out-Null
    }

    # Archivo temporal según versión
    $TempFile = Join-Path $env:TEMP "app-$Version.tmp"

    Write-Host "Descargando paquete desde $UrlDescarga ..."
    Invoke-WebRequest -Uri $UrlDescarga -OutFile $TempFile
    Write-Host "Descarga completada."

    # Detectar extensión automáticamente
    $Extension = [System.IO.Path]::GetExtension($UrlDescarga).ToLower()

    Write-Host "Detectando tipo de archivo: $Extension"

    switch ($Extension) {

        # ---------------- ZIP ----------------
        ".zip" {
            Write-Host "Descomprimiendo ZIP sin crear doble carpeta..."

            # Carpeta temporal para extraer el ZIP
            $TempExtract = Join-Path $env:TEMP "extract-$Version"
            if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
            New-Item -ItemType Directory -Path $TempExtract | Out-Null

            # Extraer ZIP
            Expand-Archive -Path $TempFile -DestinationPath $TempExtract -Force

            # Detectar si el ZIP tiene carpeta raíz
            $rootItems = Get-ChildItem $TempExtract
            if ($rootItems.Count -eq 1 -and $rootItems[0].PSIsContainer) {
                # ZIP con carpeta raíz → mover contenido interno
                $innerFolder = $rootItems[0].FullName
                Write-Host "ZIP contiene carpeta raíz: $($rootItems[0].Name)"
                Write-Host "Moviendo contenido a $CarpetaDestino..."

                Get-ChildItem $innerFolder | ForEach-Object {
                    Move-Item $_.FullName -Destination $CarpetaDestino -Force
                }
            }
            else {
                # ZIP sin carpeta raíz → mover todo
                Write-Host "ZIP sin carpeta raíz. Moviendo contenido..."
                Get-ChildItem $TempExtract | ForEach-Object {
                    Move-Item $_.FullName -Destination $CarpetaDestino -Force
                }
            }

            # Limpiar temporales
            Remove-Item $TempExtract -Recurse -Force
        }

        # ---------------- TGZ / TAR.GZ ----------------
        ".tgz" { tar -xzf $TempFile -C $CarpetaDestino }
        ".gz"  { tar -xzf $TempFile -C $CarpetaDestino }
        ".tar" { tar -xf  $TempFile -C $CarpetaDestino }

        default {
            throw "Extensión no soportada: $Extension"
        }
    }

    Write-Host "Aplicación versión $Version instalada en $CarpetaDestino"
    Remove-Item $TempFile -Force
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
        git rm -rf --cached $sub | Out-Null

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
