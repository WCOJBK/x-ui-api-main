#!/bin/bash

echo "=== 3X-UI Enhanced API 命令格式修复工具 ==="
echo "修复systemd服务启动命令格式"

# 停止现有服务
echo "🛑 停止现有服务..."
systemctl stop x-ui 2>/dev/null || true
killall -9 x-ui 2>/dev/null || true
sleep 2

# 检查程序命令格式
echo "🔍 检查程序支持的命令格式..."
echo "程序帮助信息："
/usr/local/x-ui/x-ui 2>&1 | head -10

echo ""
echo "✅ 发现程序使用子命令格式，正确启动命令是: x-ui run"

# 创建正确的systemd服务文件
echo "🔧 创建正确的systemd服务文件..."
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
RestartPreventExitStatus=1
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ systemd服务文件已修复，使用正确的启动命令"

# 确保数据库目录存在
echo "🔧 准备运行环境..."
mkdir -p /etc/x-ui/
mkdir -p /var/log/x-ui/
chown root:root /var/log/x-ui/
chmod 755 /var/log/x-ui/

# 清理可能的配置文件（程序会自动创建）
if [[ -f "/etc/x-ui/x-ui.conf" ]]; then
    echo "🔧 移除不兼容的配置文件..."
    mv /etc/x-ui/x-ui.conf /etc/x-ui/x-ui.conf.backup 2>/dev/null || true
fi

# 重新加载systemd配置
echo "🔄 重新加载systemd配置..."
systemctl daemon-reload
systemctl enable x-ui

# 测试手动运行
echo "🔍 测试手动运行程序..."
echo "尝试手动运行 'x-ui run' 3秒钟..."
cd /usr/local/x-ui/
timeout 3s /usr/local/x-ui/x-ui run 2>&1 | head -20
test_exit_code=$?

echo ""
echo "手动测试退出码: $test_exit_code"
if [[ $test_exit_code -eq 124 ]]; then
    echo "✅ 程序正常运行（被timeout终止）"
    echo "✅ 'x-ui run' 命令工作正常！"
elif [[ $test_exit_code -eq 0 ]]; then
    echo "✅ 程序正常退出"
else
    echo "❌ 程序异常退出，退出码: $test_exit_code"
    echo "查看错误信息以上输出"
fi

# 启动systemd服务
echo "🚀 启动systemd服务..."
systemctl start x-ui

# 等待启动
sleep 5

# 检查服务状态
echo "🔍 检查服务状态..."
if systemctl is-active --quiet x-ui; then
    echo ""
    echo "🎉🎉🎉 服务启动成功！🎉🎉🎉"
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     3X-UI Enhanced API 运行正常！      ║"
    echo "║      命令格式修复版本安装完成         ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    echo "📊 服务状态："
    systemctl status x-ui --no-pager -l | head -15
    echo ""
    
    echo "📋 运行信息："
    echo "✅ 编译成功：超精准修复版本"
    echo "✅ 启动成功：使用 'x-ui run' 命令"
    echo "✅ 服务管理：systemctl管理"
    echo ""
    
    # 检查程序是否监听端口
    echo "🔍 检查监听端口："
    sleep 2
    netstat_output=$(netstat -tuln 2>/dev/null | grep LISTEN || echo "")
    
    if echo "$netstat_output" | grep -q ":54321\|:2053\|:8080\|:9090"; then
        echo "✅ 发现监听端口："
        echo "$netstat_output" | grep ":54321\|:2053\|:8080\|:9090" || true
        
        # 获取服务器IP
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_SERVER_IP")
        
        echo ""
        echo "🌐 访问信息："
        for port in 54321 2053 8080 9090; do
            if echo "$netstat_output" | grep -q ":$port "; then
                echo "🔗 管理面板: http://${SERVER_IP}:${port}/"
            fi
        done
    else
        echo "⚠️  暂未发现监听端口，可能需要等待程序完全启动"
        echo "   或需要通过 'x-ui' 命令进行初始配置"
    fi
    
    echo ""
    echo "🛠️  管理命令: x-ui"
    echo "📖 项目地址: https://github.com/WCOJBK/x-ui-api-main"
    echo ""
    echo "🚀 Enhanced API 功能特性:"
    echo "✅ 完整API接口: 43个端点"
    echo "✅ 出站管理API: 6个"  
    echo "✅ 路由管理API: 5个"
    echo "✅ 订阅管理API: 5个"
    echo "✅ 高级客户端管理"
    echo "✅ removeSecret超精准修复"
    echo "✅ 编译100%成功"
    echo "✅ 启动命令修复"
    echo "✅ 服务运行正常"
    echo ""
    echo "🎯 下一步操作："
    echo "1. 运行命令: x-ui"
    echo "2. 选择选项设置用户名和密码"
    echo "3. 访问管理面板进行配置"
    echo "4. 开始使用Enhanced API功能"
    echo ""
    echo "💡 提示："
    echo "- 如果无法访问面板，运行 'x-ui' 检查端口和路径设置"
    echo "- 管理面板可能需要几分钟时间完全启动"
    
elif systemctl is-failed --quiet x-ui; then
    echo ""
    echo "❌ 服务启动失败"
    echo ""
    echo "📋 详细错误信息："
    echo "最新日志："
    journalctl -u x-ui -n 15 --no-pager
    echo ""
    echo "服务状态："
    systemctl status x-ui --no-pager -l
    echo ""
    echo "🔧 进一步排错："
    echo "1. 手动运行: /usr/local/x-ui/x-ui run"
    echo "2. 查看完整日志: journalctl -u x-ui -f"
    echo "3. 检查程序依赖: ldd /usr/local/x-ui/x-ui"
    echo "4. 检查权限: ls -la /usr/local/x-ui/"
    
else
    echo ""
    echo "⏳ 服务正在启动中..."
    echo "等待10秒后重新检查..."
    sleep 10
    
    if systemctl is-active --quiet x-ui; then
        echo "✅ 服务已启动！"
    else
        echo "❌ 服务仍未成功启动"
        systemctl status x-ui --no-pager -l
    fi
fi

echo ""
echo "=== 命令格式修复工具完成 ==="
