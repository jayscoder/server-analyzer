# 服务器分析工具 (Server Analyzer)

<div align="center">
<img src="https://raw.githubusercontent.com/iconic/open-iconic/master/svg/globe.svg" width="80" height="80">
<br>
<strong>快速收集服务器信息并生成详细报告</strong>
</div>

<div align="center">

![版本](https://img.shields.io/badge/版本-v1.2.0-blue)
![许可证](https://img.shields.io/badge/许可证-MIT-green)
![平台](https://img.shields.io/badge/平台-Linux%20%7C%20macOS-lightgrey)

**GitHub 仓库地址：** [jayscoder/server-analyzer](https://github.com/jayscoder/server-analyzer)  
**最新版本：** [v1.2.0](https://github.com/jayscoder/server-analyzer/releases/tag/v1.2.0)

</div>

<p align="center">
  <a href="README.md">中文</a> |
  <a href="README_EN.md">English</a> |
  <a href="README_JA.md">日本語</a> |
  <a href="README_ES.md">Español</a>
</p>

## 📋 概述

服务器分析工具是一个功能强大的 Bash 脚本，可以快速收集 Linux/Unix 服务器上的各种系统信息，并生成格式化的报告。该工具专为系统管理员、DevOps 工程师和 AI 工程师设计，帮助快速了解服务器配置和状态。

### ✨ 特色功能

- 🖥️ **全面信息收集**：收集 CPU、内存、存储、网络、GPU 等硬件信息
- 🔍 **软件环境检测**：检测操作系统、已安装服务、Docker 容器和编程语言环境
- 🔒 **安全状态分析**：检查防火墙状态、SSH 配置和基本安全设置
- 🤖 **AI 框架支持**：检测常见 AI 框架如 Ollama、PyTorch、TensorFlow 等
- 📊 **多格式报告**：支持生成 Markdown 或 HTML 格式的详细报告
- 🌐 **本地/远程模式**：支持分析本地服务器或通过 SSH 分析远程服务器

## 🧠 将报告作为 AI 模型上下文

生成的报告格式规范、信息丰富，非常适合作为大型语言模型的上下文信息。您可以：

1. 将生成的报告直接上传给 AI 模型（如 ChatGPT、Claude 等）
2. 让 AI 模型根据服务器实际情况提供定制化的优化建议
3. 通过报告辅助 AI 进行更精准的服务器配置、优化和故障排查

## 📥 安装方法

### 方法一：直接下载

```bash
curl -o server_analyzer.sh https://raw.githubusercontent.com/jayscoder/server-analyzer/main/server_analyzer.sh
chmod +x server_analyzer.sh
```

### 方法二：从发布版下载

访问[发布页面](https://github.com/jayscoder/server-analyzer/releases)下载最新版本。

### 方法三：克隆仓库

```bash
git clone git@github.com:jayscoder/server-analyzer.git
cd server-analyzer
chmod +x server_analyzer.sh
```

## 🚀 使用方法

### 基本用法

分析本地服务器并生成 markdown 报告：

```bash
./server_analyzer.sh
```

### 命令行选项

```
选项:
  -i, --ip IP              远程服务器IP地址 (不提供则分析本地服务器)
  -p, --port PORT          SSH端口 (默认: 22)
  -u, --user USER          SSH用户名
  -o, --output PATH        报告输出路径 (默认: ./server_report.md)
  -f, --format FORMAT      报告格式: markdown 或 html (默认: markdown)
  -h, --help               显示此帮助信息
```

### 示例

分析远程服务器：

```bash
./server_analyzer.sh -i 192.168.1.100 -p 2222 -u admin -o /tmp/server_report.md
```

生成 HTML 格式报告：

```bash
./server_analyzer.sh -f html -o server_report.html
```

## 📊 报告内容

生成的报告包含以下主要部分：

| 部分               | 内容                                        |
| ------------------ | ------------------------------------------- |
| **基本信息**       | 主机名、IP 地址、操作系统、内核版本等       |
| **硬件配置**       | CPU、内存、存储设备和 GPU 信息              |
| **网络配置**       | 网络接口、公网 IP、开放端口等               |
| **软件和服务**     | 系统服务、Docker 容器、编程语言环境等       |
| **AI 框架**        | 检测 Ollama、PyTorch、TensorFlow 等 AI 框架 |
| **性能和资源使用** | 系统负载、资源使用最高的进程等              |
| **安全信息**       | 防火墙状态、SSH 配置、SELinux 状态等        |
| **用户信息**       | 当前登录用户、管理权限用户等                |
| **结论和建议**     | 基于收集到的信息提供的建议                  |

## 🔧 依赖

工具会尝试使用以下命令（如可用）来收集更多信息：

- 基本命令: `ps`, `grep`, `awk`, `free`, `df`, `top` 等
- 网络分析: `netstat` 或 `ss`, `curl`, `speedtest-cli`
- GPU 分析: `nvidia-smi` (NVIDIA GPU), `rocm-smi` (AMD GPU), `npu-smi` (华为昇腾)
- 编程环境: `python`/`python3`, `conda`, `node`, `npm`, `java`
- AI 框架: `ollama`, PyTorch, TensorFlow, ONNX Runtime

## 📝 许可证

[MIT License](LICENSE)

## 👥 贡献

欢迎提交 Issues 和 Pull Requests！可以通过以下方式参与项目：

1. Fork 仓库
2. 创建您的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开一个 Pull Request
