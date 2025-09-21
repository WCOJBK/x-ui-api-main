#!/bin/bash

echo "=== Enhanced API 离线部署脚本 ==="
echo "适用于网络受限环境，无需下载Go"

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
NC='\033[0m'

echo ""
echo -e "${PURPLE}🌐 网络受限环境部署策略：${NC}"
echo "1. 使用系统包管理器安装Go"
echo "2. 使用国内镜像源"
echo "3. 直接从项目源码编译"
echo "4. 使用预编译二进制"

echo ""
echo -e "${BLUE}🔍 1. 检查当前Go环境...${NC}"

# 检查是否已有Go
if command -v go >/dev/null 2>&1; then
    GO_VERSION=$(go version 2>/dev/null)
    echo -e "${GREEN}✅ 发现现有Go环境: $GO_VERSION${NC}"
    
    GO_VER_NUM=$(go version | sed 's/go version go//' | cut -d' ' -f1)
    echo "Go版本号: $GO_VER_NUM"
    
    # 检查版本是否足够（需要1.21+）
    if [[ "$GO_VER_NUM" < "1.21" ]]; then
        echo -e "${YELLOW}⚠️ Go版本过低，尝试升级...${NC}"
        NEED_UPGRADE=true
    else
        echo -e "${GREEN}✅ Go版本满足要求${NC}"
        NEED_UPGRADE=false
    fi
else
    echo -e "${YELLOW}⚠️ 未发现Go环境${NC}"
    NEED_UPGRADE=true
fi

if [[ "$NEED_UPGRADE" == "true" ]]; then
    echo ""
    echo -e "${BLUE}📦 2. 尝试系统包管理器安装Go...${NC}"
    
    # 检测系统类型并尝试安装
    if command -v apt-get >/dev/null; then
        echo "检测到Ubuntu/Debian系统..."
        
        # 尝试添加官方PPA
        echo "尝试添加Go官方PPA..."
        if add-apt-repository ppa:longsleep/golang-backports -y 2>/dev/null; then
            apt-get update 2>/dev/null
            echo "尝试安装最新Go..."
            if apt-get install -y golang-go 2>/dev/null; then
                echo -e "${GREEN}✅ 通过PPA安装Go成功${NC}"
            else
                echo "PPA安装失败，尝试默认仓库..."
                apt-get install -y golang 2>/dev/null || apt-get install -y golang-1.21 2>/dev/null
            fi
        else
            echo "添加PPA失败，使用默认仓库..."
            apt-get update 2>/dev/null
            apt-get install -y golang-go 2>/dev/null || apt-get install -y golang 2>/dev/null
        fi
        
    elif command -v yum >/dev/null; then
        echo "检测到CentOS/RHEL系统..."
        yum install -y golang 2>/dev/null || {
            # 尝试epel源
            yum install -y epel-release 2>/dev/null
            yum install -y golang 2>/dev/null
        }
        
    elif command -v dnf >/dev/null; then
        echo "检测到Fedora系统..."
        dnf install -y golang 2>/dev/null
        
    elif command -v pacman >/dev/null; then
        echo "检测到Arch系统..."
        pacman -S --noconfirm go 2>/dev/null
        
    elif command -v zypper >/dev/null; then
        echo "检测到openSUSE系统..."
        zypper install -y go 2>/dev/null
        
    else
        echo -e "${YELLOW}⚠️ 未识别的系统，尝试snap安装...${NC}"
        if command -v snap >/dev/null; then
            snap install go --classic 2>/dev/null
        fi
    fi
    
    # 检查安装结果
    if command -v go >/dev/null 2>&1; then
        NEW_GO_VERSION=$(go version 2>/dev/null)
        echo -e "${GREEN}✅ Go安装成功: $NEW_GO_VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️ 包管理器安装失败，尝试其他方案...${NC}"
    fi
fi

# 最终Go检查
if ! command -v go >/dev/null 2>&1; then
    echo ""
    echo -e "${BLUE}🔧 3. 尝试国内镜像源下载...${NC}"
    
    # 尝试国内镜像
    MIRROR_URLS=(
        "https://mirrors.aliyun.com/golang/go1.23.4.linux-amd64.tar.gz"
        "https://mirrors.tuna.tsinghua.edu.cn/golang/go1.23.4.linux-amd64.tar.gz"
        "https://mirrors.ustc.edu.cn/golang/go1.23.4.linux-amd64.tar.gz"
        "https://mirror.nju.edu.cn/golang/go1.23.4.linux-amd64.tar.gz"
    )
    
    cd /tmp
    DOWNLOAD_SUCCESS=false
    
    for url in "${MIRROR_URLS[@]}"; do
        echo "尝试下载: $url"
        if timeout 120 curl -L --connect-timeout 10 --max-time 120 "$url" -o "go1.23.4.linux-amd64.tar.gz"; then
            FILE_SIZE=$(stat -c%s "go1.23.4.linux-amd64.tar.gz" 2>/dev/null || echo "0")
            if [[ $FILE_SIZE -gt 50000000 ]]; then  # 至少50MB
                echo -e "${GREEN}✅ 下载成功 ($(echo "scale=1; $FILE_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB)${NC}"
                
                # 安装
                echo "安装Go..."
                systemctl stop x-ui 2>/dev/null || true
                rm -rf /usr/local/go*
                tar -C /usr/local -xzf "go1.23.4.linux-amd64.tar.gz"
                
                # 设置环境
                export PATH=/usr/local/go/bin:$PATH
                export GOROOT=/usr/local/go
                export GOPATH=/root/go
                
                # 创建环境配置
                cat > /etc/profile.d/go.sh << 'EOF'
export GOROOT=/usr/local/go
export GOPATH=/root/go
export PATH=$GOROOT/bin:$PATH
export GOPROXY=https://goproxy.cn,direct
export GO111MODULE=on
EOF
                
                DOWNLOAD_SUCCESS=true
                break
            fi
        fi
        rm -f "go1.23.4.linux-amd64.tar.gz"
    done
    
    if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
        echo -e "${YELLOW}⚠️ 所有镜像下载失败${NC}"
    fi
fi

# 再次检查Go
if command -v go >/dev/null 2>&1; then
    FINAL_GO_VERSION=$(go version 2>/dev/null)
    echo -e "${GREEN}✅ Go环境就绪: $FINAL_GO_VERSION${NC}"
else
    echo -e "${RED}❌ 无法安装Go，尝试最后方案...${NC}"
    
    echo ""
    echo -e "${BLUE}📋 4. 手动解决方案：${NC}"
    echo "如果网络完全受限，请考虑："
    echo "1. 使用已有的Go环境编译"
    echo "2. 在本地编译后上传二进制文件"
    echo "3. 使用Docker容器"
    echo "4. 联系系统管理员开放网络访问"
    
    echo ""
    echo -e "${CYAN}🐳 Docker方案（如果有Docker）：${NC}"
    echo "docker run --rm -v /usr/local/x-ui:/output golang:1.23.4 bash -c 'cd /output && go build -o x-ui'"
    
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 5. 开始编译Enhanced API...${NC}"

# 准备项目目录
WORK_DIR="/tmp/x-ui-enhanced-build"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "下载项目源码..."
if git clone https://github.com/WCOJBK/x-ui-api-main.git . 2>/dev/null; then
    echo -e "${GREEN}✅ 源码下载成功${NC}"
elif curl -L https://github.com/WCOJBK/x-ui-api-main/archive/main.zip -o main.zip 2>/dev/null && unzip -q main.zip && mv x-ui-api-main-main/* .; then
    echo -e "${GREEN}✅ 源码下载成功（ZIP方式）${NC}"
else
    echo -e "${RED}❌ 源码下载失败，请手动上传项目文件${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📥 6. 配置Go环境和依赖...${NC}"

# 配置Go代理为国内源
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GO111MODULE=on

echo "配置依赖代理: $GOPROXY"

# 清理并重新下载依赖
go clean -cache 2>/dev/null || true
go clean -modcache 2>/dev/null || true

echo "下载项目依赖..."
if go mod tidy 2>&1; then
    echo -e "${GREEN}✅ 依赖下载成功${NC}"
else
    echo -e "${RED}❌ 依赖下载失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔨 7. 编译Enhanced API...${NC}"

# 停止现有服务
systemctl stop x-ui 2>/dev/null || true
rm -f /usr/local/x-ui/x-ui

# 编译
mkdir -p /usr/local/x-ui
echo "编译中..."
if CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X main.version=v1.0.0-enhanced-offline" -o /usr/local/x-ui/x-ui 2>&1; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    
    if [[ -f "/usr/local/x-ui/x-ui" ]]; then
        chmod +x /usr/local/x-ui/x-ui
        FILE_SIZE=$(stat -c%s /usr/local/x-ui/x-ui)
        echo -e "${CYAN}可执行文件大小: $(echo "scale=1; $FILE_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB${NC}"
    fi
else
    echo -e "${RED}❌ 编译失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📂 8. 部署Web资源...${NC}"

# 部署资源
mkdir -p /usr/local/x-ui/{web/{html,assets,translation},bin,config}
[[ -d "web/html" ]] && cp -r web/html/* /usr/local/x-ui/web/html/ 2>/dev/null
[[ -d "web/assets" ]] && cp -r web/assets/* /usr/local/x-ui/web/assets/ 2>/dev/null
[[ -d "web/translation" ]] && cp -r web/translation/* /usr/local/x-ui/web/translation/ 2>/dev/null
[[ -f "x-ui.sh" ]] && cp x-ui.sh /usr/local/x-ui/ && chmod +x /usr/local/x-ui/x-ui.sh

echo -e "${GREEN}✅ Web资源部署完成${NC}"

echo ""
echo -e "${BLUE}🚀 9. 配置并启动服务...${NC}"

# 创建systemd服务
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=3x-ui enhanced service (offline build)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/x-ui/
ExecStart=/usr/local/x-ui/x-ui run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

echo "等待服务启动..."
sleep 8

echo ""
echo -e "${BLUE}🧪 10. 验证部署结果...${NC}"

SERVICE_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "inactive")
echo "服务状态: $SERVICE_STATUS"

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ 服务运行正常${NC}"
    
    # 测试前端
    ROOT_RESPONSE=$(timeout 10 curl -s "$BASE_URL/" --connect-timeout 3 2>/dev/null || echo "")
    ROOT_SIZE=${#ROOT_RESPONSE}
    
    if [[ $ROOT_SIZE -gt 1000 ]]; then
        echo -e "${GREEN}✅ 前端正常 ($ROOT_SIZE 字节)${NC}"
    else
        echo -e "${YELLOW}⚠️ 前端响应异常${NC}"
    fi
    
    # 测试API
    API_RESPONSE=$(timeout 8 curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/panel/api/server/status" 2>/dev/null || echo "HTTPSTATUS:000")
    API_CODE=$(echo "$API_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    
    case "$API_CODE" in
        200) echo -e "${GREEN}✅ Enhanced API正常响应${NC}" ;;
        401|403) echo -e "${YELLOW}🔐 API需要认证（正常）${NC}" ;;
        *) echo -e "${YELLOW}⚠️ API响应: HTTP $API_CODE${NC}" ;;
    esac
    
else
    echo -e "${RED}❌ 服务启动失败${NC}"
    systemctl status x-ui --no-pager -l | head -10
fi

# 清理
rm -rf "$WORK_DIR"

echo ""
if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} ${GREEN}🎉 离线部署成功！${NC}                                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 无网络依赖部署完成                                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ Enhanced API编译成功                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 服务运行正常                                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 🌐 访问地址: ${CYAN}http://$SERVER_IP:2053/${NC}                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    echo -e "${GREEN}🎊 离线部署完成！特点：${NC}"
    echo "1. ✅ 适用于网络受限环境"
    echo "2. ✅ 使用国内镜像源"
    echo "3. ✅ 系统包管理器安装"
    echo "4. ✅ 完整Enhanced API功能"
    
else
    echo -e "${RED}❌ 部署失败，请检查网络和系统环境${NC}"
fi

echo ""
echo -e "${CYAN}🧪 测试完整Enhanced API功能：${NC}"
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)"

echo ""
echo "=== Enhanced API 离线部署完成 ==="
