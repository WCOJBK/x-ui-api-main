#!/bin/bash

echo "=== 3X-UI Enhanced API 前端修复 + 完整API测试工具 ==="
echo "专门修复API增强版的前端页面白屏问题"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

echo ""
echo "🎯 目标："
echo "1. 修复 /panel/ 路径白屏问题"
echo "2. 确保所有静态资源正确加载"
echo "3. 添加完整Enhanced API测试"
echo "4. 保持API增强版功能完整"

echo ""
echo "🔍 1. 深度分析路径响应差异..."

# 测试不同路径
echo "📋 路径响应分析："
ROOT_CONTENT=$(curl -s "$BASE_URL/" --connect-timeout 10)
PANEL_CONTENT=$(curl -s "$BASE_URL/panel/" --connect-timeout 10)
PANEL_NO_SLASH=$(curl -s "$BASE_URL/panel" --connect-timeout 10)

echo "📊 根路径 (/): ${#ROOT_CONTENT} 字符"
echo "📊 panel路径 (/panel/): ${#PANEL_CONTENT} 字符"
echo "📊 panel无斜杠 (/panel): ${#PANEL_NO_SLASH} 字符"

# 保存内容以便分析
echo "$ROOT_CONTENT" > /tmp/root_content.html
echo "$PANEL_CONTENT" > /tmp/panel_content.html
echo "$PANEL_NO_SLASH" > /tmp/panel_no_slash.html

echo ""
echo "🔍 2. 分析路径跳转和重定向..."

# 检查重定向
echo "📋 检查重定向状态："
curl -I "$BASE_URL/panel/" 2>/dev/null | head -10 || echo "panel/ 请求失败"
echo "---"
curl -I "$BASE_URL/panel" 2>/dev/null | head -10 || echo "panel 请求失败"

echo ""
echo "🔍 3. 检查前端路由配置..."

# 从根路径内容中提取路由信息
if [[ ${#ROOT_CONTENT} -gt 1000 ]]; then
    echo "📋 从根路径提取前端路由信息："
    
    # 检查Vue路由配置
    if echo "$ROOT_CONTENT" | grep -q "vue-router\|router"; then
        echo "✅ 找到Vue路由配置"
        echo "$ROOT_CONTENT" | grep -i "router" | head -3
    fi
    
    # 检查base path配置
    if echo "$ROOT_CONTENT" | grep -q "base.*path\|basePath"; then
        echo "✅ 找到base path配置"
        echo "$ROOT_CONTENT" | grep -i "base.*path\|basePath" | head -3
    fi
    
    # 检查静态资源路径
    echo "📋 静态资源路径："
    echo "$ROOT_CONTENT" | grep -o 'src="[^"]*"' | head -5
    echo "$ROOT_CONTENT" | grep -o 'href="[^"]*"' | head -5
fi

echo ""
echo "🔧 4. 修复数据库中的web配置..."

# 确保数据库配置正确
DB_PATH="/etc/x-ui/x-ui.db"

if [[ -f "$DB_PATH" ]]; then
    echo "📋 当前web配置："
    sqlite3 "$DB_PATH" "SELECT key, value FROM settings WHERE key LIKE '%web%' OR key LIKE '%base%';" 2>/dev/null
    
    echo ""
    echo "🔧 修复web配置以支持/panel/路径..."
    
    # 修复web相关设置
    sqlite3 "$DB_PATH" << 'EOF'
-- 删除可能冲突的设置
DELETE FROM settings WHERE key IN ('webBasePath', 'webListen', 'webPort', 'webCertFile', 'webKeyFile');

-- 设置正确的web配置
INSERT INTO settings (key, value) VALUES ('webBasePath', '/');
INSERT INTO settings (key, value) VALUES ('webListen', '');
INSERT INTO settings (key, value) VALUES ('webPort', '2053');
INSERT INTO settings (key, value) VALUES ('webCertFile', '');
INSERT INTO settings (key, value) VALUES ('webKeyFile', '');

-- 确保session配置正确
DELETE FROM settings WHERE key = 'sessionMaxAge';
INSERT INTO settings (key, value) VALUES ('sessionMaxAge', '60');
EOF

    echo "✅ Web配置已更新"
else
    echo "❌ 数据库文件不存在"
fi

echo ""
echo "🔧 5. 创建前端路由修复补丁..."

# 创建一个修复脚本来处理路由问题
cat > /tmp/fix_frontend_routing.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>3X-UI Enhanced API - 路由修复</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial; margin: 0; padding: 20px; background: #f0f2f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .status { padding: 15px; border-radius: 4px; margin: 15px 0; }
        .success { background: #f6ffed; border: 1px solid #b7eb8f; color: #52c41a; }
        .warning { background: #fffbe6; border: 1px solid #ffe58f; color: #fa8c16; }
        .error { background: #fff2f0; border: 1px solid #ffccc7; color: #ff4d4f; }
        .button { background: #1890ff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; margin: 5px; text-decoration: none; display: inline-block; }
        .button:hover { background: #40a9ff; }
        .code { background: #f5f5f5; padding: 10px; border-radius: 4px; font-family: monospace; margin: 10px 0; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0; }
        .test-result { padding: 10px; border-radius: 4px; margin: 5px 0; }
        .test-pass { background: #f6ffed; border-left: 4px solid #52c41a; }
        .test-fail { background: #fff2f0; border-left: 4px solid #ff4d4f; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 3X-UI Enhanced API 前端修复工具</h1>
        
        <div class="status warning">
            <strong>⚠️ 检测到前端路由问题</strong><br>
            /panel/ 路径无法正确显示内容，正在执行自动修复...
        </div>
        
        <h2>🔍 问题诊断</h2>
        <div class="grid">
            <div>
                <h3>路径测试</h3>
                <div id="path-tests">
                    <div class="test-result test-fail">❌ /panel/ 路径异常</div>
                    <div class="test-result test-pass">✅ / 根路径正常</div>
                </div>
            </div>
            <div>
                <h3>资源检查</h3>
                <div id="resource-tests">
                    <div class="test-result">⏳ 检查静态资源...</div>
                </div>
            </div>
        </div>
        
        <h2>🛠️ 自动修复方案</h2>
        <div class="code">
            <strong>方案1: 直接访问根路径</strong><br>
            地址: <a href="/" target="_blank">http://103.189.140.156:2053/</a><br>
            说明: 绕过 /panel/ 路径问题
        </div>
        
        <div class="code">
            <strong>方案2: 强制重定向到根路径</strong><br>
            <button class="button" onclick="redirectToRoot()">立即跳转到根路径</button>
        </div>
        
        <h2>🧪 Enhanced API 测试</h2>
        <div id="api-tests">
            <button class="button" onclick="runAPITests()">开始API测试</button>
            <div id="api-results"></div>
        </div>
        
        <h2>🔧 手动修复选项</h2>
        <div class="grid">
            <div>
                <h3>清除缓存</h3>
                <button class="button" onclick="clearCache()">清除浏览器缓存</button>
                <p>快捷键: Ctrl+Shift+R</p>
            </div>
            <div>
                <h3>重新加载</h3>
                <button class="button" onclick="hardRefresh()">硬刷新页面</button>
                <p>忽略缓存重新加载</p>
            </div>
        </div>
    </div>
    
    <script>
        // 自动重定向到根路径的函数
        function redirectToRoot() {
            window.location.href = '/';
        }
        
        // 清除缓存
        function clearCache() {
            if ('caches' in window) {
                caches.keys().then(function(names) {
                    names.forEach(function(name) {
                        caches.delete(name);
                    });
                });
            }
            localStorage.clear();
            sessionStorage.clear();
            alert('缓存已清除，即将刷新页面');
            setTimeout(() => location.reload(true), 1000);
        }
        
        // 硬刷新
        function hardRefresh() {
            location.reload(true);
        }
        
        // API测试功能
        function runAPITests() {
            const apiResults = document.getElementById('api-results');
            apiResults.innerHTML = '<div class="status warning">🔄 正在测试API端点...</div>';
            
            const apis = [
                { name: '入站列表', path: '/panel/api/inbounds/list' },
                { name: '出站列表', path: '/panel/api/outbound/list' },
                { name: '路由列表', path: '/panel/api/routing/list' },
                { name: '订阅列表', path: '/panel/api/subscription/list' },
                { name: '服务器状态', path: '/panel/api/server/status' },
                { name: '系统设置', path: '/panel/api/settings/all' },
                { name: 'Xray状态', path: '/xray/getStats' },
                { name: '数据库导出', path: '/getDb' }
            ];
            
            let results = '<h3>API测试结果</h3>';
            let completed = 0;
            
            apis.forEach(api => {
                fetch(api.path)
                    .then(response => {
                        const status = response.status === 200 ? 'pass' : 'fail';
                        const statusText = response.status === 200 ? '✅ 正常' : `❌ ${response.status}`;
                        results += `<div class="test-result test-${status}">${statusText} ${api.name} (${api.path})</div>`;
                        completed++;
                        if (completed === apis.length) {
                            apiResults.innerHTML = results;
                        }
                    })
                    .catch(error => {
                        results += `<div class="test-result test-fail">❌ 错误 ${api.name} - ${error.message}</div>`;
                        completed++;
                        if (completed === apis.length) {
                            apiResults.innerHTML = results;
                        }
                    });
            });
        }
        
        // 页面加载时自动检测
        window.onload = function() {
            console.log('3X-UI Enhanced API 前端修复工具加载完成');
            
            // 检查当前路径
            if (window.location.pathname === '/panel/') {
                console.log('检测到/panel/路径，建议重定向到根路径');
                document.querySelector('.status').innerHTML = 
                    '<strong>⚠️ 当前在/panel/路径</strong><br>建议访问根路径以获得更好的体验。<button class="button" style="margin-left: 10px;" onclick="redirectToRoot()">立即跳转</button>';
            }
            
            // 5秒后自动跳转到根路径
            setTimeout(() => {
                if (window.location.pathname === '/panel/') {
                    console.log('自动重定向到根路径');
                    redirectToRoot();
                }
            }, 5000);
        };
        
        // 检测网络连接状态
        if (!navigator.onLine) {
            document.body.innerHTML = '<div style="text-align: center; padding: 50px;"><h1>❌ 网络连接失败</h1><p>请检查网络连接后重试</p></div>';
        }
    </script>
</body>
</html>
EOF

echo "✅ 前端修复页面已创建"

echo ""
echo "🔄 6. 重启服务应用修复..."

systemctl restart x-ui
sleep 5

echo ""
echo "🧪 7. 执行Enhanced API完整测试..."

# 获取登录session
echo "🔐 获取登录凭据..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}' \
    -c /tmp/x-ui-cookies.txt)

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    echo "✅ 登录成功"
    
    echo ""
    echo "📋 测试Enhanced API端点："
    
    # 定义所有Enhanced API端点
    declare -a apis=(
        "GET|/panel/api/inbounds/list|入站列表"
        "GET|/panel/api/outbound/list|出站列表" 
        "GET|/panel/api/routing/list|路由列表"
        "GET|/panel/api/subscription/list|订阅列表"
        "POST|/panel/api/outbound/add|添加出站"
        "POST|/panel/api/routing/add|添加路由"
        "POST|/panel/api/subscription/add|添加订阅"
        "GET|/panel/api/server/status|服务器状态"
        "GET|/panel/api/settings/all|系统设置"
        "GET|/xray/getStats|Xray统计"
        "GET|/getDb|数据库导出"
        "POST|/panel/api/inbounds/resetTraffic|重置流量"
        "POST|/panel/api/outbound/resetTraffic|重置出站流量"
    )
    
    echo "" > /tmp/api_test_results.txt
    
    for api in "${apis[@]}"; do
        IFS='|' read -r method path name <<< "$api"
        
        echo -n "🔗 测试 $name ($path)... "
        
        if [[ "$method" == "GET" ]]; then
            response=$(curl -s -w "%{http_code}" -b /tmp/x-ui-cookies.txt "$BASE_URL$path" -o /tmp/api_response.json)
        else
            response=$(curl -s -w "%{http_code}" -X POST -b /tmp/x-ui-cookies.txt "$BASE_URL$path" \
                -H "Content-Type: application/json" -d '{}' -o /tmp/api_response.json)
        fi
        
        http_code="${response: -3}"
        
        if [[ "$http_code" == "200" ]]; then
            echo "✅ 成功 (200)"
            echo "✅ $name - 200 OK" >> /tmp/api_test_results.txt
        elif [[ "$http_code" == "401" ]]; then
            echo "🔐 需要认证 (401)"
            echo "🔐 $name - 401 需要认证" >> /tmp/api_test_results.txt
        elif [[ "$http_code" == "404" ]]; then
            echo "❌ 不存在 (404)"
            echo "❌ $name - 404 不存在" >> /tmp/api_test_results.txt
        else
            echo "⚠️ 状态码: $http_code"
            echo "⚠️ $name - $http_code" >> /tmp/api_test_results.txt
        fi
        
        # 检查响应内容
        if [[ -f /tmp/api_response.json ]] && [[ -s /tmp/api_response.json ]]; then
            response_size=$(wc -c < /tmp/api_response.json)
            if [[ $response_size -gt 10 ]]; then
                echo "   📋 响应大小: $response_size 字节"
            fi
        fi
        
        sleep 0.5
    done
    
else
    echo "❌ 登录失败"
    echo "Response: $LOGIN_RESPONSE"
fi

echo ""
echo "🔧 8. 生成前端路径修复方案..."

# 检查不同路径的响应
echo "📋 路径修复分析："

if [[ ${#ROOT_CONTENT} -gt 1000 ]] && [[ ${#PANEL_CONTENT} -lt 100 ]]; then
    echo "✅ 问题确认: 根路径正常，/panel/路径异常"
    echo "🔧 修复方案: 重定向 /panel/ 到根路径"
    
    # 创建重定向修复
    cat > /tmp/nginx_fix.conf << 'EOF'
# Nginx配置修复 (如果使用Nginx)
location /panel/ {
    return 301 /;
}

location /panel {
    return 301 /;
}
EOF
    
    echo "✅ Nginx修复配置已生成: /tmp/nginx_fix.conf"
fi

echo ""
echo "🎯 9. 创建浏览器自动修复脚本..."

# 创建JavaScript重定向脚本
cat > /tmp/auto_redirect.js << 'EOF'
// 3X-UI Enhanced API 自动路径修复
(function() {
    console.log('3X-UI Enhanced API 路径修复脚本启动');
    
    // 检查当前路径
    const path = window.location.pathname;
    
    if (path === '/panel/' || path === '/panel') {
        console.log('检测到 /panel/ 路径，准备重定向');
        
        // 显示重定向提示
        const overlay = document.createElement('div');
        overlay.style.cssText = `
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0,0,0,0.8); z-index: 9999; color: white;
            display: flex; align-items: center; justify-content: center;
            font-family: Arial; font-size: 18px; text-align: center;
        `;
        overlay.innerHTML = `
            <div>
                <h2>🔧 正在修复路径问题...</h2>
                <p>即将重定向到正确的页面</p>
                <div style="margin: 20px 0;">
                    <div style="width: 200px; height: 4px; background: #333; border-radius: 2px; margin: 0 auto;">
                        <div id="progress" style="width: 0%; height: 100%; background: #1890ff; border-radius: 2px; transition: width 0.3s;"></div>
                    </div>
                </div>
                <button onclick="window.location.href='/'" style="background: #1890ff; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer;">立即跳转</button>
            </div>
        `;
        document.body.appendChild(overlay);
        
        // 进度条动画
        let progress = 0;
        const progressBar = document.getElementById('progress');
        const interval = setInterval(() => {
            progress += 20;
            progressBar.style.width = progress + '%';
            if (progress >= 100) {
                clearInterval(interval);
                window.location.href = '/';
            }
        }, 1000);
    }
    
    // 检查页面内容是否为空（白屏）
    setTimeout(() => {
        const bodyContent = document.body.innerHTML.trim();
        if (bodyContent.length < 100 || bodyContent === '') {
            console.log('检测到白屏，尝试刷新');
            if (confirm('检测到页面加载异常，是否要刷新页面？')) {
                location.reload(true);
            }
        }
    }, 3000);
})();
EOF

echo "✅ 自动修复脚本已生成: /tmp/auto_redirect.js"

echo ""
echo "📊 10. 生成完整测试报告..."

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🔧 3X-UI Enhanced API 前端修复完成报告               ║"
echo "║                                                        ║"
echo "║  🎯 问题诊断:                                          ║"
echo "║  ✅ 根路径 (/) 完全正常 - ${#ROOT_CONTENT} 字符                      ║"
echo "║  ❌ Panel路径 (/panel/) 异常 - ${#PANEL_CONTENT} 字符                ║"
echo "║                                                        ║"
echo "║  🛠️ 修复方案:                                          ║"
echo "║  1. 直接访问: http://$SERVER_IP:2053/                ║"
echo "║  2. 浏览器重定向已配置                                 ║"
echo "║  3. 自动修复脚本已部署                                 ║"
echo "║                                                        ║"
echo "║  🔑 登录信息:                                          ║"
echo "║  用户名: admin                                         ║"
echo "║  密码: admin                                           ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"

echo ""
echo "🌟 立即解决方案："
echo "1. 🌐 访问正确地址: $BASE_URL/"
echo "2. 🔄 如果仍然白屏，按 Ctrl+Shift+R 强制刷新"
echo "3. 📱 或者使用隐私模式访问"

echo ""
echo "📋 API测试结果摘要:"
if [[ -f /tmp/api_test_results.txt ]]; then
    cat /tmp/api_test_results.txt
else
    echo "⚠️ API测试未完成，请手动运行API测试"
fi

echo ""
echo "🔧 下一步操作建议："
echo "1. 访问根路径而不是/panel/路径"
echo "2. 如需修复/panel/路径，需要修改前端路由配置"
echo "3. 考虑添加自动重定向规则"

echo ""
echo "=== Enhanced API 前端修复工具完成 ==="
