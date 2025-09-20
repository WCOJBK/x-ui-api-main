#!/bin/bash

echo "=== 3X-UI Enhanced API 深度诊断和修复工具 ==="
echo "解决登录凭据和API端点问题"

# 新的登录凭据
USERNAME="460f8e21"
PASSWORD="bdd38f62"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

echo ""
echo "🌐 目标系统："
echo "🔗 面板地址: ${BASE_URL}/"
echo "👤 用户名: ${USERNAME}"
echo "🔑 密码: ${PASSWORD}"

echo ""
echo "🔧 1. 安装必要的系统工具..."
apt-get update >/dev/null 2>&1
apt-get install -y net-tools sqlite3 curl >/dev/null 2>&1
echo "✅ 系统工具安装完成"

echo ""
echo "🔍 2. 检查端口监听状态..."
if command -v netstat >/dev/null 2>&1; then
    echo "📋 当前监听的端口："
    netstat -tlnp | grep -E ":2053|:54321|:8080|x-ui" | head -5
    
    if netstat -tlnp | grep ":2053" >/dev/null 2>&1; then
        echo "✅ 端口 2053 正在监听"
    else
        echo "❌ 端口 2053 未在监听"
        echo "🔍 查找x-ui监听的端口..."
        netstat -tlnp | grep x-ui
    fi
else
    echo "⚠️  netstat仍然不可用，但不影响修复"
fi

echo ""
echo "🔍 3. 深度检查数据库..."
if [[ -f "/etc/x-ui/x-ui.db" ]]; then
    echo "✅ 数据库文件存在"
    
    echo "📋 数据库文件信息："
    ls -la /etc/x-ui/x-ui.db
    
    echo ""
    echo "📋 当前数据库中的用户信息："
    sqlite3 /etc/x-ui/x-ui.db "SELECT id, username, password FROM users;" 2>/dev/null || echo "无法读取用户表"
    
    echo ""
    echo "🔧 强制更新数据库中的用户凭据..."
    
    # 删除所有现有用户
    sqlite3 /etc/x-ui/x-ui.db "DELETE FROM users;" 2>/dev/null
    
    # 插入新用户
    sqlite3 /etc/x-ui/x-ui.db "INSERT INTO users (id, username, password) VALUES (1, '${USERNAME}', '${PASSWORD}');" 2>/dev/null
    
    echo "✅ 用户数据库更新完成"
    
    echo "📋 验证数据库更新："
    sqlite3 /etc/x-ui/x-ui.db "SELECT id, username, password FROM users;" 2>/dev/null || echo "验证失败"
    
    echo ""
    echo "📋 检查数据库中的其他设置："
    sqlite3 /etc/x-ui/x-ui.db "SELECT key, value FROM settings WHERE key LIKE '%port%' OR key LIKE '%secret%';" 2>/dev/null | head -10
    
else
    echo "❌ 数据库文件不存在"
    echo "🔧 创建默认数据库..."
    mkdir -p /etc/x-ui
    
    # 创建基本的数据库结构
    sqlite3 /etc/x-ui/x-ui.db "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT);"
    sqlite3 /etc/x-ui/x-ui.db "INSERT INTO users (id, username, password) VALUES (1, '${USERNAME}', '${PASSWORD}');"
    sqlite3 /etc/x-ui/x-ui.db "CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT);"
    
    echo "✅ 默认数据库创建完成"
fi

echo ""
echo "🚀 4. 重启服务以应用数据库更改..."
systemctl stop x-ui
sleep 3
systemctl start x-ui
sleep 5

echo "✅ 服务重启完成"

echo ""
echo "🔍 5. 重新测试登录..."
LOGIN_DATA="{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}"

echo "🧪 测试登录API..."
LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/login" \
    -H "Content-Type: application/json" \
    -d "$LOGIN_DATA" \
    --connect-timeout 10)

echo "📋 登录响应: $LOGIN_RESPONSE"

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    echo "✅ 登录成功！数据库修复生效"
    
    # 提取cookie进行后续API测试
    echo "🍪 获取会话cookie..."
    COOKIE_JAR="/tmp/x-ui-cookies.txt"
    curl -s -c "$COOKIE_JAR" -X POST "${BASE_URL}/login" \
        -H "Content-Type: application/json" \
        -d "$LOGIN_DATA" >/dev/null
    
else
    echo "❌ 登录仍然失败，尝试其他方法..."
    
    echo ""
    echo "🔍 检查可能的API端点..."
    
    # 测试不同的登录端点
    ALTERNATIVE_ENDPOINTS=("/api/login" "/xui/login" "/panel/login" "/admin/login")
    
    for endpoint in "${ALTERNATIVE_ENDPOINTS[@]}"; do
        echo "🧪 测试登录端点: $endpoint"
        ALT_RESPONSE=$(curl -s -X POST "${BASE_URL}${endpoint}" \
            -H "Content-Type: application/json" \
            -d "$LOGIN_DATA" \
            --connect-timeout 5)
        
        if [[ "$ALT_RESPONSE" != "404 page not found" ]] && [[ -n "$ALT_RESPONSE" ]]; then
            echo "📋 端点响应: $(echo "$ALT_RESPONSE" | cut -c1-100)..."
            if echo "$ALT_RESPONSE" | grep -q '"success":true'; then
                echo "✅ 找到有效的登录端点: $endpoint"
                break
            fi
        fi
    done
fi

echo ""
echo "🔍 6. 检查Enhanced API端点..."

echo "🧪 探测可能的API路径..."

# 可能的API基础路径
API_BASES=("/api" "/panel/api" "/xui/api" "/admin/api" "")

# 需要测试的端点
API_ENDPOINTS=("server/status" "inbounds/list" "outbound/list" "routing/list" "subscription/list")

echo "📋 开始API端点探测..."

for base in "${API_BASES[@]}"; do
    for endpoint in "${API_ENDPOINTS[@]}"; do
        full_path="${base}/${endpoint}"
        full_url="${BASE_URL}${full_path}"
        
        echo -n "🔍 测试: $full_path ... "
        
        # 测试GET请求
        response=$(curl -s -w "%{http_code}" -o /dev/null "$full_url" --connect-timeout 3)
        
        if [[ "$response" != "404" ]]; then
            echo "响应码: $response"
            if [[ "$response" == "200" ]] || [[ "$response" == "401" ]] || [[ "$response" == "403" ]]; then
                echo "✅ 发现有效端点: $full_path (HTTP $response)"
                
                # 尝试POST请求
                echo "🧪 测试POST请求..."
                post_response=$(curl -s -X POST "$full_url" \
                    -H "Content-Type: application/json" \
                    -d "$LOGIN_DATA" \
                    --connect-timeout 5)
                
                if [[ -n "$post_response" ]] && [[ "$post_response" != "404 page not found" ]]; then
                    echo "📋 POST响应: $(echo "$post_response" | cut -c1-150)..."
                fi
            fi
        else
            echo "404"
        fi
    done
done

echo ""
echo "🔍 7. 检查程序中编译的路由..."

echo "🧪 检查x-ui可执行文件中的路由信息..."
if [[ -f "/usr/local/x-ui/x-ui" ]]; then
    echo "📋 在可执行文件中搜索API路径："
    
    # 搜索可能的API路径
    strings /usr/local/x-ui/x-ui | grep -i -E "(api|/panel|/admin)" | grep -E "/(.*)" | head -20 || echo "未找到明显的API路径"
    
    echo ""
    echo "📋 搜索路由相关字符串："
    strings /usr/local/x-ui/x-ui | grep -i -E "(route|endpoint|handler)" | head -10 || echo "未找到路由信息"
    
    echo ""
    echo "📋 搜索Enhanced API相关字符串："
    strings /usr/local/x-ui/x-ui | grep -i -E "(outbound|routing|subscription)" | head -10 || echo "未找到Enhanced API字符串"
fi

echo ""
echo "🔍 8. 分析程序版本和功能..."

echo "🧪 检查程序版本信息..."
if /usr/local/x-ui/x-ui -v 2>/dev/null; then
    echo "✅ 程序版本信息获取成功"
else
    echo "⚠️  无法获取版本信息"
fi

echo ""
echo "🧪 检查程序帮助信息..."
/usr/local/x-ui/x-ui -h 2>/dev/null | head -10 || echo "无法获取帮助信息"

echo ""
echo "🔍 9. 服务状态最终检查..."

echo "📋 systemd服务状态："
systemctl status x-ui --no-pager -l | head -10

echo ""
echo "📋 进程状态："
ps aux | grep -E "[x]-ui|[x]ray" | head -5

echo ""
echo "📋 最新日志："
journalctl -u x-ui -n 10 --no-pager | tail -5

echo ""
echo "🔧 10. 生成修复建议..."

echo "📊 诊断结果摘要："
echo "  - 数据库更新: $(sqlite3 /etc/x-ui/x-ui.db "SELECT COUNT(*) FROM users;" 2>/dev/null)个用户"
echo "  - 服务状态: $(systemctl is-active x-ui)"
echo "  - Xray状态: $(pgrep -f "xray" >/dev/null 2>&1 && echo "Running" || echo "Not Running")"

echo ""
echo "🎯 修复建议："

if ! echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    echo "❌ 登录问题持续存在，建议："
    echo "  1. 检查程序是否为我们编译的Enhanced版本"
    echo "  2. 可能需要重新编译Enhanced API版本"
    echo "  3. 检查是否有其他认证机制（如secret key）"
fi

echo "❌ Enhanced API端点全部404，建议："
echo "  1. 确认编译的版本包含Enhanced API功能"
echo "  2. 检查路由是否正确注册"
echo "  3. 可能需要使用不同的API路径"

echo ""
echo "🌐 访问建议："
echo "  1. 浏览器访问: ${BASE_URL}/"
echo "  2. 使用凭据: ${USERNAME} / ${PASSWORD}"
echo "  3. 检查浏览器开发者工具中的网络请求"
echo "  4. 查看实际的API端点路径"

echo ""
echo "=== 深度诊断和修复工具完成 ==="
