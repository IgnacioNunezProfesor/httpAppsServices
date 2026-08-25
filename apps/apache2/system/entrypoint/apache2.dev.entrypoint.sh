#!/bin/bash -x
set -e
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting ${APP_NAME} entrypoint script..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Script PID: $$"
#
# Debug: Print environment variables from dev.phpapache.env
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== ENVIRONMENT VARIABLES DEBUG ====="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_NAME=${APP_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DOCKERFILE=${DOCKERFILE:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] IMAGE_NAME=${IMAGE_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONTAINER_NAME=${CONTAINER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_LOCAL_ROOT_PATH=${APP_LOCAL_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_SERVER_ROOT_PATH=${APP_SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_LOCAL_ENTRYPOINT_PATH=${APP_LOCAL_ENTRYPOINT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_SERVER_ENTRYPOINT_PATH=${APP_SERVER_ENTRYPOINT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_LOCAL_HTTPCONF_PATH=${APP_LOCAL_HTTPCONF_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_SERVER_HTTPCONF_PATH=${APP_SERVER_HTTPCONF_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_LOCAL_HTTPCONFD_PATH=${APP_LOCAL_HTTPCONFD_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] APP_SERVER_HTTPCONFD_PATH=${APP_SERVER_HTTPCONFD_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_NAME=${SERVER_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_PORT=${SERVER_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_PORT=${LOCAL_PORT:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_ROOT_PATH=${LOCAL_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_ROOT_PATH=${SERVER_ROOT_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALIAS_INFO_PATH=${ALIAS_INFO_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] LOCAL_LOG_PATH=${LOCAL_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] SERVER_LOG_PATH=${SERVER_LOG_PATH:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] IP=${IP:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_NAME=${NETWORK_NAME:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_DIRVER=${NETWORK_DIRVER:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_SUBNET=${NETWORK_SUBNET:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_GATEWAY=${NETWORK_GATEWAY:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] NETWORK_IP_RANGE=${NETWORK_IP_RANGE:-NOT SET}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================"
#
# Create necessary directories and set proper permissions for Apache
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Verifying required directories..."
ensure_dir() {
  local dir_path="$1"

  if [ -z "${dir_path}" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: Directory path is empty, skipping..."
    return 0
  fi

  if [ -d "${dir_path}" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Directory already exists: ${dir_path}"
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Directory not found, creating: ${dir_path}"
    mkdir -p "${dir_path}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Created ${dir_path}" || {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to create ${dir_path}"
      return 1
    }
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing ownership of ${dir_path} to apache:apache"
  chown -R apache:apache "${dir_path}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Ownership changed: ${dir_path}" || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to change ownership of ${dir_path}"
    return 1
  }

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Changing permissions of ${dir_path} to 755"
  chmod -R 755 "${dir_path}" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: Permissions set: ${dir_path}" || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to chmod ${dir_path}"
    return 1
  }
}

ensure_dir "${SERVER_ROOT_PATH}"
ensure_dir "${SERVER_LOG_PATH}"
#
# Start Apache in foreground
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting Apache in foreground mode..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: About to execute: httpd -D FOREGROUND"
exec httpd -D FOREGROUND