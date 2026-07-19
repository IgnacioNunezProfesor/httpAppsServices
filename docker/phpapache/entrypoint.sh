#!/bin/bash -x
set -e
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting PHP-Apache entrypoint script..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"
#
# Debug: Print environment variables from dev.phpapache.env
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== ENVIRONMENT VARIABLES DEBUG ====="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] IMAGE_NAME=${IMAGE_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DOCKERFILE=${DOCKERFILE:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONTAINER_NAME=${CONTAINER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_NAME=${SERVER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_PORT=${SERVER_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_ROOT_PATH=${LOCAL_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_ROOT_PATH=${SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_INFO_PATH=${LOCAL_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_INFO_PATH=${SERVER_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_LOG_PATH=${LOCAL_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_LOG_PATH=${SERVER_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] IP=${IP:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_NAME=${NETWORK_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================"
#
# Create necessary directories
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Creating necessary directories..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_ROOT_PATH=${SERVER_ROOT_PATH}"
mkdir -p "${SERVER_ROOT_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Created ${SERVER_ROOT_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create ${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_LOG_PATH=${SERVER_LOG_PATH}"
mkdir -p "${SERVER_LOG_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Created ${SERVER_LOG_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create ${SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: SERVER_INFO_PATH=${SERVER_INFO_PATH}"
mkdir -p "${SERVER_INFO_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Created ${SERVER_INFO_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create ${SERVER_INFO_PATH}"
#
# Set proper permissions for Apache
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Setting proper permissions for Apache..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${SERVER_ROOT_PATH} to apache:apache"
chown -R apache:apache "${SERVER_ROOT_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${SERVER_ROOT_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to change ownership of ${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${SERVER_LOG_PATH} to apache:apache"
chown -R apache:apache "${SERVER_LOG_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${SERVER_LOG_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to change ownership of ${SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${SERVER_INFO_PATH} to apache:apache"
chown -R apache:apache "${SERVER_INFO_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${SERVER_INFO_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to change ownership of ${SERVER_INFO_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${SERVER_ROOT_PATH} to 755"
chmod -R 755 "${SERVER_ROOT_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${SERVER_ROOT_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to chmod ${SERVER_ROOT_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${SERVER_LOG_PATH} to 755"
chmod -R 755 "${SERVER_LOG_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${SERVER_LOG_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to chmod ${SERVER_LOG_PATH}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${SERVER_INFO_PATH} to 755"
chmod -R 755 "${SERVER_INFO_PATH}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${SERVER_INFO_PATH}" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to chmod ${SERVER_INFO_PATH}"
#
# Start Apache in foreground
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting Apache in foreground mode..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: About to execute: httpd -D FOREGROUND"
exec httpd -D FOREGROUND