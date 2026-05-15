# 🛡️ Plan de Auditoría de Seguridad: WordPress Core & Infrastructure

Este documento detalla el procedimiento estándar para evaluar la postura de seguridad de un sitio WordPress.

## 1. Fase de Reconocimiento y Enumeración (Infraestructura)

El primer paso es identificar la superficie de ataque a nivel de servidor.

### 1.1 Escaneo de Puertos y Servicios (nmap)

Determinar qué servicios están corriendo y si existen versiones vulnerables.

- Comando:

  ```bash

  nmap -sV -sC -Pn -T4 <target_ip>

  ```

- Objetivos:
  - Detectar servicios innecesarios (FTP, Telnet, SMB).
  - Identificar la versión del servidor web (Apache, Nginx).
  - Verificar si el puerto de la base de datos (3306) es accesible desde el exterior.

### 1.2 Análisis de Cabeceras HTTP

Verificar si el servidor implementa medidas de protección básicas contra ataques XSS, clickjacking e inyección de MIME.

- Herramientas:
  - `curl -I`
  - Extensiones de navegador de análisis HTTP

- Checklist de cabeceras:
  - `Strict-Transport-Security` (HSTS)
  - `Content-Security-Policy` (CSP)
  - `X-Frame-Options` (`DENY` o `SAMEORIGIN`)
  - `X-Content-Type-Options` (`nosniff`)
  - `Referrer-Policy`

## 2. Auditoría Específica de WordPress

Análisis profundo de los componentes propios del CMS.

### 2.1 Escaneo Especializado (WPScan)

WPScan es la herramienta estándar de la industria para identificar vulnerabilidades conocidas.

- Comando sugerido:

  ```bash

  wpscan --url <url_sitio> --enumerate vp,vt,u --api-token <tu_token>
  ```

- Puntos de control:
  - Versión del Core: comparar con la última versión estable.
  - Plugins (`vp`): identificar plugins instalados y vulnerabilidades asociadas (CVE).
  - Temas (`vt`): verificar si el tema está desactualizado o tiene fallos de seguridad.
  - Usuarios (`u`): enumerar nombres de usuario para ataques de fuerza bruta.

### 2.2 Verificación de Archivos Sensibles

Comprobar que no existan archivos expuestos que revelen información del sistema.

- Archivos a buscar:
  - `wp-config.php` (debe tener permisos `400` o `440`)
  - `.htaccess` / `nginx.conf`
  - `readme.html` y `license.txt` (revelan la versión de WP)
  - Archivos de backup (`.zip`, `.sql`, `.bak`)

## 3. Pruebas de Inyección y Base de Datos

### 3.1 Pruebas de SQL Injection (sqlmap)

Aunque el Core de WordPress es robusto, los plugins de terceros suelen presentar fallos de sanitización.

- Escenario: formularios de contacto, barras de búsqueda o parámetros URL.
- Comando:

  ```bash

  sqlmap -u "https://target.com/?p=1" --forms --batch --crawl=2 --dbms=mysql
  ```

- Objetivo: verificar si es posible extraer información de la base de datos o escalar privilegios.

## 4. Pruebas de Acceso y Autenticación

### 4.1 Fuerza Bruta y Diccionario

Evaluar si existe un límite de intentos de login (rate limiting).

- Herramientas:
  - WPScan
  - Hydra
- Prueba: intentar loguearse en `/wp-login.php` o `/xmlrpc.php` con una lista de contraseñas comunes.

### 4.2 Análisis de XML-RPC

El archivo `xmlrpc.php` suele ser un vector común para ataques de denegación de servicio (DoS) y fuerza bruta.

- Test: enviar una petición `POST` a `xmlrpc.php` para listar los métodos disponibles (`system.listMethods`).

## 5. Matriz de Riesgos (Resumen de Tests)

| Categoría     | Herramienta             | Objetivo principal                                   |
|---------------|-------------------------|------------------------------------------------------|
| Red           | `nmap`                  | Puertos abiertos y servicios vulnerables             |
| Aplicación    | `WPScan`                | Versiones de plugins, temas y core                   |
| Datos         | `sqlmap`                | Inyección SQL en parámetros                          |
| Configuración | `curl` / checkers       | Cabeceras de seguridad y SSL/TLS                     |
| Lógica        | Manual                  | Enumeración de autores y acceso a `/wp-admin`        |

## 6. Recomendaciones de Mitigación (Hardening)

- Actualización: mantener Core, plugins y temas al día.
- 2FA: implementar autenticación de dos factores para administradores.
- Deshabilitar XML-RPC: si no se usa la app móvil de WordPress.
- WAF: instalar un Web Application Firewall (por ejemplo Cloudflare o Wordfence).
- Permisos: configurar correctamente los permisos de archivos (`carpetas 755`, `archivos 644`).
