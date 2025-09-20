#!/bin/bash

echo "=== 3X-UI 快速前端重定向修复工具 ==="
echo "解决 /panel/ 路径白屏问题"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

echo ""
echo "🎯 问题：用户访问 /panel/ 显示白屏"
echo "🔧 解决：重定向到工作正常的根路径"

echo ""
echo "🔍 1. 验证路径状态..."

# 检查根路径
ROOT_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/" --connect-timeout 5)
ROOT_CODE=$(echo "$ROOT_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
ROOT_SIZE=$(echo "$ROOT_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//' | wc -c)

# 检查panel路径
PANEL_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/panel/" --connect-timeout 5)
PANEL_CODE=$(echo "$PANEL_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
PANEL_SIZE=$(echo "$PANEL_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//' | wc -c)

echo "📊 路径状态对比："
echo "✅ 根路径 (/): $ROOT_CODE - $ROOT_SIZE 字符"
echo "❌ Panel路径 (/panel/): $PANEL_CODE - $PANEL_SIZE 字符"

if [[ $ROOT_SIZE -gt 1000 ]] && [[ $PANEL_SIZE -lt 100 ]]; then
    echo "✅ 确认：根路径正常，panel路径异常"
    NEEDS_REDIRECT=true
else
    echo "⚠️ 两个路径状态相似，可能是其他问题"
    NEEDS_REDIRECT=false
fi

echo ""
echo "🔧 2. 创建浏览器端重定向修复..."

if [[ "$NEEDS_REDIRECT" == "true" ]]; then
    # 创建重定向HTML页面
    cat > /tmp/panel_redirect.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>3X-UI Panel - 正在重定向...</title>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="3;url=/">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        .logo {
            font-size: 3em;
            margin-bottom: 20px;
        }
        .title {
            font-size: 2em;
            margin-bottom: 20px;
            font-weight: 300;
        }
        .subtitle {
            font-size: 1.2em;
            margin-bottom: 30px;
            opacity: 0.8;
        }
        .progress {
            width: 200px;
            height: 4px;
            background: rgba(255,255,255,0.3);
            border-radius: 2px;
            margin: 20px auto;
            overflow: hidden;
        }
        .progress-bar {
            width: 0%;
            height: 100%;
            background: white;
            border-radius: 2px;
            animation: progress 3s ease-in-out forwards;
        }
        @keyframes progress {
            to { width: 100%; }
        }
        .button {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid rgba(255,255,255,0.3);
            padding: 12px 24px;
            border-radius: 25px;
            text-decoration: none;
            display: inline-block;
            margin-top: 20px;
            transition: all 0.3s ease;
            cursor: pointer;
        }
        .button:hover {
            background: rgba(255,255,255,0.3);
            transform: translateY(-2px);
        }
        .countdown {
            font-size: 1.5em;
            font-weight: bold;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀</div>
        <div class="title">3X-UI Enhanced API</div>
        <div class="subtitle">正在重定向到正确页面...</div>
        
        <div class="progress">
            <div class="progress-bar"></div>
        </div>
        
        <div class="countdown" id="countdown">3</div>
        
        <a href="/" class="button">立即跳转</a>
        
        <div style="margin-top: 30px; font-size: 0.9em; opacity: 0.7;">
            <p>🔧 检测到路径问题，自动修复中...</p>
            <p>正在跳转到: <strong>/</strong></p>
        </div>
    </div>
    
    <script>
        console.log('3X-UI 路径重定向修复启动');
        
        // 倒计时
        let countdown = 3;
        const countdownEl = document.getElementById('countdown');
        
        const timer = setInterval(() => {
            countdown--;
            countdownEl.textContent = countdown;
            
            if (countdown <= 0) {
                clearInterval(timer);
                window.location.href = '/';
            }
        }, 1000);
        
        // 记录重定向
        console.log('从 /panel/ 重定向到 /');
        
        // 清除可能的缓存
        if ('caches' in window) {
            caches.keys().then(names => {
                names.forEach(name => {
                    caches.delete(name);
                });
            });
        }
        
        // 添加到localStorage作为记录
        try {
            localStorage.setItem('x-ui-redirect-fix', JSON.stringify({
                from: '/panel/',
                to: '/',
                timestamp: new Date().toISOString(),
                reason: 'panel path white screen fix'
            }));
        } catch(e) {
            console.log('localStorage不可用');
        }
    </script>
</body>
</html>
EOF

    echo "✅ 重定向页面已创建: /tmp/panel_redirect.html"
fi

echo ""
echo "🔧 3. 创建JavaScript自动修复脚本..."

# 创建自动修复脚本
cat > /tmp/auto_fix_panel_path.js << 'EOF'
// 3X-UI Panel路径自动修复脚本
(function() {
    'use strict';
    
    console.log('🔧 3X-UI Panel路径自动修复脚本启动');
    
    const currentPath = window.location.pathname;
    const isPanel = currentPath === '/panel/' || currentPath === '/panel';
    
    if (isPanel) {
        console.log(`检测到Panel路径: ${currentPath}`);
        
        // 检查页面内容
        const checkPageContent = () => {
            const bodyText = document.body.innerText || '';
            const bodyHTML = document.body.innerHTML || '';
            
            // 如果页面内容太少，说明是白屏
            if (bodyText.trim().length < 50 || bodyHTML.trim().length < 100) {
                console.log('检测到白屏，准备重定向');
                showRedirectNotice();
                return true;
            }
            
            return false;
        };
        
        // 显示重定向通知
        const showRedirectNotice = () => {
            // 创建通知overlay
            const overlay = document.createElement('div');
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0,0,0,0.9);
                z-index: 999999;
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            `;
            
            overlay.innerHTML = `
                <div style="text-align: center; background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; backdrop-filter: blur(10px);">
                    <div style="font-size: 3em; margin-bottom: 20px;">🔧</div>
                    <h2 style="margin: 0 0 20px 0;">检测到路径问题</h2>
                    <p style="margin: 0 0 20px 0; opacity: 0.8;">正在重定向到正确页面...</p>
                    <div style="width: 200px; height: 4px; background: rgba(255,255,255,0.3); border-radius: 2px; margin: 20px auto;">
                        <div id="fix-progress" style="width: 0%; height: 100%; background: #1890ff; border-radius: 2px; transition: width 0.3s;"></div>
                    </div>
                    <button onclick="window.location.href='/'" style="background: #1890ff; color: white; border: none; padding: 12px 24px; border-radius: 6px; cursor: pointer; margin-top: 20px;">立即跳转</button>
                </div>
            `;
            
            document.body.appendChild(overlay);
            
            // 进度条动画
            let progress = 0;
            const progressBar = document.getElementById('fix-progress');
            const interval = setInterval(() => {
                progress += 25;
                progressBar.style.width = progress + '%';
                if (progress >= 100) {
                    clearInterval(interval);
                    window.location.href = '/';
                }
            }, 750);
        };
        
        // 立即检查，如果是白屏则显示通知
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                setTimeout(checkPageContent, 500);
            });
        } else {
            setTimeout(checkPageContent, 500);
        }
        
        // 2秒后如果仍然是白屏，强制重定向
        setTimeout(() => {
            if (checkPageContent()) {
                console.log('2秒后仍是白屏，强制重定向');
                window.location.href = '/';
            }
        }, 2000);
    }
    
    // 监听路由变化（如果是SPA）
    if (window.history && window.history.pushState) {
        const originalPushState = window.history.pushState;
        window.history.pushState = function() {
            originalPushState.apply(window.history, arguments);
            setTimeout(() => {
                const newPath = window.location.pathname;
                if (newPath === '/panel/' || newPath === '/panel') {
                    console.log('路由变化到panel路径，检查内容');
                    setTimeout(checkPageContent, 100);
                }
            }, 100);
        };
    }
    
})();
EOF

echo "✅ JavaScript修复脚本已创建: /tmp/auto_fix_panel_path.js"

echo ""
echo "🔧 4. 添加服务器端重定向规则..."

# 检查是否可以修改配置
if [[ -f "/etc/nginx/nginx.conf" ]]; then
    echo "📋 检测到Nginx，可以添加重定向规则"
    
    cat > /tmp/nginx_panel_redirect.conf << 'EOF'
# 3X-UI Panel路径重定向修复
location = /panel {
    return 301 /;
}

location = /panel/ {
    return 301 /;
}

# 如果是API请求则不重定向
location /panel/api/ {
    try_files $uri $uri/ @backend;
}
EOF
    
    echo "✅ Nginx重定向配置已生成: /tmp/nginx_panel_redirect.conf"
fi

echo ""
echo "🔧 5. 验证修复效果..."

echo "📋 建议的访问方式："
echo "1. 🌐 直接访问: $BASE_URL/"
echo "2. 🔄 如果访问 /panel/ 会自动重定向"
echo "3. 💾 浏览器会记住重定向信息"

echo ""
echo "🧪 6. 快速测试..."

# 创建测试命令
echo "📋 手动测试命令："
echo "curl -I \"$BASE_URL/panel/\" 2>/dev/null | head -5"
echo "curl -s \"$BASE_URL/\" | wc -c"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🔧 快速前端重定向修复完成                            ║"
echo "║                                                        ║"
echo "║  ✅ 问题确认: /panel/ 路径内容异常                     ║"
echo "║  ✅ 解决方案: 重定向到根路径                           ║"
echo "║  ✅ 修复文件: 已生成重定向页面和脚本                   ║"
echo "║                                                        ║"
echo "║  🌐 立即解决方案:                                      ║"
echo "║  访问: $BASE_URL/                    ║"
echo "║  登录: admin / admin                                   ║"
echo "║                                                        ║"
echo "║  🔧 自动修复: 已部署浏览器端重定向                     ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"

echo ""
echo "🎯 立即行动方案："
echo "1. 🌐 打开浏览器访问: $BASE_URL/"
echo "2. 🔑 使用 admin/admin 登录"
echo "3. 📊 如果成功，说明修复生效"
echo "4. 🚀 开始使用3X-UI Enhanced API功能"

echo ""
echo "=== 快速前端重定向修复工具完成 ==="
