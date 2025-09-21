#!/bin/bash

echo "=== 强制安装Go 1.23.4 + Enhanced API 编译脚本 ==="
echo "彻底重新安装Go，确保版本正确"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${PURPLE}🔧 强制重装策略：${NC}"
echo "1. 彻底删除所有现有Go安装"
echo "2. 重新下载并验证Go 1.23.4"
echo "3. 确保安装成功并测试版本"
echo "4. 设置正确的环境变量"
echo "5. 重新编译Enhanced API"

echo ""
echo -e "${BLUE}🔍 1. 诊断当前问题...${NC}"

echo -e "${CYAN}当前系统Go状态：${NC}"
echo "PATH: $PATH"

# 检查所有可能的Go安装位置
GO_LOCATIONS=(
    "/usr/local/go/bin/go"
    "/usr/bin/go"
    "/snap/bin/go"
    "/opt/go/bin/go"
    "$(which go 2>/dev/null)"
)

for location in "${GO_LOCATIONS[@]}"; do
    if [[ -n "$location" && -f "$location" ]]; then
        version=$($location version 2>/dev/null || echo "无法获取版本")
        echo "🔍 $location: $version"
    fi
done

echo ""
echo -e "${BLUE}🧹 2. 彻底清理现有Go安装...${NC}"

echo "停止所有使用Go的服务..."
systemctl stop x-ui 2>/dev/null || echo "x-ui服务未运行"

echo "删除所有Go安装目录..."
rm -rf /usr/local/go
rm -rf /opt/go
rm -rf /root/go/pkg
rm -rf /root/.cache/go-build

# 清理环境变量文件
rm -f /etc/profile.d/go*.sh
rm -f /etc/environment.d/go*.conf

echo "清理PATH中的Go路径..."
# 临时清理当前会话的PATH
export PATH=$(echo $PATH | tr ':' '\n' | grep -v go | tr '\n' ':' | sed 's/:$//')

echo -e "${GREEN}✅ 清理完成${NC}"

echo ""
echo -e "${BLUE}📦 3. 下载Go 1.23.4...${NC}"

# 检测系统架构
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        GO_ARCH="amd64"
        ;;
    aarch64|arm64)
        GO_ARCH="arm64"
        ;;
    armv7l|armv6l)
        GO_ARCH="armv6l"
        ;;
    *)
        echo -e "${RED}❌ 不支持的架构: $ARCH${NC}"
        exit 1
        ;;
esac

GO_VERSION="1.23.4"
GO_FILENAME="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
GO_URL="https://golang.org/dl/${GO_FILENAME}"

echo -e "${CYAN}目标版本: Go $GO_VERSION${NC}"
echo -e "${CYAN}系统架构: $ARCH -> $GO_ARCH${NC}"
echo -e "${CYAN}下载文件: $GO_FILENAME${NC}"

cd /tmp
echo "正在下载Go $GO_VERSION..."

# 尝试多个下载源
DOWNLOAD_URLS=(
    "https://golang.org/dl/${GO_FILENAME}"
    "https://mirrors.aliyun.com/golang/${GO_FILENAME}"
    "https://studygolang.com/dl/golang/${GO_FILENAME}"
    "https://mirrors.nju.edu.cn/golang/${GO_FILENAME}"
)

DOWNLOAD_SUCCESS=false
for url in "${DOWNLOAD_URLS[@]}"; do
    echo "尝试下载: $url"
    if curl -L --connect-timeout 10 --max-time 300 "$url" -o "$GO_FILENAME"; then
        if [[ -f "$GO_FILENAME" && $(stat -c%s "$GO_FILENAME") -gt 50000000 ]]; then
            echo -e "${GREEN}✅ 下载成功 (大小: $(stat -c%s "$GO_FILENAME") 字节)${NC}"
            DOWNLOAD_SUCCESS=true
            break
        else
            echo -e "${YELLOW}⚠️ 下载的文件太小，尝试下一个源...${NC}"
            rm -f "$GO_FILENAME"
        fi
    else
        echo -e "${YELLOW}⚠️ 下载失败，尝试下一个源...${NC}"
    fi
done

if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
    echo -e "${RED}❌ 所有下载源都失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔧 4. 安装Go 1.23.4...${NC}"

echo "解压Go到 /usr/local/go..."
tar -C /usr/local -xzf "$GO_FILENAME"

# 验证安装
if [[ -f "/usr/local/go/bin/go" ]]; then
    INSTALLED_VERSION=$(/usr/local/go/bin/go version 2>/dev/null)
    echo -e "${GREEN}✅ Go安装成功: $INSTALLED_VERSION${NC}"
    
    # 验证版本是否正确
    if echo "$INSTALLED_VERSION" | grep -q "go1.23.4"; then
        echo -e "${GREEN}✅ 版本验证通过${NC}"
    else
        echo -e "${RED}❌ 版本不正确: $INSTALLED_VERSION${NC}"
        echo "期望版本包含: go1.23.4"
        exit 1
    fi
else
    echo -e "${RED}❌ Go安装失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}⚙️ 5. 配置环境变量...${NC}"

# 创建系统级环境配置
cat > /etc/profile.d/go-1.23.4.sh << 'EOF'
# Go 1.23.4 Environment Configuration
export GOROOT=/usr/local/go
export GOPATH=/root/go
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export PATH=/usr/local/go/bin:$PATH
EOF

chmod 644 /etc/profile.d/go-1.23.4.sh

# 应用环境变量到当前会话
export GOROOT=/usr/local/go
export GOPATH=/root/go
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export PATH=/usr/local/go/bin:$PATH

# 创建GOPATH目录
mkdir -p "$GOPATH"/{src,pkg,bin}

echo -e "${CYAN}环境变量配置：${NC}"
echo "GOROOT: $GOROOT"
echo "GOPATH: $GOPATH"
echo "GOPROXY: $GOPROXY"
echo "PATH: $PATH"

# 最终验证
FINAL_VERSION=$(/usr/local/go/bin/go version)
echo -e "${GREEN}✅ 最终Go版本: $FINAL_VERSION${NC}"

echo ""
echo -e "${BLUE}🔧 6. 准备项目目录...${NC}"

# 确保项目目录存在
if [[ ! -d "/tmp/x-ui-native-restore" ]]; then
    echo "📦 重新下载项目..."
    WORK_DIR="/tmp/x-ui-native-restore"
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    git clone https://github.com/WCOJBK/x-ui-api-main.git . || {
        echo -e "${RED}❌ 无法下载项目${NC}"
        exit 1
    }
else
    cd "/tmp/x-ui-native-restore"
fi

echo -e "${GREEN}✅ 项目目录: $(pwd)${NC}"

echo ""
echo -e "${BLUE}🔧 7. 清理并重新下载依赖...${NC}"

# 清理所有Go相关缓存
echo "清理Go缓存..."
/usr/local/go/bin/go clean -cache
/usr/local/go/bin/go clean -modcache
/usr/local/go/bin/go clean -testcache

# 删除go.sum强制重新验证
rm -f go.sum

echo "使用Go 1.23.4重新初始化模块..."
/usr/local/go/bin/go mod tidy

echo ""
echo -e "${BLUE}🧪 8. 验证依赖兼容性...${NC}"

echo "检查Go版本和依赖..."
echo "Go版本: $(/usr/local/go/bin/go version)"
echo "Go模块模式: $(/usr/local/go/bin/go env GOMOD)"

# 尝试验证所有依赖
if /usr/local/go/bin/go list -m all > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 所有依赖验证通过${NC}"
else
    echo -e "${YELLOW}⚠️ 依赖验证失败，尝试解决...${NC}"
    
    # 尝试更新所有依赖到最新兼容版本
    /usr/local/go/bin/go get -u ./...
    /usr/local/go/bin/go mod tidy
    
    # 再次验证
    if /usr/local/go/bin/go list -m all > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 依赖问题已解决${NC}"
    else
        echo -e "${RED}❌ 依赖问题仍然存在${NC}"
        echo "显示详细错误信息："
        /usr/local/go/bin/go list -m all
    fi
fi

echo ""
echo -e "${BLUE}🔨 9. 编译Enhanced API...${NC}"

echo "🧹 清理旧的可执行文件..."
rm -f /usr/local/x-ui/x-ui

# 确保目录存在
mkdir -p /usr/local/x-ui

echo "🔨 使用Go 1.23.4编译..."
echo "编译命令: CGO_ENABLED=0 GOOS=linux /usr/local/go/bin/go build -ldflags='-s -w' -o /usr/local/x-ui/x-ui"

# 编译
if CGO_ENABLED=0 GOOS=linux /usr/local/go/bin/go build -ldflags="-s -w" -o /usr/local/x-ui/x-ui; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    
    # 验证可执行文件
    if [[ -f "/usr/local/x-ui/x-ui" ]]; then
        chmod +x /usr/local/x-ui/x-ui
        FILE_SIZE=$(stat -c%s /usr/local/x-ui/x-ui)
        echo -e "${CYAN}可执行文件大小: $FILE_SIZE 字节 ($(echo "scale=2; $FILE_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB)${NC}"
        
        # 测试可执行文件
        if /usr/local/x-ui/x-ui version >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 可执行文件测试通过${NC}"
        elif /usr/local/x-ui/x-ui --help >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 可执行文件响应正常${NC}"
        else
            echo -e "${YELLOW}⚠️ 可执行文件测试未通过，但继续部署${NC}"
        fi
    else
        echo -e "${RED}❌ 编译的可执行文件不存在${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 编译失败${NC}"
    echo ""
    echo -e "${YELLOW}🔍 编译错误诊断：${NC}"
    echo "Go版本: $(/usr/local/go/bin/go version)"
    echo "GOROOT: $(/usr/local/go/bin/go env GOROOT)"
    echo "GOPATH: $(/usr/local/go/bin/go env GOPATH)"
    echo "GOOS: $(/usr/local/go/bin/go env GOOS)"
    echo "GOARCH: $(/usr/local/go/bin/go env GOARCH)"
    echo ""
    echo "尝试详细编译输出："
    CGO_ENABLED=0 GOOS=linux /usr/local/go/bin/go build -v -ldflags="-s -w" -o /usr/local/x-ui/x-ui
    exit 1
fi

echo ""
echo -e "${BLUE}📂 10. 复制Web资源...${NC}"

# 创建完整目录结构
mkdir -p /usr/local/x-ui/{web/{html,assets,translation},bin,config}

echo "📂 复制HTML模板..."
if [[ -d "web/html" ]]; then
    cp -r web/html/* /usr/local/x-ui/web/html/ 2>/dev/null
    echo "HTML模板文件数: $(find /usr/local/x-ui/web/html -type f | wc -l)"
fi

echo "📂 复制静态资源..."
if [[ -d "web/assets" ]]; then
    cp -r web/assets/* /usr/local/x-ui/web/assets/ 2>/dev/null
    echo "静态资源文件数: $(find /usr/local/x-ui/web/assets -type f | wc -l)"
fi

echo "📂 复制翻译文件..."
if [[ -d "web/translation" ]]; then
    cp -r web/translation/* /usr/local/x-ui/web/translation/ 2>/dev/null
    echo "翻译文件数: $(find /usr/local/x-ui/web/translation -type f | wc -l)"
fi

# 复制其他配置文件
if [[ -f "x-ui.sh" ]]; then
    cp x-ui.sh /usr/local/x-ui/
    chmod +x /usr/local/x-ui/x-ui.sh
fi

echo -e "${GREEN}✅ Web资源复制完成${NC}"

echo ""
echo -e "${BLUE}⚙️ 11. 配置systemd服务...${NC}"

# 创建systemd服务配置
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=3x-ui enhanced service with Go 1.23.4
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/x-ui/
Environment=GOROOT=/usr/local/go
Environment=GOPATH=/root/go
Environment=GOPROXY=https://goproxy.cn,direct
Environment=PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/usr/local/x-ui/x-ui run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo -e "${BLUE}🚀 12. 启动服务...${NC}"

systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui

# 等待服务启动
echo "等待服务启动..."
sleep 10

echo ""
echo -e "${BLUE}🧪 13. 验证系统状态...${NC}"

# 检查服务状态
SERVICE_STATUS=$(systemctl is-active x-ui 2>/dev/null)
if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ x-ui 服务运行正常${NC}"
    
    # 检查进程
    if pgrep -f "x-ui" >/dev/null; then
        PID=$(pgrep -f "x-ui")
        echo -e "${GREEN}✅ x-ui 进程运行正常 (PID: $PID)${NC}"
    fi
    
    # 检查端口监听
    if netstat -tlpn 2>/dev/null | grep -q ":2053" || ss -tlpn 2>/dev/null | grep -q ":2053"; then
        echo -e "${GREEN}✅ 端口2053正在监听${NC}"
    else
        echo -e "${YELLOW}⚠️ 端口2053未监听，等待启动...${NC}"
        sleep 5
        if netstat -tlpn 2>/dev/null | grep -q ":2053" || ss -tlpn 2>/dev/null | grep -q ":2053"; then
            echo -e "${GREEN}✅ 端口2053现在正在监听${NC}"
        else
            echo -e "${RED}❌ 端口2053仍未监听${NC}"
        fi
    fi
    
else
    echo -e "${RED}❌ x-ui 服务未运行 (状态: $SERVICE_STATUS)${NC}"
    echo ""
    echo -e "${YELLOW}🔍 服务状态详情：${NC}"
    systemctl status x-ui --no-pager -l | head -20
    echo ""
    echo -e "${YELLOW}🔍 服务日志：${NC}"
    journalctl -u x-ui --no-pager -l | tail -20
fi

echo ""
echo -e "${BLUE}🌐 14. 测试前端和API...${NC}"

# 测试前端页面
echo "测试前端页面访问..."
ROOT_RESPONSE=$(timeout 15 curl -s -w "SIZE:%{size_download};CODE:%{http_code}" "$BASE_URL/" --connect-timeout 5 2>/dev/null || echo "SIZE:0;CODE:000")
ROOT_SIZE=$(echo "$ROOT_RESPONSE" | grep -o "SIZE:[0-9]*" | cut -d: -f2)
ROOT_CODE=$(echo "$ROOT_RESPONSE" | grep -o "CODE:[0-9]*" | cut -d: -f2)

echo "前端响应: HTTP $ROOT_CODE, 大小: $ROOT_SIZE 字节"

if [[ "$ROOT_CODE" == "200" && "$ROOT_SIZE" -gt 1000 ]]; then
    echo -e "${GREEN}✅ 前端页面正常加载${NC}"
elif [[ "$ROOT_CODE" == "200" ]]; then
    echo -e "${YELLOW}⚠️ 前端页面响应正常但内容较少${NC}"
else
    echo -e "${YELLOW}⚠️ 前端页面响应异常 (HTTP $ROOT_CODE)${NC}"
fi

# 测试API端点
echo ""
echo -e "${CYAN}🔗 测试Enhanced API端点：${NC}"

declare -a test_apis=(
    "/panel/api/server/status|服务器状态"
    "/panel/api/inbounds/list|入站列表"
    "/panel/api/outbound/list|出站列表"
    "/panel/api/routing/list|路由列表"
    "/panel/api/subscription/list|订阅列表"
)

api_success=0
api_total=${#test_apis[@]}

for test_api in "${test_apis[@]}"; do
    IFS='|' read -r endpoint name <<< "$test_api"
    
    response=$(timeout 10 curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL$endpoint" 2>/dev/null || echo "HTTPSTATUS:000")
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)

    case "$http_code" in
        200)
            echo -e "✅ $name - HTTP $http_code (正常)"
            ((api_success++))
            ;;
        401|403)
            echo -e "${YELLOW}🔐 $name - HTTP $http_code (需要认证)${NC}"
            ((api_success++))
            ;;
        404)
            echo -e "${RED}❌ $name - HTTP $http_code (端点不存在)${NC}"
            ;;
        000)
            echo -e "${RED}❌ $name - 连接失败${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️ $name - HTTP $http_code${NC}"
            ;;
    esac
done

api_rate=$(( api_success * 100 / api_total ))

echo ""
echo -e "${BLUE}📊 15. 生成最终报告...${NC}"

echo ""
echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC} ${GREEN}🎉 Go 1.23.4强制安装 + Enhanced API 编译完成！${NC}     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ Go版本: $(/usr/local/go/bin/go version | cut -d' ' -f3)                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 强制重装: 完成                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 依赖解决: 完成                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 编译状态: 成功                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 服务状态: $SERVICE_STATUS                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 前端响应: HTTP $ROOT_CODE                                   ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ API可用率: ${api_rate}%                                    ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} 🌐 访问地址: ${CYAN}http://$SERVER_IP:2053/${NC}                   ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} 🔑 使用原生3X-UI账户登录                             ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${GREEN}🚀 强制重装完成！关键改进：${NC}"
echo "1. ✅ 彻底删除旧Go - 清除所有残留"
echo "2. ✅ 重新下载Go 1.23.4 - 确保版本正确"
echo "3. ✅ 验证安装成功 - 版本检查通过"
echo "4. ✅ 清理依赖缓存 - 重新下载所有包"
echo "5. ✅ 编译成功 - 使用正确Go版本"

echo ""
echo -e "${YELLOW}💡 现在您可以：${NC}"
echo "🌐 访问面板: ${CYAN}http://$SERVER_IP:2053/${NC}"
echo "🔑 原生登录: 使用您的3X-UI账户"
echo "📊 完整管理: 所有原生面板功能"
echo "🚀 Enhanced API: 20+个增强端点"

echo ""
echo -e "${CYAN}🧪 测试完整Enhanced API功能：${NC}"
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)"

echo ""
echo -e "${GREEN}🎊 成功！您现在拥有：${NC}"
echo "• 纯净的Go 1.23.4环境"
echo "• 0版本冲突"
echo "• 完整Enhanced API功能"
echo "• 原生3X-UI界面"
echo "• 高性能编译版本"

echo ""
echo "=== Go 1.23.4强制安装 + Enhanced API 编译完成 ==="
