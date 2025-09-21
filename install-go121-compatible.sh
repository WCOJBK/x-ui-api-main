#!/bin/bash

# 3X-UI Go 1.21 兼容版本快速安装脚本
# Quick install script for Go 1.21 compatibility

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="WCOJBK/x-ui-api-main"
INSTALL_PATH="/usr/local/x-ui"
VERSION="latest"

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN} 3X-UI Go 1.21 兼容版本安装脚本${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# Check root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
    echo -e "${YELLOW}请使用: sudo $0${NC}"
    exit 1
fi

# Detect system architecture
case "$(uname -m)" in
    x86_64|x64|amd64) ARCH='amd64' ;;
    i*86|x86) ARCH='386' ;;
    armv8*|armv8|arm64|aarch64) ARCH='arm64' ;;
    armv7*|armv7) ARCH='armv7' ;;
    armv6*|armv6) ARCH='armv6' ;;
    armv5*|armv5) ARCH='armv5' ;;
    s390x) ARCH='s390x' ;;
    *) 
        echo -e "${RED}不支持的系统架构: $(uname -m)${NC}"
        exit 1
        ;;
esac

echo -e "${BLUE}检测到系统架构: ${ARCH}${NC}"

# Install dependencies
echo -e "${BLUE}安装系统依赖...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y wget curl tar unzip
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y wget curl tar unzip
elif command -v dnf &> /dev/null; then
    dnf update -y  
    dnf install -y wget curl tar unzip
else
    echo -e "${YELLOW}未知的包管理器，请手动安装: wget curl tar unzip${NC}"
fi

# Check Go version
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | head -1 | sed 's/go//')
    echo -e "${GREEN}检测到Go版本: ${GO_VERSION}${NC}"
    
    # Compare version
    if [[ $(printf '%s\n' "1.21" "$GO_VERSION" | sort -V | head -n1) == "1.21" ]]; then
        echo -e "${GREEN}✓ Go版本满足要求${NC}"
        USE_SOURCE_BUILD=true
    else
        echo -e "${YELLOW}Go版本较低，将从预编译包安装${NC}"
        USE_SOURCE_BUILD=false
    fi
else
    echo -e "${YELLOW}未检测到Go环境，将从预编译包安装${NC}"
    USE_SOURCE_BUILD=false
fi

if [[ "$USE_SOURCE_BUILD" == "true" ]]; then
    echo -e "${BLUE}使用源码编译安装...${NC}"
    
    # Download source code
    cd /tmp
    rm -rf x-ui-api-main
    wget -O x-ui-source.tar.gz "https://github.com/${GITHUB_REPO}/archive/refs/heads/main.tar.gz"
    tar -xzf x-ui-source.tar.gz
    cd x-ui-api-main-main || cd x-ui-api-main || {
        echo -e "${RED}源码解压失败${NC}"
        exit 1
    }
    
    # Configure Go proxy
    export GOPROXY=https://goproxy.cn,direct
    export GOSUMDB=off
    
    # Build
    echo -e "${BLUE}编译中...${NC}"
    CGO_ENABLED=1 go build -ldflags="-w -s" -o x-ui main.go
    
    if [[ ! -f x-ui ]]; then
        echo -e "${RED}编译失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 编译成功${NC}"
    
    # Create installation directory
    mkdir -p ${INSTALL_PATH}/bin
    
    # Copy binary
    cp x-ui ${INSTALL_PATH}/
    chmod +x ${INSTALL_PATH}/x-ui
    
    # Copy web assets
    if [[ -d web ]]; then
        cp -r web ${INSTALL_PATH}/
    fi
    
    # Copy service files
    if [[ -f x-ui.service ]]; then
        cp x-ui.service ${INSTALL_PATH}/
        cp x-ui.service /etc/systemd/system/
    fi
    
    if [[ -f x-ui.sh ]]; then
        cp x-ui.sh ${INSTALL_PATH}/
        cp x-ui.sh /usr/bin/x-ui
        chmod +x /usr/bin/x-ui
    fi
    
    # Download Xray binary
    echo -e "${BLUE}下载Xray核心...${NC}"
    cd ${INSTALL_PATH}/bin
    
    case ${ARCH} in
        "amd64") XRAY_ARCH="64" ;;
        "386") XRAY_ARCH="32" ;;
        "arm64") XRAY_ARCH="arm64-v8a" ;;
        "armv7") XRAY_ARCH="arm32-v7a" ;;
        "armv6") XRAY_ARCH="arm32-v6" ;;
        "armv5") XRAY_ARCH="arm32-v5" ;;
        "s390x") XRAY_ARCH="s390x" ;;
    esac
    
    wget -O xray.zip "https://github.com/XTLS/Xray-core/releases/download/v25.1.30/Xray-linux-${XRAY_ARCH}.zip"
    unzip -q xray.zip
    rm xray.zip
    mv xray xray-linux-${ARCH}
    chmod +x xray-linux-${ARCH}
    
    # Download geo files
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
    
else
    echo -e "${BLUE}从预编译包安装...${NC}"
    
    # Download precompiled package
    cd /tmp
    PACKAGE_URL="https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${ARCH}.tar.gz"
    
    echo -e "${BLUE}下载预编译包: ${PACKAGE_URL}${NC}"
    wget -O x-ui-package.tar.gz "${PACKAGE_URL}"
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}预编译包下载失败${NC}"
        exit 1
    fi
    
    tar -xzf x-ui-package.tar.gz
    cd x-ui || {
        echo -e "${RED}解压失败${NC}"
        exit 1
    }
    
    # Stop existing service
    systemctl stop x-ui 2>/dev/null || true
    
    # Install
    mkdir -p ${INSTALL_PATH}
    cp -rf * ${INSTALL_PATH}/
    
    chmod +x ${INSTALL_PATH}/x-ui
    chmod +x ${INSTALL_PATH}/bin/xray-linux-* 2>/dev/null || true
    chmod +x ${INSTALL_PATH}/x-ui.sh
    
    # Install service
    cp ${INSTALL_PATH}/x-ui.service /etc/systemd/system/ 2>/dev/null || true
    cp ${INSTALL_PATH}/x-ui.sh /usr/bin/x-ui 2>/dev/null || true
    chmod +x /usr/bin/x-ui 2>/dev/null || true
fi

# Configure service
echo -e "${BLUE}配置系统服务...${NC}"
systemctl daemon-reload
systemctl enable x-ui

# Generate random credentials
echo -e "${BLUE}生成随机凭据...${NC}"
RANDOM_USERNAME=$(openssl rand -hex 6)
RANDOM_PASSWORD=$(openssl rand -hex 8) 
RANDOM_PATH=$(openssl rand -hex 8)
RANDOM_PORT=$((RANDOM % 10000 + 10000))

# Configure initial settings
if [[ -f "${INSTALL_PATH}/x-ui" ]]; then
    ${INSTALL_PATH}/x-ui setting -username "${RANDOM_USERNAME}" -password "${RANDOM_PASSWORD}" -webBasePath "${RANDOM_PATH}" -port "${RANDOM_PORT}" >/dev/null 2>&1 || true
fi

# Start service
echo -e "${BLUE}启动服务...${NC}"
systemctl start x-ui

# Check status
sleep 3
if systemctl is-active --quiet x-ui; then
    echo -e "${GREEN}✓ 服务启动成功${NC}"
else
    echo -e "${YELLOW}⚠ 服务可能启动失败，请检查日志: journalctl -u x-ui -f${NC}"
fi

# Get server IP
SERVER_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")

echo -e ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} 安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${CYAN}访问信息:${NC}"
echo -e "用户名: ${RANDOM_USERNAME}"
echo -e "密码: ${RANDOM_PASSWORD}"  
echo -e "端口: ${RANDOM_PORT}"
echo -e "路径: ${RANDOM_PATH}"
echo -e "访问地址: http://${SERVER_IP}:${RANDOM_PORT}/${RANDOM_PATH}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}管理命令:${NC}"
echo -e "  x-ui              - 管理菜单"
echo -e "  systemctl start x-ui      - 启动服务"
echo -e "  systemctl stop x-ui       - 停止服务" 
echo -e "  systemctl restart x-ui    - 重启服务"
echo -e "  systemctl status x-ui     - 查看状态"
echo -e ""
echo -e "${CYAN}请保存上述访问信息！${NC}"

# Cleanup
cd /
rm -rf /tmp/x-ui* 2>/dev/null || true

echo -e "${GREEN}安装完成！${NC}"

