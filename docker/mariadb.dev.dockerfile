FROM alpine:latest

ENV DB_SERVER_DATADIR=${DB_SERVER_DATADIR} \
    DB_SERVER_LOG=${DB_SERVER_LOG} \
    DB_UNIX_USER=${DB_UNIX_USER}

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

USER ${DB_UNIX_USER}

ENTRYPOINT ["sh", "/entrypoint.sh"]

