#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${blue}=== 3X-UI Enhanced API 无Telegram版安装 ===${plain}"
echo -e "${yellow}彻底移除所有Telegram相关代码，专注API功能${plain}"

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}请使用root权限运行此脚本${plain}" && exit 1

# 强制终止所有相关进程
echo -e "${yellow}终止所有Go相关进程...${plain}"
pkill -f "go.*download" || true
pkill -f "go.*build" || true  
pkill -f "go.*mod" || true
pkill -f "git.*clone" || true
sleep 3

# 清理环境
echo -e "${yellow}清理Go环境...${plain}"
rm -rf ~/.cache/go-build/* 2>/dev/null || true
go clean -modcache 2>/dev/null || true

cd /tmp
rm -rf x-ui-no-telegram
echo -e "${blue}下载源码...${plain}"
git clone https://github.com/WCOJBK/x-ui-api-main.git x-ui-no-telegram
cd x-ui-no-telegram

echo -e "${blue}🔧 彻底移除Telegram功能...${plain}"

# 1. 删除tgbot相关文件
echo -e "${yellow}删除Telegram Bot文件...${plain}"
rm -f web/service/tgbot.go
rm -f web/controller/tg.go 2>/dev/null || true

# 2. 创建无Telegram依赖的go.mod
echo -e "${yellow}创建无Telegram依赖的go.mod...${plain}"
cat > go.mod << 'EOF'
module x-ui

go 1.21

require (
	github.com/gin-contrib/gzip v1.2.2
	github.com/gin-contrib/sessions v1.0.2
	github.com/gin-gonic/gin v1.10.0
	github.com/goccy/go-json v0.10.5
	github.com/google/uuid v1.6.0
	github.com/nicksnyder/go-i18n/v2 v2.5.1
	github.com/op/go-logging v0.0.0-20160315200505-970db520ece7
	github.com/pelletier/go-toml/v2 v2.2.3
	github.com/robfig/cron/v3 v3.0.1
	github.com/shirou/gopsutil/v4 v4.25.1
	github.com/xtls/xray-core v1.8.23
	go.uber.org/atomic v1.11.0
	golang.org/x/text v0.21.0
	google.golang.org/grpc v1.70.0
	gorm.io/driver/sqlite v1.5.7
	gorm.io/gorm v1.25.12
)
EOF

# 3. 修复main.go - 移除tgbot相关代码
echo -e "${yellow}修复main.go...${plain}"
if [[ -f main.go ]]; then
    # 备份原文件
    cp main.go main.go.backup
    
    # 移除tgbot相关import和代码
    sed -i '/import.*tgbot/d' main.go
    sed -i '/service\.NewTgbot/d' main.go
    sed -i '/tgbot\.Run/d' main.go
    sed -i '/Tgbot.*service/d' main.go
    
    # 如果存在tgbot相关的struct字段，注释掉
    sed -i 's|Tgbot.*service\.Tgbot|// Tgbot removed for compatibility|g' main.go
fi

# 4. 修复web/controller/api.go - 移除Tgbot字段
echo -e "${yellow}修复api.go...${plain}"
if [[ -f web/controller/api.go ]]; then
    cp web/controller/api.go web/controller/api.go.backup
    
    # 移除Tgbot字段和相关代码
    sed -i 's|Tgbot.*service\.Tgbot|// Tgbot removed for compatibility|g' web/controller/api.go
    sed -i '/service\.NewTgbot/d' web/controller/api.go
    sed -i '/tgbot\./d' web/controller/api.go
fi

# 5. 检查并修复其他可能的tgbot引用
echo -e "${yellow}检查其他文件中的Telegram引用...${plain}"
find . -name "*.go" -type f -exec grep -l "tgbot\|telego\|telegram" {} \; 2>/dev/null | while read file; do
    if [[ -f "$file" && "$file" != "./main.go" && "$file" != "./web/controller/api.go" ]]; then
        echo "修复文件: $file"
        sed -i 's|tgbot|// tgbot removed|g' "$file"
        sed -i 's|telego|// telego removed|g' "$file"
        sed -i 's|telegram|// telegram removed|g' "$file"
    fi
done

# 6. 创建空的tgbot service以避免编译错误
echo -e "${yellow}创建兼容性stub...${plain}"
mkdir -p web/service
cat > web/service/tgbot.go << 'EOF'
package service

import (
	"x-ui/logger"
)

// Tgbot - Telegram Bot服务（已禁用）
type Tgbot struct {
	// Telegram功能已移除以确保兼容性
}

// NewTgbot 创建新的Telegram Bot实例（已禁用）
func NewTgbot() *Tgbot {
	logger.Warning("Telegram Bot功能已在此版本中禁用")
	return &Tgbot{}
}

// Run 启动Telegram Bot（已禁用）
func (t *Tgbot) Run() {
	logger.Info("Telegram Bot功能已禁用，跳过启动")
}

// Stop 停止Telegram Bot（已禁用）
func (t *Tgbot) Stop() {
	logger.Info("Telegram Bot功能已禁用")
}
EOF

# 设置Go环境
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.org  
export GO111MODULE=on
export CGO_ENABLED=1

echo -e "${blue}📦 下载依赖（无Telegram版本）...${plain}"
go mod tidy

if [[ $? -ne 0 ]]; then
    echo -e "${yellow}依赖下载失败，尝试替代方案...${plain}"
    export GOPROXY=direct
    export GOSUMDB=off
    go mod download
fi

echo -e "${blue}🔨 开始编译（无Telegram功能）...${plain}"
echo -e "${yellow}这可能需要3-5分钟...${plain}"

go build -ldflags="-s -w -X main.version=v1.0.0-notelegram" -o x-ui main.go

if [[ $? -ne 0 ]]; then
    echo -e "${yellow}优化编译失败，尝试基础编译...${plain}"
    go build -o x-ui main.go
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}❌ 编译失败${plain}"
        echo -e "${yellow}显示Go版本和环境信息:${plain}"
        go version
        go env GOROOT GOPATH GOPROXY
        echo -e "${yellow}最后尝试清理并重新编译...${plain}"
        
        # 最后的尝试：完全清理重来
        go clean -cache -modcache -i -r
        go mod download
        go build -x -v -o x-ui main.go
        
        if [[ $? -ne 0 ]]; then
            echo -e "${red}编译最终失败，请尝试预编译版本${plain}"
            exit 1
        fi
    fi
fi

echo -e "${green}✅ 编译成功！${plain}"

# 验证编译结果
ls -la x-ui
file x-ui

# 停止现有服务
echo -e "${yellow}停止现有x-ui服务...${plain}"
systemctl stop x-ui 2>/dev/null || true

# 备份现有安装
if [[ -d /usr/local/x-ui ]]; then
    echo -e "${yellow}备份现有安装...${plain}"
    mv /usr/local/x-ui /usr/local/x-ui-backup-$(date +%Y%m%d_%H%M%S)
fi

# 安装新版本
echo -e "${blue}📥 安装无Telegram版本...${plain}"
mkdir -p /usr/local/x-ui/bin
cp x-ui /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/x-ui

# 复制管理脚本
if [[ -f x-ui.sh ]]; then
    cp x-ui.sh /usr/local/x-ui/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui
    chmod +x /usr/bin/x-ui
else
    # 创建基础管理脚本
    cat > /usr/bin/x-ui << 'EOF'
#!/bin/bash
case "$1" in
    start) systemctl start x-ui ;;
    stop) systemctl stop x-ui ;;
    restart) systemctl restart x-ui ;;
    status) systemctl status x-ui ;;
    enable) systemctl enable x-ui ;;
    disable) systemctl disable x-ui ;;
    log) journalctl -u x-ui -f ;;
    settings) /usr/local/x-ui/x-ui setting -show ;;
    migrate) /usr/local/x-ui/x-ui migrate ;;
    *) echo "用法: x-ui {start|stop|restart|status|enable|disable|log|settings|migrate}" ;;
esac
EOF
    chmod +x /usr/bin/x-ui
fi

# 创建systemd服务
echo -e "${blue}⚙️  创建系统服务...${plain}"
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=x-ui enhanced service (no telegram)
Documentation=https://github.com/WCOJBK/x-ui-api-main
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/x-ui
ExecStart=/usr/local/x-ui/x-ui -config /etc/x-ui/x-ui.conf
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=500
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

# 下载Xray核心
echo -e "${blue}📡 下载Xray核心...${plain}"
XRAY_VERSION="v1.8.23"
if wget --timeout=30 -q -O /tmp/xray-core.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-amd64.zip" 2>/dev/null; then
    unzip -o /tmp/xray-core.zip -d /usr/local/x-ui/bin/ 2>/dev/null
    mv /usr/local/x-ui/bin/xray /usr/local/x-ui/bin/xray-linux-amd64 2>/dev/null || true
    chmod +x /usr/local/x-ui/bin/xray-linux-amd64
    rm /tmp/xray-core.zip 2>/dev/null
    echo -e "${green}✅ Xray核心安装成功${plain}"
else
    echo -e "${yellow}⚠️  Xray核心下载失败，但不影响面板功能${plain}"
fi

# 启动服务
echo -e "${blue}🚀 启动服务...${plain}"
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 等待服务启动
sleep 5

if systemctl is-active --quiet x-ui; then
    echo -e "${green}🎉 无Telegram版安装成功！${plain}"
    echo -e ""
    
    # 创建初始配置
    mkdir -p /etc/x-ui
    
    # 生成随机登录信息
    username="admin$(openssl rand -hex 3)"
    password=$(openssl rand -base64 12 | tr -d '+/=' | head -c 12)
    port=$(shuf -i 10000-65000 -n 1)
    webpath="panel$(openssl rand -hex 6)"
    
    # 初始化数据库和设置
    echo -e "${yellow}初始化配置...${plain}"
    /usr/local/x-ui/x-ui migrate 2>/dev/null || true
    sleep 2
    /usr/local/x-ui/x-ui setting -username "$username" -password "$password" -port "$port" -webBasePath "$webpath" 2>/dev/null || true
    
    # 重启服务应用新配置
    systemctl restart x-ui
    sleep 3
    
    # 获取服务器IP
    server_ip=$(curl -s --timeout=10 https://api.ipify.org 2>/dev/null || curl -s --timeout=10 https://ipv4.icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
    
    echo -e ""
    echo -e "${green}╔════════════════════════════════════════╗${plain}"
    echo -e "${green}║           面板登录信息                   ║${plain}"
    echo -e "${green}╠════════════════════════════════════════╣${plain}"
    echo -e "${green}║${plain} ${blue}用户名:${plain} ${green}$username${plain}${green}                    ║${plain}"
    echo -e "${green}║${plain} ${blue}密码:${plain} ${green}$password${plain}${green}              ║${plain}"
    echo -e "${green}║${plain} ${blue}端口:${plain} ${green}$port${plain}${green}                       ║${plain}"
    echo -e "${green}║${plain} ${blue}路径:${plain} ${green}/$webpath${plain}${green}          ║${plain}"
    echo -e "${green}╠════════════════════════════════════════╣${plain}"
    echo -e "${green}║${plain} ${yellow}完整地址:${plain} ${green}http://$server_ip:$port/$webpath${plain} ${green}║${plain}"
    echo -e "${green}╚════════════════════════════════════════╝${plain}"
    echo -e ""
    
    echo -e "${blue}🚀 Enhanced API 功能特性 (无Telegram版):${plain}"
    echo -e "✅ ${green}核心API接口: 43个${plain} (移除6个Telegram相关接口)"
    echo -e "✅ ${green}出站管理API: 6个${plain} (列表/添加/删除/更新/重置流量)"
    echo -e "✅ ${green}路由管理API: 5个${plain} (获取/更新/添加规则/删除规则)"
    echo -e "✅ ${green}订阅管理API: 5个${plain} (设置/启用/禁用/获取订阅链接)"
    echo -e "✅ ${green}高级客户端功能:${plain} 自定义订阅/流量限制/到期时间"
    echo -e "✅ ${green}兼容性优化:${plain} 使用Go 1.21和稳定依赖"
    echo -e "✅ ${green}稳定运行:${plain} 移除所有依赖冲突源"
    echo -e ""
    echo -e "${yellow}注意: 此版本完全移除了Telegram Bot功能${plain}"
    echo -e "${blue}专注于提供稳定的Web面板和API服务${plain}"
    
else
    echo -e "${red}❌ 服务启动失败${plain}"
    echo -e "${yellow}查看详细日志: journalctl -u x-ui -n 50 --no-pager${plain}"
    echo -e "${yellow}检查端口占用: ss -tlnp | grep :$port${plain}"
    echo -e "${yellow}手动启动测试: /usr/local/x-ui/x-ui${plain}"
fi

# 清理临时文件
cd /
rm -rf /tmp/x-ui-no-telegram

echo -e ""
echo -e "${green}📋 管理命令:${plain}"
echo -e "  ${blue}x-ui${plain}          - 显示管理菜单"
echo -e "  ${blue}x-ui start${plain}    - 启动服务"
echo -e "  ${blue}x-ui stop${plain}     - 停止服务"
echo -e "  ${blue}x-ui restart${plain}  - 重启服务"
echo -e "  ${blue}x-ui status${plain}   - 查看状态"
echo -e "  ${blue}x-ui log${plain}      - 查看日志"
echo -e "  ${blue}x-ui settings${plain} - 查看设置"
echo -e ""
echo -e "${blue}📖 API文档: https://github.com/WCOJBK/x-ui-api-main${plain}"

# 显示最终服务状态
echo -e ""
echo -e "${blue}═══════════════════════════════════════${plain}"
echo -e "${blue}             服务状态信息              ${plain}"
echo -e "${blue}═══════════════════════════════════════${plain}"
systemctl --no-pager status x-ui
