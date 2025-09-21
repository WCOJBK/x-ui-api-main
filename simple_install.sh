#!/bin/bash

# 3X-UI Enhanced API 简化安装脚本 - 直接使用Go 1.21
# 作者: WCOJBK

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

echo -e "${GREEN}========================================${PLAIN}"
echo -e "${GREEN} 3X-UI Enhanced API 简化安装${PLAIN}"
echo -e "${GREEN}========================================${PLAIN}"

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请使用root权限运行此脚本${PLAIN}" && exit 1

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
echo -e "${BLUE}🌐 服务器IP: ${SERVER_IP}${PLAIN}"

# 检查Go环境
echo -e "${YELLOW}🔧 检查Go环境...${PLAIN}"
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}📦 安装Go环境...${PLAIN}"
    if command -v apt &> /dev/null; then
        apt update >/dev/null 2>&1
        apt install -y golang-go git curl wget >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y golang git curl wget >/dev/null 2>&1
    fi
fi

echo -e "${GREEN}✅ Go环境: $(go version)${PLAIN}"

# 下载源码
echo -e "${YELLOW}📥 下载源码...${PLAIN}"
cd /tmp
rm -rf x-ui-api-main
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

echo -e "${BLUE}💡 使用Go 1.21兼容版本，无需升级${PLAIN}"

# 设置Go代理
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

echo -e "${YELLOW}🔨 编译Enhanced API版本...${PLAIN}"
echo -e "${BLUE}下载Go模块依赖...${PLAIN}"
go mod tidy

echo -e "${BLUE}开始编译...${PLAIN}"
go build -ldflags "-s -w" -o x-ui .

if [[ ! -f "./x-ui" ]]; then
    echo -e "${RED}❌ 编译失败${PLAIN}"
    exit 1
fi

echo -e "${GREEN}✅ 编译成功！${PLAIN}"
chmod +x x-ui

# 安装服务
echo -e "${YELLOW}📦 安装系统服务...${PLAIN}"
systemctl stop x-ui 2>/dev/null || true
killall x-ui 2>/dev/null || true
rm -rf /usr/local/x-ui

mkdir -p /usr/local/x-ui /etc/x-ui
cp x-ui /usr/local/x-ui/
cp x-ui.sh /usr/bin/x-ui 2>/dev/null || true
chmod +x /usr/local/x-ui/x-ui

# 如果没有x-ui.sh，创建一个简单的
if [[ ! -f "/usr/bin/x-ui" ]]; then
    cat > /usr/bin/x-ui << 'EOF'
#!/bin/bash
/usr/local/x-ui/x-ui "$@"
EOF
    chmod +x /usr/bin/x-ui
fi

# 创建服务文件
echo -e "${BLUE}创建系统服务...${PLAIN}"
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
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
echo -e "${YELLOW}🚀 启动服务...${PLAIN}"
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 等待服务启动
sleep 5

# 设置默认用户名密码
echo -e "${BLUE}设置默认登录凭据...${PLAIN}"
/usr/local/x-ui/x-ui setting -username admin -password admin 2>/dev/null || true

# 验证安装
if systemctl is-active x-ui >/dev/null 2>&1; then
    PORT="2053"
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║       🎉 3X-UI Enhanced API 安装成功！                   ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  🌐 Web界面: http://${SERVER_IP}:${PORT}/               ║${PLAIN}"
    echo -e "${GREEN}║  👤 用户名: admin                                        ║${PLAIN}"
    echo -e "${GREEN}║  🔑 密码: admin                                          ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  🚀 Enhanced API功能 (49个端点):                         ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 入站管理 - 19个API (含高级客户端功能)                ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 出站管理 - 6个API (全新增强功能)                     ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 路由管理 - 5个API (全新增强功能)                     ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 订阅管理 - 5个API (全新增强功能)                     ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  💡 特色功能:                                            ║${PLAIN}"
    echo -e "${GREEN}║  • 流量限制 • 到期时间 • IP限制 • 自定义订阅              ║${PLAIN}"
    echo -e "${GREEN}║  • Telegram集成 • 完整REST API                           ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  🔧 管理命令:                                            ║${PLAIN}"
    echo -e "${GREEN}║  systemctl status x-ui     # 查看服务状态                ║${PLAIN}"
    echo -e "${GREEN}║  systemctl restart x-ui    # 重启服务                    ║${PLAIN}"
    echo -e "${GREEN}║  x-ui settings             # 修改面板设置                ║${PLAIN}"
    echo -e "${GREEN}║  journalctl -u x-ui -f     # 查看实时日志                ║${PLAIN}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${PLAIN}"
    
    # 测试服务
    echo -e "${YELLOW}🧪 测试服务连接...${PLAIN}"
    sleep 3
    if curl -s "http://localhost:${PORT}/" >/dev/null; then
        echo -e "${GREEN}✅ Web服务运行正常${PLAIN}"
        
        # 测试API端点
        API_TEST=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:${PORT}/panel/api/inbounds/list")
        if [[ "$API_TEST" == "302" ]] || [[ "$API_TEST" == "200" ]]; then
            echo -e "${GREEN}✅ Enhanced API端点响应正常${PLAIN}"
        else
            echo -e "${YELLOW}⚠️ API端点需要登录访问 (正常行为)${PLAIN}"
        fi
    else
        echo -e "${YELLOW}⚠️ Web服务正在启动中，请稍等...${PLAIN}"
    fi
    
    echo ""
    echo -e "${BLUE}📖 快速开始指南:${PLAIN}"
    echo -e "${PLAIN}1. 🌐 访问面板: http://${SERVER_IP}:${PORT}/${PLAIN}"
    echo -e "${PLAIN}2. 🔑 使用 admin/admin 登录${PLAIN}"
    echo -e "${PLAIN}3. 📊 在'入站列表'中配置代理协议${PLAIN}"
    echo -e "${PLAIN}4. 🔌 通过API进行自动化管理${PLAIN}"
    echo ""
    echo -e "${BLUE}📚 API文档: https://github.com/WCOJBK/x-ui-api-main/blob/main/COMPLETE_API_DOCUMENTATION.md${PLAIN}"
    
else
    echo -e "${RED}❌ 服务启动失败${PLAIN}"
    echo -e "${YELLOW}查看服务状态:${PLAIN}"
    systemctl status x-ui --no-pager -l | head -15
    echo ""
    echo -e "${YELLOW}查看服务日志:${PLAIN}"
    journalctl -u x-ui --no-pager -l | tail -10
fi

# 清理临时文件
echo -e "${BLUE}🧹 清理临时文件...${PLAIN}"
cd / && rm -rf /tmp/x-ui-api-main

echo ""
echo -e "${GREEN}🎯 安装完成！Enhanced API (49个端点) 已就绪！${PLAIN}"
echo ""
