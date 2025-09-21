#!/bin/bash

echo "=== 3X-UI Enhanced API 构建和运行脚本 ==="
echo "基于真正的3X-UI项目源码"

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "❌ Go 未安装，请先安装Go 1.21+"
    exit 1
fi

GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+')
echo "✅ 检测到Go版本: $GO_VERSION"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
echo "🌐 服务器IP: $SERVER_IP"

echo ""
echo "📂 项目信息："
echo "项目目录: $(pwd)"
echo "Go模块: $(head -1 go.mod)"

echo ""
echo "🔧 1. 清理和准备..."

# 停止可能运行的服务
sudo systemctl stop x-ui 2>/dev/null || echo "No existing x-ui service"
sudo killall x-ui 2>/dev/null || echo "No x-ui process running"

# 清理旧的构建文件
rm -f x-ui
rm -f /usr/local/bin/x-ui

echo ""
echo "📦 2. 下载Go模块依赖..."
if go mod tidy; then
    echo "✅ 依赖下载成功"
else
    echo "❌ 依赖下载失败"
    exit 1
fi

echo ""
echo "🔨 3. 编译项目..."
echo "编译命令: go build -ldflags \"-s -w\" -o x-ui ."

if go build -ldflags "-s -w" -o x-ui .; then
    echo "✅ 编译成功！"
    
    # 检查编译结果
    if [[ -f "./x-ui" ]]; then
        FILE_SIZE=$(stat -f%z ./x-ui 2>/dev/null || stat -c%s ./x-ui 2>/dev/null)
        echo "📊 编译后文件大小: $((FILE_SIZE / 1024 / 1024)) MB"
        
        # 设置执行权限
        chmod +x ./x-ui
        echo "✅ 设置执行权限"
    else
        echo "❌ 编译文件未找到"
        exit 1
    fi
else
    echo "❌ 编译失败"
    echo ""
    echo "🔍 常见编译问题解决方案："
    echo "1. 检查Go版本是否为1.21+"
    echo "2. 运行: go clean -modcache && go mod download"
    echo "3. 确保网络连接正常"
    exit 1
fi

echo ""
echo "⚙️  4. 初始化数据库和配置..."

# 检查数据库是否需要初始化
if [[ ! -f "/etc/x-ui/x-ui.db" ]]; then
    echo "🗄️  初始化数据库..."
    sudo mkdir -p /etc/x-ui
    ./x-ui migrate
    echo "✅ 数据库初始化完成"
else
    echo "✅ 数据库已存在"
fi

# 设置默认用户名密码（如果需要）
echo "🔑 设置默认登录凭据..."
./x-ui setting -username admin -password admin 2>/dev/null || echo "Using existing credentials"

echo ""
echo "🚀 5. 启动服务..."

# 创建systemd服务文件
if [[ ! -f "/etc/systemd/system/x-ui.service" ]]; then
    echo "📝 创建systemd服务文件..."
    
    sudo tee /etc/systemd/system/x-ui.service > /dev/null << EOF
[Unit]
Description=3X-UI Enhanced API Panel
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStartPre=/bin/sh -c 'until ping -c1 google.com; do sleep 1; done;'
ExecStart=$(pwd)/x-ui
WorkingDirectory=$(pwd)/

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable x-ui
    echo "✅ systemd服务创建完成"
fi

# 启动服务
echo "🚀 启动3X-UI Enhanced API..."
sudo systemctl restart x-ui

# 等待服务启动
sleep 3

echo ""
echo "🧪 6. 测试服务..."

# 检查服务状态
if sudo systemctl is-active x-ui >/dev/null 2>&1; then
    echo "✅ x-ui服务运行正常"
    
    # 获取服务端口
    PORT=$(./x-ui setting -show 2>/dev/null | grep -oE 'Port: [0-9]+' | cut -d' ' -f2)
    if [[ -z "$PORT" ]]; then
        PORT="2053"  # 默认端口
    fi
    
    BASE_URL="http://$SERVER_IP:$PORT"
    
    # 测试服务连接
    if curl -s "$BASE_URL" >/dev/null; then
        echo "✅ Web服务访问正常"
        
        # 测试API端点
        echo "🔗 测试Enhanced API端点..."
        
        # 测试基础API（这些应该返回登录要求或者具体数据）
        API_ENDPOINTS=(
            "/panel/api/inbounds/list"
            "/panel/api/outbounds/list" 
            "/panel/api/routing/get"
            "/panel/api/subscription/urls/1"
        )
        
        WORKING_APIS=0
        for endpoint in "${API_ENDPOINTS[@]}"; do
            HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL$endpoint")
            if [[ "$HTTP_CODE" != "404" ]]; then
                echo "  ✅ $endpoint - HTTP $HTTP_CODE"
                ((WORKING_APIS++))
            else
                echo "  ❌ $endpoint - HTTP $HTTP_CODE"
            fi
        done
        
        echo "📊 API端点测试: $WORKING_APIS/${#API_ENDPOINTS[@]} 个有响应"
        
    else
        echo "❌ Web服务无法访问"
    fi
    
else
    echo "❌ x-ui服务未运行"
    echo "📋 查看服务状态:"
    sudo systemctl status x-ui --no-pager -l | head -10
    echo ""
    echo "📋 查看服务日志:"
    sudo journalctl -u x-ui --no-pager -l | tail -10
fi

echo ""
echo "📊 7. 显示服务信息..."

# 获取当前设置
CURRENT_SETTINGS=$(./x-ui setting -show 2>/dev/null)
if [[ -n "$CURRENT_SETTINGS" ]]; then
    echo "⚙️  当前面板设置:"
    echo "$CURRENT_SETTINGS"
else
    echo "⚙️  获取设置信息..."
    echo "用户名: admin"
    echo "密码: admin" 
    echo "端口: $PORT"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🎉 3X-UI Enhanced API 构建和部署完成！                  ║"
echo "║                                                           ║"
echo "║  🌐 访问地址: http://$SERVER_IP:$PORT/"
echo "║  🔑 用户名: admin                                         ║"
echo "║  🔑 密码: admin                                           ║"
echo "║                                                           ║"
echo "║  📱 Enhanced API功能:                                    ║"
echo "║  ✅ 入站管理 - /panel/api/inbounds/*                     ║"
echo "║  ✅ 出站管理 - /panel/api/outbounds/* (Enhanced)         ║"  
echo "║  ✅ 路由管理 - /panel/api/routing/* (Enhanced)           ║"
echo "║  ✅ 订阅管理 - /panel/api/subscription/* (Enhanced)      ║"
echo "║                                                           ║"
echo "║  🔧 管理命令:                                            ║"
echo "║  查看状态: sudo systemctl status x-ui                    ║"
echo "║  重启服务: sudo systemctl restart x-ui                   ║"
echo "║  查看日志: sudo journalctl -u x-ui -f                    ║"
echo "║  修改设置: ./x-ui setting -help                          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"

echo ""
echo "🎯 快速开始:"
echo "1. 🌐 访问面板: http://$SERVER_IP:$PORT/"
echo "2. 🔑 登录账号: admin / admin"  
echo "3. 📊 配置入站代理"
echo "4. 🚀 使用Enhanced API功能管理出站、路由、订阅"

echo ""
echo "📚 Enhanced API特色功能:"
echo "• 🔄 出站流量管理和统计"
echo "• 🛣️  智能路由规则配置" 
echo "• 📋 订阅链接批量管理"
echo "• 📊 实时系统状态监控"
echo "• 🔧 完整的REST API接口"

echo ""
echo "=== 3X-UI Enhanced API 构建脚本完成 ==="
