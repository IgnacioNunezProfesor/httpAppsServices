FROM alpine:latest

ARG DB_SERVER_DATADIR=${DB_SERVER_DATADIR} \
    DB_SERVER_LOG=${DB_SERVER_LOG} \
    DB_UNIX_USER=${DB_UNIX_USER}

ENV DB_SERVER_DATADIR=${DB_SERVER_DATADIR} \
    DB_SERVER_LOG=${DB_SERVER_LOG} \
    DB_UNIX_USER=${DB_UNIX_USER}

# Instalar MariaDB y utilidades
RUN apk add --no-cache \
    mariadb \
    mariadb-client \
    mariadb-server-utils \
    dos2unix

RUN addgroup -S ${DB_UNIX_USER} && \
    adduser -S ${DB_UNIX_USER} -G ${DB_UNIX_USER}

# Crear directorios y asignar permisos al usuario UNIX
RUN mkdir -p /entrypointsql ${DB_SERVER_DATADIR} ${DB_SERVER_LOG} && \
    chown -R ${DB_UNIX_USER}:${DB_UNIX_USER} ${DB_SERVER_DATADIR} ${DB_SERVER_LOG} /entrypointsql

# Copiar scripts y configuración
COPY ./docker/bd/scripts/docker-entrypoint.sh /entrypoint.sh
COPY ./docker/bd/sql/*.sql /entrypointsql/
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf

RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["sh", "/entrypoint.sh"]

