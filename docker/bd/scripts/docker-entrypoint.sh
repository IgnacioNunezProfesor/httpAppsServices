#!/bin/sh
set -euo pipefail

echo "[Entrypoint] Iniciando contenedor MariaDB"

: "${DB_UNIX_USER:?Falta DB_UNIX_USER}"
: "${DB_ROOT_PASS:?Falta DB_ROOT_PASS}"
: "${DB_SERVER_DATA_DIR:?Falta DB_SERVER_DATA_DIR}"
: "${DB_SERVER_LOG:=/var/log/mysql}"
: "${DB_PORT:=3306}"

echo "[Entrypoint] Creando usuario UNIX: ${DB_UNIX_USER}"
if ! id "${DB_UNIX_USER}" >/dev/null 2>&1; then
    addgroup -S "${DB_UNIX_USER}"
    adduser -S "${DB_UNIX_USER}" -G "${DB_UNIX_USER}"
fi

mkdir -p /run/mysqld
chown ${DB_UNIX_USER}:${DB_UNIX_USER} /run/mysqld
chmod 777 /run/mysqld

mkdir -p /entrypointsql "${DB_SERVER_DATA_DIR}" "${DB_SERVER_LOG}"
chown -R "${DB_UNIX_USER}:${DB_UNIX_USER}" "${DB_SERVER_DATA_DIR}" "${DB_SERVER_LOG}" /entrypointsql

# --------------------------------------------------------------------
# Inicializar base de datos (solo primera vez)
# --------------------------------------------------------------------
if [ ! -d "${DB_SERVER_DATA_DIR}/mysql" ]; then
    echo "[Entrypoint] Inicializando base de datos..."
    mariadb-install-db \
        --datadir="${DB_SERVER_DATA_DIR}" \
        --user="${DB_UNIX_USER}" \
        --basedir=/usr \
        --auth-root-authentication-method=normal
fi

# --------------------------------------------------------------------
# Arranque temporal (socket local)
# --------------------------------------------------------------------
echo "[Entrypoint] Arrancando MariaDB temporalmente..."
mariadbd \
    --user="${DB_UNIX_USER}" \
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
# Configurar root SOLO en localhost (socket)
# --------------------------------------------------------------------
echo "[Entrypoint] Configurando usuario root..."
mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
FLUSH PRIVILEGES;
EOF

# --------------------------------------------------------------------
# Ejecutar scripts init por socket (ya con contraseña)
# --------------------------------------------------------------------
echo "[Entrypoint] Ejecutando scripts init..."
for f in /entrypointsql/init*.sql; do
    [ -e "$f" ] || continue
    echo "[Entrypoint] Ejecutando $f"
    mariadb -u root -p"${DB_ROOT_PASS}" < "$f"
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
    --user="${DB_UNIX_USER}" \
    --datadir="${DB_SERVER_DATA_DIR}" \
    --bind-address=0.0.0.0 \
    --port="${DB_PORT}"
