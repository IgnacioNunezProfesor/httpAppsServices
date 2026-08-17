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
        [string]$DownloadUrl,

        [Parameter(Mandatory=$true)]
        [string]$Destination
    )

    Write-Host "=== Add-FromUrl iniciado ==="

       $downloads = Join-Path $wwwroot "downloads"

    Write-Host "Destino final: $Destination"
    Write-Host "Carpeta de descargas: $downloads"

    # ---------------------------------------------------------
    # 2. Validar carpeta destino
    # ---------------------------------------------------------
    if (-not (Test-Path $Destination)) {
        Write-Host "La carpeta destino no existe. Creándola..."
        New-Item -ItemType Directory -Path $Destination | Out-Null
    } else {
        $items = Get-ChildItem $Destination
        if ($items.Count -gt 0) {
            Write-Host "ERROR: La carpeta '$Destination' existe y NO está vacía."
            Write-Host "Proceso cancelado."
            return
        }
        Write-Host "La carpeta destino existe y está vacía. Continuando..."
    }

    # ---------------------------------------------------------
    # 3. Crear carpeta downloads si no existe
    # ---------------------------------------------------------
    if (-not (Test-Path $downloads)) {
        Write-Host "Creando carpeta de descargas..."
        New-Item -ItemType Directory -Path $downloads | Out-Null
    }

    # ---------------------------------------------------------
    # 4. Obtener nombre del archivo desde la URL
    # ---------------------------------------------------------
    $FileName = [System.IO.Path]::GetFileName($DownloadUrl)
    if ([string]::IsNullOrWhiteSpace($FileName)) {
        throw "La URL '$DownloadUrl' no contiene un nombre de archivo válido."
    }

    $TempFile = Join-Path $downloads $FileName
    Write-Host "Archivo detectado: $FileName"

    # ---------------------------------------------------------
    # 5. Descargar archivo
    # ---------------------------------------------------------
    Write-Host "Descargando paquete desde $DownloadUrl ..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFile -ErrorAction Stop
    Write-Host "Descarga completada: $TempFile"

    # ---------------------------------------------------------
    # 6. Detectar extensión
    # ---------------------------------------------------------
    $Extension = [System.IO.Path]::GetExtension($FileName).ToLower()
    Write-Host "Detectando tipo de archivo: $Extension"

    # ---------------------------------------------------------
    # 7. Descomprimir en carpeta destino
    # ---------------------------------------------------------
    Write-Host "Descomprimiendo en $Destination ..."

    switch ($Extension) {

        ".zip" {
            Expand-Archive -Path $TempFile -DestinationPath $Destination -Force -ErrorAction Stop
        }

        ".tgz" { tar -xzf $TempFile -C $Destination }
        ".gz"  { tar -xzf $TempFile -C $Destination }
        ".tar" { tar -xf  $TempFile -C $Destination }

        default {
            throw "Extensión no soportada: $Extension"
        }
    }

    Write-Host "Descompresión completada."

    # ---------------------------------------------------------
    # 8. Normalizar contenido: evitar carpeta única
    # ---------------------------------------------------------
    $content = Get-ChildItem $Destination

    if ($content.Count -eq 1 -and $content[0].PSIsContainer) {
        Write-Host "El paquete contiene una única carpeta. Moviendo contenido al destino raíz..."

        $innerFolder = $content[0].FullName
        Get-ChildItem $innerFolder | ForEach-Object {
            Move-Item $_.FullName $Destination -Force
        }

        Remove-Item $innerFolder -Force -Recurse
        Write-Host "Contenido normalizado."
    } else {
        Write-Host "El paquete contiene múltiples archivos o carpetas. No se requiere normalización."
    }

    # ---------------------------------------------------------
    # 9. Limpieza
    # ---------------------------------------------------------
    Write-Host "Eliminando archivo temporal..."
    Remove-Item $TempFile -Force

    Write-Host "Aplicación instalada correctamente en $Destination"
    Write-Host "=== Add-FromUrl finalizado ==="
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
