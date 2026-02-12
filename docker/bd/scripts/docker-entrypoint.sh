#!/bin/sh
set -euo pipefail

echo "[Entrypoint] Iniciando contenedor MariaDB"

: "${SERVER_DATADIR:?Falta SERVER_DATADIR}"
: "${SERVER_LOG:=/var/log/mysql}"
: "${PORT:=3306}"

echo "[Entrypoint] Creando usuario UNIX: $mariadb"
if ! id "mariadb" >/dev/null 2>&1; then
    addgroup -S "mariadb"
    adduser -S "mariadb" -G "mariadb"
fi

mkdir -p /run/mysqld
chown mariadb:mariadb /run/mysqld
chmod 777 /run/mysqld

mkdir -p /entrypointsql "${SERVER_DATADIR}" "${SERVER_LOG}"
chown -R "mariadb:mariadb" "${SERVER_DATADIR}" "${SERVER_LOG}" /entrypointsql

# --------------------------------------------------------------------
# Inicializar base de datos (solo primera vez)
# --------------------------------------------------------------------
if [ ! -d "${DB_SERVER_DATA_DIR}/mysql" ]; then
    echo "[Entrypoint] Inicializando base de datos..."
    mariadb-install-db \
        --datadir="${DB_SERVER_DATA_DIR}" \
        --basedir=/usr \
        --auth-root-authentication-method=normal
fi

# --------------------------------------------------------------------
# Arranque temporal (socket local)
# --------------------------------------------------------------------
echo "[Entrypoint] Arrancando MariaDB temporalmente..."
mariadbd \
    --datadir="${DB_SERVER_DATA_DIR}" \
    --bind-address=127.0.0.1 \
    --port="${DB_PORT}" &
TEMP_PID=$!

# --------------------------------------------------------------------
# Esperar a que esté listo (por socket, sin contraseña)
# --------------------------------------------------------------------
echo "[Entrypoint] Esperando a que MariaDB esté listo..."
until mariadb -u root -e "SELECT 1" >/dev/null 2>&1; do
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
        "$f" | mariadb -u root
done



# --------------------------------------------------------------------
# Parar servidor temporal
# --------------------------------------------------------------------
echo "[Entrypoint] Deteniendo servidor temporal..."
kill "$TEMP_PID"
sleep 2

# --------------------------------------------------------------------
# Arranque final (PID 1, accesible desde fuera)
# --------------------------------------------------------------------
echo "[Entrypoint] Arrancando MariaDB en modo servidor..."
exec mariadbd \
    --datadir="${SERVER_DATADIR}" \
    --bind-address=0.0.0.0 \
    --port="${PORT}"
