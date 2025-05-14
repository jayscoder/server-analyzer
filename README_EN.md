# Server Analyzer

<div align="center">
<img src="https://raw.githubusercontent.com/iconic/open-iconic/master/svg/globe.svg" width="80" height="80">
<br>
<strong>Quickly collect server information and generate detailed reports</strong>
</div>

<p align="center">
  <a href="README.md">中文</a> |
  <a href="README_EN.md">English</a> |
  <a href="README_JA.md">日本語</a> |
  <a href="README_ES.md">Español</a>
</p>

## Overview

Server Analyzer is a powerful Bash script that quickly collects various system information from Linux/Unix servers and generates formatted reports. The tool is designed for system administrators, DevOps engineers, and AI engineers to help them quickly understand server configurations and status.

### Key Features

- **Comprehensive Information Collection**: Collects hardware information about CPU, memory, storage, network, GPU, etc.
- **Software Environment Detection**: Detects operating systems, installed services, Docker containers, and programming language environments
- **Security Status Analysis**: Checks firewall status, SSH configuration, and basic security settings
- **AI Framework Support**: Detects common AI frameworks such as Ollama, PyTorch, TensorFlow, etc.
- **Multi-format Reports**: Supports generating detailed reports in Markdown or HTML format
- **Local/Remote Mode**: Supports analyzing local servers or remote servers via SSH

## Using Reports as AI Model Context

The generated reports are well-formatted and information-rich, making them ideal as context information for large language models. You can:

1. Upload the generated reports directly to AI models (such as ChatGPT, Claude, etc.)
2. Have AI models provide customized optimization suggestions based on actual server conditions
3. Use the reports to assist AI in more accurate server configuration, optimization, and troubleshooting

## Installation Methods

### Direct Download

```bash
curl -o server_analyzer.sh https://raw.githubusercontent.com/username/server-analyzer/main/server_analyzer.sh
chmod +x server_analyzer.sh
```

### Download from Releases

Visit the [Releases page](https://github.com/username/server-analyzer/releases) to download the latest version.

## Usage

### Basic Usage

Analyze the local server and generate a markdown report:

```bash
./server_analyzer.sh
```

### Command Line Options

```
Options:
  -i, --ip IP              Remote server IP address (analyzes local server if not provided)
  -p, --port PORT          SSH port (default: 22)
  -u, --user USER          SSH username
  -o, --output PATH        Report output path (default: ./server_report.md)
  -f, --format FORMAT      Report format: markdown or html (default: markdown)
  -h, --help               Display this help information
```

### Examples

Analyze a remote server:

```bash
./server_analyzer.sh -i 192.168.1.100 -p 2222 -u admin -o /tmp/server_report.md
```

Generate an HTML format report:

```bash
./server_analyzer.sh -f html -o server_report.html
```

## Report Content

The generated reports include the following main sections:

- **Basic Information**: Hostname, IP address, operating system, kernel version, etc.
- **Hardware Configuration**: CPU, memory, storage devices, and GPU information
- **Network Configuration**: Network interfaces, public IP, open ports, etc.
- **Software and Services**: System services, Docker containers, programming language environments, etc.
- **AI Frameworks**: Detection of Ollama, PyTorch, TensorFlow, and other AI frameworks
- **Performance and Resource Usage**: System load, processes with highest resource usage, etc.
- **Security Information**: Firewall status, SSH configuration, SELinux status, etc.
- **User Information**: Currently logged-in users, users with administrative privileges, etc.
- **Conclusions and Recommendations**: Suggestions based on collected information

## License

MIT License

## Contribution

Issues and Pull Requests are welcome!
