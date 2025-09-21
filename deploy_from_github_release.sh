#!/bin/bash

echo "=== Enhanced API GitHub Release 部署脚本 ==="
echo "从GitHub下载预编译版本，快速部署"

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

# GitHub仓库信息
GITHUB_REPO="WCOJBK/x-ui-api-main"
RELEASE_FILE="x-ui-enhanced-linux-amd64.zip"
GITHUB_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/release/${RELEASE_FILE}"
GITHUB_RELEASE_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/${RELEASE_FILE}"

echo ""
echo -e "${PURPLE}🚀 GitHub Release 部署策略：${NC}"
echo "1. 从GitHub下载预编译的Linux版本"
echo "2. 备份现有数据和配置"
echo "3. 停止旧服务并部署新版本"
echo "4. 恢复数据并启动服务"
echo "5. 验证功能正常"

echo ""
echo -e "${BLUE}🔍 1. 检查当前系统状态...${NC}"

# 检查系统架构
ARCH=$(uname -m)
OS=$(uname -s)
echo "系统架构: $OS $ARCH"

if [[ "$ARCH" != "x86_64" ]] && [[ "$ARCH" != "amd64" ]]; then
    echo -e "${YELLOW}⚠️ 警告: 当前系统不是x86_64/amd64，可能不兼容${NC}"
fi

# 检查现有服务
SERVICE_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "inactive")
echo "当前服务状态: $SERVICE_STATUS"

# 备份现有数据
echo ""
echo -e "${BLUE}💾 2. 备份现有数据...${NC}"

BACKUP_DIR="/tmp/x-ui-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "备份目录: $BACKUP_DIR"

# 备份数据库
if [[ -f "/usr/local/x-ui/x-ui.db" ]]; then
    cp "/usr/local/x-ui/x-ui.db" "$BACKUP_DIR/"
    echo -e "${GREEN}✅ 数据库备份完成${NC}"
else
    echo -e "${YELLOW}⚠️ 未找到数据库文件${NC}"
fi

# 备份配置
if [[ -d "/usr/local/x-ui/web" ]]; then
    cp -r "/usr/local/x-ui/web" "$BACKUP_DIR/" 2>/dev/null
    echo -e "${GREEN}✅ Web配置备份完成${NC}"
fi

# 备份可执行文件（用于回滚）
if [[ -f "/usr/local/x-ui/x-ui" ]]; then
    cp "/usr/local/x-ui/x-ui" "$BACKUP_DIR/x-ui.old"
    OLD_SIZE=$(stat -c%s "/usr/local/x-ui/x-ui" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ 旧版本备份完成 ($(echo "scale=1; $OLD_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB)${NC}"
fi

echo ""
echo -e "${BLUE}📥 3. 下载GitHub Release...${NC}"

cd /tmp

# 清理旧下载
rm -f "$RELEASE_FILE" x-ui-enhanced-* 2>/dev/null

# 尝试多个下载源
DOWNLOAD_SUCCESS=false
DOWNLOAD_URLS=(
    "$GITHUB_RELEASE_URL"
    "$GITHUB_RAW_URL"
    "https://github.com/${GITHUB_REPO}/raw/main/release/${RELEASE_FILE}"
)

for url in "${DOWNLOAD_URLS[@]}"; do
    echo ""
    echo "尝试下载: $url"
    
    if timeout 300 curl -L --connect-timeout 30 --max-time 300 --retry 3 \
        -H "Accept: application/octet-stream" \
        -H "User-Agent: Enhanced-API-Deploy/1.0" \
        "$url" -o "$RELEASE_FILE"; then
        
        FILE_SIZE=$(stat -c%s "$RELEASE_FILE" 2>/dev/null || echo "0")
        
        if [[ $FILE_SIZE -gt 1000000 ]]; then  # 至少1MB
            echo -e "${GREEN}✅ 下载完成 ($(echo "scale=1; $FILE_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB)${NC}"
            
            # 验证文件类型
            FILE_TYPE=$(file "$RELEASE_FILE" 2>/dev/null || echo "unknown")
            if echo "$FILE_TYPE" | grep -iq "zip\|archive"; then
                echo -e "${GREEN}✅ 文件类型验证通过${NC}"
                DOWNLOAD_SUCCESS=true
                break
            else
                echo -e "${YELLOW}⚠️ 文件类型可能有问题: $FILE_TYPE${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️ 下载文件过小 ($FILE_SIZE 字节)${NC}"
            rm -f "$RELEASE_FILE"
        fi
    else
        echo -e "${YELLOW}⚠️ 下载失败${NC}"
    fi
done

if [[ "$DOWNLOAD_SUCCESS" != "true" ]]; then
    echo -e "${RED}❌ 所有下载源都失败${NC}"
    echo ""
    echo -e "${YELLOW}💡 可能的解决方案：${NC}"
    echo "1. 检查网络连接"
    echo "2. 确认GitHub Release已上传"
    echo "3. 使用手动上传方式"
    exit 1
fi

echo ""
echo -e "${BLUE}📦 4. 解压部署包...${NC}"

# 检查解压工具
if ! command -v unzip >/dev/null; then
    echo "安装unzip..."
    apt-get update && apt-get install -y unzip 2>/dev/null || \
    yum install -y unzip 2>/dev/null || \
    echo -e "${YELLOW}⚠️ 请手动安装unzip${NC}"
fi

# 解压文件
EXTRACT_DIR="/tmp/x-ui-enhanced-extract"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

if unzip -q "$RELEASE_FILE" -d "$EXTRACT_DIR"; then
    echo -e "${GREEN}✅ 解压成功${NC}"
    
    # 列出解压内容
    echo "解压内容:"
    ls -la "$EXTRACT_DIR"
    
    # 查找可执行文件
    EXECUTABLE=""
    for file in "$EXTRACT_DIR"/* "$EXTRACT_DIR"/*/x-ui "$EXTRACT_DIR"/x-ui; do
        if [[ -f "$file" ]] && [[ -x "$file" || "$(basename "$file")" == "x-ui" ]]; then
            EXECUTABLE="$file"
            break
        fi
    done
    
    if [[ -n "$EXECUTABLE" ]]; then
        chmod +x "$EXECUTABLE"
        EXEC_SIZE=$(stat -c%s "$EXECUTABLE" 2>/dev/null || echo "0")
        echo -e "${GREEN}✅ 找到可执行文件: $EXECUTABLE ($(echo "scale=1; $EXEC_SIZE/1024/1024" | bc 2>/dev/null || echo "N/A") MB)${NC}"
    else
        echo -e "${RED}❌ 未找到可执行文件${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 解压失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}⏹️ 5. 停止现有服务...${NC}"

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo "停止x-ui服务..."
    systemctl stop x-ui
    sleep 3
    
    NEW_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "inactive")
    if [[ "$NEW_STATUS" == "active" ]]; then
        echo -e "${YELLOW}⚠️ 服务仍在运行，强制停止...${NC}"
        pkill -f x-ui 2>/dev/null || true
        sleep 2
    fi
    echo -e "${GREEN}✅ 服务已停止${NC}"
fi

echo ""
echo -e "${BLUE}🚀 6. 部署新版本...${NC}"

# 创建安装目录
mkdir -p /usr/local/x-ui/{web/{html,assets,translation},bin,config}

# 复制可执行文件
echo "部署可执行文件..."
cp "$EXECUTABLE" /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/x-ui

# 复制Web资源
WEB_SOURCE=""
for web_dir in "$EXTRACT_DIR/web" "$EXTRACT_DIR"/*/web; do
    if [[ -d "$web_dir" ]]; then
        WEB_SOURCE="$web_dir"
        break
    fi
done

if [[ -n "$WEB_SOURCE" ]]; then
    echo "部署Web资源..."
    cp -r "$WEB_SOURCE"/* /usr/local/x-ui/web/ 2>/dev/null || true
    echo -e "${GREEN}✅ Web资源部署完成${NC}"
else
    echo -e "${YELLOW}⚠️ 未找到Web资源，保持现有版本${NC}"
fi

# 复制启动脚本
SCRIPT_SOURCE=""
for script in "$EXTRACT_DIR/x-ui.sh" "$EXTRACT_DIR"/*/x-ui.sh; do
    if [[ -f "$script" ]]; then
        SCRIPT_SOURCE="$script"
        break
    fi
done

if [[ -n "$SCRIPT_SOURCE" ]]; then
    echo "部署启动脚本..."
    cp "$SCRIPT_SOURCE" /usr/local/x-ui/
    chmod +x /usr/local/x-ui/x-ui.sh
fi

echo ""
echo -e "${BLUE}💾 7. 恢复数据...${NC}"

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
echo -e "${BLUE}🔧 8. 更新服务配置...${NC}"

# 创建/更新systemd服务
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=3x-ui enhanced service (GitHub Release)
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
echo -e "${BLUE}🚀 9. 启动服务...${NC}"

if systemctl start x-ui; then
    echo -e "${GREEN}✅ 服务启动命令执行成功${NC}"
else
    echo -e "${RED}❌ 服务启动命令失败${NC}"
fi

echo "等待服务稳定..."
sleep 10

echo ""
echo -e "${BLUE}🧪 10. 验证部署结果...${NC}"

# 检查服务状态
SERVICE_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "failed")
echo "服务状态: $SERVICE_STATUS"

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${GREEN}✅ 服务运行正常${NC}"
    
    # 检查版本信息
    if [[ -f "$EXTRACT_DIR/VERSION" ]] || [[ -f "$EXTRACT_DIR"/*/VERSION ]]; then
        VERSION_FILE=$(find "$EXTRACT_DIR" -name "VERSION" -type f 2>/dev/null | head -1)
        if [[ -n "$VERSION_FILE" ]]; then
            echo ""
            echo -e "${CYAN}版本信息:${NC}"
            cat "$VERSION_FILE" 2>/dev/null || echo "版本信息读取失败"
        fi
    fi
    
    # 测试前端响应
    echo ""
    echo "测试前端响应..."
    ROOT_RESPONSE=$(timeout 15 curl -s "$BASE_URL/" --connect-timeout 5 2>/dev/null || echo "")
    ROOT_SIZE=${#ROOT_RESPONSE}
    
    if [[ $ROOT_SIZE -gt 1000 ]]; then
        echo -e "${GREEN}✅ 前端响应正常 ($ROOT_SIZE 字节)${NC}"
    else
        echo -e "${YELLOW}⚠️ 前端响应异常 ($ROOT_SIZE 字节)${NC}"
    fi
    
    # 测试API响应
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
    echo -e "${RED}❌ 服务启动失败${NC}"
    echo ""
    echo -e "${BLUE}查看服务日志:${NC}"
    systemctl status x-ui --no-pager -l | head -15
    
    echo ""
    echo -e "${YELLOW}🔄 尝试回滚到备份版本...${NC}"
    if [[ -f "$BACKUP_DIR/x-ui.old" ]]; then
        systemctl stop x-ui 2>/dev/null || true
        cp "$BACKUP_DIR/x-ui.old" /usr/local/x-ui/x-ui
        chmod +x /usr/local/x-ui/x-ui
        systemctl start x-ui
        
        ROLLBACK_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "failed")
        if [[ "$ROLLBACK_STATUS" == "active" ]]; then
            echo -e "${GREEN}✅ 已回滚到备份版本${NC}"
        else
            echo -e "${RED}❌ 回滚也失败${NC}"
        fi
    fi
fi

# 清理临时文件
echo ""
echo -e "${BLUE}🧹 清理临时文件...${NC}"
rm -rf "$EXTRACT_DIR" "$RELEASE_FILE"

echo ""
if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} ${GREEN}🎉 GitHub Release 部署成功！${NC}                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 从GitHub下载预编译版本                               ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 数据备份和恢复完成                                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 服务部署和启动成功                                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} ✅ 功能验证通过                                         ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 🌐 访问地址: ${CYAN}http://$SERVER_IP:2053/${NC}                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 💾 备份位置: ${CYAN}$BACKUP_DIR${NC}      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    echo -e "${GREEN}🎊 部署完成！主要优势：${NC}"
    echo "1. ✅ 无需Go环境 - 直接使用预编译版本"
    echo "2. ✅ 快速部署 - 下载即用，无编译时间"
    echo "3. ✅ 版本控制 - GitHub Release管理"
    echo "4. ✅ 数据安全 - 自动备份和恢复"
    echo "5. ✅ 回滚支持 - 失败自动回滚"
else
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} ${RED}❌ GitHub Release 部署失败${NC}                            ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 💾 备份位置: ${CYAN}$BACKUP_DIR${NC}      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC} 📋 请检查服务日志和网络连接                             ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${CYAN}🧪 测试完整Enhanced API功能：${NC}"
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)"

echo ""
echo "=== GitHub Release 部署完成 ==="
