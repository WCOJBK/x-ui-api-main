#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${blue}=== 3X-UI Enhanced API 快速修复安装 ===${plain}"

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}请使用root权限运行此脚本${plain}" && exit 1

# 停止当前卡住的安装进程
echo -e "${yellow}终止可能卡住的进程...${plain}"
pkill -f "go.*download" || true
pkill -f "go.*build" || true
sleep 2

# 清理Go模块缓存
echo -e "${yellow}清理Go模块缓存...${plain}"
go clean -modcache 2>/dev/null || true

cd /tmp
rm -rf x-ui-enhanced-quick
echo -e "${blue}下载修复版源码...${plain}"
git clone https://github.com/WCOJBK/x-ui-api-main.git x-ui-enhanced-quick
cd x-ui-enhanced-quick

# 设置Go环境变量，使用国内代理
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=off
export GO111MODULE=on

echo -e "${blue}应用兼容性修复...${plain}"

# 修复go.mod文件 - 使用兼容Go 1.22的版本
cat > go.mod << 'EOF'
module x-ui

go 1.21

require (
	github.com/gin-contrib/gzip v1.2.2
	github.com/gin-contrib/sessions v1.0.2
	github.com/gin-gonic/gin v1.10.0
	github.com/goccy/go-json v0.10.5
	github.com/google/uuid v1.6.0
	github.com/mymmrac/telego v0.32.0
	github.com/nicksnyder/go-i18n/v2 v2.5.1
	github.com/op/go-logging v0.0.0-20160315200505-970db520ece7
	github.com/pelletier/go-toml/v2 v2.2.3
	github.com/robfig/cron/v3 v3.0.1
	github.com/shirou/gopsutil/v4 v4.25.1
	github.com/valyala/fasthttp v1.58.0
	github.com/xtls/xray-core v1.8.24
	go.uber.org/atomic v1.11.0
	golang.org/x/text v0.21.0
	google.golang.org/grpc v1.70.0
	gorm.io/driver/sqlite v1.5.7
	gorm.io/gorm v1.25.12
)
EOF

echo -e "${blue}修复源码编译错误...${plain}"

# 修复 web/controller/inbound.go 中未使用的变量
sed -i '414s/data := fmt.Sprintf("%s-%d", email, timestamp)/\/\/ Removed unused variable/' web/controller/inbound.go 2>/dev/null || true

echo -e "${blue}下载依赖并编译...${plain}"
go mod tidy
if [[ $? -ne 0 ]]; then
    echo -e "${yellow}依赖下载失败，尝试清理缓存后重试...${plain}"
    go clean -modcache
    go mod tidy
fi

echo -e "${blue}开始编译（可能需要几分钟）...${plain}"
go build -ldflags="-s -w" -o x-ui main.go

if [[ $? -eq 0 ]]; then
    echo -e "${green}✅ 编译成功！${plain}"
else
    echo -e "${red}❌ 编译失败${plain}"
    echo -e "${yellow}尝试使用更简单的构建参数...${plain}"
    go build -o x-ui main.go
    if [[ $? -ne 0 ]]; then
        echo -e "${red}编译仍然失败，请查看错误信息${plain}"
        exit 1
    fi
fi

# 停止现有服务
echo -e "${yellow}停止现有服务...${plain}"
systemctl stop x-ui 2>/dev/null || true

# 备份现有安装
if [[ -d /usr/local/x-ui ]]; then
    echo -e "${yellow}备份现有安装...${plain}"
    mv /usr/local/x-ui /usr/local/x-ui-backup-$(date +%Y%m%d_%H%M%S)
fi

# 安装新版本
echo -e "${blue}安装增强版本...${plain}"
mkdir -p /usr/local/x-ui/bin
cp x-ui /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/x-ui

# 复制其他必要文件
cp x-ui.sh /usr/local/x-ui/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh
cp x-ui.sh /usr/bin/x-ui
chmod +x /usr/bin/x-ui
cp x-ui.service /etc/systemd/system/

# 下载xray核心
echo -e "${blue}下载Xray核心...${plain}"
XRAY_VERSION="v1.8.24"
wget -q -O /tmp/Xray-linux-amd64.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-amd64.zip" 2>/dev/null
if [[ $? -eq 0 ]]; then
    unzip -o /tmp/Xray-linux-amd64.zip -d /usr/local/x-ui/bin/
    mv /usr/local/x-ui/bin/xray /usr/local/x-ui/bin/xray-linux-amd64 2>/dev/null || true
    chmod +x /usr/local/x-ui/bin/xray-linux-amd64
    rm /tmp/Xray-linux-amd64.zip
else
    echo -e "${yellow}Warning: Xray核心下载失败${plain}"
fi

# 启动服务
echo -e "${blue}启动服务...${plain}"
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 等待服务启动
sleep 3

if systemctl is-active --quiet x-ui; then
    echo -e "${green}🎉 安装成功！${plain}"
    echo -e ""
    
    # 配置随机登录信息
    if [[ ! -f /etc/x-ui/x-ui.db ]] || [[ ! -s /etc/x-ui/x-ui.db ]]; then
        echo -e "${blue}配置初始设置...${plain}"
        /usr/local/x-ui/x-ui migrate
        
        username=$(openssl rand -base64 6 | tr -d '+/=' | head -c 8)
        password=$(openssl rand -base64 8 | tr -d '+/=' | head -c 10)
        port=$(shuf -i 10000-65000 -n 1)
        webpath=$(openssl rand -base64 9 | tr -d '+/=' | head -c 12)
        
        /usr/local/x-ui/x-ui setting -username "$username" -password "$password" -port "$port" -webBasePath "$webpath"
        
        server_ip=$(curl -s https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")
        
        echo -e ""
        echo -e "${green}=== 面板登录信息 ===${plain}"
        echo -e "${blue}用户名: ${green}$username${plain}"
        echo -e "${blue}密码: ${green}$password${plain}"
        echo -e "${blue}端口: ${green}$port${plain}"
        echo -e "${blue}路径: ${green}/$webpath${plain}"
        echo -e "${blue}完整访问地址: ${green}http://$server_ip:$port/$webpath${plain}"
        echo -e ""
    fi
    
    echo -e "${blue}🚀 Enhanced API 功能亮点:${plain}"
    echo -e "✅ API接口总数: ${green}49个${plain} (原版19个)"
    echo -e "✅ 出站管理: ${green}6个API${plain} (列表/添加/删除/更新/重置流量)"
    echo -e "✅ 路由管理: ${green}5个API${plain} (获取/更新/添加规则/删除规则/更新规则)"
    echo -e "✅ 订阅管理: ${green}5个API${plain} (设置/启用/禁用/获取订阅链接)"
    echo -e "✅ 高级客户端: 自定义订阅/流量限制/到期时间"
    echo -e "✅ 兼容性修复: 适配Xray-core v1.8.24和Go 1.22+"
    
else
    echo -e "${red}❌ 服务启动失败${plain}"
    echo -e "${yellow}查看日志: journalctl -u x-ui --no-pager${plain}"
fi

# 清理
cd /
rm -rf /tmp/x-ui-enhanced-quick

echo -e ""
echo -e "${green}使用 'x-ui' 命令管理面板${plain}"
echo -e "${blue}API文档: https://github.com/WCOJBK/x-ui-api-main/blob/main/COMPLETE_API_DOCUMENTATION.md${plain}"
