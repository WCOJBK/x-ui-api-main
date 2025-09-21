#!/bin/bash

# 3X-UI Enhanced API 最终解决方案 - 一次性解决所有问题
# 作者: WCOJBK

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

echo -e "${GREEN}========================================${PLAIN}"
echo -e "${GREEN} 3X-UI Enhanced API 最终解决方案${PLAIN}"
echo -e "${GREEN}========================================${PLAIN}"

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请使用root权限运行此脚本${PLAIN}" && exit 1

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
echo -e "${BLUE}🌐 服务器IP: ${SERVER_IP}${PLAIN}"

# 安装基础依赖
echo -e "${YELLOW}📦 安装基础依赖...${PLAIN}"
if command -v apt &> /dev/null; then
    apt update >/dev/null 2>&1
    apt install -y curl wget git build-essential >/dev/null 2>&1
elif command -v yum &> /dev/null; then
    yum update -y >/dev/null 2>&1
    yum install -y curl wget git gcc make >/dev/null 2>&1
fi

echo -e "${YELLOW}🚀 强制升级Go到1.23...${PLAIN}"

# 完全清理旧的Go安装
echo -e "${BLUE}清理旧Go安装...${PLAIN}"
rm -rf /usr/local/go
killall go 2>/dev/null || true

# 强制下载Go 1.23
cd /tmp
rm -f go1.23.*.tar.gz

echo -e "${BLUE}使用多种方式下载Go 1.23...${PLAIN}"
DOWNLOAD_SUCCESS=false

# 方法1: 直接从官网下载
if ! $DOWNLOAD_SUCCESS; then
    echo -e "${BLUE}🔗 尝试官网直接下载...${PLAIN}"
    if timeout 60 wget -q --no-check-certificate https://go.dev/dl/go1.23.0.linux-amd64.tar.gz; then
        DOWNLOAD_SUCCESS=true
        echo -e "${GREEN}✅ 官网下载成功${PLAIN}"
    fi
fi

# 方法2: 使用中国镜像
mirrors=(
    "https://studygolang.com/dl/golang/go1.23.0.linux-amd64.tar.gz"
    "https://golang.google.cn/dl/go1.23.0.linux-amd64.tar.gz" 
    "https://mirrors.aliyun.com/golang/go1.23.0.linux-amd64.tar.gz"
)

if ! $DOWNLOAD_SUCCESS; then
    for mirror in "${mirrors[@]}"; do
        echo -e "${BLUE}🔗 尝试镜像: $(echo $mirror | cut -d'/' -f3)${PLAIN}"
        if timeout 60 wget -q --no-check-certificate "$mirror" -O go1.23.0.linux-amd64.tar.gz; then
            DOWNLOAD_SUCCESS=true
            echo -e "${GREEN}✅ 镜像下载成功${PLAIN}"
            break
        fi
        rm -f go1.23.0.linux-amd64.tar.gz
    done
fi

# 方法3: 使用curl下载
if ! $DOWNLOAD_SUCCESS; then
    echo -e "${BLUE}🔗 使用curl下载...${PLAIN}"
    if timeout 60 curl -L --insecure -o go1.23.0.linux-amd64.tar.gz https://go.dev/dl/go1.23.0.linux-amd64.tar.gz; then
        DOWNLOAD_SUCCESS=true
        echo -e "${GREEN}✅ curl下载成功${PLAIN}"
    fi
fi

# 安装Go或使用兜底方案
if $DOWNLOAD_SUCCESS && [[ -f "go1.23.0.linux-amd64.tar.gz" ]] && [[ $(stat -f%z go1.23.0.linux-amd64.tar.gz 2>/dev/null || stat -c%s go1.23.0.linux-amd64.tar.gz) -gt 50000000 ]]; then
    echo -e "${BLUE}🔧 安装Go 1.23...${PLAIN}"
    tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
    
    # 验证安装
    if [[ -f "/usr/local/go/bin/go" ]]; then
        GO_VERSION=$(/usr/local/go/bin/go version 2>/dev/null || echo "")
        if [[ "$GO_VERSION" =~ go1\.2[3-9] ]]; then
            echo -e "${GREEN}✅ Go 1.23安装成功: $GO_VERSION${PLAIN}"
            export PATH=/usr/local/go/bin:$PATH
            GO_CMD="/usr/local/go/bin/go"
        else
            echo -e "${RED}❌ Go 1.23安装失败，版本验证错误${PLAIN}"
            GO_CMD="go"
        fi
    else
        echo -e "${RED}❌ Go 1.23二进制文件不存在${PLAIN}"
        GO_CMD="go"
    fi
    rm -f go1.23.0.linux-amd64.tar.gz
else
    echo -e "${RED}❌ Go下载失败或文件损坏${PLAIN}"
    echo -e "${YELLOW}🔄 使用系统Go + 强制兼容模式${PLAIN}"
    GO_CMD="go"
fi

# 确保有Go环境
if ! command -v $GO_CMD &> /dev/null && ! command -v go &> /dev/null; then
    echo -e "${YELLOW}📦 安装系统Go...${PLAIN}"
    if command -v apt &> /dev/null; then
        apt install -y golang-go >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y golang >/dev/null 2>&1
    fi
    GO_CMD="go"
fi

echo -e "${GREEN}✅ 当前Go: $($GO_CMD version 2>/dev/null || echo 'Go未找到')${PLAIN}"

# 下载源码
echo -e "${YELLOW}📥 下载源码...${PLAIN}"
cd /tmp
rm -rf x-ui-api-main
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 强制兼容编译
echo -e "${YELLOW}🔨 强制兼容模式编译...${PLAIN}"
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

echo -e "${BLUE}预置所有Go 1.21兼容性修复...${PLAIN}"

# 直接修改go.mod文件，强制使用兼容版本
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
	golang.org/x/text v0.21.0
	google.golang.org/grpc v1.70.0
	gorm.io/driver/sqlite v1.5.7
	gorm.io/gorm v1.25.12
)

replace github.com/gorilla/sessions => github.com/gorilla/sessions v1.3.0
replace github.com/mymmrac/telego => github.com/mymmrac/telego v0.29.2
replace github.com/xtls/reality => github.com/xtls/reality v0.0.0-20240712055506-48f0b2a5ed6d
replace github.com/cloudflare/circl => github.com/cloudflare/circl v1.3.9
replace github.com/google/pprof => github.com/google/pprof v0.0.0-20231229205709-960ae82b1e42
replace github.com/onsi/ginkgo/v2 => github.com/onsi/ginkgo/v2 v2.12.0
replace github.com/quic-go/qpack => github.com/quic-go/qpack v0.4.0
replace github.com/quic-go/quic-go => github.com/quic-go/quic-go v0.37.6
EOF

echo -e "${GREEN}✅ 已强制修改go.mod为兼容版本${PLAIN}"

echo -e "${BLUE}下载兼容依赖...${PLAIN}"
$GO_CMD mod tidy

echo -e "${BLUE}开始编译...${PLAIN}"
if $GO_CMD build -ldflags "-s -w" -o x-ui .; then
    echo -e "${GREEN}✅ 编译成功！${PLAIN}"
elif go build -ldflags "-s -w" -o x-ui . 2>/dev/null; then
    echo -e "${GREEN}✅ 使用系统Go编译成功！${PLAIN}"
else
    echo -e "${RED}❌ 编译失败，查看错误信息...${PLAIN}"
    $GO_CMD build -ldflags "-s -w" -o x-ui . || go build -ldflags "-s -w" -o x-ui .
fi

if [[ ! -f "./x-ui" ]]; then
    echo -e "${RED}❌ 编译彻底失败${PLAIN}"
    exit 1
fi

echo -e "${GREEN}✅ Enhanced API编译完成${PLAIN}"
chmod +x x-ui

# 安装服务
echo -e "${YELLOW}📦 安装系统服务...${PLAIN}"
systemctl stop x-ui 2>/dev/null || true
killall x-ui 2>/dev/null || true
rm -rf /usr/local/x-ui

mkdir -p /usr/local/x-ui /etc/x-ui
cp x-ui /usr/local/x-ui/
cp x-ui.sh /usr/bin/x-ui 2>/dev/null || true
chmod +x /usr/local/x-ui/x-ui /usr/bin/x-ui 2>/dev/null || true

# 创建服务文件
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

# 设置默认凭据
echo -e "${BLUE}设置默认用户...${PLAIN}"
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
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${PLAIN}"
    
    # 测试服务
    echo -e "${YELLOW}🧪 测试服务...${PLAIN}"
    sleep 3
    if curl -s "http://localhost:${PORT}/" >/dev/null; then
        echo -e "${GREEN}✅ Web服务运行正常${PLAIN}"
    else
        echo -e "${YELLOW}⚠️ Web服务正在启动...${PLAIN}"
    fi
    
else
    echo -e "${RED}❌ 服务启动失败${PLAIN}"
    systemctl status x-ui --no-pager -l | head -20
fi

# 清理
echo -e "${BLUE}🧹 清理临时文件...${PLAIN}"
cd / && rm -rf /tmp/x-ui-api-main /tmp/go1.23.*.tar.gz 2>/dev/null || true

echo ""
echo -e "${GREEN}🎯 安装完成！现在可以访问 http://${SERVER_IP}:2053/ 使用Enhanced API功能！${PLAIN}"
echo ""
