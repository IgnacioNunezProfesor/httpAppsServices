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
    nikto \
    whatweb \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar sqlmap desde builder
COPY --from=builder /opt/sqlmap /opt/sqlmap

# Copiar WPScan ya instalado
COPY --from=builder /usr/local/bin/wpscan /usr/local/bin/wpscan
COPY --from=builder /var/lib/gems /var/lib/gems
COPY --from=builder /usr/local/lib/ruby /usr/local/lib/ruby

# Añadir sqlmap al PATH
ENV PATH="/opt/sqlmap:$PATH"

# Directorio de trabajo
RUN mkdir -p /analysis/results
WORKDIR /analysis

# Copiar script bash
COPY run-analysis.sh /analysis/run-analysis.sh
RUN chmod +x /analysis/run-analysis.sh

CMD ["/bin/bash"]
