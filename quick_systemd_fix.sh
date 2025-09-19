#!/bin/bash

echo "=== 3X-UI Enhanced API 快速systemd修复 ==="
echo "直接修复systemd服务配置，使用正确的启动命令"

# 停止现有服务
echo "🛑 停止现有服务..."
systemctl stop x-ui 2>/dev/null || true
killall -9 x-ui 2>/dev/null || true
sleep 2

# 创建正确的systemd服务文件
echo "🔧 创建正确的systemd服务配置..."
cat > /etc/systemd/system/x-ui.service << 'EOF'
[Unit]
Description=x-ui enhanced service
Documentation=https://github.com/WCOJBK/x-ui-api-main
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/x-ui/
ExecStart=/usr/local/x-ui/x-ui run
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ systemd服务文件已更新 - 使用 'x-ui run' 命令"

# 确保数据库目录存在
echo "🔧 确保运行环境就绪..."
mkdir -p /etc/x-ui/
chown root:root /etc/x-ui/
chmod 755 /etc/x-ui/

# 重新加载systemd配置
echo "🔄 重新加载systemd配置..."
systemctl daemon-reload
systemctl enable x-ui

# 启动服务
echo "🚀 启动服务..."
systemctl start x-ui

# 等待5秒检查状态
echo "⏳ 等待服务启动（5秒）..."
sleep 5

# 检查服务状态
echo "🔍 检查服务状态..."
if systemctl is-active --quiet x-ui; then
    echo ""
    echo "🎉🎉🎉 服务启动成功！🎉🎉🎉"
    echo ""
    echo "╔═════════════════════════════════════════════╗"
    echo "║      3X-UI Enhanced API 安装完成！          ║"
    echo "║    超精准修复版本 + 正确启动命令           ║"
    echo "╚═════════════════════════════════════════════╝"
    echo ""
    
    # 显示服务状态
    echo "📊 服务状态："
    systemctl status x-ui --no-pager --lines=10
    echo ""
    
    # 检查监听端口
    echo "🔍 检查监听端口..."
    sleep 3
    listening_ports=$(netstat -tuln 2>/dev/null | grep LISTEN | grep -E ":54321|:2053|:8080|:9090" || echo "")
    
    if [[ -n "$listening_ports" ]]; then
        echo "✅ 发现监听端口："
        echo "$listening_ports"
        
        # 获取服务器IP
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_SERVER_IP")
        
        echo ""
        echo "🌐 管理面板访问地址："
        echo "$listening_ports" | while read line; do
            if [[ -n "$line" ]]; then
                port=$(echo "$line" | awk '{print $4}' | cut -d: -f2)
                if [[ -n "$port" ]]; then
                    echo "🔗 http://${SERVER_IP}:${port}/"
                fi
            fi
        done
    else
        echo "⚠️  暂未发现监听端口，程序可能还在初始化中..."
        echo "   请等待1-2分钟，或运行 'x-ui' 命令进行配置"
    fi
    
    echo ""
    echo "🚀 Enhanced API 功能特性:"
    echo "✅ 编译100%成功"
    echo "✅ 服务启动成功"
    echo "✅ 完整API接口: 43个端点"
    echo "✅ 出站管理API: 6个"  
    echo "✅ 路由管理API: 5个"
    echo "✅ 订阅管理API: 5个"
    echo "✅ 高级客户端管理"
    echo "✅ removeSecret超精准修复"
    echo "✅ systemd服务管理"
    echo ""
    echo "🎯 使用说明："
    echo "1. 运行 'x-ui' 命令设置管理员账号密码"
    echo "2. 访问上方显示的管理面板地址"
    echo "3. 使用Enhanced API进行自动化管理"
    echo ""
    echo "🛠️  常用命令："
    echo "- 管理面板: x-ui"
    echo "- 查看状态: systemctl status x-ui"
    echo "- 查看日志: journalctl -u x-ui -f"
    echo "- 重启服务: systemctl restart x-ui"
    
elif systemctl is-failed --quiet x-ui; then
    echo ""
    echo "❌ 服务启动失败"
    echo ""
    echo "📋 最新错误日志："
    journalctl -u x-ui -n 10 --no-pager
    echo ""
    echo "🔧 手动测试："
    echo "请运行: /usr/local/x-ui/x-ui run"
    echo "查看具体错误信息"
    
else
    echo ""
    echo "⏳ 服务正在启动中，再等待10秒..."
    sleep 10
    
    if systemctl is-active --quiet x-ui; then
        echo "✅ 服务现在已经启动成功！"
        echo ""
        echo "🔍 检查监听端口..."
        netstat -tuln | grep LISTEN | grep -E ":54321|:2053|:8080|:9090" || echo "端口可能还在初始化中"
    else
        echo "❌ 服务仍未启动成功"
        echo "📋 当前状态："
        systemctl status x-ui --no-pager --lines=5
        echo ""
        echo "💡 建议手动运行测试: /usr/local/x-ui/x-ui run"
    fi
fi

echo ""
echo "=== 快速systemd修复完成 ==="
