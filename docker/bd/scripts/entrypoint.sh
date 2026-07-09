#!/bin/sh
set -euo pipefail
#
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting MariaDB container entrypoint"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"
#
# =====================================================================
# Validation of required variables
# =====================================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Validating required environment variables..."
: "${SERVER_ID:?ERROR:SERVER_ID is required}"
: "${SERVER_PORT:?ERROR:SERVER_PORT is required}"
: "${SERVER_DATA_DIR:?ERROR: SERVER_DATA_DIR is required}"
: "${SERVER_LOG_PATH:?ERROR: SERVER_LOG_PATH is required}"
: "${DB_NAME:?ERROR: DB_NAME is required}"
: "${DB_USER:?ERROR: DB_USER is required}"
: "${DB_PASS:?ERROR: DB_PASS is required}"
: "${IP:?ERROR: IP is required}"
: "${NETWORK_NAME:?ERROR: NETWORK_NAME is required}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_ID=${SERVER_ID}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_PORT=${SERVER_PORT}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_DATA_DIR=${SERVER_DATA_DIR}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_LOG_PATH=${SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: DB_NAME=${DB_NAME}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: DB_USER=${DB_USER}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: DB_PASS=${DB_PASS}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: IP=${IP}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: NETWORK_NAME=${NETWORK_NAME}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: All required variables are set"
#
# =====================================================================
# Prepare necessary directories
# =====================================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Preparing necessary directories..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Creating /run/mysqld"
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Set ownership for /run/mysqld" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to set ownership for /run/mysqld"
chmod 755 /run/mysqld && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Set permissions for /run/mysqld" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to set permissions for /run/mysqld"
#
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Creating data and log directories"
mkdir -p /entrypointsql "${SERVER_DATA_DIR}" "${SERVER_LOG_PATH}"
chown -R mysql:mysql "${SERVER_DATA_DIR}" "${SERVER_LOG_PATH}" /entrypointsql && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Set ownership for data directories" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to set ownership"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: All directories prepared"
#
# =====================================================================
# Initialize database (only first time)
# =====================================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Checking if database needs initialization..."
if [ ! -d "${SERVER_DATA_DIR}/mysql" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Database not found, initializing..."
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Running mariadb-install-db..."
    mariadb-install-db \
        --datadir="${SERVER_DATA_DIR}" \
        --basedir=/usr \
        --auth-root-authentication-method=normal \
        --user=mysql && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Database initialized" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Database initialization failed"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Database already exists, skipping initialization"
fi
#
# =====================================================================
# Temporary startup (local socket)
# =====================================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting MariaDB temporarily..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Listening on 127.0.0.1:3307"
mariadbd \
    --user=mysql \
    --datadir="${SERVER_DATA_DIR}" \
    --bind-address=127.0.0.1 \
    --port=3307 &
TEMP_PID=$!
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Temporary server PID: $TEMP_PID"
#
# =====================================================================
# Wait for temporary server to be ready (socket, no password)
# =====================================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Waiting for MariaDB to be ready..."
RETRY_COUNT=0
MAX_RETRIES=60
until mariadb -h 127.0.0.1 -P 3307 -u root -e "SELECT 1" >/dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: MariaDB did not become ready after $MAX_RETRIES attempts"
        kill "$TEMP_PID" 2>/dev/null || true
        exit 1
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: MariaDB not responding yet (attempt $RETRY_COUNT/$MAX_RETRIES)..."
    sleep 1
done
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: MariaDB is ready"
#
# =====================================================================
# Execute init scripts via socket
# =====================================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Executing initialization scripts..."
SCRIPT_COUNT=0
for f in /entrypointsql/init*.sql; do
    [ -e "$f" ] || continue
    SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Processing script: $f"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Expanding variables in script..."
    sed \
        -e "s|\${DB_NAME}|${DB_NAME}|g" \
        -e "s|\${DB_USER}|${DB_USER}|g" \
        -e "s|\${DB_PASS}|${DB_PASS}|g" \
        "$f" | mariadb -h 127.0.0.1 -P 3307 -u root && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Script executed: $f" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to execute script: $f"
done
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Executed $SCRIPT_COUNT initialization scripts"
#
# =====================================================================
# Stop temporary server
# =====================================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Stopping temporary server..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Killing PID $TEMP_PID"
kill "$TEMP_PID"
wait "$TEMP_PID" 2>/dev/null || true
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Temporary server stopped"
#
# =====================================================================
# Final startup (PID 1, accessible from outside)
# =====================================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting MariaDB server mode (PID 1)..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Listening on 0.0.0.0:${SERVER_PORT}"
exec mariadbd \
    --user=mysql \
    --datadir="${SERVER_DATA_DIR}" \
    --bind-address=0.0.0.0 \
    --port="${SERVER_PORT}" \
    --server-id=${SERVER_ID} \
    --log-error="${SERVER_LOG_PATH}/mariadb.log" \
    --general-log=1 \
    --general-log-file="${SERVER_LOG_PATH}/mariadb_general.log" \
    --slow-query-log=1 \
    --slow-query-log-file="${SERVER_LOG_PATH}/mariadb_slow.log" || {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: MariaDB failed to start"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Checking mariadb.log..."
        tail -30 "${SERVER_LOG_PATH}/mariadb.log" || echo "Log file not found"
        exit 1
    }
