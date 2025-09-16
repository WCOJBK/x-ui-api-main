#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}请使用root权限运行此脚本${plain}" && exit 1

echo -e "${blue}=== 3X-UI Enhanced API 手动安装 ===${plain}"

# 步骤1: 修复包管理器问题
echo -e "${yellow}步骤1: 修复可能的包管理器问题...${plain}"
pkill -f unattended-upgr || true
sleep 2
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock /var/lib/apt/lists/lock
dpkg --configure -a

# 步骤2: 手动安装依赖，增加超时和重试
echo -e "${yellow}步骤2: 安装系统依赖（可能需要几分钟）...${plain}"
export DEBIAN_FRONTEND=noninteractive

# 清理apt缓存
apt-get clean

# 更新包索引，增加超时
echo -e "${blue}更新包索引...${plain}"
timeout 300 apt-get update || echo -e "${yellow}包索引更新超时，继续安装...${plain}"

# 分步安装依赖，避免一次性安装导致卡死
echo -e "${blue}安装基础工具...${plain}"
apt-get install -y wget curl || echo -e "${yellow}基础工具安装可能有问题，继续...${plain}"

echo -e "${blue}安装编译工具...${plain}"
apt-get install -y build-essential || echo -e "${yellow}编译工具安装可能有问题，继续...${plain}"

echo -e "${blue}安装Go语言...${plain}"
apt-get install -y golang-go || echo -e "${yellow}Go安装可能有问题，尝试其他方式...${plain}"

# 如果apt安装Go失败，尝试手动安装
if ! command -v go &> /dev/null; then
    echo -e "${yellow}从官方源安装Go...${plain}"
    GO_VERSION="1.21.5"
    wget -q https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
    if [[ $? -eq 0 ]]; then
        tar -C /usr/local -xzf /tmp/go.tar.gz
        echo 'export PATH=/usr/local/go/bin:$PATH' >> /etc/profile
        source /etc/profile
        ln -sf /usr/local/go/bin/go /usr/bin/go
        rm /tmp/go.tar.gz
    fi
fi

echo -e "${blue}安装Git...${plain}"
apt-get install -y git || echo -e "${yellow}Git安装可能有问题，继续...${plain}"

echo -e "${blue}安装其他必要工具...${plain}"
apt-get install -y tar tzdata unzip || echo -e "${yellow}其他工具安装可能有问题，继续...${plain}"

# 步骤3: 验证Go安装
echo -e "${yellow}步骤3: 验证Go环境...${plain}"
if command -v go &> /dev/null; then
    echo -e "${green}✅ Go版本: $(go version)${plain}"
else
    echo -e "${red}❌ Go安装失败${plain}"
    exit 1
fi

# 步骤4: 编译和安装
echo -e "${yellow}步骤4: 下载和编译源码...${plain}"
cd /tmp
rm -rf x-ui-enhanced
git clone https://github.com/WCOJBK/x-ui-api-main.git x-ui-enhanced
cd x-ui-enhanced

# 设置Go代理（中国大陆用户）
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.org

echo -e "${blue}下载Go模块依赖...${plain}"
go mod tidy

echo -e "${blue}编译增强版本（可能需要几分钟）...${plain}"
go build -ldflags="-s -w" -o x-ui main.go

if [[ $? -eq 0 ]]; then
    echo -e "${green}✅ 编译成功！${plain}"
else
    echo -e "${red}❌ 编译失败${plain}"
    exit 1
fi

# 步骤5: 停止现有服务并备份
echo -e "${yellow}步骤5: 停止现有服务并备份...${plain}"
systemctl stop x-ui || true
if [[ -d /usr/local/x-ui ]]; then
    mv /usr/local/x-ui /usr/local/x-ui-backup-$(date +%Y%m%d_%H%M%S)
fi

# 步骤6: 安装新版本
echo -e "${yellow}步骤6: 安装增强版本...${plain}"
mkdir -p /usr/local/x-ui/bin
cp x-ui /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/x-ui

# 复制管理脚本
cp x-ui.sh /usr/local/x-ui/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh
cp x-ui.sh /usr/bin/x-ui
chmod +x /usr/bin/x-ui

# 安装系统服务
cp x-ui.service /etc/systemd/system/
systemctl daemon-reload

# 步骤7: 下载Xray核心
echo -e "${yellow}步骤7: 下载Xray核心...${plain}"
XRAY_VERSION=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.8.24")
echo -e "${blue}下载Xray ${XRAY_VERSION}...${plain}"
wget -q -O /tmp/Xray-linux-amd64.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-amd64.zip"
if [[ $? -eq 0 ]]; then
    unzip -o /tmp/Xray-linux-amd64.zip -d /usr/local/x-ui/bin/
    mv /usr/local/x-ui/bin/xray /usr/local/x-ui/bin/xray-linux-amd64
    chmod +x /usr/local/x-ui/bin/xray-linux-amd64
    rm /tmp/Xray-linux-amd64.zip
else
    echo -e "${yellow}Warning: 下载Xray失败，使用现有版本${plain}"
fi

# 步骤8: 启动服务
echo -e "${yellow}步骤8: 启动服务...${plain}"
systemctl enable x-ui
systemctl start x-ui

# 步骤9: 验证安装
echo -e "${yellow}步骤9: 验证安装...${plain}"
sleep 3
if systemctl is-active --quiet x-ui; then
    echo -e "${green}🎉 安装成功！${plain}"
    
    # 生成随机登录信息
    if [[ ! -f /etc/x-ui/x-ui.db ]]; then
        /usr/local/x-ui/x-ui migrate
        username=$(openssl rand -base64 6)
        password=$(openssl rand -base64 8)
        port=$(shuf -i 10000-65000 -n 1)
        webpath=$(openssl rand -base64 9 | tr -d '+/=')
        
        /usr/local/x-ui/x-ui setting -username "$username" -password "$password" -port "$port" -webBasePath "$webpath"
        
        server_ip=$(curl -s https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")
        
        echo -e ""
        echo -e "${green}=== 登录信息 ===${plain}"
        echo -e "${blue}用户名: $username${plain}"
        echo -e "${blue}密码: $password${plain}"
        echo -e "${blue}端口: $port${plain}"
        echo -e "${blue}路径: /$webpath${plain}"
        echo -e "${blue}访问地址: http://$server_ip:$port/$webpath${plain}"
        echo -e ""
    fi
    
    echo -e "${blue}🎯 Enhanced API Features:${plain}"
    echo -e "✅ 49个API接口 (原版19个)"
    echo -e "✅ 出站管理API (6个接口)"
    echo -e "✅ 路由管理API (5个接口)"
    echo -e "✅ 订阅管理API (5个接口)"  
    echo -e "✅ 高级客户端功能"
    echo -e ""
else
    echo -e "${red}❌ 服务启动失败${plain}"
    echo -e "${yellow}查看日志: journalctl -u x-ui --no-pager${plain}"
fi

# 清理临时文件
cd /
rm -rf /tmp/x-ui-enhanced

echo -e "${green}安装完成！使用 'x-ui' 命令管理面板${plain}"
