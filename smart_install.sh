#!/bin/bash

# 3X-UI Enhanced API 智能安装脚本 - 自动处理Go版本兼容问题
# 作者: WCOJBK

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

echo -e "${GREEN}========================================${PLAIN}"
echo -e "${GREEN} 3X-UI Enhanced API 智能安装脚本${PLAIN}"
echo -e "${GREEN}========================================${PLAIN}"

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请使用root权限运行此脚本${PLAIN}" && exit 1

# 获取服务器IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
echo -e "${BLUE}🌐 服务器IP: ${SERVER_IP}${PLAIN}"

# 检查Go环境
echo -e "${YELLOW}🔧 检查Go环境...${PLAIN}"
if ! command -v go &> /dev/null; then
    echo -e "${RED}❌ 未检测到Go环境，正在安装...${PLAIN}"
    if command -v apt &> /dev/null; then
        apt update && apt install -y golang-go
    elif command -v yum &> /dev/null; then
        yum install -y golang
    else
        echo -e "${RED}❌ 不支持的操作系统${PLAIN}"
        exit 1
    fi
else
    CURRENT_GO_VERSION=$(go version)
    echo -e "${GREEN}✅ ${CURRENT_GO_VERSION}${PLAIN}"
fi

# 下载源码
echo -e "${YELLOW}📥 下载源码...${PLAIN}"
cd /tmp
rm -rf x-ui-api-main
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 智能编译 - 自动处理依赖版本问题
echo -e "${YELLOW}🔨 智能编译...${PLAIN}"
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# 第一次尝试编译
echo -e "${BLUE}尝试编译...${PLAIN}"
go mod tidy
if go build -ldflags "-s -w" -o x-ui . 2>/dev/null; then
    echo -e "${GREEN}✅ 编译成功！${PLAIN}"
else
    echo -e "${YELLOW}⚠️ 检测到Go版本兼容问题，自动修复中...${PLAIN}"
    
    # 自动修复常见的版本兼容问题
    echo -e "${BLUE}修复依赖版本...${PLAIN}"
    
    # 自动修复所有已知的Go版本兼容问题
    echo -e "${BLUE}正在修复所有已知的版本兼容问题...${PLAIN}"
    
    # 修复各种高版本依赖到Go 1.21兼容版本
    go mod edit -replace=github.com/gorilla/sessions=github.com/gorilla/sessions@v1.3.0
    go mod edit -replace=github.com/mymmrac/telego=github.com/mymmrac/telego@v0.29.2
    go mod edit -replace=github.com/xtls/reality=github.com/xtls/reality@v0.0.0-20240712055506-48f0b2a5ed6d
    go mod edit -replace=github.com/cloudflare/circl=github.com/cloudflare/circl@v1.3.9
    go mod edit -replace=github.com/google/pprof=github.com/google/pprof@v0.0.0-20231229205709-960ae82b1e42
    
    echo -e "${GREEN}✅ 已应用兼容性修复:${PLAIN}"
    echo -e "${GREEN}  - gorilla/sessions → v1.3.0${PLAIN}"
    echo -e "${GREEN}  - mymmrac/telego → v0.29.2${PLAIN}"
    echo -e "${GREEN}  - xtls/reality → 20240712版本${PLAIN}"
    echo -e "${GREEN}  - cloudflare/circl → v1.3.9${PLAIN}"
    echo -e "${GREEN}  - google/pprof → 20231229版本${PLAIN}"
    
    # 重新下载依赖并编译
    go mod tidy
    echo -e "${BLUE}重新编译...${PLAIN}"
    if go build -ldflags "-s -w" -o x-ui .; then
        echo -e "${GREEN}✅ 修复后编译成功！${PLAIN}"
    else
        echo -e "${RED}❌ 编译失败，可能需要升级Go版本${PLAIN}"
        echo -e "${YELLOW}正在自动升级Go到1.23...${PLAIN}"
        
        # 升级Go版本作为最后手段
        cd /tmp
        wget -q https://golang.org/dl/go1.23.0.linux-amd64.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
        export PATH=/usr/local/go/bin:$PATH
        echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
        
        cd x-ui-api-main
        go mod tidy
        go build -ldflags "-s -w" -o x-ui .
        echo -e "${GREEN}✅ Go升级后编译成功！${PLAIN}"
    fi
fi

# 检查编译结果
if [[ ! -f "./x-ui" ]]; then
    echo -e "${RED}❌ 编译失败${PLAIN}"
    exit 1
fi

chmod +x x-ui

# 安装服务
echo -e "${YELLOW}📦 安装服务...${PLAIN}"
systemctl stop x-ui 2>/dev/null || true
killall x-ui 2>/dev/null || true
rm -rf /usr/local/x-ui

mkdir -p /usr/local/x-ui /etc/x-ui
cp x-ui /usr/local/x-ui/
cp x-ui.sh /usr/bin/x-ui
chmod +x /usr/local/x-ui/x-ui /usr/bin/x-ui

# 创建系统服务
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=3X-UI Enhanced API Panel
After=network-online.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/x-ui/x-ui
WorkingDirectory=/usr/local/x-ui

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
echo -e "${YELLOW}🚀 启动服务...${PLAIN}"
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui
sleep 5

# 设置默认用户名密码
/usr/local/x-ui/x-ui setting -username admin -password admin 2>/dev/null || true

# 验证安装
if systemctl is-active x-ui >/dev/null 2>&1; then
    PORT="2053"
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║    🎉 3X-UI Enhanced API 安装完成！          ║${PLAIN}"
    echo -e "${GREEN}║                                               ║${PLAIN}"
    echo -e "${GREEN}║  🌐 Web界面: http://${SERVER_IP}:${PORT}/    ║${PLAIN}"
    echo -e "${GREEN}║  👤 用户名: admin                            ║${PLAIN}"
    echo -e "${GREEN}║  🔑 密码: admin                              ║${PLAIN}"
    echo -e "${GREEN}║                                               ║${PLAIN}"
    echo -e "${GREEN}║  🚀 Enhanced API功能 (49个端点):             ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 入站管理 - 19个API (含高级客户端功能)     ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 出站管理 - 6个API (全新增强功能)         ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 路由管理 - 5个API (全新增强功能)         ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 订阅管理 - 5个API (全新增强功能)         ║${PLAIN}"
    echo -e "${GREEN}║                                               ║${PLAIN}"
    echo -e "${GREEN}║  💡 特色功能:                                ║${PLAIN}"
    echo -e "${GREEN}║  • 流量限制 • 到期时间 • IP限制              ║${PLAIN}"
    echo -e "${GREEN}║  • 自定义订阅 • Telegram集成                ║${PLAIN}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${PLAIN}"
    
    # 测试服务
    echo -e "${YELLOW}🧪 测试服务...${PLAIN}"
    sleep 2
    if curl -s "http://localhost:${PORT}/" >/dev/null; then
        echo -e "${GREEN}✅ Web服务正常运行${PLAIN}"
    else
        echo -e "${YELLOW}⚠️ Web服务正在启动中...${PLAIN}"
    fi
    
else
    echo -e "${RED}❌ 服务启动失败${PLAIN}"
    systemctl status x-ui --no-pager
fi

# 清理临时文件
cd / && rm -rf /tmp/x-ui-api-main /tmp/go1.23.0.linux-amd64.tar.gz

echo ""
echo -e "${GREEN}🎯 安装完成！现在可以访问 http://${SERVER_IP}:2053/ 开始使用${PLAIN}"
echo -e "${BLUE}📚 API文档: https://github.com/WCOJBK/x-ui-api-main/blob/main/COMPLETE_API_DOCUMENTATION.md${PLAIN}"
echo ""
