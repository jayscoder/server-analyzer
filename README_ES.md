# Analizador de Servidores

<div align="center">
<img src="https://raw.githubusercontent.com/iconic/open-iconic/master/svg/globe.svg" width="80" height="80">
<br>
<strong>Recopila rápidamente información del servidor y genera informes detallados</strong>
</div>

<p align="center">
  <a href="README.md">中文</a> |
  <a href="README_EN.md">English</a> |
  <a href="README_JA.md">日本語</a> |
  <a href="README_ES.md">Español</a>
</p>

## Visión general

El Analizador de Servidores es un potente script de Bash que recopila rápidamente información de sistema de servidores Linux/Unix y genera informes formateados. La herramienta está diseñada para administradores de sistemas, ingenieros DevOps e ingenieros de IA para ayudarles a comprender rápidamente las configuraciones y el estado del servidor.

### Características principales

- **Recopilación completa de información**: Recopila información sobre CPU, memoria, almacenamiento, red, GPU, etc.
- **Detección del entorno de software**: Detecta sistemas operativos, servicios instalados, contenedores Docker y entornos de lenguajes de programación
- **Análisis del estado de seguridad**: Comprueba el estado del firewall, la configuración SSH y la configuración básica de seguridad
- **Soporte para frameworks de IA**: Detecta frameworks comunes de IA como Ollama, PyTorch, TensorFlow, etc.
- **Informes multiformato**: Admite la generación de informes detallados en formato Markdown o HTML
- **Modo local/remoto**: Admite el análisis de servidores locales o servidores remotos a través de SSH

## Uso de informes como contexto para modelos de IA

Los informes generados están bien formateados y son ricos en información, lo que los hace ideales como información de contexto para modelos de lenguaje grandes. Puedes:

1. Cargar los informes generados directamente a modelos de IA (como ChatGPT, Claude, etc.)
2. Hacer que los modelos de IA proporcionen sugerencias de optimización personalizadas basadas en las condiciones reales del servidor
3. Utilizar los informes para ayudar a la IA en una configuración, optimización y solución de problemas más precisas del servidor

## Métodos de instalación

### Descarga directa

```bash
curl -o server_analyzer.sh https://raw.githubusercontent.com/nombredeusuario/server-analyzer/main/server_analyzer.sh
chmod +x server_analyzer.sh
```

### Descargar desde Releases

Visita la [página de Releases](https://github.com/nombredeusuario/server-analyzer/releases) para descargar la última versión.

## Uso

### Uso básico

Analiza el servidor local y genera un informe en markdown:

```bash
./server_analyzer.sh
```

### Opciones de línea de comandos

```
Opciones:
  -i, --ip IP              Dirección IP del servidor remoto (analiza el servidor local si no se proporciona)
  -p, --port PORT          Puerto SSH (predeterminado: 22)
  -u, --user USER          Nombre de usuario SSH
  -o, --output PATH        Ruta de salida del informe (predeterminado: ./server_report.md)
  -f, --format FORMAT      Formato del informe: markdown o html (predeterminado: markdown)
  -h, --help               Muestra esta información de ayuda
```

### Ejemplos

Analizar un servidor remoto:

```bash
./server_analyzer.sh -i 192.168.1.100 -p 2222 -u admin -o /tmp/server_report.md
```

Generar un informe en formato HTML:

```bash
./server_analyzer.sh -f html -o server_report.html
```

## Contenido del informe

Los informes generados incluyen las siguientes secciones principales:

- **Información básica**: Nombre del host, dirección IP, sistema operativo, versión del kernel, etc.
- **Configuración de hardware**: CPU, memoria, dispositivos de almacenamiento e información de GPU
- **Configuración de red**: Interfaces de red, IP pública, puertos abiertos, etc.
- **Software y servicios**: Servicios del sistema, contenedores Docker, entornos de lenguajes de programación, etc.
- **Frameworks de IA**: Detección de Ollama, PyTorch, TensorFlow y otros frameworks de IA
- **Rendimiento y uso de recursos**: Carga del sistema, procesos con mayor uso de recursos, etc.
- **Información de seguridad**: Estado del firewall, configuración SSH, estado de SELinux, etc.
- **Información de usuarios**: Usuarios actualmente conectados, usuarios con privilegios administrativos, etc.
- **Conclusiones y recomendaciones**: Sugerencias basadas en la información recopilada

## Licencia

Licencia MIT

## Contribución

¡Se agradecen los Issues y Pull Requests!
