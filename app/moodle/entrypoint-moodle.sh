#!/bin/bash
set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/apache2/entrypoint-moodle.log
}

log "===== MOODLE UNATTENDED INSTALLER ====="
log "Starting entrypoint for ${APP_NAME:-Moodle}"
log "DEBUG: Script PID: $$"

# -----------------------------------------------------------------------------
# 0. CORREGIR ORDEN DE CARGA DE MÓDULOS PHP (ALPINE / PHP 8.3)
# -----------------------------------------------------------------------------
PHP_CONF_DIR="/etc/php83/conf.d"

if [ -d "$PHP_CONF_DIR" ]; then
    log "Fixing PHP module loading order in $PHP_CONF_DIR..."
    (
        cd "$PHP_CONF_DIR" || exit 1

        # Asegurar que los módulos core/base tengan prioridad de carga
        [ -f dom.ini ] && mv dom.ini 00_dom.ini 2>/dev/null || true
        [ -f mysqlnd.ini ] && mv mysqlnd.ini 00_mysqlnd.ini 2>/dev/null || true

        # Asegurar que las extensiones dependientes carguen después
        [ -f xmlreader.ini ] && mv xmlreader.ini 10_xmlreader.ini || true
        [ -f pdo_mysql.ini ] && mv pdo_mysql.ini 10_pdo_mysql.ini || true
        [ -f mysqli.ini ] && mv mysqli.ini 10_mysqli.ini || true
    )
    log "PHP module loading order successfully configured."
else
    log "WARNING: Directory $PHP_CONF_DIR not found. Skipping PHP module order fix."
fi

# -----------------------------------------------------------------------------
# 1. VALIDAR VARIABLES DE ENTORNO
# -----------------------------------------------------------------------------
required_vars="
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASS
SERVER_NAME
SERVER_PORT
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
    else
        log "INFO: Environment variable '$var' is set to '$value'."
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

log "Applying folder permissions..."

web_user="apache"
if ! id "$web_user" >/dev/null 2>&1; then
    web_user="www-data"
fi

chown -R ${web_user}:${web_user} "${SERVER_ROOT_PATH}"
chown -R ${web_user}:${web_user} "${SERVER_DATA_PATH}"

chmod -R 750 "${SERVER_ROOT_PATH}"
chmod -R 770 "${SERVER_DATA_PATH}"

log "Permissions successfully applied for user ${web_user}."

# -----------------------------------------------------------------------------
# 3. VALIDAR REQUISITOS CON COMPOSER
# -----------------------------------------------------------------------------
if [ -f "${SERVER_ROOT_PATH}/composer.json" ]; then
    if command -v composer >/dev/null 2>&1; then
        log "Checking Composer platform requirements..."
        (
            cd "${SERVER_ROOT_PATH}" || exit 1
            export COMPOSER_ROOT_VERSION="${MOODLE_VERSION:-4.5.0}"
            su -s /bin/sh apache -c "composer check-platform-reqs --no-interaction && \
            composer install --no-interaction --prefer-dist --no-progress && \
            composer dump-autoload --optimize"
        ) || {
            log "ERROR: Composer tasks failed."
            exit 1
        }

        # Asegurar permisos correctos sobre la carpeta vendor recién generada
        if [ -d "${SERVER_ROOT_PATH}/vendor" ]; then
            log "Applying ${web_user}:${web_user} ownership to vendor folder..."
            chown -R "${web_user}:${web_user}" "${SERVER_ROOT_PATH}/vendor"
            chmod -R 750 "${SERVER_ROOT_PATH}/vendor"
        fi
    else
        log "WARNING: composer command not found. Skipping Composer checks."
    fi
else
    log "No composer.json found in ${SERVER_ROOT_PATH}. Skipping Composer tasks."
fi

# -----------------------------------------------------------------------------
# 4. CONFIG.PHP GENERATION
# -----------------------------------------------------------------------------
log "Checking for config.php..."

CONFIG_FILE="${SERVER_ROOT_PATH}/config.php"

if [ "${SERVER_PORT}" = "80" ] || [ "${SERVER_PORT}" = "443" ]; then
    wwwroot_url="http://${SERVER_NAME}"
else
    wwwroot_url="http://${SERVER_NAME}:${SERVER_PORT}"
fi

if [ ! -f "$CONFIG_FILE" ]; then
    log "Creating config.php dynamically from environment variables..."

    cat <<PHP > "$CONFIG_FILE"
<?php  // Moodle configuration file

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
\$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '${DB_PORT}',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

\$CFG->wwwroot   = '${wwwroot_url}';
\$CFG->dataroot  = '${SERVER_DATA_PATH}';
\$CFG->admin     = 'admin';

\$CFG->directorypermissions = 02770;

require_once(__DIR__ . '/lib/setup.php');
// There is no php closing tag in this file, it is intentional because it prevents trailing whitespace!
PHP

    chown ${web_user}:${web_user} "$CONFIG_FILE"
    chmod 640 "$CONFIG_FILE"
    log "config.php successfully created."
else
    log "config.php already exists. Skipping creation."
fi

# -----------------------------------------------------------------------------
# 5. UNATTENDED DATABASE INSTALLATION
# -----------------------------------------------------------------------------
log "Checking/Installing Moodle database..."
if [ ! -f "${SERVER_ROOT_PATH}/admin/cli/install_database.php" ]; then
    log "ERROR: Moodle database installation script not found at ${SERVER_ROOT_PATH}/admin/cli/install_database.php."
    exit 1
else
    su -s apache -c php "${SERVER_ROOT_PATH}/admin/cli/install_database.php -h" || {
        log "ERROR: Moodle database installation script failed."
    }    
fi

set -- \
    su -s apache -c php \
    "${SERVER_ROOT_PATH}/admin/cli/install_database.php" \
    --lang="es" \
    --adminuser="${APP_ADMIN_USER}" \
    --adminpass="${APP_ADMIN_PASS}" \
    --adminemail="${APP_ADMIN_EMAIL}" \
    --agree-license \
    --fullname="${APP_NAME}" \
    --shortname="${APP_NAME}" \
    --summary="${APP_NAME} Moodle site"    

log "Running database installation..."

install_log="$(mktemp)"
if "$@" >"$install_log" 2>&1; then
    log "Moodle database setup completed successfully."
else
    install_status=$?
    if grep -qiE "already installed|tables already exist|already configured" "$install_log"; then
        log "Moodle database is already populated. Continuing startup..."
        else
        log "ERROR: Moodle database installation failed. Showing errors:"
        cat "$install_log" >&2
        rm -f "$install_log"
        exit "$install_status"
    fi
fi
rm -f "$install_log"

# -----------------------------------------------------------------------------
# 6. PURGAR CACHES Y REGENERAR AUTOLOAD DE MOODLE
# -----------------------------------------------------------------------------
log "Purging Moodle caches..."
php "${SERVER_ROOT_PATH}/admin/cli/purge_caches.php" || log "WARNING: Cache purge failed."

# -----------------------------------------------------------------------------
# 7. RESETEAR OPCACHE (si existe)
# -----------------------------------------------------------------------------
if php -r "echo function_exists('opcache_reset');"; then
    log "Resetting OPcache..."
    php -r "opcache_reset();"
else
    log "OPcache not enabled or not available."
fi

# -----------------------------------------------------------------------------
# 8. ARRANCAR APACHE
# -----------------------------------------------------------------------------
log "Starting Apache web server..."

if command -v httpd >/dev/null 2>&1; then
    exec httpd -D FOREGROUND
elif command -v apache2-foreground >/dev/null 2>&1; then
    exec apache2-foreground
else
    exec apache2 -D FOREGROUND
fi