#!/bin/bash

IMAGE_NAME="auditoria-web"
CONTAINER_NAME="auditoria-web-container"

TARGET=""
PARAMS=""
RESULTS_DIR="./results"

# --- Parseo de parámetros ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--target) TARGET="$2"; shift ;;
        *) PARAMS="$PARAMS $1" ;;
    esac
    shift
done

if [[ -z "$TARGET" ]]; then
    echo "Uso: ./launch-container.sh -t https://site.com [opciones del script]"
    exit 1
fi

# --- Construir imagen si no existe ---
if [[ -z "$(docker images -q $IMAGE_NAME)" ]]; then
    echo "[+] Imagen no encontrada. Construyendo..."
    docker build -t $IMAGE_NAME .
fi

# --- Crear carpeta de resultados ---
mkdir -p "$RESULTS_DIR"

# --- Ejecutar contenedor y lanzar análisis ---
echo "[+] Lanzando contenedor y ejecutando análisis..."
docker run --rm \
    -v "$(pwd)/results:/analysis/results" \
    --name $CONTAINER_NAME \
    $IMAGE_NAME \
    bash -c "./run-analysis.sh -t $TARGET $PARAMS"

echo "[+] Análisis completado. Resultados en ./results"
