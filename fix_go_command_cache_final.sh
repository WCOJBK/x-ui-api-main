#!/bin/bash

echo "=== Go命令缓存修复 + 最终编译脚本 ==="
echo "解决解压成功但命令缓存旧版本的问题"

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
echo -e "${PURPLE}🔧 缓存修复策略：${NC}"
echo "1. 验证Go 1.23.4已正确解压"
echo "2. 清除所有shell命令缓存"
echo "3. 修复PATH优先级问题"
echo "4. 强制使用正确的go命令"
echo "5. 重新编译Enhanced API"

echo ""
echo -e "${BLUE}🔍 1. 详细验证Go安装状态...${NC}"

# 检查VERSION文件
if [[ -f "/usr/local/go/VERSION" ]]; then
    VERSION_CONTENT=$(cat /usr/local/go/VERSION)
    echo -e "${CYAN}VERSION文件内容: $VERSION_CONTENT${NC}"
    
    if echo "$VERSION_CONTENT" | grep -q "go1.23.4"; then
        echo -e "${GREEN}✅ Go 1.23.4 确实已正确安装${NC}"
    else
        echo -e "${RED}❌ VERSION文件不正确${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ VERSION文件不存在${NC}"
    exit 1
fi

# 检查二进制文件
if [[ -f "/usr/local/go/bin/go" ]]; then
    echo -e "${CYAN}Go可执行文件存在: /usr/local/go/bin/go${NC}"
    ls -la /usr/local/go/bin/go
    
    # 直接测试二进制文件
    echo ""
    echo -e "${CYAN}直接测试二进制文件：${NC}"
    DIRECT_VERSION=$(/usr/local/go/bin/go version 2>/dev/null || echo "执行失败")
    echo "直接执行结果: $DIRECT_VERSION"
    
    if echo "$DIRECT_VERSION" | grep -q "go1.23.4"; then
        echo -e "${GREEN}✅ 二进制文件是正确的Go 1.23.4${NC}"
    else
        echo -e "${RED}❌ 二进制文件仍显示错误版本${NC}"
        
        # 检查文件是否损坏
        if file /usr/local/go/bin/go | grep -q "ELF"; then
            echo -e "${CYAN}文件格式正常，可能是其他问题${NC}"
        else
            echo -e "${RED}❌ 二进制文件损坏${NC}"
            exit 1
        fi
    fi
else
    echo -e "${RED}❌ Go可执行文件不存在${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🧹 2. 清除所有命令缓存...${NC}"

# 清除bash命令缓存
echo "清除bash命令哈希缓存..."
hash -r 2>/dev/null || true
type -P go 2>/dev/null && hash -d go 2>/dev/null || true

# 清除which缓存（如果存在）
which go >/dev/null 2>&1 && echo "当前which go: $(which go)"

# 检查所有可能的go命令位置
echo ""
echo -e "${CYAN}检查系统中所有go命令：${NC}"
find /usr -name "go" -type f -executable 2>/dev/null | grep -E "bin/go$" | while read -r go_path; do
    if [[ -f "$go_path" ]]; then
        go_version=$($go_path version 2>/dev/null || echo "无法执行")
        echo "🔍 $go_path: $go_version"
    fi
done

# 检查snap中的go
if [[ -f "/snap/bin/go" ]]; then
    snap_version=$(/snap/bin/go version 2>/dev/null || echo "无法执行")
    echo "🔍 /snap/bin/go: $snap_version"
fi

echo ""
echo -e "${BLUE}🔧 3. 修复PATH和环境变量...${NC}"

# 备份当前PATH
OLD_PATH="$PATH"
echo "原PATH: $OLD_PATH"

# 清理PATH中所有go相关路径，然后添加正确路径
echo "清理并重建PATH..."
NEW_PATH="/usr/local/go/bin"

# 添加其他必要路径，但确保go路径在最前面
for path_dir in /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/games /usr/local/games; do
    if [[ -d "$path_dir" ]]; then
        NEW_PATH="$NEW_PATH:$path_dir"
    fi
done

# 如果有snap，添加到最后
if [[ -d "/snap/bin" ]]; then
    NEW_PATH="$NEW_PATH:/snap/bin"
fi

export PATH="$NEW_PATH"
echo "新PATH: $PATH"

# 更新系统环境变量配置
echo ""
echo "更新系统环境变量文件..."

# 删除所有旧的Go环境文件
rm -f /etc/profile.d/go*.sh

# 创建新的环境文件，确保优先级最高
cat > /etc/profile.d/00-go-1.23.4.sh << 'EOF'
# Go 1.23.4 Environment Configuration - Highest Priority
export GOROOT=/usr/local/go
export GOPATH=/root/go
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GO111MODULE=on
# Ensure Go 1.23.4 has highest priority in PATH
export PATH=/usr/local/go/bin:$PATH
EOF

chmod 644 /etc/profile.d/00-go-1.23.4.sh

# 应用环境变量
export GOROOT=/usr/local/go
export GOPATH=/root/go  
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GO111MODULE=on

# 创建GOPATH目录
mkdir -p "$GOPATH"/{src,pkg,bin}

# 再次清除命令缓存
hash -r 2>/dev/null || true

echo ""
echo -e "${BLUE}🧪 4. 验证修复结果...${NC}"

echo "重新测试go命令..."
sleep 2

# 测试which命令
WHICH_GO=$(which go 2>/dev/null)
echo "which go: $WHICH_GO"

# 测试go version
echo ""
echo "测试go version命令："
GO_VERSION_RESULT=$(go version 2>/dev/null || echo "命令执行失败")
echo "go version结果: $GO_VERSION_RESULT"

# 再次直接测试二进制文件
echo ""
echo "再次直接测试二进制文件："
DIRECT_VERSION_2=$(/usr/local/go/bin/go version 2>/dev/null || echo "执行失败")
echo "直接执行结果: $DIRECT_VERSION_2"

# 验证是否修复成功
if echo "$GO_VERSION_RESULT" | grep -q "go1.23.4"; then
    echo -e "${GREEN}✅ Go命令缓存修复成功！现在使用Go 1.23.4${NC}"
elif echo "$DIRECT_VERSION_2" | grep -q "go1.23.4"; then
    echo -e "${YELLOW}⚠️ 直接执行正确，但go命令仍有问题，强制使用绝对路径${NC}"
    
    # 创建别名强制使用正确路径
    echo 'alias go="/usr/local/go/bin/go"' >> /root/.bashrc
    echo 'alias gofmt="/usr/local/go/bin/gofmt"' >> /root/.bashrc
    
    # 当前会话也设置别名
    alias go="/usr/local/go/bin/go"
    alias gofmt="/usr/local/go/bin/gofmt"
    
    # 测试别名
    GO_VERSION_ALIAS=$(go version 2>/dev/null || echo "别名失败")
    echo "使用别名测试: $GO_VERSION_ALIAS"
    
    if echo "$GO_VERSION_ALIAS" | grep -q "go1.23.4"; then
        echo -e "${GREEN}✅ 别名修复成功！${NC}"
    else
        echo -e "${RED}❌ 别名也失败了${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 仍然无法使用Go 1.23.4${NC}"
    echo ""
    echo -e "${YELLOW}🔍 进一步诊断：${NC}"
    echo "PATH: $PATH"
    echo "GOROOT: $GOROOT"
    
    # 尝试强制重新链接
    echo ""
    echo "尝试创建强制链接..."
    rm -f /usr/local/bin/go /usr/local/bin/gofmt
    ln -sf /usr/local/go/bin/go /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    
    # 测试链接
    LINK_VERSION=$(/usr/local/bin/go version 2>/dev/null || echo "链接失败")
    echo "链接测试结果: $LINK_VERSION"
    
    if echo "$LINK_VERSION" | grep -q "go1.23.4"; then
        echo -e "${GREEN}✅ 强制链接成功！${NC}"
        export PATH="/usr/local/bin:$PATH"
    else
        echo -e "${RED}❌ 所有方法都失败了${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}🔧 5. 准备项目编译...${NC}"

# 确保项目目录存在
if [[ ! -d "/tmp/x-ui-native-restore" ]]; then
    echo "📦 重新下载项目..."
    WORK_DIR="/tmp/x-ui-native-restore" 
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    if git clone https://github.com/WCOJBK/x-ui-api-main.git . 2>/dev/null; then
        echo -e "${GREEN}✅ 项目下载成功${NC}"
    else
        echo -e "${RED}❌ 项目下载失败${NC}"
        exit 1
    fi
else
    cd "/tmp/x-ui-native-restore"
    echo -e "${GREEN}✅ 使用现有项目目录${NC}"
fi

echo -e "${CYAN}项目目录: $(pwd)${NC}"

echo ""
echo -e "${BLUE}🔧 6. 清理并重新下载依赖...${NC}"

# 使用正确的go命令（可能是别名或链接）
GO_CMD="go"
if ! $GO_CMD version | grep -q "go1.23.4"; then
    GO_CMD="/usr/local/go/bin/go"
    echo "使用绝对路径: $GO_CMD"
fi

# 验证go命令
FINAL_GO_VERSION=$($GO_CMD version 2>/dev/null)
echo "最终使用的Go版本: $FINAL_GO_VERSION"

if ! echo "$FINAL_GO_VERSION" | grep -q "go1.23.4"; then
    echo -e "${RED}❌ 仍无法使用Go 1.23.4编译${NC}"
    exit 1
fi

# 清理依赖缓存
echo "清理Go缓存..."
$GO_CMD clean -cache 2>/dev/null || true
$GO_CMD clean -modcache 2>/dev/null || true
$GO_CMD clean -testcache 2>/dev/null || true

# 删除go.sum
rm -f go.sum

echo "使用Go 1.23.4重新下载依赖..."
if $GO_CMD mod tidy 2>&1; then
    echo -e "${GREEN}✅ 依赖下载成功${NC}"
else
    echo -e "${RED}❌ 依赖下载失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔨 7. 编译Enhanced API...${NC}"

systemctl stop x-ui 2>/dev/null || true
rm -f /usr/local/x-ui/x-ui
mkdir -p /usr/local/x-ui

echo "🔨 使用Go 1.23.4编译..."
echo "编译命令: CGO_ENABLED=0 GOOS=linux $GO_CMD build -ldflags='-s -w' -o /usr/local/x-ui/x-ui"

if CGO_ENABLED=0 GOOS=linux $GO_CMD build -ldflags="-s -w" -o /usr/local/x-ui/x-ui 2>&1; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    
    if [[ -f "/usr/local/x-ui/x-ui" ]]; then
        chmod +x /usr/local/x-ui/x-ui
        FILE_SIZE=$(stat -c%s /usr/local/x-ui/x-ui)
        echo -e "${CYAN}可执行文件大小: $FILE_SIZE 字节 ($(echo "scale=1; $FILE_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB)${NC}"
        
        if [[ $FILE_SIZE -gt 10000000 ]]; then
            echo -e "${GREEN}✅ 可执行文件大小正常${NC}"
        else
            echo -e "${YELLOW}⚠️ 可执行文件可能过小${NC}"
        fi
    else
        echo -e "${RED}❌ 编译失败，可执行文件不存在${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 编译失败${NC}"
    echo ""
    echo "Go环境信息："
    $GO_CMD env GOROOT
    $GO_CMD env GOOS
    $GO_CMD env GOARCH
    exit 1
fi

echo ""
echo -e "${BLUE}📂 8. 复制Web资源...${NC}"

mkdir -p /usr/local/x-ui/{web/{html,assets,translation},bin,config}

echo "📂 复制资源文件..."
[[ -d "web/html" ]] && cp -r web/html/* /usr/local/x-ui/web/html/ 2>/dev/null
[[ -d "web/assets" ]] && cp -r web/assets/* /usr/local/x-ui/web/assets/ 2>/dev/null
[[ -d "web/translation" ]] && cp -r web/translation/* /usr/local/x-ui/web/translation/ 2>/dev/null
[[ -f "x-ui.sh" ]] && cp x-ui.sh /usr/local/x-ui/ && chmod +x /usr/local/x-ui/x-ui.sh

echo -e "${GREEN}✅ Web资源复制完成${NC}"

echo ""
echo -e "${BLUE}🚀 9. 启动服务...${NC}"

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
Environment=PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/usr/local/x-ui/x-ui run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui

echo "等待服务启动..."
sleep 10

echo ""
echo -e "${BLUE}🧪 10. 最终验证...${NC}"

SERVICE_STATUS=$(systemctl is-active x-ui 2>/dev/null)
echo "服务状态: $SERVICE_STATUS"

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ 服务运行正常${NC}"
    
    # 测试前端
    ROOT_SIZE=$(timeout 15 curl -s "$BASE_URL/" --connect-timeout 5 | wc -c 2>/dev/null || echo "0")
    echo "前端响应大小: $ROOT_SIZE 字节"
    
    if [[ $ROOT_SIZE -gt 1000 ]]; then
        echo -e "${GREEN}✅ 前端正常${NC}"
    else
        echo -e "${YELLOW}⚠️ 前端响应较小${NC}"
    fi
    
    # 测试API
    echo ""
    echo -e "${CYAN}测试Enhanced API端点：${NC}"
    API_RESPONSE=$(timeout 10 curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/panel/api/server/status" 2>/dev/null || echo "HTTPSTATUS:000")
    API_CODE=$(echo "$API_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    
    if [[ "$API_CODE" == "200" ]]; then
        echo -e "${GREEN}✅ Enhanced API正常响应${NC}"
    elif [[ "$API_CODE" == "401" || "$API_CODE" == "403" ]]; then
        echo -e "${YELLOW}🔐 API需要认证（正常）${NC}"
    else
        echo -e "${YELLOW}⚠️ API响应: HTTP $API_CODE${NC}"
    fi
else
    echo -e "${RED}❌ 服务未正常启动${NC}"
    systemctl status x-ui --no-pager -l | head -15
fi

echo ""
echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC} ${GREEN}🎉 Go命令缓存修复 + Enhanced API 编译完成！${NC}       ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ Go版本: $($GO_CMD version | cut -d' ' -f3 2>/dev/null || echo "go1.23.4")                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 缓存修复: 完成                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 编译状态: 成功                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 服务状态: $SERVICE_STATUS                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} 🌐 访问地址: ${CYAN}http://$SERVER_IP:2053/${NC}                   ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} 🔑 使用原生3X-UI账户登录                             ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${GREEN}🎊 缓存修复完成！解决了：${NC}"
echo "1. ✅ Shell命令缓存问题 - 清除所有哈希缓存"
echo "2. ✅ PATH优先级问题 - 确保Go 1.23.4优先"
echo "3. ✅ 环境变量冲突 - 重新配置系统环境"
echo "4. ✅ 别名和链接 - 多重备用方案"
echo "5. ✅ 编译成功 - 使用正确Go版本"

echo ""
echo -e "${CYAN}🧪 测试完整Enhanced API功能：${NC}"
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)"

echo ""
echo -e "${YELLOW}💡 Go命令现已修复，您可以：${NC}"
echo "🌐 访问面板: ${CYAN}http://$SERVER_IP:2053/${NC}"
echo "🔑 原生登录: 使用您的3X-UI账户"
echo "📊 完整管理: 所有原生面板功能"
echo "🚀 Enhanced API: 20+个增强端点"

echo ""
echo "=== Go命令缓存修复 + Enhanced API 编译完成 ==="
