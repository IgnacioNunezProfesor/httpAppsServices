FROM alpine:latest

ENV SERVER_NAME=${SERVER_NAME}
ENV SERVER_PORT=${SERVER_PORT}
ENV SERVER_ROOT_PATH=${SERVER_ROOT_PATH}
ENV SERVER_LOG_PATH=${SERVER_LOG_PATH}

EXPOSE ${SERVER_PORT}

RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy

COPY ./docker/apache/config/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/apache/config/conf.d/*.conf /etc/apache2/conf.d/

# Script de entrada para expandir variables
COPY ./docker/apache/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]