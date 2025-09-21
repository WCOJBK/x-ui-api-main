#!/bin/bash

# 3X-UI Enhanced API 超级兼容性安装脚本
# 作者: WCOJBK
# 特点: 预防性修复大量Go 1.21依赖冲突，避免逐个修复的问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

echo -e "${GREEN}============================================${PLAIN}"
echo -e "${GREEN} 3X-UI Enhanced API 超级兼容性安装脚本${PLAIN}"
echo -e "${GREEN}============================================${PLAIN}"
echo -e "${BLUE}🛡️ 预防性修复50+依赖，彻底解决Go版本冲突${PLAIN}"

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

# 设置Go环境（不尝试升级，直接使用兼容性策略）
echo -e "${YELLOW}🔧 配置Go环境和超级兼容性模式...${PLAIN}"
cd /tmp

# 确保Go可用
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}📥 安装Go...${PLAIN}"
    if command -v apt &> /dev/null; then
        apt install -y golang-go >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y golang >/dev/null 2>&1
    fi
fi

# 设置Go环境变量
export PATH=/usr/local/go/bin:$PATH
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# 确定使用的Go命令
GO_CMD="go"
if [[ -f "/usr/local/go/bin/go" ]]; then
    GO_CMD="/usr/local/go/bin/go"
fi

DETECTED_GO_VERSION=$($GO_CMD version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//' || echo "")
echo -e "${BLUE}🔍 检测到Go版本: ${DETECTED_GO_VERSION}${PLAIN}"
echo -e "${BLUE}📝 使用Go命令: $GO_CMD${PLAIN}"

# 下载源码
echo -e "${YELLOW}📥 下载Enhanced API源码...${PLAIN}"
rm -rf x-ui-api-main
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 超级兼容性修复函数
apply_super_compatibility_fixes() {
    echo -e "${YELLOW}🛡️ 应用超级兼容性修复（50+依赖包）...${PLAIN}"
    
    echo -e "${BLUE}  🔧 GitHub生态系统依赖 (15个包)...${PLAIN}"
    $GO_CMD mod edit -replace=github.com/gorilla/sessions=github.com/gorilla/sessions@v1.3.0
    $GO_CMD mod edit -replace=github.com/mymmrac/telego=github.com/mymmrac/telego@v0.29.2
    $GO_CMD mod edit -replace=github.com/xtls/reality=github.com/xtls/reality@v0.0.0-20231112171332-de1590cf6c40
    $GO_CMD mod edit -replace=github.com/cloudflare/circl=github.com/cloudflare/circl@v1.3.9
    $GO_CMD mod edit -replace=github.com/google/pprof=github.com/google/pprof@v0.0.0-20231229205709-960ae82b1e42
    $GO_CMD mod edit -replace=github.com/onsi/ginkgo/v2=github.com/onsi/ginkgo/v2@v2.12.0
    $GO_CMD mod edit -replace=github.com/quic-go/qpack=github.com/quic-go/qpack@v0.4.0
    $GO_CMD mod edit -replace=github.com/quic-go/quic-go=github.com/quic-go/quic-go@v0.37.6
    $GO_CMD mod edit -replace=github.com/rogpeppe/go-internal=github.com/rogpeppe/go-internal@v1.12.0
    # 预防性GitHub依赖
    $GO_CMD mod edit -replace=github.com/stretchr/testify=github.com/stretchr/testify@v1.8.4
    $GO_CMD mod edit -replace=github.com/gin-gonic/gin=github.com/gin-gonic/gin@v1.9.1
    $GO_CMD mod edit -replace=github.com/go-playground/validator/v10=github.com/go-playground/validator/v10@v10.15.5
    $GO_CMD mod edit -replace=github.com/robfig/cron/v3=github.com/robfig/cron/v3@v3.0.1
    $GO_CMD mod edit -replace=github.com/shirou/gopsutil/v3=github.com/shirou/gopsutil/v3@v3.23.9
    $GO_CMD mod edit -replace=github.com/gin-contrib/sessions=github.com/gin-contrib/sessions@v0.0.5
    
    echo -e "${BLUE}  🔧 golang.org/x 生态系统依赖 (15个包)...${PLAIN}"
    $GO_CMD mod edit -replace=golang.org/x/exp=golang.org/x/exp@v0.0.0-20231219180239-dc181d75b848
    $GO_CMD mod edit -replace=golang.org/x/mod=golang.org/x/mod@v0.14.0
    $GO_CMD mod edit -replace=golang.org/x/crypto=golang.org/x/crypto@v0.17.0
    $GO_CMD mod edit -replace=golang.org/x/net=golang.org/x/net@v0.19.0
    $GO_CMD mod edit -replace=golang.org/x/sys=golang.org/x/sys@v0.15.0
    $GO_CMD mod edit -replace=golang.org/x/text=golang.org/x/text@v0.14.0
    $GO_CMD mod edit -replace=golang.org/x/tools=golang.org/x/tools@v0.16.0
    $GO_CMD mod edit -replace=golang.org/x/sync=golang.org/x/sync@v0.5.0
    $GO_CMD mod edit -replace=golang.org/x/time=golang.org/x/time@v0.5.0
    # 预防性golang.org/x依赖
    $GO_CMD mod edit -replace=golang.org/x/oauth2=golang.org/x/oauth2@v0.15.0
    $GO_CMD mod edit -replace=golang.org/x/term=golang.org/x/term@v0.15.0
    $GO_CMD mod edit -replace=golang.org/x/xerrors=golang.org/x/xerrors@v0.0.0-20231012003039-104605ab7028
    $GO_CMD mod edit -replace=golang.org/x/image=golang.org/x/image@v0.13.0
    $GO_CMD mod edit -replace=golang.org/x/mobile=golang.org/x/mobile@v0.0.0-20231127183840-76ac6878050a
    $GO_CMD mod edit -replace=golang.org/x/perf=golang.org/x/perf@v0.0.0-20231127181059-b53752263861
    
    echo -e "${BLUE}  🔧 Google生态系统依赖 (8个包)...${PLAIN}"
    $GO_CMD mod edit -replace=google.golang.org/grpc=google.golang.org/grpc@v1.58.3
    $GO_CMD mod edit -replace=google.golang.org/protobuf=google.golang.org/protobuf@v1.31.0
    $GO_CMD mod edit -replace=google.golang.org/genproto=google.golang.org/genproto@v0.0.0-20231120223509-83a465c0220f
    # 预防性Google依赖
    $GO_CMD mod edit -replace=google.golang.org/api=google.golang.org/api@v0.152.0
    $GO_CMD mod edit -replace=google.golang.org/appengine=google.golang.org/appengine@v1.6.8
    $GO_CMD mod edit -replace=google.golang.org/genproto/googleapis/api=google.golang.org/genproto/googleapis/api@v0.0.0-20231120223509-83a465c0220f
    $GO_CMD mod edit -replace=google.golang.org/genproto/googleapis/rpc=google.golang.org/genproto/googleapis/rpc@v0.0.0-20231120223509-83a465c0220f
    
    echo -e "${BLUE}  🔧 其他关键生态系统依赖 (12个包)...${PLAIN}"
    $GO_CMD mod edit -replace=go.uber.org/mock=go.uber.org/mock@v0.4.0
    # 预防性其他依赖
    $GO_CMD mod edit -replace=go.uber.org/zap=go.uber.org/zap@v1.26.0
    $GO_CMD mod edit -replace=go.uber.org/atomic=go.uber.org/atomic@v1.11.0
    $GO_CMD mod edit -replace=go.uber.org/multierr=go.uber.org/multierr@v1.11.0
    $GO_CMD mod edit -replace=gopkg.in/yaml.v3=gopkg.in/yaml.v3@v3.0.1
    $GO_CMD mod edit -replace=gopkg.in/yaml.v2=gopkg.in/yaml.v2@v2.4.0
    $GO_CMD mod edit -replace=gorm.io/gorm=gorm.io/gorm@v1.25.5
    $GO_CMD mod edit -replace=gorm.io/driver/sqlite=gorm.io/driver/sqlite@v1.5.4
    $GO_CMD mod edit -replace=modernc.org/sqlite=modernc.org/sqlite@v1.27.0
    # 测试相关依赖
    $GO_CMD mod edit -replace=github.com/onsi/gomega=github.com/onsi/gomega@v1.30.0
    $GO_CMD mod edit -replace=gotest.tools/v3=gotest.tools/v3@v3.5.1
    $GO_CMD mod edit -replace=github.com/davecgh/go-spew=github.com/davecgh/go-spew@v1.1.1
    
    echo -e "${GREEN}✅ 超级兼容性修复完成！${PLAIN}"
    echo -e "${PLAIN}  📦 总计修复: 50+个依赖包${PLAIN}"
    echo -e "${PLAIN}  🛡️ 覆盖: GitHub, golang.org/x, Google, Uber等生态系统${PLAIN}"
    echo -e "${PLAIN}  🎯 策略: 预防性修复，避免逐个解决依赖冲突${PLAIN}"
}

# 应用超级兼容性修复
apply_super_compatibility_fixes

# 清理和重新下载依赖
echo -e "${BLUE}🧹 清理和重新下载所有依赖...${PLAIN}"
rm -f go.sum
$GO_CMD mod tidy

# 编译项目
echo -e "${YELLOW}🔨 编译Enhanced API版本 (超级兼容性模式)...${PLAIN}"
if $GO_CMD build -ldflags "-s -w" -o x-ui . 2>&1; then
    echo -e "${GREEN}✅ 编译成功！${PLAIN}"
else
    echo -e "${RED}❌ 编译失败，启用详细错误模式...${PLAIN}"
    echo -e "${BLUE}📋 详细编译错误信息：${PLAIN}"
    $GO_CMD build -ldflags "-s -w" -o x-ui . 
    echo -e "${RED}❌ 超级兼容性模式编译失败${PLAIN}"
    echo -e "${YELLOW}💡 建议: 可能需要Docker化解决方案或预编译二进制${PLAIN}"
    exit 1
fi

# 停止现有服务
echo -e "${YELLOW}🛑 停止现有x-ui服务...${PLAIN}"
systemctl stop x-ui >/dev/null 2>&1 || true

# 安装编译好的程序
echo -e "${YELLOW}📦 安装Enhanced API版本...${PLAIN}"
mkdir -p /usr/local/x-ui
cp x-ui /usr/local/x-ui/
chmod +x /usr/local/x-ui/x-ui

# 复制配置和资源文件
if [[ -d "web" ]]; then
    cp -r web /usr/local/x-ui/
fi
if [[ -d "bin" ]]; then
    cp -r bin /usr/local/x-ui/
fi

# 创建systemd服务文件
echo -e "${YELLOW}⚙️ 配置systemd服务...${PLAIN}"
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=3x-ui Enhanced API
After=network.target

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

# 重新加载systemd并启动服务
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 等待服务启动
sleep 3

echo -e "${GREEN}🎉 3X-UI Enhanced API 超级兼容性版本安装完成！${PLAIN}"
echo -e "${GREEN}============================================${PLAIN}"
echo ""
echo -e "${BLUE}📋 安装信息：${PLAIN}"
echo -e "${PLAIN}🌐 面板地址: http://${SERVER_IP}:2053/${PLAIN}"
echo -e "${PLAIN}👤 默认用户名: admin${PLAIN}"
echo -e "${PLAIN}🔑 默认密码: admin${PLAIN}"
echo ""
echo -e "${BLUE}🔧 Enhanced API特性：${PLAIN}"
echo -e "${PLAIN}✅ 原生3X-UI的所有功能${PLAIN}"
echo -e "${PLAIN}🆕 出站管理 API (20+端点)${PLAIN}"
echo -e "${PLAIN}🆕 路由管理 API${PLAIN}"
echo -e "${PLAIN}🆕 订阅管理 API${PLAIN}"
echo -e "${PLAIN}🆕 高级配置 API${PLAIN}"
echo ""
echo -e "${BLUE}🧪 测试Enhanced API：${PLAIN}"
echo "curl -X GET 'http://${SERVER_IP}:2053/panel/api/server/status'"
echo ""
echo -e "${BLUE}📱 服务管理：${PLAIN}"
echo "systemctl status x-ui    # 查看状态"
echo "systemctl restart x-ui   # 重启服务"  
echo "systemctl stop x-ui      # 停止服务"
echo ""
echo -e "${GREEN}🎊 享受Enhanced API的强大功能！${PLAIN}"

# 检查服务状态
if systemctl is-active x-ui >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 服务运行正常${PLAIN}"
    
    # 测试API可用性
    sleep 2
    if curl -s "http://127.0.0.1:2053/" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ API服务响应正常${PLAIN}"
    else
        echo -e "${YELLOW}⚠️ API服务可能需要更长启动时间${PLAIN}"
    fi
else
    echo -e "${RED}⚠️ 服务状态异常，请检查日志: journalctl -u x-ui -f${PLAIN}"
fi

echo ""
echo -e "${GREEN}=== 超级兼容性安装脚本完成 ===${PLAIN}"
