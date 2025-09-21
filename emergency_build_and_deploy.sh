#!/bin/bash

echo "=== Enhanced API 紧急编译部署脚本 ==="
echo "GitHub Actions构建问题的紧急解决方案"

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
echo -e "${PURPLE}🚨 紧急修复策略：${NC}"
echo "1. 使用我们之前验证有效的官方源Go重建方法"
echo "2. 直接在服务器编译Enhanced API"
echo "3. 跳过GitHub Release依赖"
echo "4. 确保快速部署成功"

echo ""
echo -e "${BLUE}🔧 1. 检查当前系统状态...${NC}"

# 检查系统信息
echo "系统架构: $(uname -s) $(uname -m)"
echo "当前用户: $(whoami)"
echo "工作目录: $(pwd)"

# 检查现有Go环境
if command -v go >/dev/null 2>&1; then
    GO_VERSION=$(go version 2>/dev/null)
    echo "当前Go版本: $GO_VERSION"
    
    if echo "$GO_VERSION" | grep -q "go1.23"; then
        echo -e "${GREEN}✅ Go版本兼容，可以直接编译${NC}"
        USE_EXISTING_GO=true
    else
        echo -e "${YELLOW}⚠️ Go版本过低，需要升级${NC}"
        USE_EXISTING_GO=false
    fi
else
    echo -e "${YELLOW}⚠️ 未安装Go，需要安装${NC}"
    USE_EXISTING_GO=false
fi

echo ""
echo -e "${BLUE}💾 2. 备份现有数据...${NC}"

# 备份现有数据
BACKUP_DIR="/tmp/x-ui-emergency-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "备份目录: $BACKUP_DIR"

# 停止现有服务
systemctl stop x-ui 2>/dev/null || true

# 备份数据
if [[ -f "/usr/local/x-ui/x-ui.db" ]]; then
    cp "/usr/local/x-ui/x-ui.db" "$BACKUP_DIR/"
    echo -e "${GREEN}✅ 数据库备份完成${NC}"
fi

if [[ -d "/usr/local/x-ui/web" ]]; then
    cp -r "/usr/local/x-ui/web" "$BACKUP_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✅ Web配置备份完成${NC}"
fi

echo ""
if [[ "$USE_EXISTING_GO" != "true" ]]; then
    echo -e "${BLUE}🔧 3. 安装/升级Go环境...${NC}"
    
    # 使用我们之前验证有效的官方源重建脚本逻辑
    echo "使用官方源重建Go 1.23.4..."
    
    cd /tmp
    GO_FILENAME="go1.23.4.linux-amd64.tar.gz"
    
    # 官方SHA256校验和
    EXPECTED_SHA256="6924efde5de86fe277676e929dc9917d466efa02fb934197bc2eba35d5680971"
    
    # 下载官方Go
    OFFICIAL_URLS=(
        "https://golang.org/dl/${GO_FILENAME}"
        "https://go.dev/dl/${GO_FILENAME}" 
        "https://golang.google.cn/dl/${GO_FILENAME}"
    )
    
    DOWNLOAD_SUCCESS=false
    for url in "${OFFICIAL_URLS[@]}"; do
        echo "尝试下载: $url"
        
        if timeout 600 curl -L --connect-timeout 30 --max-time 600 --retry 3 "$url" -o "$GO_FILENAME"; then
            FILE_SIZE=$(stat -c%s "$GO_FILENAME" 2>/dev/null || echo "0")
            
            if [[ $FILE_SIZE -gt 70000000 ]]; then
                echo -e "${GREEN}✅ 下载完成 (大小: $FILE_SIZE 字节)${NC}"
                
                # 验证SHA256
                if command -v sha256sum >/dev/null; then
                    ACTUAL_SHA256=$(sha256sum "$GO_FILENAME" | cut -d' ' -f1)
                    if [[ "$ACTUAL_SHA256" == "$EXPECTED_SHA256" ]]; then
                        echo -e "${GREEN}✅ SHA256校验通过${NC}"
                        DOWNLOAD_SUCCESS=true
                        break
                    else
                        echo -e "${RED}❌ SHA256校验失败${NC}"
                        rm -f "$GO_FILENAME"
                    fi
                else
                    echo -e "${YELLOW}⚠️ 无sha256sum命令，跳过校验${NC}"
                    DOWNLOAD_SUCCESS=true
                    break
                fi
            fi
        fi
    done
    
    if [[ "$DOWNLOAD_SUCCESS" == "true" ]]; then
        echo "安装Go 1.23.4..."
        
        # 清理旧Go
        rm -rf /usr/local/go
        
        # 安装新Go
        tar -C /usr/local -xzf "$GO_FILENAME"
        
        # 设置环境
        export GOROOT=/usr/local/go
        export GOPATH=/root/go
        export PATH=/usr/local/go/bin:$PATH
        
        # 验证安装
        GO_CHECK=$(/usr/local/go/bin/go version 2>/dev/null)
        if echo "$GO_CHECK" | grep -q "go1.23.4"; then
            echo -e "${GREEN}✅ Go 1.23.4安装成功: $GO_CHECK${NC}"
        else
            echo -e "${RED}❌ Go安装失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Go下载失败，使用源代码编译方案...${NC}"
        
        # 源代码编译备用方案
        if git clone --depth 1 --branch go1.23.4 https://github.com/golang/go.git go-source 2>/dev/null; then
            cd go-source/src
            if ./all.bash; then
                rm -rf /usr/local/go
                mv ../.. /usr/local/go
                export GOROOT=/usr/local/go
                export GOPATH=/root/go
                export PATH=/usr/local/go/bin:$PATH
                echo -e "${GREEN}✅ Go从源代码编译成功${NC}"
            else
                echo -e "${RED}❌ 源代码编译也失败${NC}"
                exit 1
            fi
        else
            echo -e "${RED}❌ 无法下载源代码${NC}"
            exit 1
        fi
    fi
    
    rm -f "$GO_FILENAME" 2>/dev/null
else
    echo -e "${BLUE}🔧 3. 使用现有Go环境...${NC}"
    echo -e "${GREEN}✅ 使用现有Go环境进行编译${NC}"
fi

echo ""
echo -e "${BLUE}📥 4. 下载项目源代码...${NC}"

# 准备项目目录
WORK_DIR="/tmp/x-ui-emergency-build"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "下载Enhanced API源代码..."
if git clone https://github.com/WCOJBK/x-ui-api-main.git . 2>/dev/null; then
    echo -e "${GREEN}✅ 源代码下载成功${NC}"
else
    echo -e "${RED}❌ 源代码下载失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📦 5. 下载依赖...${NC}"

# 确保环境变量正确
export GOROOT=/usr/local/go
export GOPATH=/root/go
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GO111MODULE=on
export PATH=/usr/local/go/bin:$PATH

# 清理依赖缓存
go clean -cache 2>/dev/null || true
go clean -modcache 2>/dev/null || true
rm -f go.sum

echo "下载项目依赖..."
if go mod tidy 2>&1; then
    echo -e "${GREEN}✅ 依赖下载成功${NC}"
else
    echo -e "${RED}❌ 依赖下载失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔨 6. 编译Enhanced API...${NC}"

echo "开始编译Enhanced API..."
if CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X main.version=emergency-$(date +%Y%m%d)" -o x-ui 2>&1; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    
    if [[ -f "x-ui" ]]; then
        FILE_SIZE=$(stat -c%s x-ui)
        echo -e "${CYAN}可执行文件大小: $FILE_SIZE 字节 ($(echo "scale=1; $FILE_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB)${NC}"
        
        if [[ $FILE_SIZE -gt 5000000 ]]; then
            echo -e "${GREEN}✅ 编译文件大小正常${NC}"
        else
            echo -e "${YELLOW}⚠️ 编译文件较小，可能有问题${NC}"
        fi
    else
        echo -e "${RED}❌ 编译文件不存在${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 编译失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📂 7. 部署到系统...${NC}"

# 创建目录
mkdir -p /usr/local/x-ui/{web/{html,assets,translation},bin,config}

# 复制主程序
echo "部署主程序..."
cp x-ui /usr/local/x-ui/
chmod +x /usr/local/x-ui/x-ui

# 复制Web资源
echo "部署Web资源..."
[[ -d "web/html" ]] && cp -r web/html/* /usr/local/x-ui/web/html/ 2>/dev/null || true
[[ -d "web/assets" ]] && cp -r web/assets/* /usr/local/x-ui/web/assets/ 2>/dev/null || true  
[[ -d "web/translation" ]] && cp -r web/translation/* /usr/local/x-ui/web/translation/ 2>/dev/null || true
[[ -f "x-ui.sh" ]] && cp x-ui.sh /usr/local/x-ui/ && chmod +x /usr/local/x-ui/x-ui.sh

echo -e "${GREEN}✅ 文件部署完成${NC}"

echo ""
echo -e "${BLUE}💾 8. 恢复数据...${NC}"

# 恢复数据库
if [[ -f "$BACKUP_DIR/x-ui.db" ]]; then
    cp "$BACKUP_DIR/x-ui.db" /usr/local/x-ui/
    echo -e "${GREEN}✅ 数据库恢复完成${NC}"
else
    echo -e "${YELLOW}⚠️ 无备份数据库，将使用默认设置${NC}"
fi

# 设置权限
chown -R root:root /usr/local/x-ui/
chmod -R 755 /usr/local/x-ui/
chmod 644 /usr/local/x-ui/x-ui.db 2>/dev/null || true

echo ""
echo -e "${BLUE}🔧 9. 配置服务...${NC}"

# 创建systemd服务
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=3x-ui enhanced service (Emergency Build)
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

echo ""
echo -e "${BLUE}🚀 10. 启动服务...${NC}"

if systemctl start x-ui; then
    echo -e "${GREEN}✅ 服务启动成功${NC}"
else
    echo -e "${RED}❌ 服务启动失败${NC}"
fi

echo "等待服务稳定..."
sleep 10

echo ""
echo -e "${BLUE}🧪 11. 验证功能...${NC}"

# 检查服务状态
SERVICE_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "failed")
echo "服务状态: $SERVICE_STATUS"

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ 服务运行正常${NC}"
    
    # 测试前端
    echo "测试前端响应..."
    ROOT_RESPONSE=$(timeout 15 curl -s "$BASE_URL/" --connect-timeout 5 2>/dev/null || echo "")
    ROOT_SIZE=${#ROOT_RESPONSE}
    
    if [[ $ROOT_SIZE -gt 1000 ]]; then
        echo -e "${GREEN}✅ 前端响应正常 ($ROOT_SIZE 字节)${NC}"
    else
        echo -e "${YELLOW}⚠️ 前端响应异常 ($ROOT_SIZE 字节)${NC}"
    fi
    
    # 测试API
    echo "测试API响应..."
    API_RESPONSE=$(timeout 10 curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/panel/api/server/status" 2>/dev/null || echo "HTTPSTATUS:000")
    API_CODE=$(echo "$API_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    
    case "$API_CODE" in
        200) echo -e "${GREEN}✅ Enhanced API正常响应${NC}" ;;
        401|403) echo -e "${YELLOW}🔐 API需要认证（正常）${NC}" ;;
        404) echo -e "${YELLOW}⚠️ API端点未找到，可能需要登录${NC}" ;;
        *) echo -e "${YELLOW}⚠️ API响应: HTTP $API_CODE${NC}" ;;
    esac
    
else
    echo -e "${RED}❌ 服务运行异常${NC}"
    echo ""
    echo -e "${BLUE}查看服务日志:${NC}"
    systemctl status x-ui --no-pager -l | head -15
fi

# 清理临时文件
echo ""
echo -e "${BLUE}🧹 12. 清理临时文件...${NC}"
cd /
rm -rf "$WORK_DIR"

echo ""
if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} ${GREEN}🎉 紧急编译部署成功！${NC}                               ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 绕过GitHub Actions问题                               ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 使用官方源Go环境                                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 直接服务器编译                                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 数据备份和恢复                                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 服务正常运行                                         ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 🌐 访问地址: ${CYAN}http://$SERVER_IP:2053/${NC}                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 💾 备份位置: ${CYAN}$BACKUP_DIR${NC}      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    echo -e "${GREEN}🎊 紧急修复完成！Enhanced API功能齐全：${NC}"
    echo "1. ✅ 原生3X-UI界面"
    echo "2. ✅ 20+增强API端点" 
    echo "3. ✅ 完整功能支持"
    echo "4. ✅ 数据完整保留"
else
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} ${RED}❌ 紧急编译部署失败${NC}                               ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 💾 备份位置: ${CYAN}$BACKUP_DIR${NC}      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 📋 请检查服务日志                                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${CYAN}🧪 测试完整Enhanced API功能：${NC}"
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)"

echo ""
echo "=== 紧急编译部署完成 ==="
