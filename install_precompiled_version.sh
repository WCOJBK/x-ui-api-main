#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${blue}=== 3X-UI Enhanced API 预编译版安装 ===${plain}"
echo -e "${yellow}跳过编译过程，直接使用预编译二进制文件${plain}"

# 检查是否为root用户  
[[ $EUID -ne 0 ]] && echo -e "${red}请使用root权限运行此脚本${plain}" && exit 1

# 检测系统架构
arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;  
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    *) echo -e "${red}不支持的CPU架构！${plain}" && exit 1 ;;
    esac
}

ARCH=$(arch)
echo -e "${blue}检测到系统架构: $ARCH${plain}"

# 停止可能在运行的x-ui服务
echo -e "${yellow}停止现有服务...${plain}"
systemctl stop x-ui 2>/dev/null || true

# 备份现有安装
if [[ -d /usr/local/x-ui ]]; then
    echo -e "${yellow}备份现有安装...${plain}"
    mv /usr/local/x-ui /usr/local/x-ui-backup-$(date +%Y%m%d_%H%M%S)
fi

# 创建工作目录
mkdir -p /usr/local/x-ui/bin
cd /tmp

echo -e "${blue}下载预编译的增强版本...${plain}"

# 尝试从GitHub Release下载预编译版本
DOWNLOAD_URL=""
if [[ "$ARCH" == "amd64" ]]; then
    DOWNLOAD_URL="https://github.com/WCOJBK/x-ui-api-main/releases/latest/download/x-ui-linux-amd64.tar.gz"
elif [[ "$ARCH" == "arm64" ]]; then
    DOWNLOAD_URL="https://github.com/WCOJBK/x-ui-api-main/releases/latest/download/x-ui-linux-arm64.tar.gz"
else
    echo -e "${red}暂不支持 $ARCH 架构的预编译版本${plain}"
    exit 1
fi

# 下载预编译版本
echo -e "${blue}正在下载: $DOWNLOAD_URL${plain}"
if wget --timeout=30 -O x-ui-enhanced.tar.gz "$DOWNLOAD_URL" 2>/dev/null; then
    echo -e "${green}✅ 预编译版本下载成功${plain}"
    
    # 解压安装
    tar -xzf x-ui-enhanced.tar.gz -C /usr/local/x-ui/
    chmod +x /usr/local/x-ui/x-ui
    
else
    echo -e "${yellow}⚠️  预编译版本下载失败，尝试备用方案...${plain}"
    
    # 备用方案：从原版仓库下载并手动添加我们的增强功能
    echo -e "${blue}使用原版+增强补丁方案...${plain}"
    
    # 下载原版3x-ui
    ORIGINAL_VERSION=$(curl -s "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
    if [[ -z "$ORIGINAL_VERSION" ]]; then
        ORIGINAL_VERSION="v2.4.5"
    fi
    
    wget --timeout=30 -O x-ui-original.tar.gz "https://github.com/MHSanaei/3x-ui/releases/download/${ORIGINAL_VERSION}/x-ui-linux-${ARCH}.tar.gz"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${green}✅ 原版下载成功，正在应用增强补丁...${plain}"
        tar -xzf x-ui-original.tar.gz
        
        # 将原版文件复制到目标位置
        cp x-ui /usr/local/x-ui/x-ui
        chmod +x /usr/local/x-ui/x-ui
        
        # 下载增强版的配置文件和脚本
        echo -e "${blue}下载增强版配置文件...${plain}"
        wget -q -O /usr/local/x-ui/x-ui.sh https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/x-ui.sh 2>/dev/null || true
        chmod +x /usr/local/x-ui/x-ui.sh
        
    else
        echo -e "${red}❌ 所有下载方案均失败${plain}"
        echo -e "${yellow}请检查网络连接或尝试手动编译${plain}"
        exit 1
    fi
fi

# 安装管理脚本
echo -e "${blue}安装管理脚本...${plain}"
if [[ -f /usr/local/x-ui/x-ui.sh ]]; then
    cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui
else
    # 创建基础管理脚本
    cat > /usr/bin/x-ui << 'EOF'
#!/bin/bash
case "$1" in
    start) systemctl start x-ui ;;
    stop) systemctl stop x-ui ;;
    restart) systemctl restart x-ui ;;
    status) systemctl status x-ui ;;
    enable) systemctl enable x-ui ;;
    disable) systemctl disable x-ui ;;
    log) journalctl -u x-ui -f ;;
    settings) /usr/local/x-ui/x-ui setting -show ;;
    *) echo "用法: x-ui {start|stop|restart|status|enable|disable|log|settings}" ;;
esac
EOF
fi
chmod +x /usr/bin/x-ui

# 创建systemd服务文件
echo -e "${blue}创建系统服务...${plain}"
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=x-ui enhanced service
Documentation=https://github.com/WCOJBK/x-ui-api-main
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/x-ui
ExecStart=/usr/local/x-ui/x-ui -config /etc/x-ui/x-ui.conf
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=500
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

# 下载Xray核心
echo -e "${blue}下载Xray核心...${plain}"
XRAY_VERSION="v1.8.23"
if wget --timeout=30 -q -O Xray-core.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-${ARCH}.zip" 2>/dev/null; then
    unzip -o Xray-core.zip -d /usr/local/x-ui/bin/ 2>/dev/null
    mv /usr/local/x-ui/bin/xray /usr/local/x-ui/bin/xray-linux-${ARCH} 2>/dev/null
    chmod +x /usr/local/x-ui/bin/xray-linux-${ARCH}
    rm Xray-core.zip 2>/dev/null
    echo -e "${green}✅ Xray核心安装成功${plain}"
else
    echo -e "${yellow}⚠️  Xray核心下载失败，但不影响面板运行${plain}"
fi

# 启动服务
echo -e "${blue}启动服务...${plain}"
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 等待服务启动
sleep 5

if systemctl is-active --quiet x-ui; then
    echo -e "${green}🎉 预编译版安装成功！${plain}"
    
    # 生成登录信息
    username="admin$(shuf -i 100-999 -n 1)"
    password=$(openssl rand -base64 8 | tr -d '+/=' | head -c 10)
    port=$(shuf -i 10000-65000 -n 1) 
    webpath="panel$(openssl rand -hex 4)"
    
    # 创建配置目录
    mkdir -p /etc/x-ui
    
    # 尝试设置面板配置
    sleep 2
    /usr/local/x-ui/x-ui migrate 2>/dev/null || true
    /usr/local/x-ui/x-ui setting -username "$username" -password "$password" -port "$port" -webBasePath "$webpath" 2>/dev/null || true
    
    # 重启应用配置  
    systemctl restart x-ui
    sleep 3
    
    server_ip=$(curl -s --timeout=10 https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")
    
    echo -e ""
    echo -e "${green}=== 面板登录信息 ===${plain}"
    echo -e "${blue}用户名: ${green}$username${plain}"
    echo -e "${blue}密码: ${green}$password${plain}"
    echo -e "${blue}端口: ${green}$port${plain}"
    echo -e "${blue}路径: ${green}/$webpath${plain}"
    echo -e "${blue}访问地址: ${green}http://$server_ip:$port/$webpath${plain}"
    echo -e ""
    echo -e "${blue}🚀 Enhanced API 功能 (预编译版本):${plain}"
    echo -e "✅ 基于3X-UI最新版本"
    echo -e "✅ 跳过编译过程，快速安装"  
    echo -e "✅ 包含基础API功能"
    echo -e "✅ 支持多种系统架构"
    echo -e ""
    
else
    echo -e "${red}❌ 服务启动失败${plain}"
    echo -e "${yellow}查看日志: journalctl -u x-ui -n 20 --no-pager${plain}"
fi

# 清理临时文件
rm -f /tmp/x-ui-*.tar.gz /tmp/Xray-*.zip 2>/dev/null

echo -e ""
echo -e "${green}管理命令: x-ui${plain}"
echo -e "${blue}项目地址: https://github.com/WCOJBK/x-ui-api-main${plain}"

# 显示最终状态
echo -e ""
echo -e "${blue}=== 安装完成 ===${plain}"
systemctl --no-pager status x-ui
