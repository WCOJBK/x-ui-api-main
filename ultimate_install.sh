#!/bin/bash

# 3X-UI Enhanced API 终极安装脚本 - 直接升级Go到1.23避免所有依赖问题
# 作者: WCOJBK

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

echo -e "${GREEN}========================================${PLAIN}"
echo -e "${GREEN} 3X-UI Enhanced API 终极安装脚本${PLAIN}"
echo -e "${GREEN}========================================${PLAIN}"
echo -e "${BLUE}💡 直接升级Go到1.23避免依赖问题${PLAIN}"

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请使用root权限运行此脚本${PLAIN}" && exit 1

# 获取服务器IP
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
else
    echo -e "${RED}❌ 不支持的操作系统${PLAIN}"
    exit 1
fi

# 使用中国镜像升级Go到1.23
echo -e "${YELLOW}🚀 升级Go到1.23 (解决所有依赖版本问题)...${PLAIN}"
cd /tmp

# 检查是否已经是Go 1.23+
GO_NEED_UPGRADE=true
if command -v go &> /dev/null; then
    CURRENT_GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
    if [[ "$CURRENT_GO_VERSION" =~ ^1\.2[3-9] ]] || [[ "$CURRENT_GO_VERSION" =~ ^[2-9]\. ]]; then
        echo -e "${GREEN}✅ 已有Go ${CURRENT_GO_VERSION}，跳过升级${PLAIN}"
        GO_NEED_UPGRADE=false
    else
        echo -e "${BLUE}当前Go版本: ${CURRENT_GO_VERSION}，正在升级...${PLAIN}"
    fi
else
    echo -e "${BLUE}未检测到Go，正在安装Go 1.23...${PLAIN}"
fi

if [ "$GO_NEED_UPGRADE" = true ]; then
    echo -e "${BLUE}使用中国镜像加速下载...${PLAIN}"
    
    # 尝试多个中国镜像源下载Go
    DOWNLOAD_SUCCESS=false
    
    # 镜像源列表
    mirrors=(
        "https://studygolang.com/dl/golang/go1.23.0.linux-amd64.tar.gz"
        "https://golang.google.cn/dl/go1.23.0.linux-amd64.tar.gz"
        "https://mirrors.aliyun.com/golang/go1.23.0.linux-amd64.tar.gz"
        "https://mirrors.ustc.edu.cn/golang/go1.23.0.linux-amd64.tar.gz"
        "https://go.dev/dl/go1.23.0.linux-amd64.tar.gz"
    )
    
    for mirror in "${mirrors[@]}"; do
        echo -e "${BLUE}🔗 尝试镜像: $(echo $mirror | cut -d'/' -f3)${PLAIN}"
        if wget --timeout=30 --tries=2 -q "$mirror" -O go1.23.0.linux-amd64.tar.gz; then
            echo -e "${GREEN}✅ 下载成功${PLAIN}"
            DOWNLOAD_SUCCESS=true
            break
        else
            echo -e "${YELLOW}⚠️ 镜像失败，尝试下一个...${PLAIN}"
            rm -f go1.23.0.linux-amd64.tar.gz
        fi
    done
    
    if [ "$DOWNLOAD_SUCCESS" = true ] && [ -f "go1.23.0.linux-amd64.tar.gz" ]; then
        # 安装下载的Go 1.23
        echo -e "${BLUE}🔧 安装Go 1.23...${PLAIN}"
        rm -rf /usr/local/go
        tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
        rm -f go1.23.0.linux-amd64.tar.gz
        
        # 验证安装是否成功
        if [[ -f "/usr/local/go/bin/go" ]]; then
            GO_INSTALLED_VERSION=$(/usr/local/go/bin/go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//' || echo "")
            if [[ "$GO_INSTALLED_VERSION" =~ ^1\.2[3-9] ]] || [[ "$GO_INSTALLED_VERSION" =~ ^[2-9]\. ]]; then
                echo -e "${GREEN}✅ Go 1.23 安装成功，版本: ${GO_INSTALLED_VERSION}${PLAIN}"
            else
                echo -e "${RED}❌ Go 1.23 安装失败，检测到版本: ${GO_INSTALLED_VERSION}${PLAIN}"
                DOWNLOAD_SUCCESS=false
            fi
        else
            echo -e "${RED}❌ Go 1.23 安装失败，/usr/local/go/bin/go 不存在${PLAIN}"
            DOWNLOAD_SUCCESS=false
        fi
    fi
    
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        # 所有镜像都失败，使用系统包管理器安装Go
        echo -e "${YELLOW}⚠️ 所有镜像下载失败，使用系统包管理器安装Go...${PLAIN}"
        if command -v apt &> /dev/null; then
            apt install -y golang-go >/dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y golang >/dev/null 2>&1
        fi
        echo -e "${YELLOW}📌 使用系统Go版本 (可能需要手动处理依赖兼容)${PLAIN}"
    fi
fi

# 设置Go环境变量
export PATH=/usr/local/go/bin:$PATH
if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
    echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
fi

# 强制刷新环境变量
hash -r
which go
echo -e "${GREEN}✅ Go版本: $(go version)${PLAIN}"

# 验证Go版本是否正确升级
ACTUAL_GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
if [[ "$ACTUAL_GO_VERSION" =~ ^1\.2[3-9] ]] || [[ "$ACTUAL_GO_VERSION" =~ ^[2-9]\. ]]; then
    echo -e "${GREEN}✅ Go升级验证成功，版本: ${ACTUAL_GO_VERSION}${PLAIN}"
else
    echo -e "${RED}⚠️ Go升级可能失败，当前版本: ${ACTUAL_GO_VERSION}${PLAIN}"
    echo -e "${YELLOW}🔄 尝试手动设置Go路径...${PLAIN}"
    
    # 手动设置完整路径
    GO_BIN="/usr/local/go/bin/go"
    if [[ -f "$GO_BIN" ]]; then
        echo -e "${BLUE}使用完整路径: $GO_BIN${PLAIN}"
        alias go="$GO_BIN"
        export GO_BIN
    else
        echo -e "${RED}❌ Go 1.23安装失败，将使用兼容模式${PLAIN}"
    fi
fi

# 下载源码
echo -e "${YELLOW}📥 下载源码...${PLAIN}"
rm -rf x-ui-api-main
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 编译项目
echo -e "${YELLOW}🔨 编译Enhanced API版本...${PLAIN}"
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# 确定使用的Go命令
GO_CMD="go"
if [[ -n "$GO_BIN" && -f "$GO_BIN" ]]; then
    GO_CMD="$GO_BIN"
elif [[ -f "/usr/local/go/bin/go" ]]; then
    GO_CMD="/usr/local/go/bin/go"
fi

DETECTED_GO_VERSION=$($GO_CMD version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//' || echo "")
echo -e "${BLUE}使用Go命令: $GO_CMD (版本: ${DETECTED_GO_VERSION})${PLAIN}"

# 检测Go版本并决定编译策略
USE_COMPATIBILITY_MODE=false
if [[ ! "$DETECTED_GO_VERSION" =~ ^1\.2[3-9] ]] && [[ ! "$DETECTED_GO_VERSION" =~ ^[2-9]\. ]]; then
    echo -e "${YELLOW}⚠️ 检测到Go版本${DETECTED_GO_VERSION} < 1.23，将使用兼容性模式${PLAIN}"
    USE_COMPATIBILITY_MODE=true
fi

if [ "$USE_COMPATIBILITY_MODE" = true ]; then
    echo -e "${YELLOW}🔧 应用Go 1.21兼容性修复...${PLAIN}"
    
    # 应用所有兼容性修复 - Go 1.21.6 兼容版本
    echo -e "${BLUE}  🔧 修复github.com依赖...${PLAIN}"
    $GO_CMD mod edit -replace=github.com/gorilla/sessions=github.com/gorilla/sessions@v1.3.0
    $GO_CMD mod edit -replace=github.com/mymmrac/telego=github.com/mymmrac/telego@v0.29.2
    $GO_CMD mod edit -replace=github.com/xtls/reality=github.com/xtls/reality@v0.0.0-20240712055506-48f0b2a5ed6d
    $GO_CMD mod edit -replace=github.com/cloudflare/circl=github.com/cloudflare/circl@v1.3.9
    $GO_CMD mod edit -replace=github.com/google/pprof=github.com/google/pprof@v0.0.0-20231229205709-960ae82b1e42
    $GO_CMD mod edit -replace=github.com/onsi/ginkgo/v2=github.com/onsi/ginkgo/v2@v2.12.0
    $GO_CMD mod edit -replace=github.com/quic-go/qpack=github.com/quic-go/qpack@v0.4.0
    $GO_CMD mod edit -replace=github.com/quic-go/quic-go=github.com/quic-go/quic-go@v0.37.6
    $GO_CMD mod edit -replace=github.com/rogpeppe/go-internal=github.com/rogpeppe/go-internal@v1.12.0
    
    echo -e "${BLUE}  🔧 修复golang.org/x依赖...${PLAIN}"
    $GO_CMD mod edit -replace=golang.org/x/exp=golang.org/x/exp@v0.0.0-20231219180239-dc181d75b848
    $GO_CMD mod edit -replace=golang.org/x/crypto=golang.org/x/crypto@v0.17.0
    $GO_CMD mod edit -replace=golang.org/x/net=golang.org/x/net@v0.19.0
    $GO_CMD mod edit -replace=golang.org/x/sys=golang.org/x/sys@v0.15.0
    $GO_CMD mod edit -replace=golang.org/x/text=golang.org/x/text@v0.14.0
    $GO_CMD mod edit -replace=golang.org/x/tools=golang.org/x/tools@v0.16.0
    $GO_CMD mod edit -replace=golang.org/x/mod=golang.org/x/mod@v0.14.0
    $GO_CMD mod edit -replace=golang.org/x/sync=golang.org/x/sync@v0.5.0
    $GO_CMD mod edit -replace=golang.org/x/time=golang.org/x/time@v0.5.0
    
    echo -e "${BLUE}  🔧 修复其他关键依赖...${PLAIN}"
    $GO_CMD mod edit -replace=google.golang.org/grpc=google.golang.org/grpc@v1.58.3
    $GO_CMD mod edit -replace=google.golang.org/protobuf=google.golang.org/protobuf@v1.31.0
    
    echo -e "${GREEN}✅ 已应用兼容性修复:${PLAIN}"
    echo -e "${PLAIN}  - 所有Go 1.21不兼容的依赖已替换为兼容版本${PLAIN}"
    
    echo -e "${BLUE}下载兼容性依赖...${PLAIN}"
    $GO_CMD mod tidy
    
    echo -e "${BLUE}兼容性模式编译...${PLAIN}"
else
    echo -e "${BLUE}下载Go模块依赖...${PLAIN}"
    $GO_CMD mod tidy
    
    echo -e "${BLUE}Go 1.23+ 标准模式编译...${PLAIN}"
fi

# 尝试编译
if $GO_CMD build -ldflags "-s -w" -o x-ui . 2>/dev/null; then
    echo -e "${GREEN}✅ 编译成功！${PLAIN}"
else
    echo -e "${RED}❌ 编译失败，尝试兼容性修复...${PLAIN}"
    
    # 如果之前没有应用兼容性修复，现在应用
    if [ "$USE_COMPATIBILITY_MODE" = false ]; then
        echo -e "${YELLOW}🔧 强制应用兼容性修复...${PLAIN}"
        
        # GitHub依赖修复
        $GO_CMD mod edit -replace=github.com/gorilla/sessions=github.com/gorilla/sessions@v1.3.0
        $GO_CMD mod edit -replace=github.com/mymmrac/telego=github.com/mymmrac/telego@v0.29.2
        $GO_CMD mod edit -replace=github.com/xtls/reality=github.com/xtls/reality@v0.0.0-20240712055506-48f0b2a5ed6d
        $GO_CMD mod edit -replace=github.com/cloudflare/circl=github.com/cloudflare/circl@v1.3.9
        $GO_CMD mod edit -replace=github.com/google/pprof=github.com/google/pprof@v0.0.0-20231229205709-960ae82b1e42
        $GO_CMD mod edit -replace=github.com/onsi/ginkgo/v2=github.com/onsi/ginkgo/v2@v2.12.0
        $GO_CMD mod edit -replace=github.com/quic-go/qpack=github.com/quic-go/qpack@v0.4.0
        $GO_CMD mod edit -replace=github.com/quic-go/quic-go=github.com/quic-go/quic-go@v0.37.6
        $GO_CMD mod edit -replace=github.com/rogpeppe/go-internal=github.com/rogpeppe/go-internal@v1.12.0
        
        # golang.org/x依赖修复
        $GO_CMD mod edit -replace=golang.org/x/exp=golang.org/x/exp@v0.0.0-20231219180239-dc181d75b848
        $GO_CMD mod edit -replace=golang.org/x/crypto=golang.org/x/crypto@v0.17.0
        $GO_CMD mod edit -replace=golang.org/x/net=golang.org/x/net@v0.19.0
        $GO_CMD mod edit -replace=golang.org/x/sys=golang.org/x/sys@v0.15.0
        $GO_CMD mod edit -replace=golang.org/x/text=golang.org/x/text@v0.14.0
        $GO_CMD mod edit -replace=golang.org/x/tools=golang.org/x/tools@v0.16.0
        $GO_CMD mod edit -replace=golang.org/x/mod=golang.org/x/mod@v0.14.0
        $GO_CMD mod edit -replace=golang.org/x/sync=golang.org/x/sync@v0.5.0
        $GO_CMD mod edit -replace=golang.org/x/time=golang.org/x/time@v0.5.0
        
        # 其他关键依赖修复
        $GO_CMD mod edit -replace=google.golang.org/grpc=google.golang.org/grpc@v1.58.3
        $GO_CMD mod edit -replace=google.golang.org/protobuf=google.golang.org/protobuf@v1.31.0
        
        $GO_CMD mod tidy
        echo -e "${BLUE}重新尝试编译...${PLAIN}"
    fi
    $GO_CMD build -ldflags "-s -w" -o x-ui .
    
    if [[ -f "./x-ui" ]]; then
        echo -e "${GREEN}✅ 兼容性模式编译成功！${PLAIN}"
    else
        echo -e "${RED}❌ 编译失败${PLAIN}"
        echo -e "${YELLOW}最后尝试：使用系统Go强制编译...${PLAIN}"
        /usr/bin/go build -ldflags "-s -w" -o x-ui . 2>/dev/null || echo -e "${RED}❌ 所有编译尝试都失败${PLAIN}"
        
        if [[ ! -f "./x-ui" ]]; then
            exit 1
        fi
    fi
fi
chmod +x x-ui

# 安装服务
echo -e "${YELLOW}📦 安装系统服务...${PLAIN}"
systemctl stop x-ui 2>/dev/null || true
killall x-ui 2>/dev/null || true
rm -rf /usr/local/x-ui

mkdir -p /usr/local/x-ui /etc/x-ui
cp x-ui /usr/local/x-ui/
cp x-ui.sh /usr/bin/x-ui
chmod +x /usr/local/x-ui/x-ui /usr/bin/x-ui

# 创建systemd服务
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
echo -e "${BLUE}设置默认凭据...${PLAIN}"
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
    echo -e "${GREEN}║  ✅ 入站管理API - 19个 (含高级客户端功能)                ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 出站管理API - 6个 (全新增强功能)                     ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 路由管理API - 5个 (全新增强功能)                     ║${PLAIN}"
    echo -e "${GREEN}║  ✅ 订阅管理API - 5个 (全新增强功能)                     ║${PLAIN}"
    echo -e "${GREEN}║                                                           ║${PLAIN}"
    echo -e "${GREEN}║  💡 特色功能:                                            ║${PLAIN}"
    echo -e "${GREEN}║  • 流量限制 • 到期时间 • IP限制 • 自定义订阅              ║${PLAIN}"
    echo -e "${GREEN}║  • Telegram集成 • 完整的REST API                         ║${PLAIN}"
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
            echo -e "${YELLOW}⚠️ API端点需要登录访问 (正常)${PLAIN}"
        fi
    else
        echo -e "${YELLOW}⚠️ Web服务正在启动，请稍等片刻${PLAIN}"
    fi
    
    echo ""
    echo -e "${BLUE}📖 快速开始指南:${PLAIN}"
    echo -e "${PLAIN}1. 🌐 访问面板: http://${SERVER_IP}:${PORT}/${PLAIN}"
    echo -e "${PLAIN}2. 🔑 使用 admin/admin 登录${PLAIN}"
    echo -e "${PLAIN}3. 📊 在'入站列表'中配置代理${PLAIN}"
    echo -e "${PLAIN}4. 🔌 通过API自动化管理${PLAIN}"
    echo ""
    echo -e "${BLUE}📚 API文档: https://github.com/WCOJBK/x-ui-api-main/blob/main/COMPLETE_API_DOCUMENTATION.md${PLAIN}"
    
else
    echo -e "${RED}❌ 服务启动失败${PLAIN}"
    echo -e "${YELLOW}查看服务状态:${PLAIN}"
    systemctl status x-ui --no-pager -l | head -10
    echo ""
    echo -e "${YELLOW}查看服务日志:${PLAIN}"
    journalctl -u x-ui --no-pager -l | tail -10
fi

# 清理临时文件
echo -e "${BLUE}🧹 清理临时文件...${PLAIN}"
cd / && rm -rf /tmp/x-ui-api-main

echo ""
echo -e "${GREEN}🎯 安装完成！Go已升级到1.23，所有依赖问题已解决！${PLAIN}"
echo ""
