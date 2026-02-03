#!/bin/sh
set -euo pipefail

echo "[Entrypoint] Iniciando contenedor MariaDB"

# Validación de variables obligatorias
: "${DB_UNIX_USER:?Falta DB_UNIX_USER (usuario SQL)}"
: "${DB_ROOT_PASS:?Falta DB_ROOT_PASS}"
: "${DB_SERVER_DATA_DIR:?Falta DB_SERVER_DATA_DIR}"

# Inicializar datadir si está vacío
if [ ! -d "${DB_SERVER_DATA_DIR}/mysql" ]; then
    echo "[Entrypoint] Inicializando base de datos..."
    mariadb-install-db --datadir="${DB_SERVER_DATA_DIR}"
fi

echo "[Entrypoint] Arrancando MariaDB..."
mariadbd --datadir="${DB_SERVER_DATA_DIR}" & PID=$!

# Esperar a que MariaDB esté listo
echo "[Entrypoint] Esperando a MariaDB..."
until mariadb-admin ping --silent; do
    sleep 1
done

echo "[Entrypoint] Configurando usuarios SQL y base de datos..."
mariadb -u root <<EOF
ALTER USER 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASS}';
EOF

# Ejecutar scripts SQL adicionales
if [ -d "/entrypointsql" ]; then
    for f in /entrypointsql/*.sql; do
        [ -f "$f" ] || continue
        echo "[Entrypoint] Ejecutando script: $f"
        mariadb -u root -p"${DB_ROOT_PASS}" < "$f"
    done
fi

echo "[Entrypoint] MariaDB listo."
exec mariadbd \
    --datadir="${DB_SERVER_DATA_DIR}" \
    --user="${DB_UNIX_USER}" \
    --bind-address=0.0.0.0 \
    --port="${DB_PORT}"
wait "$PID"