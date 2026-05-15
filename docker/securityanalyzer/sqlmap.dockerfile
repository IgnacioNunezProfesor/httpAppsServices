FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ruby-full \
    build-essential \
    nmap \
    nikto \
    whatweb \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar WPScan
RUN gem install wpscan

# Instalar sqlmap desde GitHub
RUN git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git /opt/sqlmap
ENV PATH="/opt/sqlmap:$PATH"

# Directorios de trabajo
RUN mkdir -p /analysis/results
WORKDIR /analysis

# Copiar script de análisis (lo generas tú o lo añado yo)
COPY run-analysis.ps1 /analysis/run-analysis.ps1

CMD ["/bin/bash"]
