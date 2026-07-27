#!/bin/bash
set -e

# Crear archivo de log y redirigir toda la salida del script
LOG_FILE="/var/log/${APP_NAME}.log"
mkdir -p /var/log
exec > >(tee -a "$LOG_FILE") 2>&1

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
