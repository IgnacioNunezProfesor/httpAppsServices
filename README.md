# Documentación de Scripts - httpAppsServices

## 📋 Descripción General

La carpeta `scripts/` contiene utilidades de automatización desarrolladas en PowerShell diseñadas para facilitar la gestión, despliegue y mantenimiento del entorno de desarrollo de aplicaciones web y servicios HTTP.

## 🎯 Propósito de los Scripts

Los scripts en este proyecto están orientados a:

- **Automatización de tareas repetitivas** en el ciclo de desarrollo
- **Gestión de contenedores Docker** y servicios asociados
- **Configuración del entorno** de desarrollo
- **Despliegue y actualización** de componentes
- **Utilidades de diagnóstico y mantenimiento**
- **Integración con aplicaciones desde GIT** y bases de datos

## 🔧 Scripts Disponibles

Cada script debe documentarse con:

- **Nombre y propósito** específico
- **Parámetros requeridos y opcionales**
- **Ejemplos de uso**
- **Dependencias** del sistema
- **Valores de retorno** esperados

## 📌 Convenciones

- Scripts en **PowerShell** (.ps1) para tareas de administración en Windows
- Nombres descriptivos en inglés o español según contexto
- Comentarios en cabecera explicando funcionalidad principal

## ⚙️ Integración

Los scripts interactúan con:

- Configuración en `docker/` para servicios containerizados
- Carpeta `wwwroot/` para despliegue de contenido web
- Submódulo `wordpress/` para gestión de la instalación
- Entorno de VS Code mediante `.vscode/`

## 🚀 Uso del proyecto

1. Abrir PowerShell como administrador.
2. Navegar a la carpeta raíz del proyecto:
   - `cd C:\Users\inr_j\httpAppsServices`
3. Revisar los archivos de entorno en `env/` antes de ejecutar scripts.
4. Ejecutar los scripts de administración desde la raíz. Por ejemplo:
    - .\scripts\AdminApp.ps1
    - .\scripts\build.EnvFile.ps1
5. Usar los scripts bajo `scripts/` para las tareas principales de configuración y despliegue.

> Nota: los scripts están pensados para PowerShell en Windows y pueden requerir permisos de ejecución. Si es necesario, habilite la ejecución con:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

## 🧪 Pruebas

Este repositorio incluye pruebas manuales básicas para la validación de funciones de red.

### Ejecutar pruebas paso a paso

1. Abrir PowerShell en la raíz del repositorio:
   - `cd C:\Users\inr_j\httpAppsServices`
2. Ejecutar el script de prueba ubicado en `scripts/tests`:
    - .\scripts\tests\test.networks.ps1
3. Verificar los resultados mostrados en la consola.

### Qué comprueba la prueba

- Validación de direcciones IP dentro o fuera de una subred (`Test-IpInSubnet`)
- Comportamiento correcto para máscaras `/32` y `/0`
- Manejo de entradas inválidas y errores esperados

### Resultado esperado

Al finalizar, el script muestra:

- `Pasados: X`
- `Fallados: Y`

Si `Y` es mayor que 0, revise el módulo `scripts\mods
etworks.psm1` y el script de prueba para encontrar la causa.
