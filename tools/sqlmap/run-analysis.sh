#!/bin/bash

TARGET=""
SQLMAP=false
WPSCAN=false
NIKTO=false
WHATWEB=false
ALL=false
OUTPUT="./results"

# --- Parseo de parámetros ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--target) TARGET="$2"; shift ;;
        --sqlmap) SQLMAP=true ;;
        --wpscan) WPSCAN=true ;;
        --nikto) NIKTO=true ;;
        --whatweb) WHATWEB=true ;;
        --all) ALL=true ;;
        -o|--output) OUTPUT="$2"; shift ;;
        *) echo "Parámetro desconocido: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$TARGET" ]]; then
    echo "Uso: ./run-analysis.sh -t https://site.com [--sqlmap] [--wpscan] [--nikto] [--whatweb] [--all]"
    exit 1
fi

# --- Crear carpeta de resultados ---
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FOLDER="$OUTPUT/$TIMESTAMP"
mkdir -p "$FOLDER"

echo "[+] Iniciando análisis sobre $TARGET"
echo "[+] Resultados en: $FOLDER"

# --- Funciones ---
run_sqlmap() {
    echo "[SQLMAP] Ejecutando análisis..."
    sqlmap -u "$TARGET" \
        --batch \
        --crawl=3 \
        --level=5 \
        --risk=3 \
        --random-agent \
        --threads=5 \
        --output-dir="$FOLDER/sqlmap" | tee "$FOLDER/sqlmap.log"
}

run_wpscan() {
    echo "[WPSCAN] Escaneando WordPress..."
    wpscan --url "$TARGET" --enumerate ap,at,cb,dbe,u,m --random-user-agent \
        | tee "$FOLDER/wpscan.log"
}

run_nikto() {
    echo "[NIKTO] Ejecutando análisis..."
    nikto -h "$TARGET" | tee "$FOLDER/nikto.log"
}

run_whatweb() {
    echo "[WHATWEB] Fingerprinting..."
    whatweb "$TARGET" --log-verbose="$FOLDER/whatweb.log"
}

# --- Lógica de ejecución ---
if $ALL; then
    SQLMAP=true
    WPSCAN=true
    NIKTO=true
    WHATWEB=true
fi

$SQLMAP && run_sqlmap
$WPSCAN && run_wpscan
$NIKTO  && run_nikto
$WHATWEB && run_whatweb

echo "[+] Análisis completado."
