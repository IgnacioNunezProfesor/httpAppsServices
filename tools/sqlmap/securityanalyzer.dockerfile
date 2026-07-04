###############################
# Etapa 1: Builder
###############################
FROM python:3.12-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Dependencias necesarias solo para compilar/instalar
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ruby-full \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar WPScan
RUN gem install wpscan

# Descargar sqlmap
RUN git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git /opt/sqlmap


###############################
# Etapa 2: Runtime ultraligero
###############################
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Dependencias mínimas necesarias en runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby \
    nmap \
    whatweb \
    perl \
    git \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar Nikto manualmente
RUN git clone https://github.com/sullo/nikto.git /opt/nikto \
    && ln -s /opt/nikto/program/nikto.pl /usr/local/bin/nikto

# Copiar sqlmap desde builder
COPY --from=builder /opt/sqlmap /opt/sqlmap

# Copiar WPScan ya instalado
COPY --from=builder /usr/local/bin/wpscan /usr/local/bin/wpscan
COPY --from=builder /var/lib/gems /var/lib/gems
COPY --from=builder /usr/lib/ruby /usr/lib/ruby
COPY --from=builder /usr/share/rubygems-integration /usr/share/rubygems-integration


# Añadir sqlmap al PATH
ENV PATH="/opt/sqlmap:$PATH"

# Directorio de trabajo
RUN mkdir -p /analysis/results
WORKDIR /analysis

# Copiar script bash
COPY ./tools/sqlmap/run-analysis.sh /analysis/run-analysis.sh
RUN [ -s /analysis/run-analysis.sh ] || (echo "Error: run-analysis.sh no se copió o está vacío" && exit 1)

RUN chmod +x /analysis/run-analysis.sh

CMD ["/bin/bash"]
