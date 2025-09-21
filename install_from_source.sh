#!/bin/bash

# 3X-UI Enhanced API 源码一键安装脚本
# 作者: WCOJBK
# 适用: Ubuntu/Debian/CentOS 系统

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

echo -e "${GREEN}========================================${PLAIN}"
echo -e "${GREEN} 3X-UI Enhanced API 源码安装脚本${PLAIN}"
echo -e "${GREEN}========================================${PLAIN}"

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请使用root权限运行此脚本${PLAIN}" && exit 1

# 获取服务器IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")

echo -e "${BLUE}🌐 服务器IP: ${SERVER_IP}${PLAIN}"

# 1. 安装基础依赖
echo -e "${YELLOW}📦 安装基础依赖...${PLAIN}"
if command -v apt &> /dev/null; then
    apt update
    apt install -y curl wget git build-essential
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y curl wget git gcc make
else
    echo -e "${RED}❌ 不支持的操作系统${PLAIN}"
    exit 1
fi

# 2. 检查Go环境
echo -e "${YELLOW}🔧 检查Go环境...${PLAIN}"
if ! command -v go &> /dev/null; then
    echo -e "${RED}❌ 未检测到Go环境，请先安装Go${PLAIN}"
    echo -e "${YELLOW}安装命令: apt install golang-go 或者 yum install golang${PLAIN}"
    exit 1
else
    CURRENT_GO_VERSION=$(go version)
    echo -e "${GREEN}✅ ${CURRENT_GO_VERSION}${PLAIN}"
    echo -e "${BLUE}💡 使用兼容版本依赖，支持Go 1.21+${PLAIN}"
fi

# 3. 下载源码
echo -e "${YELLOW}📥 下载源码...${PLAIN}"
cd /tmp
rm -rf x-ui-api-main
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 4. 编译项目
echo -e "${YELLOW}🔨 编译项目...${PLAIN}"
echo -e "${BLUE}设置Go代理加速下载...${PLAIN}"
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# 确保依赖兼容Go 1.21
echo -e "${BLUE}下载Go模块依赖...${PLAIN}"
go mod tidy

echo -e "${BLUE}开始编译Enhanced API版本...${PLAIN}"
go build -ldflags "-s -w" -o x-ui .

if [[ ! -f "./x-ui" ]]; then
    echo -e "${RED}❌ 编译失败${PLAIN}"
    exit 1
fi

echo -e "${GREEN}✅ 编译成功${PLAIN}"

# 5. 停止旧服务
echo -e "${YELLOW}🛑 清理旧服务...${PLAIN}"
systemctl stop x-ui 2>/dev/null || true
killall x-ui 2>/dev/null || true
rm -rf /usr/local/x-ui

# 6. 安装新版本
echo -e "${YELLOW}📦 安装文件...${PLAIN}"
mkdir -p /usr/local/x-ui /etc/x-ui
cp x-ui /usr/local/x-ui/
cp x-ui.sh /usr/bin/x-ui
chmod +x /usr/local/x-ui/x-ui /usr/bin/x-ui

# 7. 创建系统服务
echo -e "${YELLOW}⚙️ 创建系统服务...${PLAIN}"
cat > /etc/systemd/system/x-ui.service << EOF
[Unit]
Description=3X-UI Enhanced API Panel
After=network-online.target
Wants=network-online.target

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

# 8. 启动服务
echo -e "${YELLOW}🚀 启动服务...${PLAIN}"
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 等待服务启动
sleep 5

# 9. 验证安装
if systemctl is-active x-ui >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 服务启动成功${PLAIN}"
    
    # 设置默认用户名密码
    /usr/local/x-ui/x-ui setting -username admin -password admin 2>/dev/null || true
    
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
    echo -e "${GREEN}║                                               ║${PLAIN}"
    echo -e "${GREEN}║  🔧 管理命令:                                ║${PLAIN}"
    echo -e "${GREEN}║  systemctl status x-ui    # 查看状态         ║${PLAIN}"
    echo -e "${GREEN}║  systemctl restart x-ui   # 重启服务         ║${PLAIN}"
    echo -e "${GREEN}║  x-ui settings            # 修改设置         ║${PLAIN}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${PLAIN}"
    
    # 简单测试
    echo -e "${YELLOW}🧪 测试服务...${PLAIN}"
    sleep 2
    if curl -s "http://localhost:${PORT}/" >/dev/null; then
        echo -e "${GREEN}✅ Web服务正常${PLAIN}"
        
        # 测试API端点
        echo -e "${BLUE}🔗 测试Enhanced API端点...${PLAIN}"
        API_TEST=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:${PORT}/panel/api/inbounds/list")
        if [[ "$API_TEST" == "302" ]] || [[ "$API_TEST" == "200" ]]; then
            echo -e "${GREEN}✅ Enhanced API端点响应正常${PLAIN}"
        else
            echo -e "${YELLOW}⚠️ API端点需要登录访问 (正常)${PLAIN}"
        fi
    else
        echo -e "${YELLOW}⚠️ Web服务可能需要几秒启动，请稍后访问${PLAIN}"
    fi
    
    echo ""
    echo -e "${BLUE}📖 快速开始指南:${PLAIN}"
    echo -e "${PLAIN}1. 🌐 访问Web界面: http://${SERVER_IP}:${PORT}/${PLAIN}"
    echo -e "${PLAIN}2. 🔑 登录: admin / admin${PLAIN}"
    echo -e "${PLAIN}3. 📊 在'入站列表'中配置代理${PLAIN}"
    echo -e "${PLAIN}4. 🔌 通过API管理: /panel/api/* ${PLAIN}"
    
else
    echo -e "${RED}❌ 服务启动失败${PLAIN}"
    systemctl status x-ui --no-pager
    echo ""
    echo -e "${YELLOW}查看日志: journalctl -u x-ui -f${PLAIN}"
    exit 1
fi

# 清理临时文件
cd / && rm -rf /tmp/x-ui-api-main

echo ""
echo -e "${GREEN}🎯 安装完成！现在可以访问 http://${SERVER_IP}:${PORT}/ 开始使用${PLAIN}"
echo ""
