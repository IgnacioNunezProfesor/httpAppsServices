#!/bin/bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== APP ${APP_NAME} DOCKER ENVIRONMENT VARIABLES DEBUG ====="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting Moodle entrypoint script..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== DOCKER ENVIRONMENT VARIABLES DEBUG ====="

echo "[$(date '+%Y-%m-%d %H:%M:%S')] IMAGE_NAME=${IMAGE_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONTAINER_NAME=${CONTAINER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DOCKERFILE_PATH=${DOCKERFILE_PATH:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_NAME=${SERVER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_PORT=${SERVER_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_ROOT_PATH=${LOCAL_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_ROOT_PATH=${SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_INFO_PATH=${LOCAL_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_INFO_PATH=${SERVER_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALIAS_INFO_PATH=${ALIAS_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_LOG_PATH=${LOCAL_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_LOG_PATH=${SERVER_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_DATA_PATH=${SERVER_DATA_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_DATA_PATH=${LOCAL_DATA_PATH:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_NAME=${DB_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_USER=${DB_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_PASS=${DB_PASS:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DB_HOST=${DB_HOST:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_NAME=${APP_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_GITHUB_URL=${APP_GITHUB_URL:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_LOCAL_PATH=${APP_LOCAL_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_COMPOSE_PATH=${APP_COMPOSE_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ENTRYPOINT_LOCAL_PATH=${APP_ENTRYPOINT_LOCAL_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ENTRYPOINT_SERVER_PATH=${APP_ENTRYPOINT_SERVER_PATH:-NOT SET}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ADMIN_USER=${APP_ADMIN_USER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ADMIN_PASS=${APP_ADMIN_PASS:-NOT SET (Set for security)}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_ADMIN_EMAIL=${APP_ADMIN_EMAIL:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ==========================================="

#!/bin/bash
set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "===== MOODLE UNATTENDED INSTALLER ====="
log "Starting entrypoint for ${APP_NAME:-Moodle}"

# -----------------------------------------------------------------------------
# 1. VALIDAR VARIABLES DE ENTORNO
# -----------------------------------------------------------------------------
# Usamos exactamente las llaves que le pasa el docker-compose.yml
required_vars="
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASS
SERVER_NAME
SERVER_PORT
LOCAL_PORT
SERVER_ROOT_PATH
SERVER_DATA_PATH
APP_ADMIN_USER
APP_ADMIN_PASS
APP_ADMIN_EMAIL
"

for var in $required_vars; do
    eval "value=\${$var}"
    if [ -z "$value" ]; then
        log "ERROR: Required environment variable '$var' is missing or empty."
        exit 1
    fi
done

log "All required environment variables are present."

# -----------------------------------------------------------------------------
# 2. CREAR DIRECTORIO moodledata
# -----------------------------------------------------------------------------
if [ ! -d "$SERVER_DATA_PATH" ]; then
    log "Creating Moodle data directory at ${SERVER_DATA_PATH}..."
    mkdir -p "$SERVER_DATA_PATH"
fi

# -----------------------------------------------------------------------------
# 3. GENERAR config.php (SI NO EXISTE)
# -----------------------------------------------------------------------------
config_file="${SERVER_ROOT_PATH}/config.php.back"

if [ -f "$config_file" ]; then
    log "Existing config.php found. Backing up to config.php.bak..."
    cp -f "$config_file" "${config_file}.bak"
fi

if [ ! -f "$config_file" ]; then
    log "Generating Moodle config.php..."

    # Determinar si el puerto debe incluirse en el wwwroot
    if [ "$SERVER_PORT" = "80" ] || [ "$SERVER_PORT" = "443" ]; then
        wwwroot_url="http://${SERVER_NAME}"
    else
        wwwroot_url="http://${SERVER_NAME}:${SERVER_PORT}"
    fi

    cat > "$config_file" <<EOF
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = 'mariadb';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${DB_HOST}';
\$CFG->dbname    = '${DB_NAME}';
\$CFG->dbuser    = '${DB_USER}';
\$CFG->dbpass    = '${DB_PASS}';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array(
    'dbpersist'   => 0,
    'dbport'      => '${DB_PORT}',
    'dbsocket'    => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

\$CFG->wwwroot   = 'http://${SERVER_NAME}';
\$CFG->dirroot   = '${SERVER_ROOT_PATH}';
\$CFG->dataroot  = '${SERVER_DATA_PATH}';

\$CFG->admin     = 'admin';
\$CFG->directorypermissions = 02777;
\$CFG->filepermissions      = 0666;

require_once(\$CFG->dirroot . '/lib/setup.php');
EOF

    log "config.php successfully created."
else
    log "config.php already exists. Skipping creation."
fi



# -----------------------------------------------------------------------------
# 4. VALIDAR REQUISITOS CON COMPOSER
# -----------------------------------------------------------------------------
if [ -f "${SERVER_ROOT_PATH}/composer.json" ]; then
    if command -v composer >/dev/null 2>&1; then
        log "Checking Composer platform requirements..."
        (
            cd "${SERVER_ROOT_PATH}" || exit 1
            composer check-platform-reqs --no-interaction
        ) || {
            log "ERROR: Composer platform requirements check failed."
            exit 1
        }

        log "Installing Composer dependencies..."
        (
            cd "${SERVER_ROOT_PATH}" || exit 1
            composer install --no-interaction --prefer-dist --no-progress
        ) || {
            log "ERROR: Composer install failed."
            exit 1
        }
    else
        log "WARNING: composer command not found. Skipping Composer platform requirements check and install."
    fi
else
    log "No composer.json found in ${SERVER_ROOT_PATH}. Skipping Composer requirements check and install."
fi



# -----------------------------------------------------------------------------
# 5. INSTALACIÓN DESATENDIDA COMPLETA DE MOODLE
# -----------------------------------------------------------------------------
# Usamos el instalador CLI completo para que Moodle se configure en su totalidad
# en modo no interactivo, sin depender de la instalación manual por navegador.

log "Checking/Installing Moodle with the complete unattended CLI installer..."

php "${SERVER_ROOT_PATH}/admin/cli/install.php" \
    --non-interactive \
    --agree-license \
    --chmod=0777 \
    --lang=es \
    --wwwroot="http://${SERVER_NAME}:${SERVER_PORT}" \
    --dataroot="${SERVER_DATA_PATH}" \
    --dirroot="${SERVER_ROOT_PATH}" \
    --dirlib="${SERVER_ROOT_PATH}/lib" \
    --dbtype=mariadb \
    --dbhost="${DB_HOST}" \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbport="${DB_PORT}" \
    --prefix=mdl_ \
    --fullname="${APP_NAME}" \
    --shortname="${APP_NAME}" \
    --adminuser="${APP_ADMIN_USER}" \
    --adminpass="${APP_ADMIN_PASS}" \
    --adminemail="${APP_ADMIN_EMAIL}" || log "Moodle is already installed or populated. Continuing startup..."

# -----------------------------------------------------------------------------
# 6. APLICAR PERMISOS
# -----------------------------------------------------------------------------
log "Applying folder permissions..."

# Aseguramos que el usuario que ejecuta Apache (apache o www-data) sea el propietario
web_user="apache"
if ! id "$web_user" >/dev/null 2>&1; then
    web_user="www-data"
fi

chown -R ${web_user}:${web_user} "${SERVER_ROOT_PATH}"
chown -R ${web_user}:${web_user} "${SERVER_DATA_PATH}"

log "Permissions successfully applied for user ${web_user}."

# -----------------------------------------------------------------------------
# 7. ARRANCAR EL SERVIDOR APACHE
# -----------------------------------------------------------------------------
log "Starting Apache web server..."

if command -v httpd >/dev/null 2>&1; then
    exec httpd -D FOREGROUND
elif command -v apache2-foreground >/dev/null 2>&1; then
    exec apache2-foreground
else
    exec apache2 -D FOREGROUND
fi