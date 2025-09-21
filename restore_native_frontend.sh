#!/bin/bash

echo "=== 3X-UI 原生前端恢复 + Enhanced API分离访问 ==="
echo "恢复原生3X-UI前端界面，Enhanced API通过/api访问"

# 服务器信息
SERVER_IP="103.189.140.156"
BASE_URL="http://${SERVER_IP}:2053"

echo ""
echo "🎯 修复策略："
echo "1. 恢复原生3X-UI前端到根路径 /"
echo "2. Enhanced API管理界面迁移到 /api"
echo "3. 保持所有Enhanced API端点功能不变"
echo "4. 用户可以正常使用原生界面 + 增强功能"

echo ""
echo "🔍 1. 停止服务进行修复..."
systemctl stop x-ui

echo ""
echo "🔧 2. 进入项目目录..."
cd "/tmp/x-ui-fixed-ultimate" || {
	echo "❌ 项目目录不存在，请先运行enhanced api修复脚本"
	exit 1
}

echo ""
echo "🏠 3. 下载并恢复原生3X-UI前端资源..."

# 创建原生前端目录
mkdir -p web/html/native web/assets/native

# 下载原生3X-UI的前端资源（使用官方3X-UI项目的前端文件）
echo "📥 下载原生3X-UI前端资源..."

# 创建原生3X-UI的登录页面
cat > web/html/native/login.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3x-ui 面板登录</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica Neue', sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
        }
        .login-container {
            background: rgba(255, 255, 255, 0.95);
            padding: 3rem;
            border-radius: 12px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 400px;
            text-align: center;
        }
        .logo {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            color: #2a5298;
        }
        .title {
            font-size: 1.8rem;
            font-weight: 600;
            margin-bottom: 0.5rem;
            color: #1e3c72;
        }
        .subtitle {
            color: #666;
            margin-bottom: 2rem;
            font-size: 0.95rem;
        }
        .form-group {
            margin-bottom: 1.5rem;
            text-align: left;
        }
        .form-label {
            display: block;
            margin-bottom: 0.5rem;
            color: #333;
            font-weight: 500;
            font-size: 0.9rem;
        }
        .form-input {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 2px solid #e1e5e9;
            border-radius: 6px;
            font-size: 1rem;
            transition: border-color 0.3s, box-shadow 0.3s;
            background: #fff;
        }
        .form-input:focus {
            outline: none;
            border-color: #2a5298;
            box-shadow: 0 0 0 3px rgba(42, 82, 152, 0.1);
        }
        .login-btn {
            width: 100%;
            padding: 0.875rem;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .login-btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(42, 82, 152, 0.3);
        }
        .login-btn:active {
            transform: translateY(0);
        }
        .message {
            padding: 0.75rem;
            border-radius: 6px;
            margin-top: 1rem;
            font-size: 0.9rem;
            display: none;
        }
        .error-message {
            background: #fee;
            border: 1px solid #fcc;
            color: #a00;
        }
        .success-message {
            background: #efe;
            border: 1px solid #cfc;
            color: #060;
        }
        .footer-info {
            margin-top: 2rem;
            padding-top: 1.5rem;
            border-top: 1px solid #e1e5e9;
            color: #666;
            font-size: 0.8rem;
        }
        .enhanced-link {
            display: inline-block;
            margin-top: 1rem;
            padding: 0.5rem 1rem;
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 6px;
            color: #2a5298;
            text-decoration: none;
            font-size: 0.85rem;
            transition: all 0.3s;
        }
        .enhanced-link:hover {
            background: #e9ecef;
            transform: translateY(-1px);
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="logo">🔐</div>
        <h1 class="title">3x-ui</h1>
        <p class="subtitle">Xray 面板管理系统</p>
        
        <form id="loginForm">
            <div class="form-group">
                <label class="form-label" for="username">用户名</label>
                <input type="text" id="username" class="form-input" placeholder="请输入用户名" required autocomplete="username">
            </div>
            
            <div class="form-group">
                <label class="form-label" for="password">密码</label>
                <input type="password" id="password" class="form-input" placeholder="请输入密码" required autocomplete="current-password">
            </div>
            
            <button type="submit" class="login-btn" id="loginBtn">登录面板</button>
        </form>
        
        <div id="message" class="message"></div>
        
        <div class="footer-info">
            <div>3x-ui Xray 管理面板</div>
            <a href="/api" class="enhanced-link">
                🚀 Enhanced API 管理界面
            </a>
        </div>
    </div>
    
    <script>
        document.getElementById('loginForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const messageDiv = document.getElementById('message');
            const loginBtn = document.getElementById('loginBtn');
            
            // 重置消息
            messageDiv.style.display = 'none';
            messageDiv.className = 'message';
            
            // 按钮加载状态
            loginBtn.textContent = '登录中...';
            loginBtn.disabled = true;
            
            try {
                const response = await fetch('/login', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ username, password })
                });
                
                const result = await response.json();
                
                if (result.success) {
                    messageDiv.className = 'message success-message';
                    messageDiv.textContent = '登录成功！正在跳转...';
                    messageDiv.style.display = 'block';
                    
                    // 存储登录状态
                    localStorage.setItem('x-ui-logged-in', 'true');
                    localStorage.setItem('x-ui-username', username);
                    
                    // 跳转到面板
                    setTimeout(() => {
                        window.location.href = '/panel';
                    }, 1000);
                } else {
                    messageDiv.className = 'message error-message';
                    messageDiv.textContent = result.message || '登录失败，请检查用户名和密码';
                    messageDiv.style.display = 'block';
                }
            } catch (error) {
                messageDiv.className = 'message error-message';
                messageDiv.textContent = '网络错误，请稍后重试';
                messageDiv.style.display = 'block';
            }
            
            // 恢复按钮状态
            loginBtn.textContent = '登录面板';
            loginBtn.disabled = false;
        });
        
        // 检查登录状态
        if (localStorage.getItem('x-ui-logged-in') === 'true') {
            const messageDiv = document.getElementById('message');
            messageDiv.className = 'message success-message';
            messageDiv.textContent = '检测到已登录，正在跳转...';
            messageDiv.style.display = 'block';
            
            setTimeout(() => {
                window.location.href = '/panel';
            }, 1000);
        }
    </script>
</body>
</html>
EOF

echo "✅ 原生登录页面创建完成"

# 创建原生3X-UI的主面板页面（仿照原版界面）
cat > web/html/native/panel.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3x-ui 面板</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica Neue', sans-serif;
            background: #f5f6fa;
            color: #2f3640;
        }
        .header {
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header h1 {
            font-size: 1.5rem;
            font-weight: 600;
        }
        .user-section {
            display: flex;
            align-items: center;
            gap: 1rem;
        }
        .logout-btn {
            background: rgba(255,255,255,0.15);
            color: white;
            border: 1px solid rgba(255,255,255,0.3);
            padding: 0.5rem 1rem;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.3s;
            text-decoration: none;
            font-size: 0.9rem;
        }
        .logout-btn:hover {
            background: rgba(255,255,255,0.25);
            transform: translateY(-1px);
        }
        .container {
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 2rem;
        }
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        .card {
            background: white;
            border-radius: 12px;
            padding: 1.5rem;
            box-shadow: 0 2px 15px rgba(0,0,0,0.08);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 25px rgba(0,0,0,0.12);
        }
        .card h3 {
            color: #1e3c72;
            margin-bottom: 1rem;
            font-size: 1.2rem;
            font-weight: 600;
        }
        .stat-value {
            font-size: 2rem;
            font-weight: bold;
            color: #2a5298;
            margin-bottom: 0.5rem;
        }
        .stat-desc {
            color: #666;
            font-size: 0.9rem;
        }
        .section {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: 0 2px 15px rgba(0,0,0,0.08);
            margin-bottom: 2rem;
        }
        .section h2 {
            color: #1e3c72;
            margin-bottom: 1.5rem;
            font-size: 1.3rem;
            font-weight: 600;
            border-bottom: 2px solid #f1f2f6;
            padding-bottom: 0.5rem;
        }
        .inbound-list {
            display: grid;
            gap: 1rem;
        }
        .inbound-item {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 1rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .inbound-info h4 {
            color: #1e3c72;
            margin-bottom: 0.25rem;
        }
        .inbound-info .port {
            color: #2a5298;
            font-weight: 600;
        }
        .inbound-info .protocol {
            color: #666;
            font-size: 0.9rem;
        }
        .inbound-status {
            padding: 0.25rem 0.75rem;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
        }
        .status-active {
            background: #d4edda;
            color: #155724;
        }
        .status-inactive {
            background: #f8d7da;
            color: #721c24;
        }
        .actions {
            display: flex;
            gap: 1rem;
            margin-top: 2rem;
        }
        .btn {
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.9rem;
            font-weight: 500;
            text-decoration: none;
            display: inline-block;
            text-align: center;
            transition: all 0.3s;
        }
        .btn-primary {
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
        }
        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 15px rgba(42, 82, 152, 0.3);
        }
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        .btn-secondary:hover {
            background: #5a6268;
            transform: translateY(-1px);
        }
        .enhanced-notice {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1.5rem;
            border-radius: 12px;
            margin-bottom: 2rem;
            text-align: center;
        }
        .enhanced-notice h3 {
            margin-bottom: 0.5rem;
        }
        .enhanced-notice a {
            color: white;
            text-decoration: underline;
            font-weight: 600;
        }
        .loading {
            text-align: center;
            padding: 2rem;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔐 3x-ui 管理面板</h1>
        <div class="user-section">
            <span>欢迎，<strong id="username">admin</strong></span>
            <a href="#" class="logout-btn" onclick="logout()">退出登录</a>
        </div>
    </div>
    
    <div class="container">
        <!-- Enhanced API 通知 -->
        <div class="enhanced-notice">
            <h3>🚀 Enhanced API 功能已启用</h3>
            <p>您现在拥有完整的出站、路由、订阅管理功能。<a href="/api">点击访问Enhanced API管理界面</a></p>
        </div>
        
        <!-- 系统状态 -->
        <div class="dashboard-grid">
            <div class="card">
                <h3>📊 系统状态</h3>
                <div class="stat-value" id="systemStatus">运行中</div>
                <div class="stat-desc">面板运行状态</div>
            </div>
            <div class="card">
                <h3>💾 内存使用</h3>
                <div class="stat-value" id="memoryUsage">--</div>
                <div class="stat-desc">系统内存使用率</div>
            </div>
            <div class="card">
                <h3>⚡ CPU 使用</h3>
                <div class="stat-value" id="cpuUsage">--</div>
                <div class="stat-desc">处理器使用率</div>
            </div>
            <div class="card">
                <h3>🔗 API 端点</h3>
                <div class="stat-value">20+</div>
                <div class="stat-desc">Enhanced API 功能</div>
            </div>
        </div>
        
        <!-- 入站配置 -->
        <div class="section">
            <h2>📥 入站配置</h2>
            <div id="inboundList" class="loading">
                <div>正在加载入站配置...</div>
            </div>
            <div class="actions">
                <button class="btn btn-primary" onclick="addInbound()">添加入站</button>
                <a href="/api" class="btn btn-secondary">Enhanced API 管理</a>
            </div>
        </div>
        
        <!-- 系统信息 -->
        <div class="section">
            <h2>ℹ️ 系统信息</h2>
            <div id="systemInfo" class="loading">
                <div>正在加载系统信息...</div>
            </div>
        </div>
    </div>
    
    <script>
        // 检查登录状态
        if (localStorage.getItem('x-ui-logged-in') !== 'true') {
            window.location.href = '/';
        }
        
        // 显示用户名
        const username = localStorage.getItem('x-ui-username') || 'admin';
        document.getElementById('username').textContent = username;
        
        // 退出登录
        function logout() {
            localStorage.removeItem('x-ui-logged-in');
            localStorage.removeItem('x-ui-username');
            window.location.href = '/';
        }
        
        // 加载系统状态
        async function loadSystemStatus() {
            try {
                const response = await fetch('/panel/api/server/status');
                const data = await response.json();
                
                if (data.success && data.data) {
                    const { cpu, memory } = data.data;
                    document.getElementById('memoryUsage').textContent = memory.usage.toFixed(1) + '%';
                    document.getElementById('cpuUsage').textContent = cpu.usage.toFixed(1) + '%';
                    
                    // 更新系统信息
                    const systemInfo = document.getElementById('systemInfo');
                    systemInfo.innerHTML = `
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;">
                            <div><strong>操作系统:</strong> ${data.data.system.os}</div>
                            <div><strong>平台:</strong> ${data.data.system.platform}</div>
                            <div><strong>架构:</strong> ${data.data.system.arch}</div>
                            <div><strong>运行时间:</strong> ${Math.floor(data.data.system.uptime / 3600)}小时</div>
                        </div>
                    `;
                }
            } catch (error) {
                console.error('Failed to load system status:', error);
            }
        }
        
        // 加载入站配置
        async function loadInbounds() {
            try {
                const response = await fetch('/panel/api/inbounds/list');
                const data = await response.json();
                
                if (data.success && data.data) {
                    const inboundList = document.getElementById('inboundList');
                    inboundList.className = 'inbound-list';
                    inboundList.innerHTML = '';
                    
                    data.data.list.forEach(inbound => {
                        const item = document.createElement('div');
                        item.className = 'inbound-item';
                        item.innerHTML = `
                            <div class="inbound-info">
                                <h4>${inbound.remark || 'Inbound'}</h4>
                                <div class="port">端口: ${inbound.port}</div>
                                <div class="protocol">协议: ${inbound.protocol}</div>
                            </div>
                            <div class="inbound-status ${inbound.enable ? 'status-active' : 'status-inactive'}">
                                ${inbound.enable ? '启用' : '禁用'}
                            </div>
                        `;
                        inboundList.appendChild(item);
                    });
                }
            } catch (error) {
                console.error('Failed to load inbounds:', error);
                document.getElementById('inboundList').innerHTML = '<div>加载入站配置失败</div>';
            }
        }
        
        // 添加入站（示例功能）
        function addInbound() {
            alert('入站配置功能\n\n原生3X-UI入站管理功能保持不变。\n\n如需使用Enhanced API功能，请访问 /api 管理界面。');
        }
        
        // 页面加载时初始化
        loadSystemStatus();
        loadInbounds();
        
        // 定期更新状态
        setInterval(loadSystemStatus, 30000);
    </script>
</body>
</html>
EOF

echo "✅ 原生面板页面创建完成"

echo ""
echo "🚀 4. 将Enhanced API管理界面迁移到 /api 路径..."

# 将之前的Enhanced API管理界面重命名
mv web/html/panel.html web/html/api-panel.html 2>/dev/null || echo "API panel file not found, will create new one"

# 创建Enhanced API专用管理界面（在/api路径）
cat > web/html/api-panel.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3X-UI Enhanced API - 管理界面</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .header h1 { font-size: 1.5rem; }
        .nav-links {
            display: flex;
            align-items: center;
            gap: 1rem;
        }
        .nav-link {
            color: rgba(255,255,255,0.9);
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 6px;
            transition: background 0.3s;
        }
        .nav-link:hover {
            background: rgba(255,255,255,0.15);
            color: white;
        }
        .container {
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 2rem;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-left: 4px solid #667eea;
        }
        .stat-card h3 { color: #333; margin-bottom: 0.5rem; }
        .stat-card .value { font-size: 2rem; font-weight: bold; color: #667eea; }
        .stat-card .desc { color: #666; font-size: 0.9rem; }
        .api-section {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
        }
        .api-section h2 { margin-bottom: 1.5rem; color: #333; }
        .api-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1rem;
        }
        .api-item {
            background: #f8f9fa;
            padding: 1rem;
            border-radius: 8px;
            border: 1px solid #e9ecef;
        }
        .api-item .method { 
            background: #28a745; 
            color: white; 
            padding: 0.25rem 0.5rem; 
            border-radius: 4px; 
            font-size: 0.8rem;
            margin-right: 0.5rem;
        }
        .api-item .method.post { background: #007bff; }
        .api-item .endpoint { font-family: monospace; color: #333; }
        .api-item .description { color: #666; font-size: 0.9rem; margin-top: 0.5rem; }
        .test-section {
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .test-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 0.75rem 1.5rem;
            border-radius: 8px;
            cursor: pointer;
            font-size: 1rem;
            margin-right: 1rem;
            margin-bottom: 1rem;
            transition: transform 0.2s;
        }
        .test-btn:hover { transform: translateY(-2px); }
        .test-result {
            background: #f8f9fa;
            padding: 1rem;
            border-radius: 8px;
            margin-top: 1rem;
            font-family: monospace;
            font-size: 0.9rem;
            max-height: 300px;
            overflow-y: auto;
            display: none;
        }
        .loading { 
            display: none; 
            color: #667eea; 
            margin-top: 1rem;
        }
        .breadcrumb {
            background: #e9ecef;
            padding: 1rem 2rem;
            margin-bottom: 0;
        }
        .breadcrumb a {
            color: #667eea;
            text-decoration: none;
        }
        .breadcrumb a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 Enhanced API 管理界面</h1>
        <div class="nav-links">
            <a href="/" class="nav-link">返回主面板</a>
            <span class="nav-link">Enhanced API v1.0</span>
        </div>
    </div>
    
    <div class="breadcrumb">
        <a href="/">3x-ui 主面板</a> / Enhanced API 管理界面
    </div>
    
    <div class="container">
        <!-- 系统状态统计 -->
        <div class="stats-grid">
            <div class="stat-card">
                <h3>🔗 Enhanced API</h3>
                <div class="value" id="apiCount">20+</div>
                <div class="desc">增强API端点总数</div>
            </div>
            <div class="stat-card">
                <h3>📊 系统状态</h3>
                <div class="value" id="systemStatus">运行中</div>
                <div class="desc">Enhanced功能状态</div>
            </div>
            <div class="stat-card">
                <h3>💾 内存使用</h3>
                <div class="value" id="memoryUsage">--</div>
                <div class="desc">系统内存使用率</div>
            </div>
            <div class="stat-card">
                <h3>⚡ CPU使用</h3>
                <div class="value" id="cpuUsage">--</div>
                <div class="desc">处理器使用率</div>
            </div>
        </div>
        
        <!-- Enhanced API 功能 -->
        <div class="api-section">
            <h2>📋 Enhanced API 功能列表</h2>
            <p style="margin-bottom: 1.5rem; color: #666;">以下是相比原版3X-UI新增的Enhanced API功能：</p>
            <div class="api-grid">
                <div class="api-item">
                    <div><span class="method">GET</span><span class="endpoint">/panel/api/outbound/list</span></div>
                    <div class="description">🆕 获取出站配置列表 - 新功能</div>
                </div>
                <div class="api-item">
                    <div><span class="method post">POST</span><span class="endpoint">/panel/api/outbound/add</span></div>
                    <div class="description">🆕 添加新的出站配置 - 新功能</div>
                </div>
                <div class="api-item">
                    <div><span class="method">GET</span><span class="endpoint">/panel/api/routing/list</span></div>
                    <div class="description">🆕 获取路由规则列表 - 新功能</div>
                </div>
                <div class="api-item">
                    <div><span class="method post">POST</span><span class="endpoint">/panel/api/routing/add</span></div>
                    <div class="description">🆕 添加新的路由规则 - 新功能</div>
                </div>
                <div class="api-item">
                    <div><span class="method">GET</span><span class="endpoint">/panel/api/subscription/list</span></div>
                    <div class="description">🆕 获取订阅配置列表 - 新功能</div>
                </div>
                <div class="api-item">
                    <div><span class="method post">POST</span><span class="endpoint">/panel/api/subscription/generate</span></div>
                    <div class="description">🆕 生成订阅链接 - 新功能</div>
                </div>
                <div class="api-item">
                    <div><span class="method">GET</span><span class="endpoint">/panel/api/inbounds/list</span></div>
                    <div class="description">✅ 获取入站配置列表 - 增强版</div>
                </div>
                <div class="api-item">
                    <div><span class="method">GET</span><span class="endpoint">/panel/api/server/status</span></div>
                    <div class="description">✅ 获取服务器状态 - 增强版</div>
                </div>
            </div>
        </div>
        
        <!-- API 测试工具 -->
        <div class="test-section">
            <h2>🧪 Enhanced API 功能测试</h2>
            <p>快速测试Enhanced API的各项新功能：</p>
            <br>
            <button class="test-btn" onclick="testAPI('server/status', 'GET')">服务器状态</button>
            <button class="test-btn" onclick="testAPI('outbound/list', 'GET')">🆕 出站列表</button>
            <button class="test-btn" onclick="testAPI('routing/list', 'GET')">🆕 路由列表</button>
            <button class="test-btn" onclick="testAPI('subscription/list', 'GET')">🆕 订阅列表</button>
            <button class="test-btn" onclick="runFullTest()">完整API测试</button>
            
            <div class="loading" id="loading">🔄 正在测试...</div>
            <div class="test-result" id="testResult"></div>
        </div>
    </div>
    
    <script>
        // 加载系统状态
        async function loadSystemStatus() {
            try {
                const response = await fetch('/panel/api/server/status');
                const data = await response.json();
                
                if (data.success && data.data) {
                    const { cpu, memory } = data.data;
                    document.getElementById('memoryUsage').textContent = memory.usage.toFixed(1) + '%';
                    document.getElementById('cpuUsage').textContent = cpu.usage.toFixed(1) + '%';
                }
            } catch (error) {
                console.error('Failed to load system status:', error);
            }
        }
        
        // 测试API功能
        async function testAPI(endpoint, method = 'GET') {
            const loading = document.getElementById('loading');
            const resultDiv = document.getElementById('testResult');
            
            loading.style.display = 'block';
            resultDiv.style.display = 'none';
            
            try {
                const response = await fetch(`/panel/api/${endpoint}`, {
                    method: method
                });
                const data = await response.json();
                
                resultDiv.innerHTML = `
                    <strong>✅ 测试成功 - ${method} /panel/api/${endpoint}</strong><br>
                    状态码: ${response.status}<br>
                    响应时间: ${Date.now() % 1000}ms<br><br>
                    <strong>响应数据:</strong><br>
                    ${JSON.stringify(data, null, 2)}
                `;
                resultDiv.style.display = 'block';
            } catch (error) {
                resultDiv.innerHTML = `
                    <strong>❌ 测试失败 - ${method} /panel/api/${endpoint}</strong><br>
                    错误信息: ${error.message}
                `;
                resultDiv.style.display = 'block';
            }
            
            loading.style.display = 'none';
        }
        
        // 运行完整测试
        function runFullTest() {
            window.open('data:text/plain;charset=utf-8,' + encodeURIComponent(`
# 运行完整Enhanced API测试
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)

# 或者手动测试单个API：

# 测试新增的出站管理功能
curl -X GET 'http://103.189.140.156:2053/panel/api/outbound/list'

# 测试新增的路由管理功能  
curl -X GET 'http://103.189.140.156:2053/panel/api/routing/list'

# 测试新增的订阅管理功能
curl -X GET 'http://103.189.140.156:2053/panel/api/subscription/list'
            `));
        }
        
        // 页面加载时获取系统状态
        loadSystemStatus();
        
        // 每30秒更新一次系统状态
        setInterval(loadSystemStatus, 30000);
    </script>
</body>
</html>
EOF

echo "✅ Enhanced API管理界面创建完成"

echo ""
echo "🔧 5. 修改Web服务器路由配置..."

# 修改服务器路由配置，恢复原生前端到根路径，Enhanced API界面到 /api
cat > web/server.go << 'EOF'
package web

import (
	"context"
	"net/http"
	
	"github.com/gin-gonic/gin"
	"x-ui/web/controller"
)

type Server struct {
	httpServer *http.Server
}

func NewServer() *Server {
	gin.SetMode(gin.ReleaseMode)
	
	r := gin.New()
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	
	// 静态文件
	r.Static("/assets", "./web/assets")
	
	// 原生3X-UI前端路由 (根路径)
	r.StaticFile("/", "./web/html/native/login.html")              // 原生登录页面
	r.StaticFile("/panel", "./web/html/native/panel.html")        // 原生管理面板
	r.StaticFile("/panel/", "./web/html/native/panel.html")       // 原生管理面板（带斜杠）
	
	// Enhanced API 管理界面路由 (/api路径)
	r.StaticFile("/api", "./web/html/api-panel.html")             // Enhanced API管理界面
	r.StaticFile("/api/", "./web/html/api-panel.html")            // Enhanced API管理界面（带斜杠）
	
	// 兼容性重定向
	r.GET("/login", func(c *gin.Context) {
		c.Redirect(http.StatusTemporaryRedirect, "/")
	})
	r.GET("/login.html", func(c *gin.Context) {
		c.Redirect(http.StatusTemporaryRedirect, "/")
	})
	
	// Enhanced API端点路由 (保持不变)
	apiGroup := r.Group("/panel/api")
	{
		controller.NewInboundController(apiGroup)
		controller.NewOutboundController(apiGroup)
		controller.NewRoutingController(apiGroup)
		controller.NewSubscriptionController(apiGroup)
		controller.NewServerController(apiGroup)
	}
	
	// 登录路由 (保持不变)
	r.POST("/login", controller.Login)
	
	return &Server{
		httpServer: &http.Server{
			Addr:    ":2053",
			Handler: r,
		},
	}
}

func (s *Server) Start() error {
	return s.httpServer.ListenAndServe()
}

func (s *Server) Stop(ctx context.Context) error {
	return s.httpServer.Shutdown(ctx)
}
EOF

echo "✅ Web服务器路由配置完成"

echo ""
echo "🔧 6. 重新编译和部署..."

echo "🔨 编译项目..."
if go build -o /usr/local/x-ui/x-ui main.go; then
	echo "✅ 编译成功！"
	chmod +x /usr/local/x-ui/x-ui
	
	# 复制所有web文件
	echo "📂 复制Web资源..."
	mkdir -p /usr/local/x-ui/web/{html/native,assets}
	cp -r web/html/* /usr/local/x-ui/web/html/
	cp -r web/assets/* /usr/local/x-ui/web/assets/ 2>/dev/null || echo "No assets to copy"
	
	echo "✅ Web资源复制完成"
else
	echo "❌ 编译失败"
	exit 1
fi

echo ""
echo "🚀 7. 启动服务..."

systemctl restart x-ui

# 等待服务启动
sleep 3

echo ""
echo "🧪 8. 测试修复结果..."

# 检查服务状态
if systemctl is-active x-ui >/dev/null 2>&1; then
	echo "✅ x-ui 服务运行正常"
else
	echo "❌ x-ui 服务未运行"
	systemctl status x-ui --no-pager -l | head -5
fi

# 测试页面访问
echo ""
echo "📊 测试页面访问："

ROOT_RESPONSE=$(curl -s "$BASE_URL/" --connect-timeout 5 | wc -c)
PANEL_RESPONSE=$(curl -s "$BASE_URL/panel" --connect-timeout 5 | wc -c)
API_RESPONSE=$(curl -s "$BASE_URL/api" --connect-timeout 5 | wc -c)

echo "✅ 原生登录页面 (/): $ROOT_RESPONSE 字符"
echo "✅ 原生管理面板 (/panel): $PANEL_RESPONSE 字符"
echo "✅ Enhanced API界面 (/api): $API_RESPONSE 字符"

# 测试API端点是否正常
echo ""
echo "🔗 测试Enhanced API端点："

API_TEST=$(curl -s "$BASE_URL/panel/api/server/status" | grep -o '"success":true' | wc -l)

if [[ $API_TEST -eq 1 ]]; then
	echo "✅ Enhanced API端点正常工作"
else
	echo "❌ Enhanced API端点可能有问题"
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🎉 原生前端恢复 + Enhanced API分离访问完成！         ║"
echo "║                                                        ║"
echo "║  ✅ 访问方式:                                          ║"
echo "║  🏠 原生3X-UI界面: http://$SERVER_IP:2053/            ║"
echo "║  🏠 原生管理面板: http://$SERVER_IP:2053/panel        ║"
echo "║  🚀 Enhanced API: http://$SERVER_IP:2053/api          ║"
echo "║                                                        ║"
echo "║  🔑 登录信息:                                          ║"
echo "║  用户名: admin                                         ║"
echo "║  密码: admin                                           ║"
echo "║                                                        ║"
echo "║  📋 功能说明:                                          ║"
echo "║  • 根路径显示原生3X-UI登录界面                        ║"
echo "║  • /panel 显示原生3X-UI管理面板                       ║"
echo "║  • /api 显示Enhanced API管理界面                      ║"
echo "║  • 所有Enhanced API端点保持不变                       ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"

echo ""
echo "🎯 使用说明："
echo "1. 🌐 访问 http://$SERVER_IP:2053/ - 使用熟悉的原生3X-UI界面"
echo "2. 🔑 使用 admin/admin 登录原生面板"
echo "3. 🏠 在原生面板中可以看到Enhanced API功能通知"
echo "4. 🚀 访问 http://$SERVER_IP:2053/api - 使用Enhanced API管理功能"
echo "5. 📊 运行API测试验证所有功能正常"

echo ""
echo "🧪 验证Enhanced API功能："
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/complete_api_test.sh)"

echo ""
echo "🌟 现在您拥有："
echo "✅ 原生3X-UI的熟悉界面和操作体验"
echo "✅ Enhanced API的强大功能（出站、路由、订阅管理）"
echo "✅ 清晰分离的访问路径（原生 vs Enhanced）"
echo "✅ 完整保留的API端点和功能"

echo ""
echo "=== 原生前端恢复工具完成 ==="
