FROM alpine:latest

RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy

COPY ./docker/apache/config/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/apache/config/conf.d/*.conf /etc/apache2/conf.d/

# Script de entrada para expandir variables
COPY ./docker/apache/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]