#!/bin/bash

# 服务器分析脚本
# 用于收集服务器信息并生成markdown格式报告

# 设置默认值
IP="localhost"
PORT=22
SSH_USER="root"
REPORT_PATH="./server_report.md"
USE_LOCAL=true
VERSION="1.2.0"  # 更新版本号
REPORT_FORMAT="markdown" # 新增: 报告格式，默认markdown

# 颜色和格式化
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m" # 无颜色

# 显示帮助信息
show_help() {
    echo -e "${BLUE}服务器分析工具 v${VERSION}${NC}"
    echo -e "${GREEN}快速分析服务器配置并生成详细报告${NC}"
    echo
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -i, --ip IP              远程服务器IP地址 (不提供则分析本地服务器)"
    echo "  -p, --port PORT          SSH端口 (默认: 22)"
    echo "  -u, --user USER          SSH用户名"
    echo "  -o, --output PATH        报告输出路径 (默认: ./server_report.md)"
    echo "  -f, --format FORMAT      报告格式: markdown 或 html (默认: markdown)"
    echo "  -h, --help               显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0                       # 分析本地服务器，生成markdown报告"
    echo "  $0 -i 192.168.1.100 -p 2222 -u admin -o /tmp/report.md  # 分析远程服务器"
    echo "  $0 -f html -o report.html  # 生成HTML格式报告"
    exit 0
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -i|--ip)
            IP="$2"
            USE_LOCAL=false
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -u|--user)
            SSH_USER="$2"
            shift 2
            ;;
        -o|--output)
            REPORT_PATH="$2"
            shift 2
            ;;
        -f|--format)
            REPORT_FORMAT=$(echo "$2" | tr '[:upper:]' '[:lower:]')
            if [[ "$REPORT_FORMAT" != "markdown" && "$REPORT_FORMAT" != "html" ]]; then
                echo -e "${RED}错误: 报告格式必须是 markdown 或 html${NC}"
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}未知参数: $1${NC}"
            show_help
            ;;
    esac
done

# 检查报告文件扩展名与格式是否匹配
if [[ "$REPORT_FORMAT" == "html" && ! "$REPORT_PATH" =~ \.html$ ]]; then
    REPORT_PATH="${REPORT_PATH%.md}.html"
    echo -e "${YELLOW}注意: 已将报告输出文件修改为 $REPORT_PATH 以匹配HTML格式${NC}"
elif [[ "$REPORT_FORMAT" == "markdown" && ! "$REPORT_PATH" =~ \.md$ ]]; then
    REPORT_PATH="${REPORT_PATH%.html}.md"
    echo -e "${YELLOW}注意: 已将报告输出文件修改为 $REPORT_PATH 以匹配Markdown格式${NC}"
fi

# 创建临时文件
TEMP_FILE=$(mktemp)
trap 'rm -f $TEMP_FILE' EXIT

# 定义获取远程命令输出的函数
remote_exec() {
    if [[ $USE_LOCAL == true ]]; then
        eval "$1"
    else
        if [[ -z "$SSH_USER" ]]; then
            ssh -p $PORT $IP "$1"
        else
            ssh -p $PORT ${SSH_USER}@${IP} "$1"
        fi
    fi
}

# 检查远程连接
check_connection() {
    if [[ $USE_LOCAL == false ]]; then
        echo -e "${BLUE}正在检查与 ${IP}:${PORT} 的连接...${NC}"
        if [[ -z "$SSH_USER" ]]; then
            ssh -p $PORT $IP -o ConnectTimeout=5 -o BatchMode=yes exit 2>/dev/null
        else
            ssh -p $PORT ${SSH_USER}@${IP} -o ConnectTimeout=5 -o BatchMode=yes exit 2>/dev/null
        fi

        if [[ $? -ne 0 ]]; then
            echo -e "${RED}无法连接到 ${IP}:${PORT}，请检查连接信息或SSH密钥配置${NC}"
            exit 1
        fi
        echo -e "${GREEN}连接成功！${NC}"
    else
        echo -e "${BLUE}分析本地服务器...${NC}"
    fi
}

# 获取系统信息
get_system_info() {
    echo -e "${BLUE}正在收集系统信息...${NC}"
    
    # 获取主机名
    HOSTNAME=$(remote_exec "hostname")
    
    # 获取操作系统信息
    OS_INFO=$(remote_exec "cat /etc/os-release 2>/dev/null || cat /etc/*-release 2>/dev/null")
    OS_NAME=$(echo "$OS_INFO" | grep -E "^NAME=" | head -1 | cut -d= -f2 | tr -d '"')
    OS_VERSION=$(echo "$OS_INFO" | grep -E "^VERSION=" | head -1 | cut -d= -f2 | tr -d '"')
    
    # 获取内核信息
    KERNEL=$(remote_exec "uname -r")
    
    # 获取运行时间
    UPTIME=$(remote_exec "uptime -p")
    
    # 获取最后一次启动时间
    LAST_BOOT=$(remote_exec "who -b | awk '{print \$3, \$4}'")
    
    # 获取系统类型
    SYS_TYPE=$(remote_exec "uname -m")

    # 获取基本的系统评分
    SYS_SCORE=0
    
    # 写入报告
    cat << EOF > "$TEMP_FILE"
# 服务器分析报告

<div align="center">
<img src="https://raw.githubusercontent.com/iconic/open-iconic/master/svg/globe.svg" width="80" height="80">
<br>
<strong>服务器分析工具 v${VERSION}</strong>
</div>

## 基本信息

- **主机名**: $HOSTNAME
- **IP地址**: $IP
EOF

    if [[ $USE_LOCAL == false ]]; then
        echo "- **SSH端口**: $PORT" >> "$TEMP_FILE"
    fi

    cat << EOF >> "$TEMP_FILE"
- **操作系统**: $OS_NAME $OS_VERSION
- **系统架构**: $SYS_TYPE
- **内核版本**: $KERNEL
- **运行时间**: $UPTIME
- **最后启动**: $LAST_BOOT

EOF
}

# 获取硬件信息（更新函数）
get_hardware_info() {
    echo -e "${BLUE}正在收集硬件信息...${NC}"
    
    # CPU信息
    CPU_MODEL=$(remote_exec "grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//'")
    CPU_CORES=$(remote_exec "grep -c processor /proc/cpuinfo")
    CPU_PHYS=$(remote_exec "grep 'physical id' /proc/cpuinfo | sort -u | wc -l")
    CPU_FREQ=$(remote_exec "lscpu | grep 'CPU MHz' | head -1 | awk '{print \$3}'")
    
    # 内存信息
    MEM_INFO=$(remote_exec "free -h")
    MEM_TOTAL=$(echo "$MEM_INFO" | grep Mem | awk '{print $2}')
    MEM_USED=$(echo "$MEM_INFO" | grep Mem | awk '{print $3}')
    MEM_FREE=$(echo "$MEM_INFO" | grep Mem | awk '{print $4}')
    MEM_AVAILABLE=$(echo "$MEM_INFO" | grep Mem | awk '{print $7}')
    SWAP_INFO=$(echo "$MEM_INFO" | grep Swap)

    # 内存利用率百分比
    MEM_PERCENT=$(remote_exec "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2*100}'")
    
    # 磁盘信息
    DISK_INFO=$(remote_exec "df -h | grep -v 'tmpfs' | grep -v 'devtmpfs'")
    ROOT_USAGE=$(remote_exec "df -h / | tail -1 | awk '{print \$5}'")
    
    # 获取GPU信息
    get_gpu_info
    
    # 写入报告
    cat << EOF >> "$TEMP_FILE"
## 硬件配置

### CPU
- **型号**: $CPU_MODEL
- **物理CPU数量**: $CPU_PHYS
- **CPU核心/线程总数**: $CPU_CORES
- **CPU频率**: ${CPU_FREQ} MHz

### 内存
- **总内存**: $MEM_TOTAL
- **已使用**: $MEM_USED ($MEM_PERCENT%)
- **空闲内存**: $MEM_FREE
- **可用内存**: $MEM_AVAILABLE
- **交换分区**: $SWAP_INFO

### 存储
\`\`\`
$(echo "$DISK_INFO" | grep -v "^Filesystem")
\`\`\`
- **根分区使用率**: $ROOT_USAGE

EOF

    # 添加GPU部分（如果可用）
    if $GPU_AVAILABLE; then
        cat << EOF >> "$TEMP_FILE"
### GPU ($GPU_TYPE)
- **检测到 $GPU_COUNT 个GPU/加速器**
\`\`\`
$GPU_INFO
\`\`\`

EOF
    else 
        cat << EOF >> "$TEMP_FILE"
### GPU
- **未检测到GPU或加速设备**

EOF
    fi
}

# 获取GPU信息(修改)
get_gpu_info() {
    # 初始化变量
    GPU_AVAILABLE=false
    GPU_INFO="未检测到GPU"
    GPU_TYPE="none"
    
    # NVIDIA GPU检测
    if remote_exec "which nvidia-smi > /dev/null 2>&1"; then
        GPU_AVAILABLE=true
        GPU_TYPE="nvidia"
        GPU_INFO=$(remote_exec "nvidia-smi --query-gpu=gpu_name,driver_version,memory.total,memory.used,temperature.gpu,utilization.gpu --format=csv,noheader")
        GPU_COUNT=$(echo "$GPU_INFO" | wc -l)
        
        # 获取CUDA版本
        CUDA_VERSION=$(remote_exec "nvidia-smi | grep CUDA | awk '{print \$9}' || echo '未知'")
    fi
    
    # AMD GPU详细检测
    if ! $GPU_AVAILABLE && remote_exec "which rocm-smi > /dev/null 2>&1"; then
        GPU_AVAILABLE=true
        GPU_TYPE="amd"
        
        # 获取AMD GPU基本信息
        AMD_GPU_LIST=$(remote_exec "rocm-smi --showproductname")
        GPU_COUNT=$(echo "$AMD_GPU_LIST" | grep -c "GPU\[[0-9]\]")
        
        # 收集详细信息
        AMD_GPU_TEMP=$(remote_exec "rocm-smi --showtemp")
        AMD_GPU_MEM=$(remote_exec "rocm-smi --showmeminfo vram")
        AMD_GPU_USAGE=$(remote_exec "rocm-smi --showuse")
        AMD_GPU_CLOCK=$(remote_exec "rocm-smi --showclocks")
        AMD_GPU_DRIVER=$(remote_exec "rocm-smi --showdriverversion")
        
        # 组合信息
        GPU_INFO="${AMD_GPU_LIST}\n\n${AMD_GPU_TEMP}\n\n${AMD_GPU_MEM}\n\n${AMD_GPU_USAGE}\n\n${AMD_GPU_CLOCK}\n\n驱动版本: ${AMD_GPU_DRIVER}"
    fi
    
    # 华为昇腾处理器检测
    if ! $GPU_AVAILABLE && remote_exec "which npu-smi > /dev/null 2>&1"; then
        GPU_AVAILABLE=true
        GPU_TYPE="ascend"
        
        # 获取昇腾NPU信息
        ASCEND_INFO=$(remote_exec "npu-smi info")
        GPU_COUNT=$(echo "$ASCEND_INFO" | grep -c "NPU-")
        
        # 获取更多昇腾NPU详情
        ASCEND_MEM=$(remote_exec "npu-smi info -m")
        ASCEND_UTILIZATION=$(remote_exec "npu-smi info -u")
        ASCEND_HEALTH=$(remote_exec "npu-smi info -h")
        
        # 组合信息
        GPU_INFO="${ASCEND_INFO}\n\n${ASCEND_MEM}\n\n${ASCEND_UTILIZATION}\n\n${ASCEND_HEALTH}"
    fi
    
    # 使用lspci检测是否有GPU但未安装驱动
    if ! $GPU_AVAILABLE && remote_exec "which lspci > /dev/null 2>&1"; then
        GPU_CHECK=$(remote_exec "lspci | grep -i 'vga\|3d\|display\|nvidia\|amd\|radeon\|gpu'")
        if [[ ! -z "$GPU_CHECK" ]]; then
            GPU_INFO="检测到GPU硬件，但可能未安装驱动:\n$GPU_CHECK"
        fi
    fi
    
    return 0
}

# 获取网络信息
get_network_info() {
    echo -e "${BLUE}正在收集网络信息...${NC}"
    
    # 网络接口信息
    INTERFACES=$(remote_exec "ip -o addr show | grep -v '127.0.0.1' | grep 'inet ' | awk '{print \$2, \$4}'")
    
    # 获取公网IP
    PUBLIC_IP=$(remote_exec "curl -s https://api.ipify.org 2>/dev/null || curl -s https://ipinfo.io/ip 2>/dev/null || echo '无法获取'")

    # 网络速度测试（如果可用）
    SPEEDTEST_AVAILABLE=false
    NETWORK_SPEED=""
    if remote_exec "which speedtest-cli > /dev/null 2>&1"; then
        SPEEDTEST_AVAILABLE=true
        NETWORK_SPEED=$(remote_exec "speedtest-cli --simple 2>/dev/null || echo '无法执行速度测试'")
    fi
    
    # 开放端口
    if remote_exec "which netstat > /dev/null 2>&1"; then
        OPEN_PORTS=$(remote_exec "netstat -tulpn | grep LISTEN")
    elif remote_exec "which ss > /dev/null 2>&1"; then
        OPEN_PORTS=$(remote_exec "ss -tulpn | grep LISTEN")
    else
        OPEN_PORTS="无法获取端口信息（需要netstat或ss命令）"
    fi
    
    # 写入报告
    cat << EOF >> "$TEMP_FILE"
## 网络配置

### 网络接口
\`\`\`
$INTERFACES
\`\`\`

### 网络信息
- **公网IP**: $PUBLIC_IP
EOF

    if $SPEEDTEST_AVAILABLE; then
        cat << EOF >> "$TEMP_FILE"
- **网络速度测试**:
\`\`\`
$NETWORK_SPEED
\`\`\`
EOF
    fi

    cat << EOF >> "$TEMP_FILE"

### 开放端口
\`\`\`
$OPEN_PORTS
\`\`\`

EOF
}

# 获取软件和服务信息
get_software_info() {
    echo -e "${BLUE}正在收集软件和服务信息...${NC}"
    
    # 检查常见服务
    SYSTEMD_SERVICES=""
    if remote_exec "which systemctl > /dev/null 2>&1"; then
        SYSTEMD_SERVICES=$(remote_exec "systemctl list-units --type=service --state=running | grep '\.service' | head -15")
    fi
    
    # 检查Docker
    DOCKER_RUNNING=false
    DOCKER_CONTAINERS=""
    if remote_exec "which docker > /dev/null 2>&1"; then
        DOCKER_VERSION=$(remote_exec "docker --version")
        if [[ $? -eq 0 ]]; then
            DOCKER_RUNNING=true
            DOCKER_CONTAINERS=$(remote_exec "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | head -15")
        fi
    fi
    
    # 检查Python
    PYTHON_AVAILABLE=false
    PYTHON_INFO=""
    if remote_exec "which python3 > /dev/null 2>&1 || which python > /dev/null 2>&1"; then
        PYTHON_AVAILABLE=true
        if remote_exec "which python3 > /dev/null 2>&1"; then
            PYTHON_VERSION=$(remote_exec "python3 --version 2>&1")
            PYTHON_PACKAGES=$(remote_exec "python3 -m pip list 2>/dev/null | head -10 || echo '无法获取包信息'")
        else
            PYTHON_VERSION=$(remote_exec "python --version 2>&1")
            PYTHON_PACKAGES=$(remote_exec "python -m pip list 2>/dev/null | head -10 || echo '无法获取包信息'")
        fi
        PYTHON_INFO="$PYTHON_VERSION
顶部安装的包:
$PYTHON_PACKAGES
..."
    fi
    
    # 检查Anaconda
    ANACONDA_AVAILABLE=false
    ANACONDA_INFO=""
    if remote_exec "which conda > /dev/null 2>&1"; then
        ANACONDA_AVAILABLE=true
        ANACONDA_VERSION=$(remote_exec "conda --version 2>&1")
        ANACONDA_ENVS=$(remote_exec "conda env list 2>/dev/null || echo '无法获取环境信息'")
        ANACONDA_INFO="$ANACONDA_VERSION
环境列表:
$ANACONDA_ENVS"
    fi
    
    # 检查Node.js
    NODEJS_AVAILABLE=false
    NODEJS_INFO=""
    if remote_exec "which node > /dev/null 2>&1"; then
        NODEJS_AVAILABLE=true
        NODEJS_VERSION=$(remote_exec "node --version 2>&1")
        NPM_VERSION=$(remote_exec "npm --version 2>&1 || echo '未安装npm'")
        GLOBAL_PACKAGES=$(remote_exec "npm list -g --depth=0 2>/dev/null | head -10 || echo '无法获取全局包信息'")
        NODEJS_INFO="Node.js: $NODEJS_VERSION
npm: $NPM_VERSION
全局安装的包:
$GLOBAL_PACKAGES
..."
    fi
    
    # 检查Java
    JAVA_AVAILABLE=false
    JAVA_INFO=""
    if remote_exec "which java > /dev/null 2>&1"; then
        JAVA_AVAILABLE=true
        JAVA_VERSION=$(remote_exec "java -version 2>&1 | head -1")
        JAVA_INFO="$JAVA_VERSION"
    fi
    
    # 写入报告
    cat << EOF >> "$TEMP_FILE"
## 软件和服务

### 系统服务
\`\`\`
$SYSTEMD_SERVICES
\`\`\`

EOF

    if [[ $DOCKER_RUNNING == true ]]; then
        cat << EOF >> "$TEMP_FILE"
### Docker
- **Docker版本**: $DOCKER_VERSION

\`\`\`
$DOCKER_CONTAINERS
\`\`\`

EOF
    fi

    cat << EOF >> "$TEMP_FILE"
### 编程语言和环境
EOF

    if $PYTHON_AVAILABLE; then
        cat << EOF >> "$TEMP_FILE"
#### Python
\`\`\`
$PYTHON_INFO
\`\`\`

EOF
    fi

    if $ANACONDA_AVAILABLE; then
        cat << EOF >> "$TEMP_FILE"
#### Anaconda
\`\`\`
$ANACONDA_INFO
\`\`\`

EOF
    fi

    if $NODEJS_AVAILABLE; then
        cat << EOF >> "$TEMP_FILE"
#### Node.js
\`\`\`
$NODEJS_INFO
\`\`\`

EOF
    fi

    if $JAVA_AVAILABLE; then
        cat << EOF >> "$TEMP_FILE"
#### Java
\`\`\`
$JAVA_INFO
\`\`\`

EOF
    fi
}

# 生成性能和资源使用信息
get_performance_info() {
    echo -e "${BLUE}正在收集性能信息...${NC}"
    
    # CPU负载
    LOAD_AVG=$(remote_exec "cat /proc/loadavg")
    
    # 获取CPU和内存使用最高的进程
    TOP_PROCESSES=$(remote_exec "ps aux --sort=-%cpu,-%mem | head -11")
    
    # CPU平均使用率
    CPU_USAGE=$(remote_exec "top -bn1 | grep '%Cpu' | awk '{print \$2 + \$4}'")
    
    # 磁盘IO信息
    DISK_IO=""
    if remote_exec "which iostat > /dev/null 2>&1"; then
        DISK_IO=$(remote_exec "iostat -d -x 1 2 | tail -n +20 | head -5")
    fi
    
    # 写入报告
    cat << EOF >> "$TEMP_FILE"
## 性能和资源使用

### 系统负载
- **当前负载**: $LOAD_AVG
- **CPU使用率**: ${CPU_USAGE}%

### 资源使用最高的进程
\`\`\`
$TOP_PROCESSES
\`\`\`

EOF

    if [[ ! -z "$DISK_IO" ]]; then
        cat << EOF >> "$TEMP_FILE"
### 磁盘I/O
\`\`\`
$DISK_IO
\`\`\`

EOF
    fi
}

# 添加安全信息
get_security_info() {
    echo -e "${BLUE}正在收集安全信息...${NC}"
    
    # 最近的失败登录尝试
    FAILED_LOGINS=""
    if remote_exec "test -f /var/log/auth.log || test -f /var/log/secure"; then
        if remote_exec "test -f /var/log/auth.log"; then
            FAILED_LOGINS=$(remote_exec "grep 'Failed password' /var/log/auth.log 2>/dev/null | tail -5")
        elif remote_exec "test -f /var/log/secure"; then
            FAILED_LOGINS=$(remote_exec "grep 'Failed password' /var/log/secure 2>/dev/null | tail -5")
        fi
    fi
    
    # 检查防火墙状态
    FIREWALL_STATUS=""
    FIREWALL_ENABLED="未知"
    if remote_exec "which ufw > /dev/null 2>&1"; then
        FIREWALL_STATUS=$(remote_exec "ufw status")
        if echo "$FIREWALL_STATUS" | grep -q "active"; then
            FIREWALL_ENABLED="已启用"
        else
            FIREWALL_ENABLED="未启用"
        fi
    elif remote_exec "which firewalld > /dev/null 2>&1"; then
        FIREWALL_STATUS=$(remote_exec "firewall-cmd --state")
        if echo "$FIREWALL_STATUS" | grep -q "running"; then
            FIREWALL_ENABLED="已启用"
        else
            FIREWALL_ENABLED="未启用"
        fi
    elif remote_exec "which iptables > /dev/null 2>&1"; then
        FIREWALL_STATUS="iptables规则:\n$(remote_exec "iptables -L | head -10")"
        if remote_exec "iptables -L | grep -q 'Chain'"; then
            FIREWALL_ENABLED="可能已启用"
        else
            FIREWALL_ENABLED="可能未启用"
        fi
    fi
    
    # 检查SSH配置安全性
    SSH_ROOT_LOGIN="未知"
    SSH_PASSWORD_AUTH="未知"
    if remote_exec "test -f /etc/ssh/sshd_config"; then
        SSH_CONFIG=$(remote_exec "cat /etc/ssh/sshd_config")
        
        if echo "$SSH_CONFIG" | grep -q "PermitRootLogin.*no"; then
            SSH_ROOT_LOGIN="禁止"
        elif echo "$SSH_CONFIG" | grep -q "PermitRootLogin.*yes"; then
            SSH_ROOT_LOGIN="允许"
        fi
        
        if echo "$SSH_CONFIG" | grep -q "PasswordAuthentication.*no"; then
            SSH_PASSWORD_AUTH="禁止"
        elif echo "$SSH_CONFIG" | grep -q "PasswordAuthentication.*yes"; then
            SSH_PASSWORD_AUTH="允许"
        fi
    fi
    
    # 检查SELinux状态
    SELINUX_STATUS="未知"
    if remote_exec "which getenforce > /dev/null 2>&1"; then
        SELINUX_STATUS=$(remote_exec "getenforce 2>/dev/null || echo '未启用'")
    fi
    
    # 写入报告
    cat << EOF >> "$TEMP_FILE"
## 安全信息

### 防火墙
- **状态**: $FIREWALL_ENABLED
\`\`\`
$FIREWALL_STATUS
\`\`\`

### SSH配置
- **允许Root登录**: $SSH_ROOT_LOGIN
- **允许密码认证**: $SSH_PASSWORD_AUTH

### SELinux
- **状态**: $SELINUX_STATUS

EOF

    if [[ ! -z "$FAILED_LOGINS" ]]; then
        cat << EOF >> "$TEMP_FILE"
### 最近的失败登录尝试
\`\`\`
$FAILED_LOGINS
\`\`\`
EOF
    fi
}

# 分析用户信息
get_users_info() {
    echo -e "${BLUE}正在收集用户信息...${NC}"
    
    # 获取系统用户列表
    USERS_INFO=$(remote_exec "cut -d: -f1,3,7 /etc/passwd | sort")
    
    # 获取当前登录用户
    LOGGED_USERS=$(remote_exec "who")
    
    # 获取最近登录用户
    LAST_LOGINS=""
    if remote_exec "which last > /dev/null 2>&1"; then
        LAST_LOGINS=$(remote_exec "last | head -10")
    fi
    
    # 获取sudo用户组成员
    SUDO_USERS=""
    if remote_exec "grep -q sudo /etc/group"; then
        SUDO_USERS=$(remote_exec "grep sudo /etc/group | cut -d: -f4")
    elif remote_exec "grep -q wheel /etc/group"; then
        SUDO_USERS=$(remote_exec "grep wheel /etc/group | cut -d: -f4")
    fi
    
    # 获取系统管理员（root用户）最后一次密码修改时间
    ROOT_PASSWD_CHANGE=""
    if remote_exec "which chage > /dev/null 2>&1"; then
        ROOT_PASSWD_CHANGE=$(remote_exec "chage -l root | grep 'Last password change' | cut -d: -f2-")
    fi
    
    # 写入报告
    cat << EOF >> "$TEMP_FILE"
## 用户信息

### 当前登录用户
\`\`\`
$LOGGED_USERS
\`\`\`

### 最近登录用户
\`\`\`
$LAST_LOGINS
\`\`\`

### 管理权限用户
- **Sudo/管理员用户**: $SUDO_USERS
- **Root密码上次修改**: $ROOT_PASSWD_CHANGE

### 系统用户列表
\`\`\`
$(echo "$USERS_INFO" | grep -v "nologin\|false" | head -15)
... (省略部分系统用户)
\`\`\`

EOF
}

# 分析Ollama和其他AI框架
get_ai_frameworks_info() {
    echo -e "${BLUE}正在收集AI框架信息...${NC}"
    
    # Ollama检测和分析
    OLLAMA_AVAILABLE=false
    OLLAMA_INFO=""
    
    if remote_exec "which ollama > /dev/null 2>&1"; then
        OLLAMA_AVAILABLE=true
        OLLAMA_VERSION=$(remote_exec "ollama --version 2>&1 || echo '未知版本'")
        OLLAMA_MODELS=$(remote_exec "ollama list 2>/dev/null || echo '无法获取模型列表'")
        
        # 获取Ollama服务状态
        OLLAMA_STATUS="未知"
        if remote_exec "pgrep -f ollama > /dev/null"; then
            OLLAMA_STATUS="运行中"
            # 尝试获取更多信息
            OLLAMA_INFO="${OLLAMA_VERSION}\n\n模型列表:\n${OLLAMA_MODELS}"
        else
            OLLAMA_STATUS="未运行"
            OLLAMA_INFO="${OLLAMA_VERSION}\n\nOllama服务未运行"
        fi
    fi
    
    # PyTorch检测
    PYTORCH_AVAILABLE=false
    PYTORCH_INFO=""
    
    if remote_exec "python3 -c 'import torch; print(f\"PyTorch版本: {torch.__version__}\")' 2>/dev/null"; then
        PYTORCH_AVAILABLE=true
        PYTORCH_VERSION=$(remote_exec "python3 -c 'import torch; print(f\"PyTorch版本: {torch.__version__}\")' 2>/dev/null")
        PYTORCH_CUDA=$(remote_exec "python3 -c 'import torch; print(f\"CUDA可用: {torch.cuda.is_available()}\")' 2>/dev/null")
        PYTORCH_DEVICE_COUNT=$(remote_exec "python3 -c 'import torch; print(f\"CUDA设备数: {torch.cuda.device_count()}\")' 2>/dev/null")
        PYTORCH_INFO="${PYTORCH_VERSION}\n${PYTORCH_CUDA}\n${PYTORCH_DEVICE_COUNT}"
    fi
    
    # TensorFlow检测
    TF_AVAILABLE=false
    TF_INFO=""
    
    if remote_exec "python3 -c 'import tensorflow as tf; print(f\"TensorFlow版本: {tf.__version__}\")' 2>/dev/null"; then
        TF_AVAILABLE=true
        TF_VERSION=$(remote_exec "python3 -c 'import tensorflow as tf; print(f\"TensorFlow版本: {tf.__version__}\")' 2>/dev/null")
        TF_DEVICES=$(remote_exec "python3 -c 'import tensorflow as tf; print(f\"可用设备: {tf.config.list_physical_devices()}\")' 2>/dev/null")
        TF_INFO="${TF_VERSION}\n${TF_DEVICES}"
    fi
    
    # ONNX Runtime检测
    ONNX_AVAILABLE=false
    ONNX_INFO=""
    
    if remote_exec "python3 -c 'import onnxruntime as ort; print(f\"ONNX Runtime版本: {ort.__version__}\")' 2>/dev/null"; then
        ONNX_AVAILABLE=true
        ONNX_VERSION=$(remote_exec "python3 -c 'import onnxruntime as ort; print(f\"ONNX Runtime版本: {ort.__version__}\")' 2>/dev/null")
        ONNX_PROVIDERS=$(remote_exec "python3 -c 'import onnxruntime as ort; print(f\"可用提供程序: {ort.get_available_providers()}\")' 2>/dev/null")
        ONNX_INFO="${ONNX_VERSION}\n${ONNX_PROVIDERS}"
    fi
    
    # 写入报告
    if $OLLAMA_AVAILABLE || $PYTORCH_AVAILABLE || $TF_AVAILABLE || $ONNX_AVAILABLE; then
        cat << EOF >> "$TEMP_FILE"
## AI框架

EOF
    
        if $OLLAMA_AVAILABLE; then
            cat << EOF >> "$TEMP_FILE"
### Ollama
- **状态**: $OLLAMA_STATUS
\`\`\`
$OLLAMA_INFO
\`\`\`

EOF
        fi
        
        if $PYTORCH_AVAILABLE || $TF_AVAILABLE || $ONNX_AVAILABLE; then
            cat << EOF >> "$TEMP_FILE"
### 机器学习框架
EOF
            
            if $PYTORCH_AVAILABLE; then
                cat << EOF >> "$TEMP_FILE"

#### PyTorch
\`\`\`
$PYTORCH_INFO
\`\`\`
EOF
            fi
            
            if $TF_AVAILABLE; then
                cat << EOF >> "$TEMP_FILE"

#### TensorFlow
\`\`\`
$TF_INFO
\`\`\`
EOF
            fi
            
            if $ONNX_AVAILABLE; then
                cat << EOF >> "$TEMP_FILE"

#### ONNX Runtime
\`\`\`
$ONNX_INFO
\`\`\`
EOF
            fi
        fi
    fi
}

# 添加报告摘要和结论(Markdown格式)
generate_markdown_summary() {
    echo -e "${BLUE}正在生成Markdown摘要和结论...${NC}"
    
    DATE=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 在报告开头添加摘要
    TEMP_SUMMARY=$(mktemp)
    
    # 计算一些指标来生成建议
    CPU_USAGE_NUM=$(echo $CPU_USAGE | sed 's/%//')
    MEM_USAGE_PERCENT=$(echo $MEM_PERCENT | sed 's/%//')
    DISK_USAGE_PERCENT=$(echo $ROOT_USAGE | sed 's/%//')
    
    # 生成建议
    TIPS=""
    
    # CPU建议
    if (( $(echo "$CPU_USAGE_NUM > 80" | bc -l) )); then
        TIPS="${TIPS}- ⚠️ **CPU负载高**: 考虑查看并优化高CPU使用的进程\n"
    fi
    
    # 内存建议
    if (( $(echo "$MEM_USAGE_PERCENT > 85" | bc -l) )); then
        TIPS="${TIPS}- ⚠️ **内存使用率高**: 考虑增加交换空间或物理内存，或优化内存占用高的应用\n"
    fi
    
    # 磁盘建议
    if (( $(echo "$DISK_USAGE_PERCENT > 85" | bc -l) )); then
        TIPS="${TIPS}- ⚠️ **磁盘使用率高**: 考虑清理不必要的文件或增加存储空间\n"
    fi
    
    # 防火墙建议
    if [[ "$FIREWALL_ENABLED" == "未启用" ]]; then
        TIPS="${TIPS}- ⚠️ **防火墙未启用**: 建议启用防火墙以增强安全性\n"
    fi
    
    # SSH安全建议
    if [[ "$SSH_ROOT_LOGIN" == "允许" ]]; then
        TIPS="${TIPS}- ⚠️ **Root远程登录已启用**: 建议禁用Root远程登录，使用普通用户+sudo\n"
    fi
    
    if [[ "$SSH_PASSWORD_AUTH" == "允许" ]]; then
        TIPS="${TIPS}- ⚠️ **SSH密码认证已启用**: 考虑使用密钥认证替代密码认证\n"
    fi
    
    # GPU建议
    if [[ "$GPU_TYPE" != "none" ]]; then
        if [[ "$GPU_TYPE" == "nvidia" ]]; then
            TIPS="${TIPS}- 💡 **已检测到NVIDIA GPU**: 确保CUDA和cuDNN版本与您的深度学习框架兼容\n"
        elif [[ "$GPU_TYPE" == "amd" ]]; then
            TIPS="${TIPS}- 💡 **已检测到AMD GPU**: 确保ROCm版本与您的深度学习框架兼容\n"
        elif [[ "$GPU_TYPE" == "ascend" ]]; then
            TIPS="${TIPS}- 💡 **已检测到华为昇腾NPU**: 确保CANN工具包已正确安装\n"
        fi
    fi
    
    # Ollama建议
    if [[ "$OLLAMA_AVAILABLE" == "true" && "$OLLAMA_STATUS" == "未运行" ]]; then
        TIPS="${TIPS}- 💡 **Ollama未运行**: 可以通过 'ollama serve' 启动服务\n"
    fi
    
    # 如果没有特别的建议，添加一条正面评价
    if [[ -z "$TIPS" ]]; then
        TIPS="- ✅ 系统运行状况良好，无明显问题\n"
    fi
    
    # 确定GPU显示信息
    GPU_DISPLAY=""
    if [[ "$GPU_TYPE" != "none" ]]; then
        GPU_DISPLAY="检测到 ${GPU_COUNT} 个 ${GPU_TYPE} GPU"
    else
        GPU_DISPLAY="未检测到GPU"
    fi
    
    # 创建摘要报告
    cat << EOF > "$TEMP_SUMMARY"
# 服务器分析报告

<div align="center">
<img src="https://raw.githubusercontent.com/iconic/open-iconic/master/svg/globe.svg" width="80" height="80">
<br>
<strong>服务器分析工具 v${VERSION}</strong>
</div>

<div style="text-align: center; padding: 20px;">
<strong>📊 生成时间:</strong> $DATE
<br>
<strong>🖥️ 分析服务器:</strong> $IP
</div>

## 🔍 摘要
| 指标 | 值 |
|------|-----|
| 🖥️ 主机名 | $HOSTNAME |
| 🐧 操作系统 | $OS_NAME $OS_VERSION |
| 🔄 内核版本 | $KERNEL |
| 💻 CPU | $CPU_MODEL ($CPU_CORES 核心) |
| 🧠 内存 | 总计 $MEM_TOTAL, 使用率 $MEM_PERCENT% |
| 💾 磁盘使用率 | $ROOT_USAGE |
| 🎮 GPU | $GPU_DISPLAY |
| 🔐 防火墙 | $FIREWALL_ENABLED |
| ⏱️ 运行时间 | $UPTIME |

$(cat "$TEMP_FILE")

## 📝 结论和建议

${TIPS}
- 定期更新系统和软件包以修补安全漏洞
- 监控系统性能和资源使用情况
- 备份重要数据和配置文件

---

<div style="text-align: center; font-size: 0.8em; color: #888; padding-top: 20px;">
此报告由服务器分析脚本自动生成 v${VERSION}<br>
生成时间: $DATE
</div>

EOF

    mv "$TEMP_SUMMARY" "$TEMP_FILE"
}

# 直接生成HTML报告
generate_html_report() {
    local html_file="$1"
    
    echo -e "${BLUE}正在直接生成HTML报告...${NC}"
    
    # 获取当前日期和时间
    DATE=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 计算一些指标来生成建议
    CPU_USAGE_NUM=$(echo $CPU_USAGE | sed 's/%//')
    MEM_USAGE_PERCENT=$(echo $MEM_PERCENT | sed 's/%//')
    DISK_USAGE_PERCENT=$(echo $ROOT_USAGE | sed 's/%//')
    
    # 生成建议
    TIPS=""
    
    # CPU建议
    if (( $(echo "$CPU_USAGE_NUM > 80" | bc -l) )); then
        TIPS="${TIPS}<li class=\"warning\">⚠️ <strong>CPU负载高</strong>: 考虑查看并优化高CPU使用的进程</li>\n"
    fi
    
    # 内存建议
    if (( $(echo "$MEM_USAGE_PERCENT > 85" | bc -l) )); then
        TIPS="${TIPS}<li class=\"warning\">⚠️ <strong>内存使用率高</strong>: 考虑增加交换空间或物理内存，或优化内存占用高的应用</li>\n"
    fi
    
    # 磁盘建议
    if (( $(echo "$DISK_USAGE_PERCENT > 85" | bc -l) )); then
        TIPS="${TIPS}<li class=\"warning\">⚠️ <strong>磁盘使用率高</strong>: 考虑清理不必要的文件或增加存储空间</li>\n"
    fi
    
    # 防火墙建议
    if [[ "$FIREWALL_ENABLED" == "未启用" ]]; then
        TIPS="${TIPS}<li class=\"warning\">⚠️ <strong>防火墙未启用</strong>: 建议启用防火墙以增强安全性</li>\n"
    fi
    
    # SSH安全建议
    if [[ "$SSH_ROOT_LOGIN" == "允许" ]]; then
        TIPS="${TIPS}<li class=\"warning\">⚠️ <strong>Root远程登录已启用</strong>: 建议禁用Root远程登录，使用普通用户+sudo</li>\n"
    fi
    
    if [[ "$SSH_PASSWORD_AUTH" == "允许" ]]; then
        TIPS="${TIPS}<li class=\"warning\">⚠️ <strong>SSH密码认证已启用</strong>: 考虑使用密钥认证替代密码认证</li>\n"
    fi
    
    # GPU建议
    if [[ "$GPU_TYPE" != "none" ]]; then
        if [[ "$GPU_TYPE" == "nvidia" ]]; then
            TIPS="${TIPS}<li>💡 <strong>已检测到NVIDIA GPU</strong>: 确保CUDA和cuDNN版本与您的深度学习框架兼容</li>\n"
        elif [[ "$GPU_TYPE" == "amd" ]]; then
            TIPS="${TIPS}<li>💡 <strong>已检测到AMD GPU</strong>: 确保ROCm版本与您的深度学习框架兼容</li>\n"
        elif [[ "$GPU_TYPE" == "ascend" ]]; then
            TIPS="${TIPS}<li>💡 <strong>已检测到华为昇腾NPU</strong>: 确保CANN工具包已正确安装</li>\n"
        fi
    fi
    
    # Ollama建议
    if [[ "$OLLAMA_AVAILABLE" == "true" && "$OLLAMA_STATUS" == "未运行" ]]; then
        TIPS="${TIPS}<li>💡 <strong>Ollama未运行</strong>: 可以通过 'ollama serve' 启动服务</li>\n"
    fi
    
    # 如果没有特别的建议，添加一条正面评价
    if [[ -z "$TIPS" ]]; then
        TIPS="<li class=\"success\">✅ 系统运行状况良好，无明显问题</li>\n"
    fi
    
    # 确定GPU显示信息
    GPU_DISPLAY=""
    if [[ "$GPU_TYPE" != "none" ]]; then
        GPU_DISPLAY="检测到 ${GPU_COUNT} 个 ${GPU_TYPE} GPU"
    else
        GPU_DISPLAY="未检测到GPU"
    fi
    
    # HTML头部
    cat << EOF > "$html_file"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>服务器分析报告</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1100px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f7f9;
        }
        .report-header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background-color: #fff;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .report-header img {
            width: 80px;
            height: 80px;
        }
        h1 {
            color: #2c3e50;
            margin-top: 10px;
        }
        h2 {
            color: #3498db;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
            margin-top: 30px;
        }
        h3 {
            color: #2980b9;
            margin-top: 20px;
        }
        h4 {
            color: #16a085;
        }
        .summary-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background-color: #fff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .summary-table th, .summary-table td {
            padding: 12px 15px;
            text-align: left;
            border: 1px solid #ddd;
        }
        .summary-table th {
            background-color: #3498db;
            color: white;
        }
        .summary-table tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        pre {
            background-color: #f8f9fa;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            overflow-x: auto;
            font-family: SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
            font-size: 14px;
        }
        code {
            background-color: #f8f9fa;
            padding: 2px 5px;
            border-radius: 3px;
            font-family: SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
            font-size: 14px;
        }
        .section {
            background-color: #fff;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            font-size: 0.8em;
            color: #7f8c8d;
            border-top: 1px solid #ddd;
        }
        .warning {
            color: #e74c3c;
            font-weight: bold;
        }
        .success {
            color: #27ae60;
            font-weight: bold;
        }
        @media (max-width: 768px) {
            .summary-table {
                font-size: 14px;
            }
        }
        ul {
            list-style-type: none;
            padding-left: 10px;
        }
        li {
            margin-bottom: 8px;
        }
    </style>
</head>
<body>
    <div class="report-header">
        <img src="https://raw.githubusercontent.com/iconic/open-iconic/master/svg/globe.svg" alt="服务器图标">
        <h1>服务器分析报告</h1>
        <strong>服务器分析工具 v${VERSION}</strong>
        <p>
            <strong>📊 生成时间:</strong> $DATE<br>
            <strong>🖥️ 分析服务器:</strong> $IP
        </p>
    </div>

    <div class="section">
        <h2>🔍 摘要</h2>
        <table class="summary-table">
            <tr>
                <th>指标</th>
                <th>值</th>
            </tr>
            <tr>
                <td>🖥️ 主机名</td>
                <td>$HOSTNAME</td>
            </tr>
            <tr>
                <td>🐧 操作系统</td>
                <td>$OS_NAME $OS_VERSION</td>
            </tr>
            <tr>
                <td>🔄 内核版本</td>
                <td>$KERNEL</td>
            </tr>
            <tr>
                <td>💻 CPU</td>
                <td>$CPU_MODEL ($CPU_CORES 核心)</td>
            </tr>
            <tr>
                <td>🧠 内存</td>
                <td>总计 $MEM_TOTAL, 使用率 $MEM_PERCENT%</td>
            </tr>
            <tr>
                <td>💾 磁盘使用率</td>
                <td>$ROOT_USAGE</td>
            </tr>
            <tr>
                <td>🎮 GPU</td>
                <td>$GPU_DISPLAY</td>
            </tr>
            <tr>
                <td>🔐 防火墙</td>
                <td>$FIREWALL_ENABLED</td>
            </tr>
            <tr>
                <td>⏱️ 运行时间</td>
                <td>$UPTIME</td>
            </tr>
        </table>
    </div>

    <div class="section">
        <h2>基本信息</h2>
        <ul>
            <li><strong>主机名</strong>: $HOSTNAME</li>
            <li><strong>IP地址</strong>: $IP</li>
EOF

    if [[ $USE_LOCAL == false ]]; then
        echo "            <li><strong>SSH端口</strong>: $PORT</li>" >> "$html_file"
    fi

    cat << EOF >> "$html_file"
            <li><strong>操作系统</strong>: $OS_NAME $OS_VERSION</li>
            <li><strong>系统架构</strong>: $SYS_TYPE</li>
            <li><strong>内核版本</strong>: $KERNEL</li>
            <li><strong>运行时间</strong>: $UPTIME</li>
            <li><strong>最后启动</strong>: $LAST_BOOT</li>
        </ul>
    </div>

    <div class="section">
        <h2>硬件配置</h2>
        
        <h3>CPU</h3>
        <ul>
            <li><strong>型号</strong>: $CPU_MODEL</li>
            <li><strong>物理CPU数量</strong>: $CPU_PHYS</li>
            <li><strong>CPU核心/线程总数</strong>: $CPU_CORES</li>
            <li><strong>CPU频率</strong>: ${CPU_FREQ} MHz</li>
        </ul>

        <h3>内存</h3>
        <ul>
            <li><strong>总内存</strong>: $MEM_TOTAL</li>
            <li><strong>已使用</strong>: $MEM_USED ($MEM_PERCENT%)</li>
            <li><strong>空闲内存</strong>: $MEM_FREE</li>
            <li><strong>可用内存</strong>: $MEM_AVAILABLE</li>
            <li><strong>交换分区</strong>: $SWAP_INFO</li>
        </ul>

        <h3>存储</h3>
        <pre>$(echo "$DISK_INFO" | grep -v "^Filesystem")</pre>
        <p><strong>根分区使用率</strong>: $ROOT_USAGE</p>
EOF

    # 添加GPU部分（如果可用）
    if $GPU_AVAILABLE; then
        cat << EOF >> "$html_file"
        <h3>GPU ($GPU_TYPE)</h3>
        <p><strong>检测到 $GPU_COUNT 个GPU/加速器</strong></p>
        <pre>$GPU_INFO</pre>
EOF
    else 
        cat << EOF >> "$html_file"
        <h3>GPU</h3>
        <p><strong>未检测到GPU或加速设备</strong></p>
EOF
    fi

    cat << EOF >> "$html_file"
    </div>

    <div class="section">
        <h2>网络配置</h2>
        
        <h3>网络接口</h3>
        <pre>$INTERFACES</pre>

        <h3>网络信息</h3>
        <ul>
            <li><strong>公网IP</strong>: $PUBLIC_IP</li>
EOF

    if $SPEEDTEST_AVAILABLE; then
        cat << EOF >> "$html_file"
            <li>
                <strong>网络速度测试</strong>:
                <pre>$NETWORK_SPEED</pre>
            </li>
EOF
    fi

    cat << EOF >> "$html_file"
        </ul>

        <h3>开放端口</h3>
        <pre>$OPEN_PORTS</pre>
    </div>

    <div class="section">
        <h2>软件和服务</h2>

        <h3>系统服务</h3>
        <pre>$SYSTEMD_SERVICES</pre>
EOF

    if [[ $DOCKER_RUNNING == true ]]; then
        cat << EOF >> "$html_file"
        <h3>Docker</h3>
        <p><strong>Docker版本</strong>: $DOCKER_VERSION</p>
        <pre>$DOCKER_CONTAINERS</pre>
EOF
    fi

    cat << EOF >> "$html_file"
        <h3>编程语言和环境</h3>
EOF

    if $PYTHON_AVAILABLE; then
        cat << EOF >> "$html_file"
        <h4>Python</h4>
        <pre>$PYTHON_INFO</pre>
EOF
    fi

    if $ANACONDA_AVAILABLE; then
        cat << EOF >> "$html_file"
        <h4>Anaconda</h4>
        <pre>$ANACONDA_INFO</pre>
EOF
    fi

    if $NODEJS_AVAILABLE; then
        cat << EOF >> "$html_file"
        <h4>Node.js</h4>
        <pre>$NODEJS_INFO</pre>
EOF
    fi

    if $JAVA_AVAILABLE; then
        cat << EOF >> "$html_file"
        <h4>Java</h4>
        <pre>$JAVA_INFO</pre>
EOF
    fi

    cat << EOF >> "$html_file"
    </div>
EOF

    # 如果检测到AI框架，添加AI框架部分
    if $OLLAMA_AVAILABLE || $PYTORCH_AVAILABLE || $TF_AVAILABLE || $ONNX_AVAILABLE; then
        cat << EOF >> "$html_file"
    <div class="section">
        <h2>AI框架</h2>
EOF
    
        if $OLLAMA_AVAILABLE; then
            cat << EOF >> "$html_file"
        <h3>Ollama</h3>
        <p><strong>状态</strong>: $OLLAMA_STATUS</p>
        <pre>$OLLAMA_INFO</pre>
EOF
        fi
        
        if $PYTORCH_AVAILABLE || $TF_AVAILABLE || $ONNX_AVAILABLE; then
            cat << EOF >> "$html_file"
        <h3>机器学习框架</h3>
EOF
            
            if $PYTORCH_AVAILABLE; then
                cat << EOF >> "$html_file"
        <h4>PyTorch</h4>
        <pre>$PYTORCH_INFO</pre>
EOF
            fi
            
            if $TF_AVAILABLE; then
                cat << EOF >> "$html_file"
        <h4>TensorFlow</h4>
        <pre>$TF_INFO</pre>
EOF
            fi
            
            if $ONNX_AVAILABLE; then
                cat << EOF >> "$html_file"
        <h4>ONNX Runtime</h4>
        <pre>$ONNX_INFO</pre>
EOF
            fi
        fi
        
        cat << EOF >> "$html_file"
    </div>
EOF
    fi

    cat << EOF >> "$html_file"
    <div class="section">
        <h2>性能和资源使用</h2>

        <h3>系统负载</h3>
        <ul>
            <li><strong>当前负载</strong>: $LOAD_AVG</li>
            <li><strong>CPU使用率</strong>: ${CPU_USAGE}%</li>
        </ul>

        <h3>资源使用最高的进程</h3>
        <pre>$TOP_PROCESSES</pre>
EOF

    if [[ ! -z "$DISK_IO" ]]; then
        cat << EOF >> "$html_file"
        <h3>磁盘I/O</h3>
        <pre>$DISK_IO</pre>
EOF
    fi

    cat << EOF >> "$html_file"
    </div>

    <div class="section">
        <h2>安全信息</h2>

        <h3>防火墙</h3>
        <p><strong>状态</strong>: $FIREWALL_ENABLED</p>
        <pre>$FIREWALL_STATUS</pre>

        <h3>SSH配置</h3>
        <ul>
            <li><strong>允许Root登录</strong>: $SSH_ROOT_LOGIN</li>
            <li><strong>允许密码认证</strong>: $SSH_PASSWORD_AUTH</li>
        </ul>

        <h3>SELinux</h3>
        <p><strong>状态</strong>: $SELINUX_STATUS</p>
EOF

    if [[ ! -z "$FAILED_LOGINS" ]]; then
        cat << EOF >> "$html_file"
        <h3>最近的失败登录尝试</h3>
        <pre>$FAILED_LOGINS</pre>
EOF
    fi

    cat << EOF >> "$html_file"
    </div>

    <div class="section">
        <h2>用户信息</h2>

        <h3>当前登录用户</h3>
        <pre>$LOGGED_USERS</pre>

        <h3>最近登录用户</h3>
        <pre>$LAST_LOGINS</pre>

        <h3>管理权限用户</h3>
        <ul>
            <li><strong>Sudo/管理员用户</strong>: $SUDO_USERS</li>
            <li><strong>Root密码上次修改</strong>: $ROOT_PASSWD_CHANGE</li>
        </ul>

        <h3>系统用户列表</h3>
        <pre>$(echo "$USERS_INFO" | grep -v "nologin\|false" | head -15)
... (省略部分系统用户)</pre>
    </div>

    <div class="section">
        <h2>结论和建议</h2>
        <ul>
            ${TIPS}
            <li>定期更新系统和软件包以修补安全漏洞</li>
            <li>监控系统性能和资源使用情况</li>
            <li>备份重要数据和配置文件</li>
        </ul>
    </div>

    <div class="footer">
        此报告由服务器分析脚本自动生成 v${VERSION} | 生成时间: $DATE
    </div>
</body>
</html>
EOF
}

# 主函数
main() {
    # 显示标题
    echo -e "${GREEN}======================================${NC}"
    echo -e "${BLUE}      服务器分析工具 v${VERSION}      ${NC}"
    echo -e "${GREEN}======================================${NC}"
    
    # 检查连接
    check_connection
    
    # 收集信息
    get_system_info
    get_hardware_info
    get_network_info
    get_software_info
    get_users_info
    get_ai_frameworks_info
    get_performance_info
    get_security_info
    
    # 生成摘要
    generate_markdown_summary
    
    # 根据选择的格式生成对应的报告
    if [[ "$REPORT_FORMAT" == "markdown" ]]; then
        # 生成Markdown格式的摘要和报告
        generate_markdown_summary
        cp "$TEMP_FILE" "$REPORT_PATH"
        echo -e "${GREEN}Markdown报告已生成: ${REPORT_PATH}${NC}"
    elif [[ "$REPORT_FORMAT" == "html" ]]; then
        # 直接生成HTML报告
        generate_html_report "$REPORT_PATH"
        echo -e "${GREEN}HTML报告已生成: ${REPORT_PATH}${NC}"
    fi
    
    echo -e "${GREEN}分析完成!${NC}"
}

# 执行主函数
main 