#!/bin/sh

# ================================
#  buildApache2Image.sh
#  Valida variables y construye imagen
# ================================

if [ -z "$1" ]; then
    echo "❌ Debes indicar el archivo .env"
    echo "Uso: ./buildApache2Image.sh env/dev.apache2.env"
    exit 1
fi

ENV_FILE="$1"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ El archivo $ENV_FILE no existe"
    exit 1
fi

echo "📄 Cargando variables desde $ENV_FILE"
# Exportar todas las variables del .env
set -a
. "$ENV_FILE"
set +a

# ================================
#  Variables obligatorias
# ================================
required_vars="
APP_LOCAL_HTTPCONF_PATH
APP_SERVER_HTTPCONF_PATH
APP_LOCAL_HTTPCONFD_PATH
APP_SERVER_HTTPCONFD_PATH
APP_LOCAL_ENTRYPOINT_PATH
APP_SERVER_ENTRYPOINT_PATH
IMAGE_NAME
DOCKERFILE
"

echo "🔍 Validando variables obligatorias..."

missing=""

for var in $required_vars; do
    eval value=\$$var
    if [ -z "$value" ]; then
        missing="$missing\n - $var"
    fi
done

if [ -n "$missing" ]; then
    echo "❌ Faltan variables obligatorias:"
    echo "$missing"
    exit 1
fi

echo "✔ Todas las variables obligatorias están definidas."

# ================================
#  Construcción de la imagen
# ================================

echo "🚀 Ejecutando docker build..."

docker build \
    --no-cache \
    -f "$DOCKERFILE" \
    -t "$IMAGE_NAME" \
    --build-arg APP_LOCAL_HTTPCONF_PATH="$APP_LOCAL_HTTPCONF_PATH" \
    --build-arg APP_SERVER_HTTPCONF_PATH="$APP_SERVER_HTTPCONF_PATH" \
    --build-arg APP_LOCAL_HTTPCONFD_PATH="$APP_LOCAL_HTTPCONFD_PATH" \
    --build-arg APP_SERVER_HTTPCONFD_PATH="$APP_SERVER_HTTPCONFD_PATH" \
    --build-arg APP_LOCAL_ENTRYPOINT_PATH="$APP_LOCAL_ENTRYPOINT_PATH" \
    --build-arg APP_SERVER_ENTRYPOINT_PATH="$APP_SERVER_ENTRYPOINT_PATH" \
    .

code=$?

if [ $code -ne 0 ]; then
    echo "❌ docker build falló con código $code"
    exit $code
fi

echo "🎉 Build completado exitosamente."
