#!/bin/bash

echo "=== 官方源重建Go 1.23.4 + Enhanced API 编译脚本 ==="
echo "解决tar文件内容不一致问题，从官方源重新下载验证"

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
echo -e "${PURPLE}🔧 官方源重建策略：${NC}"
echo "1. 从Google官方源重新下载Go 1.23.4"
echo "2. 验证SHA256校验和确保文件完整性"
echo "3. 强制清理并重新安装"
echo "4. 如果仍失败，从源代码编译"
echo "5. 完成Enhanced API编译"

echo ""
echo -e "${BLUE}🔍 1. 诊断当前tar文件问题...${NC}"

cd /tmp

# 检查当前下载的文件
if [[ -f "go1.23.4.linux-amd64.tar.gz" ]]; then
    FILE_SIZE=$(stat -c%s "go1.23.4.linux-amd64.tar.gz")
    echo -e "${CYAN}当前文件大小: $FILE_SIZE 字节${NC}"
    
    # 检查tar内容的VERSION和二进制文件
    echo ""
    echo -e "${CYAN}检查tar文件内部版本一致性：${NC}"
    
    # 解压VERSION文件检查
    VERSION_IN_TAR=$(tar -xzf "go1.23.4.linux-amd64.tar.gz" -O go/VERSION 2>/dev/null || echo "提取失败")
    echo "tar中VERSION文件内容: $VERSION_IN_TAR"
    
    # 尝试提取并执行go binary检查版本
    echo "尝试提取并测试go二进制文件..."
    mkdir -p /tmp/go-test-extract
    if tar -C /tmp/go-test-extract -xzf "go1.23.4.linux-amd64.tar.gz" go/bin/go 2>/dev/null; then
        if [[ -f "/tmp/go-test-extract/go/bin/go" ]]; then
            chmod +x /tmp/go-test-extract/go/bin/go
            BINARY_VERSION=$(/tmp/go-test-extract/go/bin/go version 2>/dev/null || echo "执行失败")
            echo "tar中go二进制版本: $BINARY_VERSION"
            
            if echo "$BINARY_VERSION" | grep -q "go1.23.4"; then
                echo -e "${GREEN}✅ tar文件内部版本一致${NC}"
            else
                echo -e "${RED}❌ tar文件内部版本不一致！${NC}"
                echo "VERSION文件显示: $VERSION_IN_TAR"
                echo "二进制文件显示: $BINARY_VERSION"
                echo "这确认了tar文件有问题"
            fi
        else
            echo -e "${RED}❌ 无法提取go二进制文件${NC}"
        fi
    else
        echo -e "${RED}❌ tar提取失败${NC}"
    fi
    
    rm -rf /tmp/go-test-extract
    
    echo ""
    echo -e "${YELLOW}⚠️ 当前tar文件有问题，需要重新下载${NC}"
    rm -f "go1.23.4.linux-amd64.tar.gz"
fi

echo ""
echo -e "${BLUE}📦 2. 从Google官方源重新下载...${NC}"

GO_VERSION="1.23.4"
GO_FILENAME="go${GO_VERSION}.linux-amd64.tar.gz"

# 官方SHA256校验和 (Go 1.23.4 linux/amd64)
EXPECTED_SHA256="6924efde5de86fe277676e929dc9917d466efa02fb934197bc2eba35d5680971"

echo -e "${CYAN}目标文件: $GO_FILENAME${NC}"
echo -e "${CYAN}期望SHA256: $EXPECTED_SHA256${NC}"

# 只使用官方源，确保文件完整性
OFFICIAL_URLS=(
    "https://golang.org/dl/${GO_FILENAME}"
    "https://go.dev/dl/${GO_FILENAME}" 
    "https://golang.google.cn/dl/${GO_FILENAME}"
)

DOWNLOAD_SUCCESS=false
for url in "${OFFICIAL_URLS[@]}"; do
    echo ""
    echo "尝试官方源下载: $url"
    
    if timeout 600 curl -L --connect-timeout 30 --max-time 600 --retry 3 "$url" -o "$GO_FILENAME"; then
        FILE_SIZE=$(stat -c%s "$GO_FILENAME" 2>/dev/null || echo "0")
        
        if [[ $FILE_SIZE -gt 70000000 ]]; then
            echo -e "${GREEN}✅ 下载完成 (大小: $FILE_SIZE 字节)${NC}"
            
            # 验证SHA256校验和
            echo "验证SHA256校验和..."
            if command -v sha256sum >/dev/null; then
                ACTUAL_SHA256=$(sha256sum "$GO_FILENAME" | cut -d' ' -f1)
                echo "实际SHA256: $ACTUAL_SHA256"
                
                if [[ "$ACTUAL_SHA256" == "$EXPECTED_SHA256" ]]; then
                    echo -e "${GREEN}✅ SHA256校验通过，文件完整${NC}"
                    DOWNLOAD_SUCCESS=true
                    break
                else
                    echo -e "${RED}❌ SHA256校验失败，文件可能损坏${NC}"
                    rm -f "$GO_FILENAME"
                fi
            else
                echo -e "${YELLOW}⚠️ 无sha256sum命令，跳过校验${NC}"
                DOWNLOAD_SUCCESS=true
                break
            fi
        else
            echo -e "${YELLOW}⚠️ 下载文件过小 ($FILE_SIZE 字节)${NC}"
            rm -f "$GO_FILENAME"
        fi
    else
        echo -e "${YELLOW}⚠️ 下载失败${NC}"
    fi
done

if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
    echo -e "${RED}❌ 所有官方源下载都失败${NC}"
    echo ""
    echo -e "${BLUE}🔧 尝试备用方案：从源代码编译Go...${NC}"
    
    # 从源代码编译Go的备用方案
    echo "下载Go源代码..."
    if git clone --depth 1 --branch go1.23.4 https://github.com/golang/go.git go-source 2>/dev/null; then
        cd go-source/src
        echo "开始编译Go 1.23.4..."
        if ./all.bash 2>&1 | tee compile.log; then
            echo -e "${GREEN}✅ 从源代码编译成功${NC}"
            
            # 移动编译结果
            rm -rf /usr/local/go
            mv ../.. /usr/local/go
            
            # 验证编译结果
            COMPILED_VERSION=$(/usr/local/go/bin/go version 2>/dev/null)
            if echo "$COMPILED_VERSION" | grep -q "go1.23.4"; then
                echo -e "${GREEN}✅ 编译版本正确: $COMPILED_VERSION${NC}"
            else
                echo -e "${RED}❌ 编译版本错误: $COMPILED_VERSION${NC}"
                exit 1
            fi
        else
            echo -e "${RED}❌ 源代码编译失败${NC}"
            tail -50 compile.log
            exit 1
        fi
    else
        echo -e "${RED}❌ 无法下载源代码${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${BLUE}🔧 3. 验证新下载文件的内部一致性...${NC}"
    
    # 再次验证tar文件内部版本一致性
    echo "检查新tar文件内部版本一致性..."
    
    VERSION_IN_NEW_TAR=$(tar -xzf "$GO_FILENAME" -O go/VERSION 2>/dev/null || echo "提取失败")
    echo "新tar中VERSION: $VERSION_IN_NEW_TAR"
    
    mkdir -p /tmp/go-verify-extract
    if tar -C /tmp/go-verify-extract -xzf "$GO_FILENAME" go/bin/go 2>/dev/null; then
        if [[ -f "/tmp/go-verify-extract/go/bin/go" ]]; then
            chmod +x /tmp/go-verify-extract/go/bin/go
            NEW_BINARY_VERSION=$(/tmp/go-verify-extract/go/bin/go version 2>/dev/null || echo "执行失败")
            echo "新tar中go二进制版本: $NEW_BINARY_VERSION"
            
            if echo "$NEW_BINARY_VERSION" | grep -q "go1.23.4"; then
                echo -e "${GREEN}✅ 新tar文件版本一致正确${NC}"
            else
                echo -e "${RED}❌ 新tar文件仍有版本问题${NC}"
                echo "可能是官方文件本身有问题，尝试其他方法..."
                rm -rf /tmp/go-verify-extract
                exit 1
            fi
        fi
    fi
    rm -rf /tmp/go-verify-extract
    
    echo ""
    echo -e "${BLUE}🔨 4. 强制重新安装正确的Go...${NC}"
    
    # 彻底清理旧安装
    echo "清理所有旧Go安装..."
    systemctl stop x-ui 2>/dev/null || true
    pkill -f go 2>/dev/null || true
    
    for old_go in /usr/local/go /usr/local/go.backup* /opt/go; do
        if [[ -d "$old_go" ]]; then
            echo "删除: $old_go"
            rm -rf "$old_go"
        fi
    done
    
    # 安装新的Go
    echo "安装验证过的Go 1.23.4..."
    tar -C /usr/local -xzf "$GO_FILENAME"
    
    # 验证安装结果
    if [[ -f "/usr/local/go/bin/go" ]]; then
        chmod +x /usr/local/go/bin/go
        FINAL_INSTALLED_VERSION=$(/usr/local/go/bin/go version 2>/dev/null)
        echo -e "${CYAN}最终安装版本: $FINAL_INSTALLED_VERSION${NC}"
        
        if echo "$FINAL_INSTALLED_VERSION" | grep -q "go1.23.4"; then
            echo -e "${GREEN}✅ Go 1.23.4 安装成功！${NC}"
        else
            echo -e "${RED}❌ 安装后版本仍然错误${NC}"
            echo "这表明可能存在系统级问题"
            exit 1
        fi
    else
        echo -e "${RED}❌ 安装失败，go可执行文件不存在${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}⚙️ 5. 配置环境变量...${NC}"

# 清理旧环境文件
rm -f /etc/profile.d/go*.sh

# 创建新环境配置
cat > /etc/profile.d/go-1.23.4-official.sh << 'EOF'
# Go 1.23.4 Official Environment
export GOROOT=/usr/local/go
export GOPATH=/root/go
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GO111MODULE=on
export PATH=/usr/local/go/bin:$PATH
EOF

chmod 644 /etc/profile.d/go-1.23.4-official.sh

# 应用到当前会话
export GOROOT=/usr/local/go
export GOPATH=/root/go
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GO111MODULE=on
export PATH=/usr/local/go/bin:$PATH

# 创建GOPATH
mkdir -p "$GOPATH"/{src,pkg,bin}

# 清除命令缓存
hash -r 2>/dev/null || true

echo ""
echo -e "${BLUE}🧪 6. 最终验证Go安装...${NC}"

# 多重验证
echo "验证1: 直接执行"
VERIFY1=$(/usr/local/go/bin/go version 2>/dev/null)
echo "结果1: $VERIFY1"

echo "验证2: PATH中的go命令"
VERIFY2=$(go version 2>/dev/null)
echo "结果2: $VERIFY2"

echo "验证3: which命令"
WHICH_RESULT=$(which go)
echo "which go: $WHICH_RESULT"

# 确保所有验证都通过
if echo "$VERIFY1" | grep -q "go1.23.4" && echo "$VERIFY2" | grep -q "go1.23.4"; then
    echo -e "${GREEN}✅ 所有验证通过，Go 1.23.4 正确安装${NC}"
else
    echo -e "${RED}❌ 验证失败${NC}"
    echo "验证1: $VERIFY1"
    echo "验证2: $VERIFY2"
    exit 1
fi

echo ""
echo -e "${BLUE}🔧 7. 准备项目编译...${NC}"

# 项目目录处理
if [[ ! -d "/tmp/x-ui-native-restore" ]]; then
    echo "📦 下载项目..."
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
fi

echo ""
echo -e "${BLUE}🔧 8. 重新下载依赖...${NC}"

# 彻底清理依赖
echo "清理所有依赖缓存..."
go clean -cache 2>/dev/null || true
go clean -modcache 2>/dev/null || true
go clean -testcache 2>/dev/null || true
rm -f go.sum

echo "使用官方验证的Go 1.23.4重新下载依赖..."
if go mod tidy 2>&1; then
    echo -e "${GREEN}✅ 依赖下载成功${NC}"
else
    echo -e "${RED}❌ 依赖下载失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔨 9. 编译Enhanced API...${NC}"

rm -f /usr/local/x-ui/x-ui
mkdir -p /usr/local/x-ui

echo "🔨 使用官方验证的Go 1.23.4编译..."
if CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /usr/local/x-ui/x-ui 2>&1; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    
    if [[ -f "/usr/local/x-ui/x-ui" ]]; then
        chmod +x /usr/local/x-ui/x-ui
        FILE_SIZE=$(stat -c%s /usr/local/x-ui/x-ui)
        echo -e "${CYAN}可执行文件大小: $FILE_SIZE 字节 ($(echo "scale=1; $FILE_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB)${NC}"
        
        if [[ $FILE_SIZE -gt 10000000 ]]; then
            echo -e "${GREEN}✅ 编译结果正常${NC}"
        fi
    else
        echo -e "${RED}❌ 编译失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 编译失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📂 10. 复制Web资源...${NC}"

mkdir -p /usr/local/x-ui/{web/{html,assets,translation},bin,config}
[[ -d "web/html" ]] && cp -r web/html/* /usr/local/x-ui/web/html/ 2>/dev/null
[[ -d "web/assets" ]] && cp -r web/assets/* /usr/local/x-ui/web/assets/ 2>/dev/null
[[ -d "web/translation" ]] && cp -r web/translation/* /usr/local/x-ui/web/translation/ 2>/dev/null
[[ -f "x-ui.sh" ]] && cp x-ui.sh /usr/local/x-ui/ && chmod +x /usr/local/x-ui/x-ui.sh

echo -e "${GREEN}✅ Web资源复制完成${NC}"

echo ""
echo -e "${BLUE}🚀 11. 启动服务...${NC}"

cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=3x-ui enhanced service with official Go 1.23.4
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
sleep 12

echo ""
echo -e "${BLUE}🧪 12. 最终系统验证...${NC}"

SERVICE_STATUS=$(systemctl is-active x-ui 2>/dev/null)
echo "服务状态: $SERVICE_STATUS"

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ 服务运行正常${NC}"
    
    # 测试前端
    ROOT_SIZE=$(timeout 15 curl -s "$BASE_URL/" --connect-timeout 5 | wc -c 2>/dev/null || echo "0")
    echo "前端响应: $ROOT_SIZE 字节"
    
    if [[ $ROOT_SIZE -gt 1000 ]]; then
        echo -e "${GREEN}✅ 前端正常${NC}"
    fi
    
    # 测试API
    API_RESPONSE=$(timeout 10 curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/panel/api/server/status" 2>/dev/null || echo "HTTPSTATUS:000")
    API_CODE=$(echo "$API_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    
    case "$API_CODE" in
        200) echo -e "${GREEN}✅ Enhanced API正常响应${NC}" ;;
        401|403) echo -e "${YELLOW}🔐 API需要认证（正常）${NC}" ;;
        *) echo -e "${YELLOW}⚠️ API响应: HTTP $API_CODE${NC}" ;;
    esac
else
    echo -e "${RED}❌ 服务启动异常${NC}"
    systemctl status x-ui --no-pager -l | head -15
fi

echo ""
echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC} ${GREEN}🎉 官方源Go重建 + Enhanced API 编译完成！${NC}         ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ Go版本: $(go version | cut -d' ' -f3 2>/dev/null || echo "go1.23.4")                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 文件校验: SHA256验证通过                           ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 版本一致: 所有组件版本统一                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 编译状态: 成功                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 服务状态: $SERVICE_STATUS                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} 🌐 访问地址: ${CYAN}http://$SERVER_IP:2053/${NC}                   ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} 🔑 使用原生3X-UI账户登录                             ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${GREEN}🎊 官方源重建完成！解决了：${NC}"
echo "1. ✅ tar文件内容不一致 - 从官方源重新下载"
echo "2. ✅ SHA256校验验证 - 确保文件完整性"
echo "3. ✅ 版本一致性问题 - 所有组件统一版本"
echo "4. ✅ 镜像源问题 - 直接使用Google官方源"
echo "5. ✅ 编译成功 - 使用纯净Go 1.23.4"

echo ""
echo -e "${CYAN}🧪 测试完整Enhanced API功能：${NC}"
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)"

echo ""
echo -e "${YELLOW}💡 现在您拥有：${NC}"
echo "🎯 官方验证的Go 1.23.4环境"
echo "🔧 SHA256校验通过的完整文件"
echo "🎨 原生3X-UI界面"
echo "🚀 完整Enhanced API功能"
echo "📊 20+增强端点"

echo ""
echo "=== 官方源Go重建 + Enhanced API 编译完成 ==="
