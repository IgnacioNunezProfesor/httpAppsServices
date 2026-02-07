#!/bin/sh
set -euo pipefail

echo "[Entrypoint] Iniciando contenedor MariaDB"

: "${DB_UNIX_USER:?Falta DB_UNIX_USER}"
: "${DB_ROOT_PASS:?Falta DB_ROOT_PASS}"
: "${DB_SERVER_DATA_DIR:?Falta DB_SERVER_DATA_DIR}"
: "${DB_SERVER_LOG:=/var/log/mysql}"
: "${DB_PORT:=3306}"

echo "[Entrypoint] Creating ${DB_UNIX_USER}"
if ! id "${DB_UNIX_USER}" &>/dev/null; then
    addgroup -S "${DB_UNIX_USER}"
    adduser -S "${DB_UNIX_USER}" -G "${DB_UNIX_USER}"
fi

mkdir -p /run/mysqld
chown ${DB_UNIX_USER}:${DB_UNIX_USER} /run/mysqld
chmod 777 /run/mysqld

mkdir -p /entrypointsql "${DB_SERVER_DATA_DIR}" "${DB_SERVER_LOG}"
#chown -R "${DB_UNIX_USER}:${DB_UNIX_USER}" "${DB_SERVER_DATA_DIR}" "${DB_SERVER_LOG}" /entrypointsql

# Inicializar base de datos
if [ ! -d "${DB_SERVER_DATA_DIR}/mysql" ]; then
    echo "[Entrypoint] Inicializando base de datos..." 
    if ! output=$(mariadb-install-db --datadir="${DB_SERVER_DATA_DIR}" --user="${DB_UNIX_USER}" --basedir=/usr --auth-root-authentication-method=normal 2>&1); then 
        echo "[Entrypoint] ERROR: mariadb-install-db falló" 
        echo "[Entrypoint] Detalle del error:" 
        echo "$output" 
        exit 1 
    fi 
    echo "[Entrypoint] Base de datos inicializada correctamente"

    echo "[Entrypoint] Aplicando configuración inicial (bootstrap)..."
fi


echo "[Entrypoint] Arrancando MariaDB..."
exec mariadbd \
    --datadir="${DB_SERVER_DATA_DIR}" \
    --bind-address=0.0.0.0 \
    --port="${DB_PORT}"