#!/bin/bash

# 3X-UI Quick Install Script for Cloud Servers
# Supports multiple Linux distributions and architectures
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/x-ui-api-main/main/quick-install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="WCOJBK/x-ui-api-main"
INSTALL_PATH="/usr/local/x-ui"
SERVICE_NAME="x-ui"
VERSION="latest"

# System information
OS=""
ARCH=""
DIST=""

# Banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║                   3X-UI Installer                   ║"
    echo "║              快速安装脚本 / Quick Install             ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Logging functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要root权限运行 / This script must be run as root"
        echo "请使用 sudo 或 root 用户运行 / Please run with sudo or as root user"
        exit 1
    fi
}

# Detect system information
detect_system() {
    info "检测系统信息... / Detecting system information..."
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        DIST=$VERSION_ID
    elif [[ -f /usr/lib/os-release ]]; then
        source /usr/lib/os-release
        OS=$ID
        DIST=$VERSION_ID
    else
        error "无法检测系统类型 / Unable to detect system type"
        exit 1
    fi
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|x64|amd64) ARCH='amd64' ;;
        i*86|x86) ARCH='386' ;;
        armv8*|armv8|arm64|aarch64) ARCH='arm64' ;;
        armv7*|armv7) ARCH='armv7' ;;
        armv6*|armv6) ARCH='armv6' ;;
        armv5*|armv5) ARCH='armv5' ;;
        s390x) ARCH='s390x' ;;
        *) 
            error "不支持的系统架构: $(uname -m) / Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    
    info "系统类型 / OS: $OS"
    info "系统版本 / Version: $DIST"
    info "系统架构 / Architecture: $ARCH"
    
    # Check OS compatibility
    case "$OS" in
        ubuntu)
            if [[ ${DIST%.*} -lt 20 ]]; then
                warn "建议使用 Ubuntu 20.04+ / Recommend Ubuntu 20.04+"
            fi
            ;;
        debian)
            if [[ ${DIST%.*} -lt 11 ]]; then
                warn "建议使用 Debian 11+ / Recommend Debian 11+"
            fi
            ;;
        centos)
            if [[ ${DIST%.*} -lt 8 ]]; then
                error "请使用 CentOS 8+ / Please use CentOS 8+"
                exit 1
            fi
            ;;
        fedora)
            if [[ ${DIST%.*} -lt 36 ]]; then
                warn "建议使用 Fedora 36+ / Recommend Fedora 36+"
            fi
            ;;
        arch|manjaro|parch|armbian|almalinux|rocky|ol|amzn|alpine|opensuse*)
            # These are supported
            ;;
        *)
            warn "未测试的系统: $OS / Untested system: $OS"
            echo "继续安装可能遇到问题 / Continue installation may encounter issues"
            read -p "是否继续? / Continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac
}

# Install dependencies
install_dependencies() {
    info "安装系统依赖... / Installing system dependencies..."
    
    case "$OS" in
        ubuntu|debian|armbian)
            apt-get update
            apt-get install -y wget curl tar unzip systemd
            ;;
        centos|almalinux|rocky|ol)
            if command -v dnf &> /dev/null; then
                dnf update -y
                dnf install -y wget curl tar unzip systemd
            else
                yum update -y
                yum install -y wget curl tar unzip systemd
            fi
            ;;
        fedora|amzn)
            dnf update -y
            dnf install -y wget curl tar unzip systemd
            ;;
        arch|manjaro|parch)
            pacman -Sy --noconfirm
            pacman -S --noconfirm wget curl tar unzip systemd
            ;;
        alpine)
            apk update
            apk add wget curl tar unzip openrc
            ;;
        opensuse*)
            zypper refresh
            zypper install -y wget curl tar unzip systemd
            ;;
        *)
            warn "未知系统，尝试通用方法安装依赖 / Unknown system, trying generic installation"
            ;;
    esac
    
    # Check if required tools are available
    for tool in wget curl tar unzip; do
        if ! command -v $tool &> /dev/null; then
            error "依赖安装失败: $tool / Failed to install dependency: $tool"
            exit 1
        fi
    done
    
    info "系统依赖安装完成 / System dependencies installed"
}

# Get latest release information
get_latest_release() {
    info "获取最新版本信息... / Getting latest release information..."
    
    if [[ "$VERSION" == "latest" ]]; then
        # Directly use original repo since our repo doesn't have releases yet
        LATEST_VERSION=$(curl -fsSL "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' 2>/dev/null)
        
        if [[ -z "$LATEST_VERSION" || "$LATEST_VERSION" == "$DIST"* ]]; then
            # Use a known working version
            LATEST_VERSION="v2.5.2"
            warn "无法获取最新版本，使用默认版本 / Unable to get latest version, using default version: $LATEST_VERSION"
        else
            info "从原版仓库获取版本 / Got version from original repo: $LATEST_VERSION"
        fi
        
        VERSION="$LATEST_VERSION"
    fi
    
    info "安装版本 / Installing version: $VERSION"
}

# Download and install 3x-ui
download_install() {
    info "下载并安装 3x-ui... / Downloading and installing 3x-ui..."
    
    local package_name="x-ui-linux-${ARCH}"
    # Use original repo directly since our repo doesn't have releases yet
    local download_url="https://github.com/MHSanaei/3x-ui/releases/download/${VERSION}/${package_name}.tar.gz"
    
    # Create temporary directory
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    # Download package
    info "下载安装包... / Downloading package..."
    debug "下载地址 / Download URL: $download_url"
    
    if ! wget --no-check-certificate -O "${package_name}.tar.gz" "$download_url"; then
        error "下载失败 / Download failed"
        error "请检查网络连接和版本号 / Please check network connection and version number"
        error "尝试的下载地址: $download_url"
        exit 1
    fi
    
    info "下载成功 / Download successful"
    
    # Extract package
    info "解压安装包... / Extracting package..."
    tar -xzf "${package_name}.tar.gz"
    cd "$package_name"
    
    # Stop existing service
    if systemctl is-active --quiet x-ui 2>/dev/null; then
        info "停止现有服务... / Stopping existing service..."
        systemctl stop x-ui
    fi
    
    # Backup existing installation if exists
    if [[ -d "$INSTALL_PATH" ]]; then
        info "备份现有安装... / Backing up existing installation..."
        mv "$INSTALL_PATH" "${INSTALL_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Install files
    info "安装文件... / Installing files..."
    mkdir -p "$INSTALL_PATH"
    cp -rf * "$INSTALL_PATH/"
    
    # Set permissions
    chmod +x "$INSTALL_PATH/x-ui"
    chmod +x "$INSTALL_PATH/bin/xray-linux-"*
    chmod +x "$INSTALL_PATH/x-ui.sh"
    
    # Install service file
    cp "$INSTALL_PATH/x-ui.service" "/etc/systemd/system/"
    
    # Install management script
    cp "$INSTALL_PATH/x-ui.sh" "/usr/bin/x-ui"
    chmod +x "/usr/bin/x-ui"
    
    # Clean up
    cd /
    rm -rf "$tmp_dir"
    
    info "文件安装完成 / File installation completed"
}

# Configure system service
configure_service() {
    info "配置系统服务... / Configuring system service..."
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable x-ui
    
    info "系统服务配置完成 / System service configured"
}

# Initial configuration
initial_config() {
    info "进行初始配置... / Performing initial configuration..."
    
    # Run migration if needed
    "$INSTALL_PATH/x-ui" migrate >/dev/null 2>&1 || true
    
    # Generate random credentials if this is a fresh installation
    local settings_output
    if settings_output=$("$INSTALL_PATH/x-ui" setting -show true 2>/dev/null); then
        local current_username=$(echo "$settings_output" | grep -oE 'Username: .+' | awk '{print $2}')
        local current_password=$(echo "$settings_output" | grep -oE 'Password: .+' | awk '{print $2}')
        local current_port=$(echo "$settings_output" | grep -oE 'Port: .+' | awk '{print $2}')
        local current_webBasePath=$(echo "$settings_output" | grep -oE 'WebBasePath: .+' | awk '{print $2}')
        
        # Check if default credentials are being used
        if [[ "$current_username" == "admin" && "$current_password" == "admin" ]] || [[ -z "$current_webBasePath" ]]; then
            info "检测到默认配置，生成随机凭据... / Default config detected, generating random credentials..."
            
            local random_username=$(openssl rand -hex 6)
            local random_password=$(openssl rand -hex 8)
            local random_webpath=$(openssl rand -hex 8)
            local random_port=$((RANDOM % 10000 + 10000))
            
            # Apply new settings
            "$INSTALL_PATH/x-ui" setting -username "$random_username" -password "$random_password" -webBasePath "$random_webpath" -port "$random_port" >/dev/null 2>&1
            
            # Get server IP
            local server_ip=$(curl -s https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")
            
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN} 安装完成! / Installation Complete!${NC}"
            echo -e "${GREEN}========================================${NC}"
            echo -e "${YELLOW}访问信息 / Access Information:${NC}"
            echo -e "用户名 / Username: ${CYAN}$random_username${NC}"
            echo -e "密码 / Password: ${CYAN}$random_password${NC}"
            echo -e "端口 / Port: ${CYAN}$random_port${NC}"
            echo -e "路径 / Web Path: ${CYAN}$random_webpath${NC}"
            echo -e "访问地址 / Access URL: ${CYAN}http://$server_ip:$random_port/$random_webpath${NC}"
            echo -e "${GREEN}========================================${NC}"
            echo -e "${YELLOW}重要提示 / Important Notes:${NC}"
            echo -e "1. 请保存上述信息 / Please save the above information"
            echo -e "2. 如需查看设置: x-ui settings / To view settings: x-ui settings"
            echo -e "3. 管理面板: x-ui / Management panel: x-ui"
            echo ""
        else
            info "使用现有配置 / Using existing configuration"
        fi
    fi
}

# Start service
start_service() {
    info "启动服务... / Starting service..."
    
    # Start service
    if systemctl start x-ui; then
        sleep 2
        if systemctl is-active --quiet x-ui; then
            info "服务启动成功 / Service started successfully"
        else
            error "服务启动失败 / Service failed to start"
            echo "请查看日志: journalctl -u x-ui -f / Please check logs: journalctl -u x-ui -f"
            exit 1
        fi
    else
        error "无法启动服务 / Unable to start service"
        exit 1
    fi
}

# Show final information
show_final_info() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} 3X-UI 安装完成! / Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${CYAN}管理命令 / Management Commands:${NC}"
    echo -e "  x-ui              - 打开管理菜单 / Open management menu"
    echo -e "  x-ui start        - 启动服务 / Start service"  
    echo -e "  x-ui stop         - 停止服务 / Stop service"
    echo -e "  x-ui restart      - 重启服务 / Restart service"
    echo -e "  x-ui status       - 查看状态 / Check status"
    echo -e "  x-ui settings     - 查看设置 / View settings"
    echo -e "  x-ui log          - 查看日志 / View logs"
    echo -e "  x-ui update       - 更新版本 / Update version"
    echo ""
    echo -e "${CYAN}服务状态 / Service Status:${NC}"
    systemctl status x-ui --no-pager -l || true
    echo ""
    echo -e "${YELLOW}如需帮助，请访问 / For help, please visit:${NC}"
    echo -e "https://github.com/${GITHUB_REPO}"
    echo ""
}

# Error handling
handle_error() {
    error "安装过程中发生错误 / Error occurred during installation"
    error "错误位置 / Error at line: $1"
    exit 1
}

# Set error trap
trap 'handle_error $LINENO' ERR

# Main installation function
main() {
    show_banner
    
    check_root
    detect_system
    install_dependencies
    get_latest_release
    download_install
    configure_service
    initial_config
    start_service
    show_final_info
    
    info "安装完成! / Installation completed!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        --help)
            echo "3X-UI Quick Install Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --version VERSION    Install specific version (default: latest)"
            echo "  --repo REPO          Use custom GitHub repository"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Install latest version"
            echo "  $0 --version v2.5.2          # Install specific version"
            echo "  $0 --repo user/repo          # Install from custom repo"
            exit 0
            ;;
        *)
            error "未知参数: $1 / Unknown parameter: $1"
            echo "使用 --help 查看帮助 / Use --help for help"
            exit 1
            ;;
    esac
done

# Run main function
main
