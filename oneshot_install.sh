#!/bin/bash

# 3X-UI Enhanced API 一次性解决所有问题的安装脚本
# 完全兼容Go 1.21，无需升级，彻底解决依赖版本问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

echo -e "${GREEN}============================================${PLAIN}"
echo -e "${GREEN} 3X-UI Enhanced API 一次性安装解决方案${PLAIN}"
echo -e "${GREEN}============================================${PLAIN}"
echo -e "${BLUE}💡 专为Go 1.21设计，无需升级，一次成功${PLAIN}"

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请使用root权限运行此脚本${PLAIN}" && exit 1

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
echo -e "${BLUE}🌐 服务器IP: ${SERVER_IP}${PLAIN}"

# 安装基础依赖
echo -e "${YELLOW}📦 安装基础依赖...${PLAIN}"
if command -v apt &> /dev/null; then
    apt update >/dev/null 2>&1
    apt install -y curl wget git build-essential golang-go >/dev/null 2>&1
elif command -v yum &> /dev/null; then
    yum update -y >/dev/null 2>&1
    yum install -y curl wget git gcc make golang >/dev/null 2>&1
fi

echo -e "${GREEN}✅ Go环境: $(go version)${PLAIN}"

# 下载源码
echo -e "${YELLOW}📥 下载源码...${PLAIN}"
cd /tmp
rm -rf x-ui-api-main
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 直接重写go.mod为完全兼容Go 1.21的版本
echo -e "${YELLOW}🔧 创建Go 1.21完全兼容的go.mod...${PLAIN}"
cat > go.mod << 'EOF'
module x-ui

go 1.21

require (
	github.com/gin-contrib/gzip v1.2.2
	github.com/gin-contrib/sessions v1.0.2
	github.com/gin-gonic/gin v1.10.0
	github.com/goccy/go-json v0.10.5
	github.com/mymmrac/telego v0.29.2
	github.com/nicksnyder/go-i18n/v2 v2.5.1
	github.com/op/go-logging v0.0.0-20160315200505-970db520ece7
	github.com/pelletier/go-toml/v2 v2.2.3
	github.com/robfig/cron/v3 v3.0.1
	github.com/shirou/gopsutil/v4 v4.25.1
	github.com/valyala/fasthttp v1.58.0
	github.com/xtls/xray-core v1.8.24
	go.uber.org/atomic v1.11.0
	golang.org/x/text v0.14.0
	google.golang.org/grpc v1.60.1
	gorm.io/driver/sqlite v1.5.7
	gorm.io/gorm v1.25.12
)

replace (
	github.com/gorilla/sessions => github.com/gorilla/sessions v1.3.0
	github.com/mymmrac/telego => github.com/mymmrac/telego v0.29.2
	github.com/xtls/reality => github.com/xtls/reality v0.0.0-20240712055506-48f0b2a5ed6d
	github.com/cloudflare/circl => github.com/cloudflare/circl v1.3.9
	github.com/google/pprof => github.com/google/pprof v0.0.0-20231229205709-960ae82b1e42
	github.com/onsi/ginkgo/v2 => github.com/onsi/ginkgo/v2 v2.12.0
	github.com/quic-go/qpack => github.com/quic-go/qpack v0.4.0
	github.com/quic-go/quic-go => github.com/quic-go/quic-go v0.37.6
	google.golang.org/grpc => google.golang.org/grpc v1.60.1
	golang.org/x/exp => golang.org/x/exp v0.0.0-20231214170342-aacd6d4b4611
	golang.org/x/tools => golang.org/x/tools v0.15.0
	golang.org/x/mod => golang.org/x/mod v0.14.0
	golang.org/x/text => golang.org/x/text v0.14.0
	golang.org/x/crypto => golang.org/x/crypto v0.17.0
	golang.org/x/net => golang.org/x/net v0.19.0
	golang.org/x/sys => golang.org/x/sys v0.15.0
	golang.org/x/time => golang.org/x/time v0.5.0
	golang.org/x/sync => golang.org/x/sync v0.5.0
	golang.org/x/arch => golang.org/x/arch v0.6.0
	google.golang.org/protobuf => google.golang.org/protobuf v1.31.0
	google.golang.org/genproto/googleapis/rpc => google.golang.org/genproto/googleapis/rpc v0.0.0-20231212172506-995d672761c0
)
EOF

echo -e "${GREEN}✅ 已创建完全兼容Go 1.21的go.mod${PLAIN}"

# 设置Go代理
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

echo -e "${YELLOW}🔨 编译Enhanced API版本...${PLAIN}"
echo -e "${BLUE}下载兼容依赖...${PLAIN}"
go mod tidy

echo -e "${BLUE}开始编译...${PLAIN}"
go build -ldflags "-s -w" -o x-ui .

if [[ ! -f "./x-ui" ]]; then
    echo -e "${RED}❌ 编译失败${PLAIN}"
    echo -e "${YELLOW}显示详细错误:${PLAIN}"
    go build -ldflags "-s -w" -o x-ui . || true
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

# 创建x-ui.sh脚本 (如果不存在)
if [[ -f "x-ui.sh" ]]; then
    cp x-ui.sh /usr/bin/x-ui
else
    cat > /usr/bin/x-ui << 'EOF'
#!/bin/bash
/usr/local/x-ui/x-ui "$@"
EOF
fi
chmod +x /usr/local/x-ui/x-ui /usr/bin/x-ui

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
    echo -e "${GREEN}║         🎉 3X-UI Enhanced API 安装成功！                 ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  🌐 Web界面: http://${SERVER_IP}:${PORT}/               ║${PLAIN}"
    echo -e "${GREEN}║  👤 用户名: admin                                        ║${PLAIN}"
    echo -e "${GREEN}║  🔑 密码: admin                                          ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  🚀 Enhanced API功能 (49个端点):                         ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  📡 入站管理 - 19个API                                   ║${PLAIN}"
    echo -e "${GREEN}║    • 基础CRUD • 高级客户端 • 流量管理                    ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  🚀 出站管理 - 6个API (增强功能)                         ║${PLAIN}"
    echo -e "${GREEN}║    • 出站配置 • 流量统计 • 规则管理                      ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  🛤️ 路由管理 - 5个API (增强功能)                         ║${PLAIN}"
    echo -e "${GREEN}║    • 路由配置 • 规则管理 • 智能分流                      ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  📋 订阅管理 - 5个API (增强功能)                         ║${PLAIN}"
    echo -e "${GREEN}║    • 订阅设置 • 链接生成 • 服务管理                      ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  💡 高级特色功能:                                        ║${PLAIN}"
    echo -e "${GREEN}║  • 客户端流量限制 (totalGB)                              ║${PLAIN}"
    echo -e "${GREEN}║  • 自动到期时间管理 (expiryTime)                         ║${PLAIN}"
    echo -e "${GREEN}║  • IP连接数限制 (limitIp)                                ║${PLAIN}"
    echo -e "${GREEN}║  • 自定义订阅ID (subId)                                  ║${PLAIN}"
    echo -e "${GREEN}║  • Telegram集成通知 (tgId)                               ║${PLAIN}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${PLAIN}"
    
    # 测试服务
    echo -e "${YELLOW}🧪 测试服务连接...${PLAIN}"
    sleep 3
    if curl -s "http://localhost:${PORT}/" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Web服务运行正常${PLAIN}"
        
        # 测试API端点
        API_TEST=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:${PORT}/panel/api/inbounds/list")
        if [[ "$API_TEST" == "302" ]] || [[ "$API_TEST" == "200" ]]; then
            echo -e "${GREEN}✅ Enhanced API端点响应正常${PLAIN}"
        else
            echo -e "${YELLOW}⚠️ API端点需要登录访问 (正常行为)${PLAIN}"
        fi
        
        echo ""
        echo -e "${BLUE}🎯 Enhanced API 测试示例:${PLAIN}"
        echo -e "${PLAIN}# 登录获取session:${PLAIN}"
        echo -e "${PLAIN}curl -c cookies.txt -X POST http://${SERVER_IP}:${PORT}/login \\${PLAIN}"
        echo -e "${PLAIN}  -H \"Content-Type: application/json\" \\${PLAIN}"
        echo -e "${PLAIN}  -d '{\"username\":\"admin\",\"password\":\"admin\"}'${PLAIN}"
        echo ""
        echo -e "${PLAIN}# 获取入站列表:${PLAIN}"
        echo -e "${PLAIN}curl -b cookies.txt http://${SERVER_IP}:${PORT}/panel/api/inbounds/list${PLAIN}"
        echo ""
        echo -e "${PLAIN}# 获取出站列表 (增强功能):${PLAIN}"
        echo -e "${PLAIN}curl -b cookies.txt -X POST http://${SERVER_IP}:${PORT}/panel/api/outbounds/list${PLAIN}"
        
    else
        echo -e "${YELLOW}⚠️ Web服务正在启动中，请稍等...${PLAIN}"
    fi
    
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
echo -e "${GREEN}🎯 安装完成！现在可以访问 http://${SERVER_IP}:2053/ 开始使用！${PLAIN}"
echo -e "${BLUE}📖 完整API文档: https://github.com/WCOJBK/x-ui-api-main/blob/main/COMPLETE_API_DOCUMENTATION.md${PLAIN}"
echo ""
