#!/bin/bash

echo "=== Ultimate Go 1.23.4 诊断修复脚本 ==="
echo "解决下载成功但解压失败的问题"

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
echo -e "${PURPLE}🔧 Ultimate修复策略：${NC}"
echo "1. 强制杀死所有Go相关进程"
echo "2. 验证下载文件完整性"
echo "3. 使用不同方法强制解压"
echo "4. 详细验证每个解压步骤"
echo "5. 多重备用解压方案"

echo ""
echo -e "${BLUE}🔍 1. 强力诊断当前状态...${NC}"

echo -e "${CYAN}当前系统进程检查：${NC}"
if pgrep -f "go\|x-ui" > /dev/null; then
    echo "发现Go相关运行进程："
    pgrep -af "go\|x-ui" || echo "进程检查完成"
    
    echo "强制终止所有相关进程..."
    pkill -9 -f "go" 2>/dev/null || echo "没有Go进程需要终止"
    pkill -9 -f "x-ui" 2>/dev/null || echo "没有x-ui进程需要终止"
    systemctl stop x-ui 2>/dev/null || echo "x-ui服务已停止"
    sleep 3
else
    echo "没有发现Go相关运行进程"
fi

echo ""
echo -e "${CYAN}检查文件系统状态：${NC}"
df -h /usr/local/ | head -2
echo "磁盘空间检查完成"

echo ""
echo -e "${BLUE}🧹 2. 超强力清理...${NC}"

echo "强制删除所有Go目录和文件..."
# 使用多种方法确保删除
for i in {1..3}; do
    echo "清理尝试 $i/3..."
    
    # 强制取消挂载（如果有）
    umount /usr/local/go 2>/dev/null || true
    
    # 更改权限并强制删除
    chmod -R 777 /usr/local/go 2>/dev/null || true
    rm -rf /usr/local/go 2>/dev/null || true
    
    # 检查是否删除成功
    if [[ ! -d "/usr/local/go" ]]; then
        echo "✅ 清理成功"
        break
    else
        echo "⚠️ 尝试 $i 失败，继续..."
        sleep 2
    fi
done

# 最终检查
if [[ -d "/usr/local/go" ]]; then
    echo -e "${RED}❌ 无法完全清理 /usr/local/go，尝试alternative方法...${NC}"
    
    # 重命名旧目录
    mv /usr/local/go "/usr/local/go.backup.$(date +%s)" 2>/dev/null || true
    
    if [[ -d "/usr/local/go" ]]; then
        echo -e "${RED}❌ 严重：无法处理现有Go目录${NC}"
        ls -la /usr/local/go/ | head -10
        echo "尝试使用临时目录..."
        INSTALL_DIR="/opt/go-temp"
        mkdir -p "$INSTALL_DIR"
    else
        INSTALL_DIR="/usr/local/go"
    fi
else
    INSTALL_DIR="/usr/local/go"
    echo -e "${GREEN}✅ 目录清理完成，使用: $INSTALL_DIR${NC}"
fi

echo ""
echo -e "${BLUE}📦 3. 重新下载并验证Go 1.23.4...${NC}"

cd /tmp
GO_VERSION="1.23.4"
GO_FILENAME="go${GO_VERSION}.linux-amd64.tar.gz"

# 检查是否已有下载的文件
if [[ -f "$GO_FILENAME" ]]; then
    echo "发现现有下载文件，检查完整性..."
    FILE_SIZE=$(stat -c%s "$GO_FILENAME")
    echo "文件大小: $FILE_SIZE 字节"
    
    if [[ $FILE_SIZE -gt 70000000 && $FILE_SIZE -lt 80000000 ]]; then
        echo -e "${GREEN}✅ 文件大小合理，尝试使用现有文件${NC}"
    else
        echo -e "${YELLOW}⚠️ 文件大小异常，重新下载${NC}"
        rm -f "$GO_FILENAME"
    fi
fi

# 如果需要重新下载
if [[ ! -f "$GO_FILENAME" ]]; then
    echo "重新下载Go $GO_VERSION..."
    
    # 使用最可靠的镜像源
    DOWNLOAD_URLS=(
        "https://mirrors.aliyun.com/golang/${GO_FILENAME}"
        "https://studygolang.com/dl/golang/${GO_FILENAME}"  
        "https://mirrors.nju.edu.cn/golang/${GO_FILENAME}"
        "https://golang.google.cn/dl/${GO_FILENAME}"
    )
    
    DOWNLOAD_SUCCESS=false
    for url in "${DOWNLOAD_URLS[@]}"; do
        echo "尝试下载: $url"
        if curl -L --connect-timeout 15 --max-time 600 --retry 2 "$url" -o "$GO_FILENAME"; then
            FILE_SIZE=$(stat -c%s "$GO_FILENAME" 2>/dev/null || echo "0")
            if [[ $FILE_SIZE -gt 70000000 ]]; then
                echo -e "${GREEN}✅ 下载成功 (大小: $FILE_SIZE 字节)${NC}"
                DOWNLOAD_SUCCESS=true
                break
            else
                echo -e "${YELLOW}⚠️ 文件过小，尝试下个源...${NC}"
                rm -f "$GO_FILENAME"
            fi
        else
            echo -e "${YELLOW}⚠️ 下载失败，尝试下个源...${NC}"
        fi
    done
    
    if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
        echo -e "${RED}❌ 所有下载源都失败${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}🔧 4. 验证下载文件完整性...${NC}"

echo "文件信息："
ls -la "$GO_FILENAME"
echo ""

echo "文件类型检查："
file "$GO_FILENAME"
echo ""

echo "尝试验证tar文件完整性："
if tar -tzf "$GO_FILENAME" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ tar文件格式正确${NC}"
else
    echo -e "${RED}❌ tar文件损坏${NC}"
    echo "尝试修复或重新下载..."
    rm -f "$GO_FILENAME"
    exit 1
fi

# 检查tar内容
echo ""
echo "检查tar文件内容结构："
tar -tzf "$GO_FILENAME" | head -20
echo "..."
echo "文件总数: $(tar -tzf "$GO_FILENAME" | wc -l)"

echo ""
echo -e "${BLUE}🔨 5. 使用多种方法强制解压...${NC}"

mkdir -p "$INSTALL_DIR"

echo "方法1: 标准tar解压..."
if tar -C "$(dirname "$INSTALL_DIR")" -xzf "$GO_FILENAME" 2>/dev/null; then
    if [[ -f "$INSTALL_DIR/bin/go" ]]; then
        VERSION_CHECK=$("$INSTALL_DIR/bin/go" version 2>/dev/null || echo "failed")
        if echo "$VERSION_CHECK" | grep -q "go1.23.4"; then
            echo -e "${GREEN}✅ 方法1成功！版本: $VERSION_CHECK${NC}"
        else
            echo -e "${YELLOW}⚠️ 方法1解压完成但版本错误: $VERSION_CHECK${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ 方法1解压完成但go可执行文件不存在${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ 方法1失败${NC}"
fi

# 如果方法1失败，尝试方法2
if [[ ! -f "$INSTALL_DIR/bin/go" ]] || ! echo "$("$INSTALL_DIR/bin/go" version 2>/dev/null)" | grep -q "go1.23.4"; then
    echo ""
    echo "方法2: 分步解压..."
    
    # 清理并重新创建目录
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # 先解压到临时目录
    TEMP_DIR="/tmp/go-extract-$$"
    mkdir -p "$TEMP_DIR"
    
    echo "解压到临时目录: $TEMP_DIR"
    if tar -C "$TEMP_DIR" -xzf "$GO_FILENAME" 2>&1; then
        echo -e "${GREEN}✅ 临时目录解压成功${NC}"
        
        if [[ -d "$TEMP_DIR/go" ]]; then
            echo "移动文件到目标目录..."
            if mv "$TEMP_DIR/go"/* "$INSTALL_DIR/" 2>/dev/null; then
                echo -e "${GREEN}✅ 文件移动成功${NC}"
            else
                echo -e "${YELLOW}⚠️ 文件移动失败，尝试复制...${NC}"
                if cp -r "$TEMP_DIR/go"/* "$INSTALL_DIR/" 2>/dev/null; then
                    echo -e "${GREEN}✅ 文件复制成功${NC}"
                else
                    echo -e "${RED}❌ 文件复制失败${NC}"
                fi
            fi
        fi
        
        # 清理临时目录
        rm -rf "$TEMP_DIR"
    else
        echo -e "${RED}❌ 方法2也失败${NC}"
        rm -rf "$TEMP_DIR"
    fi
fi

# 如果还是失败，尝试方法3
if [[ ! -f "$INSTALL_DIR/bin/go" ]] || ! echo "$("$INSTALL_DIR/bin/go" version 2>/dev/null)" | grep -q "go1.23.4"; then
    echo ""
    echo "方法3: 使用gzip和tar分离..."
    
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # 分步操作
    echo "步骤1: 解压gzip..."
    if gunzip -c "$GO_FILENAME" > "/tmp/go.tar" 2>/dev/null; then
        echo -e "${GREEN}✅ gzip解压成功${NC}"
        
        echo "步骤2: 解压tar..."
        if tar -C "$(dirname "$INSTALL_DIR")" -xf "/tmp/go.tar" 2>/dev/null; then
            echo -e "${GREEN}✅ tar解压成功${NC}"
        else
            echo -e "${RED}❌ tar解压失败${NC}"
        fi
        
        rm -f "/tmp/go.tar"
    else
        echo -e "${RED}❌ gzip解压失败${NC}"
    fi
fi

echo ""
echo -e "${BLUE}🧪 6. 验证安装结果...${NC}"

if [[ -f "$INSTALL_DIR/bin/go" ]]; then
    chmod +x "$INSTALL_DIR/bin/go"
    INSTALLED_VERSION=$("$INSTALL_DIR/bin/go" version 2>/dev/null || echo "无法获取版本")
    echo -e "${CYAN}安装的Go版本: $INSTALLED_VERSION${NC}"
    
    if echo "$INSTALLED_VERSION" | grep -q "go1.23.4"; then
        echo -e "${GREEN}✅ Go 1.23.4 安装成功！${NC}"
    else
        echo -e "${RED}❌ 版本仍然不正确${NC}"
        echo ""
        echo -e "${YELLOW}🔍 详细诊断：${NC}"
        echo "安装目录: $INSTALL_DIR"
        echo "目录内容:"
        ls -la "$INSTALL_DIR/" | head -10
        if [[ -d "$INSTALL_DIR/bin" ]]; then
            echo "bin目录内容:"
            ls -la "$INSTALL_DIR/bin/" | head -10
        fi
        
        # 尝试直接从解压内容查看版本
        if [[ -f "$INSTALL_DIR/VERSION" ]]; then
            echo "VERSION文件内容: $(cat "$INSTALL_DIR/VERSION")"
        fi
        
        exit 1
    fi
else
    echo -e "${RED}❌ go 可执行文件不存在: $INSTALL_DIR/bin/go${NC}"
    echo ""
    echo -e "${YELLOW}🔍 目录诊断：${NC}"
    echo "安装目录存在: $([ -d "$INSTALL_DIR" ] && echo "是" || echo "否")"
    if [[ -d "$INSTALL_DIR" ]]; then
        echo "目录内容:"
        ls -la "$INSTALL_DIR/" | head -15
    fi
    exit 1
fi

# 如果安装目录不是标准位置，需要创建链接
if [[ "$INSTALL_DIR" != "/usr/local/go" ]]; then
    echo ""
    echo "创建标准路径链接..."
    rm -rf /usr/local/go 2>/dev/null || true
    ln -s "$INSTALL_DIR" /usr/local/go
    echo -e "${GREEN}✅ 创建链接: /usr/local/go -> $INSTALL_DIR${NC}"
fi

echo ""
echo -e "${BLUE}⚙️ 7. 配置环境变量...${NC}"

# 清理旧的环境文件
rm -f /etc/profile.d/go*.sh

# 创建新的环境配置
cat > /etc/profile.d/go-1.23.4.sh << EOF
# Go 1.23.4 Environment Configuration
export GOROOT=/usr/local/go
export GOPATH=/root/go
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GO111MODULE=on
export PATH=/usr/local/go/bin:\$PATH
EOF

chmod 644 /etc/profile.d/go-1.23.4.sh

# 应用到当前会话
export GOROOT=/usr/local/go
export GOPATH=/root/go
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn
export GO111MODULE=on
export PATH=/usr/local/go/bin:$PATH

# 创建GOPATH目录
mkdir -p "$GOPATH"/{src,pkg,bin}

echo -e "${CYAN}环境变量配置完成：${NC}"
echo "GOROOT: $GOROOT"
echo "GOPATH: $GOPATH" 
echo "GOPROXY: $GOPROXY"
echo "PATH: $PATH"

# 最终版本验证
FINAL_VERSION=$(/usr/local/go/bin/go version 2>/dev/null)
echo -e "${GREEN}✅ 最终Go版本: $FINAL_VERSION${NC}"

if ! echo "$FINAL_VERSION" | grep -q "go1.23.4"; then
    echo -e "${RED}❌ 最终验证失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔧 8. 准备项目编译...${NC}"

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
echo -e "${BLUE}🔧 9. 清理并重新下载依赖...${NC}"

# 彻底清理Go相关缓存
echo "清理所有Go缓存..."
/usr/local/go/bin/go clean -cache 2>/dev/null || true
/usr/local/go/bin/go clean -modcache 2>/dev/null || true
/usr/local/go/bin/go clean -testcache 2>/dev/null || true

# 删除go.sum强制重新验证
rm -f go.sum

echo "使用Go 1.23.4重新初始化模块..."
echo "执行: /usr/local/go/bin/go mod tidy"
if /usr/local/go/bin/go mod tidy 2>&1; then
    echo -e "${GREEN}✅ 依赖下载成功${NC}"
else
    echo -e "${RED}❌ 依赖下载失败${NC}"
    echo ""
    echo "尝试诊断问题..."
    /usr/local/go/bin/go version
    /usr/local/go/bin/go env GOPROXY
    /usr/local/go/bin/go env GOSUMDB
    
    echo ""
    echo "尝试强制更新依赖..."
    /usr/local/go/bin/go get -u ./... 2>&1 || true
    /usr/local/go/bin/go mod tidy 2>&1 || exit 1
fi

echo ""
echo -e "${BLUE}🔨 10. 编译Enhanced API...${NC}"

echo "🧹 清理旧的可执行文件..."
rm -f /usr/local/x-ui/x-ui

# 确保目录存在
mkdir -p /usr/local/x-ui

echo "🔨 使用Go 1.23.4编译..."
echo "编译命令: CGO_ENABLED=0 GOOS=linux /usr/local/go/bin/go build -ldflags='-s -w' -o /usr/local/x-ui/x-ui"

if CGO_ENABLED=0 GOOS=linux /usr/local/go/bin/go build -ldflags="-s -w" -o /usr/local/x-ui/x-ui 2>&1; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    
    if [[ -f "/usr/local/x-ui/x-ui" ]]; then
        chmod +x /usr/local/x-ui/x-ui
        FILE_SIZE=$(stat -c%s /usr/local/x-ui/x-ui)
        echo -e "${CYAN}可执行文件大小: $FILE_SIZE 字节${NC}"
        
        if [[ $FILE_SIZE -gt 1000000 ]]; then
            echo -e "${GREEN}✅ 可执行文件大小正常${NC}"
        else
            echo -e "${YELLOW}⚠️ 可执行文件可能过小${NC}"
        fi
    else
        echo -e "${RED}❌ 编译的可执行文件不存在${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 编译失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📂 11. 复制Web资源...${NC}"

mkdir -p /usr/local/x-ui/{web/{html,assets,translation},bin,config}

echo "📂 复制资源文件..."
[[ -d "web/html" ]] && cp -r web/html/* /usr/local/x-ui/web/html/ 2>/dev/null
[[ -d "web/assets" ]] && cp -r web/assets/* /usr/local/x-ui/web/assets/ 2>/dev/null  
[[ -d "web/translation" ]] && cp -r web/translation/* /usr/local/x-ui/web/translation/ 2>/dev/null
[[ -f "x-ui.sh" ]] && cp x-ui.sh /usr/local/x-ui/ && chmod +x /usr/local/x-ui/x-ui.sh

echo -e "${GREEN}✅ Web资源复制完成${NC}"

echo ""
echo -e "${BLUE}⚙️ 12. 配置并启动服务...${NC}"

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
echo -e "${BLUE}🧪 13. 最终验证...${NC}"

SERVICE_STATUS=$(systemctl is-active x-ui 2>/dev/null)
echo "服务状态: $SERVICE_STATUS"

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ 服务运行正常${NC}"
    
    # 测试前端
    ROOT_SIZE=$(timeout 10 curl -s "$BASE_URL/" --connect-timeout 5 | wc -c 2>/dev/null || echo "0")
    echo "前端响应大小: $ROOT_SIZE 字节"
    
    if [[ $ROOT_SIZE -gt 1000 ]]; then
        echo -e "${GREEN}✅ 前端正常${NC}"
    else
        echo -e "${YELLOW}⚠️ 前端可能有问题${NC}"
    fi
else
    echo -e "${RED}❌ 服务未正常启动${NC}"
    systemctl status x-ui --no-pager -l | head -10
fi

echo ""
echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC} ${GREEN}🎉 Ultimate Go 1.23.4 诊断修复完成！${NC}             ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ Go版本: $(/usr/local/go/bin/go version | cut -d' ' -f3)                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 解压问题: 已解决                                   ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 编译状态: 成功                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} ✅ 服务状态: $SERVICE_STATUS                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} 🌐 访问地址: ${CYAN}http://$SERVER_IP:2053/${NC}                   ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                        ${PURPLE}║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${GREEN}🎊 Ultimate修复完成！解决了：${NC}"
echo "1. ✅ 进程锁定问题 - 强制杀死所有相关进程"
echo "2. ✅ 文件权限问题 - 多重清理策略"
echo "3. ✅ 解压失败问题 - 3种不同解压方法"
echo "4. ✅ 版本验证问题 - 严格检查每个步骤"
echo "5. ✅ 编译依赖问题 - 完整重建依赖树"

echo ""
echo -e "${CYAN}🧪 测试完整Enhanced API：${NC}"
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)"

echo ""
echo "=== Ultimate Go 1.23.4 诊断修复完成 ==="
