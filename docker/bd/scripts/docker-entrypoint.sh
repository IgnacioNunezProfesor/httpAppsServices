#!/bin/sh
set -euo pipefail

echo "[Entrypoint] Iniciando contenedor MariaDB"

# --------------------------------------------------------------------
# Validación de variables obligatorias
# --------------------------------------------------------------------
: "${SERVER_DATA_DIR:?Falta SERVER_DATA_DIR}"
: "${SERVER_LOG_PATH:=/var/log/mysql}"
: "${PORT:=3306}"
: "${DB_NAME:?Falta DB_NAME}"
: "${DB_USER:?Falta DB_USER}"
: "${DB_PASS:?Falta DB_PASS}"

# --------------------------------------------------------------------
# Preparar directorios necesarios
# --------------------------------------------------------------------
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chmod 755 /run/mysqld

mkdir -p /entrypointsql "${SERVER_DATA_DIR}" "${SERVER_LOG_PATH}"
chown -R mysql:mysql "${SERVER_DATA_DIR}" "${SERVER_LOG_PATH}" /entrypointsql

# --------------------------------------------------------------------
# Inicializar base de datos (solo primera vez)
# --------------------------------------------------------------------
if [ ! -d "${SERVER_DATA_DIR}/mysql" ]; then
    echo "[Entrypoint] Inicializando base de datos..."
    mariadb-install-db \
        --datadir="${SERVER_DATA_DIR}" \
        --basedir=/usr \
        --auth-root-authentication-method=normal \
        --user=mysql
fi

# --------------------------------------------------------------------
# Arranque temporal (socket local)
# --------------------------------------------------------------------
echo "[Entrypoint] Arrancando MariaDB temporalmente..."
mariadbd \
    --user=mysql \
    --datadir="${SERVER_DATA_DIR}" \
    --bind-address=127.0.0.1 \
    --port=3307 &
TEMP_PID=$!

# --------------------------------------------------------------------
# Esperar a que esté listo (por socket, sin contraseña)
# --------------------------------------------------------------------
echo "[Entrypoint] Esperando a que MariaDB esté listo..."
until mariadb -h 127.0.0.1 -P 3307 -u root -e "SELECT 1" >/dev/null 2>&1; do
    echo "[Entrypoint] MariaDB no responde todavía..."
    sleep 1
done
echo "[Entrypoint] MariaDB está listo."

# --------------------------------------------------------------------
# Ejecutar scripts init por socket
# --------------------------------------------------------------------
echo "[Entrypoint] Ejecutando scripts init..."
for f in /entrypointsql/init*.sql; do
    [ -e "$f" ] || continue
    echo "[Entrypoint] Ejecutando $f con expansión de variables"

    sed \
        -e "s|\${DB_NAME}|${DB_NAME}|g" \
        -e "s|\${DB_USER}|${DB_USER}|g" \
        -e "s|\${DB_PASS}|${DB_PASS}|g" \
        "$f" | mariadb -h 127.0.0.1 -P 3307 -u root
done

# --------------------------------------------------------------------
# Parar servidor temporal
# --------------------------------------------------------------------
echo "[Entrypoint] Deteniendo servidor temporal..."
kill "$TEMP_PID"
wait "$TEMP_PID"

# --------------------------------------------------------------------
# Arranque final (PID 1, accesible desde fuera)
# --------------------------------------------------------------------
echo "[Entrypoint] Arrancando MariaDB en modo servidor..."
exec mariadbd \
    --user=mysql \
    --datadir="${SERVER_DATA_DIR}" \
    --bind-address=0.0.0.0 \
    --port="${PORT}"
