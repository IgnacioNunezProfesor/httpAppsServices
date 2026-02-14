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
