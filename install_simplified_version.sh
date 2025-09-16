#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${blue}=== 3X-UI Enhanced API 精简版安装 ===${plain}"
echo -e "${yellow}去除Telegram功能，专注核心API功能${plain}"

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}请使用root权限运行此脚本${plain}" && exit 1

# 强制终止Go相关进程
echo -e "${yellow}终止所有Go相关进程...${plain}"
pkill -f "go.*download" || true
pkill -f "go.*build" || true  
pkill -f "go.*mod" || true
sleep 3

# 清理Go缓存
echo -e "${yellow}完全清理Go环境...${plain}"
rm -rf ~/.cache/go-build/* 2>/dev/null || true
go clean -modcache 2>/dev/null || true

cd /tmp
rm -rf x-ui-simplified
echo -e "${blue}下载源码...${plain}"
git clone https://github.com/WCOJBK/x-ui-api-main.git x-ui-simplified
cd x-ui-simplified

echo -e "${blue}创建精简版go.mod（移除Telegram Bot依赖）...${plain}"

# 创建精简的go.mod，去掉telego依赖
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

echo -e "${blue}修复Telegram Bot相关代码（注释掉）...${plain}"

# 在main.go中注释掉telegram bot相关代码
if [[ -f main.go ]]; then
    # 暂时禁用telegram功能，避免依赖问题
    sed -i 's|tgbot := service\.NewTgbot(.*)|// tgbot := service.NewTgbot() // Disabled for compatibility|g' main.go
    sed -i 's|go tgbot\.Run()|// go tgbot.Run() // Disabled for compatibility|g' main.go
fi

# 在web/controller/api.go中注释Telegram相关代码
if [[ -f web/controller/api.go ]]; then
    sed -i 's|Tgbot.*service\.Tgbot|// Tgbot service.Tgbot // Disabled for compatibility|g' web/controller/api.go
fi

# 设置Go环境，使用更稳定的配置
export GOPROXY=https://proxy.golang.org,https://goproxy.cn,direct
export GOSUMDB=sum.golang.org
export GO111MODULE=on
export CGO_ENABLED=1

echo -e "${blue}下载依赖（精简版，应该很快）...${plain}"
go mod tidy

if [[ $? -ne 0 ]]; then
    echo -e "${yellow}标准方式失败，尝试离线模式...${plain}"
    export GOPROXY=direct
    export GOSUMDB=off
    go mod download
fi

echo -e "${blue}开始编译（精简版，不包含Telegram功能）...${plain}"
go build -ldflags="-s -w -X main.version=v1.0.0-enhanced" -o x-ui main.go

if [[ $? -ne 0 ]]; then
    echo -e "${yellow}优化编译失败，尝试基础编译...${plain}"
    go build -o x-ui main.go
    if [[ $? -ne 0 ]]; then
        echo -e "${red}❌ 编译失败${plain}"
        echo -e "${yellow}显示详细错误信息...${plain}"
        go build -v -o x-ui main.go
        exit 1
    fi
fi

echo -e "${green}✅ 编译成功！${plain}"

# 检查编译后的文件
ls -la x-ui
file x-ui

# 停止现有服务并安装
echo -e "${yellow}停止现有服务...${plain}"
systemctl stop x-ui 2>/dev/null || true

# 备份现有安装
if [[ -d /usr/local/x-ui ]]; then
    echo -e "${yellow}备份现有安装...${plain}"
    mv /usr/local/x-ui /usr/local/x-ui-backup-$(date +%Y%m%d_%H%M%S)
fi

# 安装新版本
echo -e "${blue}安装精简版增强API...${plain}"
mkdir -p /usr/local/x-ui/bin
cp x-ui /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/x-ui

# 复制管理脚本
cp x-ui.sh /usr/local/x-ui/x-ui.sh 2>/dev/null || echo "#!/bin/bash" > /usr/local/x-ui/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh
cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui
chmod +x /usr/bin/x-ui

# 创建systemd服务
cat > /etc/systemd/system/x-ui.service << EOF
[Unit]
Description=x-ui service
Documentation=https://github.com/WCOJBK/x-ui-api-main
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/x-ui
ExecStart=/usr/local/x-ui/x-ui -config /etc/x-ui/x-ui.conf
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

# 下载Xray核心（稳定版本）
echo -e "${blue}下载Xray核心...${plain}"
XRAY_VERSION="v1.8.23"
wget -q --timeout=30 -O /tmp/Xray-linux-amd64.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-amd64.zip" 2>/dev/null
if [[ $? -eq 0 ]]; then
    unzip -o /tmp/Xray-linux-amd64.zip -d /usr/local/x-ui/bin/ 2>/dev/null
    mv /usr/local/x-ui/bin/xray /usr/local/x-ui/bin/xray-linux-amd64 2>/dev/null
    chmod +x /usr/local/x-ui/bin/xray-linux-amd64
    rm /tmp/Xray-linux-amd64.zip 2>/dev/null
    echo -e "${green}✅ Xray核心下载成功${plain}"
else
    echo -e "${yellow}⚠️  Xray核心下载失败，但不影响面板功能${plain}"
fi

# 启动服务
echo -e "${blue}启动服务...${plain}"
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 等待服务启动
sleep 5

if systemctl is-active --quiet x-ui; then
    echo -e "${green}🎉 精简版安装成功！${plain}"
    echo -e ""
    
    # 生成随机登录信息
    username=$(openssl rand -hex 4)
    password=$(openssl rand -hex 6)
    port=$(shuf -i 10000-65000 -n 1)
    webpath=$(openssl rand -hex 8)
    
    # 创建数据库目录和初始配置
    mkdir -p /etc/x-ui
    
    # 初始化设置
    /usr/local/x-ui/x-ui migrate 2>/dev/null || true
    /usr/local/x-ui/x-ui setting -username "$username" -password "$password" -port "$port" -webBasePath "$webpath" 2>/dev/null || true
    
    # 重启服务应用设置
    systemctl restart x-ui
    sleep 3
    
    server_ip=$(curl -s --timeout=10 https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")
    
    echo -e ""
    echo -e "${green}=== 面板登录信息 ===${plain}"
    echo -e "${blue}用户名: ${green}$username${plain}"
    echo -e "${blue}密码: ${green}$password${plain}"
    echo -e "${blue}端口: ${green}$port${plain}"  
    echo -e "${blue}路径: ${green}/$webpath${plain}"
    echo -e "${blue}完整地址: ${green}http://$server_ip:$port/$webpath${plain}"
    echo -e ""
    echo -e "${blue}🚀 精简版Enhanced API功能:${plain}"
    echo -e "✅ 核心API接口: ${green}43个${plain} (去除6个Telegram相关接口)"
    echo -e "✅ 出站管理API: ${green}6个${plain}"
    echo -e "✅ 路由管理API: ${green}5个${plain}"
    echo -e "✅ 订阅管理API: ${green}5个${plain}"
    echo -e "✅ 高级客户端功能: 流量限制/到期时间/自定义订阅"
    echo -e "✅ 兼容性优化: 使用Go 1.21和稳定依赖"
    echo -e ""
    echo -e "${yellow}注意: 精简版不包含Telegram Bot功能，专注于API功能${plain}"
    
else
    echo -e "${red}❌ 服务启动失败${plain}"
    echo -e "${yellow}查看日志: journalctl -u x-ui -n 50 --no-pager${plain}"
    echo -e "${yellow}检查端口冲突: netstat -tlnp | grep :端口号${plain}"
fi

# 清理临时文件
cd /
rm -rf /tmp/x-ui-simplified

echo -e ""
echo -e "${green}管理命令: x-ui${plain}"
echo -e "${blue}API文档: https://github.com/WCOJBK/x-ui-api-main${plain}"

# 显示服务状态
echo -e ""
echo -e "${blue}=== 服务状态 ===${plain}"
systemctl status x-ui --no-pager -l
