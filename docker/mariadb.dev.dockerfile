FROM alpine:latest

ENV SERVER_DATADIR=${SERVER_DATADIR} \
    SERVER_LOG=${SERVER_LOG} \
    DB_NAME=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS}
    

# Instalar MariaDB y utilidades
RUN apk add --no-cache \
    mariadb \
    mariadb-client \
    mariadb-server-utils \
    dos2unix

# Copiar scripts y configuración
COPY ./docker/bd/scripts/docker-entrypoint.sh /entrypoint.sh
COPY ./docker/bd/sql/*.sql /entrypointsql/
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf

RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["sh", "/entrypoint.sh"]

