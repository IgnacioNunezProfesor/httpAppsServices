FROM alpine:latest

# Instalar MariaDB y utilidades
RUN apk add --no-cache \
    mariadb \
    mariadb-client \
    mariadb-server-utils \
    dos2unix

# Copiar scripts y configuración
COPY ./bd/scripts/entrypoint.sh /entrypoint.sh
COPY ./bd/sql/*.sql /entrypointsql/
COPY ./bd/conf/mysql.dev.cnf /etc/my.cnf

RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]