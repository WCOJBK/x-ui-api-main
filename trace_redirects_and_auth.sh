#!/bin/bash

echo "=== 3X-UI Enhanced API 重定向追踪和认证破解工具 ==="
echo "追踪301重定向，找到真正的API端点并破解认证机制"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

# 登录凭据
USERNAME="460f8e21"
PASSWORD="bdd38f62"
SECRET="Nx0DwQXXO4yd1U5floQAjJJHQWstblr5"

echo ""
echo "🌐 服务器信息："
echo "🔗 面板地址: ${BASE_URL}/"
echo "👤 用户名: ${USERNAME}"
echo "🔑 密码: ${PASSWORD}"
echo "🔐 Secret: ${SECRET}"

echo ""
echo "🔍 1. 追踪API重定向路径..."

# 发现的301路径
REDIRECT_PATHS=(
    "/panel/API/server/status"
    "/panel/API/inbounds/list"
    "/panel/API/outbound/list"
    "/panel/API/routing/list"
    "/panel/API/subscription/list"
    "/xui/API/server/status"
)

echo "📋 追踪301重定向到真实端点..."

for path in "${REDIRECT_PATHS[@]}"; do
    echo ""
    echo "🔍 追踪路径: $path"
    
    # 使用-L跟随重定向，-w显示重定向信息
    REDIRECT_INFO=$(curl -s -L -w "REDIRECT_URL:%{redirect_url};FINAL_URL:%{url_effective};HTTP_CODE:%{http_code}" \
        "${BASE_URL}${path}" --connect-timeout 10)
    
    echo "📋 重定向信息: $REDIRECT_INFO"
    
    # 提取最终URL
    FINAL_URL=$(echo "$REDIRECT_INFO" | grep -o "FINAL_URL:[^;]*" | cut -d: -f2-)
    HTTP_CODE=$(echo "$REDIRECT_INFO" | grep -o "HTTP_CODE:[^;]*" | cut -d: -f2-)
    
    if [[ -n "$FINAL_URL" ]] && [[ "$FINAL_URL" != "${BASE_URL}${path}" ]]; then
        echo "✅ 发现重定向: $path -> $FINAL_URL"
        echo "📊 最终状态码: $HTTP_CODE"
        
        # 测试最终URL
        if [[ "$HTTP_CODE" == "200" ]]; then
            echo "🎉 找到有效的API端点！"
        fi
    fi
done

echo ""
echo "🔍 2. 分析登录页面源码寻找认证机制..."

echo "🌐 获取登录页面源码..."
LOGIN_PAGE=$(curl -s "${BASE_URL}/" --connect-timeout 10)

if [[ -n "$LOGIN_PAGE" ]]; then
    echo "📋 分析登录表单..."
    
    # 查找表单字段
    FORM_FIELDS=$(echo "$LOGIN_PAGE" | grep -oE 'name="[^"]*"' | sort | uniq)
    echo "🔍 发现的表单字段:"
    echo "$FORM_FIELDS"
    
    # 查找JavaScript中的登录逻辑
    echo ""
    echo "🔍 搜索JavaScript登录逻辑..."
    JS_LOGIN=$(echo "$LOGIN_PAGE" | grep -oE 'login[^}]*\{[^}]*\}' | head -3)
    if [[ -n "$JS_LOGIN" ]]; then
        echo "📋 发现的登录JavaScript:"
        echo "$JS_LOGIN"
    fi
    
    # 查找API调用
    echo ""
    echo "🔍 搜索页面中的API调用..."
    API_CALLS=$(echo "$LOGIN_PAGE" | grep -oE '"/[^"]*[Aa][Pp][Ii][^"]*"' | sort | uniq)
    if [[ -n "$API_CALLS" ]]; then
        echo "📋 发现的API路径:"
        echo "$API_CALLS"
    fi
    
    # 查找secret相关字段
    echo ""
    echo "🔍 搜索secret相关字段..."
    SECRET_FIELDS=$(echo "$LOGIN_PAGE" | grep -iE 'secret|token|csrf' | head -5)
    if [[ -n "$SECRET_FIELDS" ]]; then
        echo "📋 发现的secret相关内容:"
        echo "$SECRET_FIELDS"
    fi
fi

echo ""
echo "🧪 3. 测试不同的认证方式..."

# 测试空secret
echo "🔐 测试1: 空secret..."
LOGIN_EMPTY_SECRET='{"username":"'${USERNAME}'","password":"'${PASSWORD}'","secret":""}'
RESPONSE1=$(curl -s -X POST "${BASE_URL}/login" \
    -H "Content-Type: application/json" \
    -d "$LOGIN_EMPTY_SECRET" \
    --connect-timeout 10)
echo "📋 响应: $RESPONSE1"

# 测试不含secret
echo ""
echo "🔐 测试2: 不含secret字段..."
LOGIN_NO_SECRET='{"username":"'${USERNAME}'","password":"'${PASSWORD}'"}'
RESPONSE2=$(curl -s -X POST "${BASE_URL}/login" \
    -H "Content-Type: application/json" \
    -d "$LOGIN_NO_SECRET" \
    --connect-timeout 10)
echo "📋 响应: $RESPONSE2"

# 测试session cookie
echo ""
echo "🔐 测试3: 尝试获取session cookie..."
COOKIE_FILE="/tmp/x-ui-test-cookies.txt"
curl -s -c "$COOKIE_FILE" "${BASE_URL}/" >/dev/null

if [[ -f "$COOKIE_FILE" ]]; then
    echo "📋 获取到的cookies:"
    cat "$COOKIE_FILE"
    
    echo ""
    echo "🔐 测试4: 使用cookies进行登录..."
    RESPONSE3=$(curl -s -X POST "${BASE_URL}/login" \
        -b "$COOKIE_FILE" \
        -H "Content-Type: application/json" \
        -d "$LOGIN_NO_SECRET" \
        --connect-timeout 10)
    echo "📋 响应: $RESPONSE3"
fi

echo ""
echo "🧪 4. 尝试直接访问面板内部页面..."

# 测试已知的面板页面
PANEL_PAGES=("" "login" "panel" "admin" "dashboard" "inbounds" "outbounds" "settings")

for page in "${PANEL_PAGES[@]}"; do
    echo -n "🔍 测试页面: /$page ... "
    
    PAGE_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "${BASE_URL}/${page}" --connect-timeout 5)
    
    if [[ "$PAGE_RESPONSE" == "200" ]]; then
        echo "✅ 可访问 ($PAGE_RESPONSE)"
        
        # 获取页面内容查找API调用
        PAGE_CONTENT=$(curl -s "${BASE_URL}/${page}" --connect-timeout 5)
        PAGE_APIS=$(echo "$PAGE_CONTENT" | grep -oE '"/[^"]*[Aa][Pp][Ii][^"]*"' | head -3)
        if [[ -n "$PAGE_APIS" ]]; then
            echo "   📋 发现API: $PAGE_APIS"
        fi
    elif [[ "$PAGE_RESPONSE" == "302" ]] || [[ "$PAGE_RESPONSE" == "301" ]]; then
        echo "重定向 ($PAGE_RESPONSE)"
    else
        echo "不可访问 ($PAGE_RESPONSE)"
    fi
done

echo ""
echo "🧪 5. 尝试暴力破解登录..."

echo "🔍 测试常见的用户名密码组合..."

# 常见的默认凭据
DEFAULT_CREDENTIALS=(
    "admin:admin"
    "admin:password"
    "admin:123456"
    "root:root"
    "root:admin"
    "admin:admin123"
    "x-ui:x-ui"
    "admin:"
    ":admin"
)

for cred in "${DEFAULT_CREDENTIALS[@]}"; do
    IFS=':' read -r test_user test_pass <<< "$cred"
    echo -n "🔐 测试: $test_user / $test_pass ... "
    
    TEST_LOGIN='{"username":"'${test_user}'","password":"'${test_pass}'"}'
    TEST_RESPONSE=$(curl -s -X POST "${BASE_URL}/login" \
        -H "Content-Type: application/json" \
        -d "$TEST_LOGIN" \
        --connect-timeout 5)
    
    if echo "$TEST_RESPONSE" | grep -q '"success":true'; then
        echo "✅ 成功！"
        echo "🎉 找到有效凭据: $test_user / $test_pass"
        WORKING_CREDENTIALS="$TEST_LOGIN"
        break
    else
        echo "失败"
    fi
done

echo ""
echo "🧪 6. 分析x-ui命令行工具..."

echo "🔍 检查x-ui命令支持的功能..."
# 注意：这部分在实际环境中用户需要手动运行
echo "💡 建议手动运行以下命令来重置或查看设置："
echo "   x-ui setting"
echo "   x-ui show"
echo "   /usr/local/x-ui/x-ui setting"

echo ""
echo "🧪 7. 数据库直接查询..."

echo "🔍 直接查询数据库获取准确信息..."
if [[ -f "/etc/x-ui/x-ui.db" ]]; then
    echo "📋 数据库中的所有用户:"
    sqlite3 /etc/x-ui/x-ui.db "SELECT id, username, password FROM users;" 2>/dev/null || echo "查询失败"
    
    echo ""
    echo "📋 数据库中的所有设置:"
    sqlite3 /etc/x-ui/x-ui.db "SELECT key, value FROM settings;" 2>/dev/null | head -20 || echo "查询失败"
    
    echo ""
    echo "📋 检查secret的确切值:"
    SECRET_FROM_DB=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key='secret';" 2>/dev/null)
    echo "数据库中的secret: '$SECRET_FROM_DB'"
    
    # 用数据库中的真实secret测试
    if [[ -n "$SECRET_FROM_DB" ]] && [[ "$SECRET_FROM_DB" != "$SECRET" ]]; then
        echo ""
        echo "🔐 使用数据库中的真实secret测试登录..."
        REAL_SECRET_LOGIN='{"username":"'${USERNAME}'","password":"'${PASSWORD}'","secret":"'${SECRET_FROM_DB}'"}'
        REAL_SECRET_RESPONSE=$(curl -s -X POST "${BASE_URL}/login" \
            -H "Content-Type: application/json" \
            -d "$REAL_SECRET_LOGIN" \
            --connect-timeout 10)
        echo "📋 响应: $REAL_SECRET_RESPONSE"
        
        if echo "$REAL_SECRET_RESPONSE" | grep -q '"success":true'; then
            echo "🎉 登录成功！使用数据库中的真实secret"
            WORKING_CREDENTIALS="$REAL_SECRET_LOGIN"
        fi
    fi
fi

echo ""
echo "📊 8. 最终诊断报告..."

echo "🎯 重定向分析结果："
echo "✅ API端点存在但被重定向"
echo "🔍 需要跟随重定向找到真实端点"

echo ""
echo "🔐 认证分析结果："
if [[ -n "$WORKING_CREDENTIALS" ]]; then
    echo "✅ 找到有效的登录凭据"
    echo "📋 有效登录数据: $WORKING_CREDENTIALS"
else
    echo "❌ 未找到有效的登录凭据"
    echo "💡 可能需要手动重置用户名密码"
fi

echo ""
echo "🌐 访问建议："
echo "1. 使用浏览器直接访问: ${BASE_URL}/"
echo "2. 通过浏览器F12开发者工具查看实际的网络请求"
echo "3. 如果能访问，通过界面查看实际的API调用"
echo "4. 使用x-ui命令行工具重置凭据"

echo ""
echo "🔧 下一步操作："
echo "1. 手动运行: x-ui setting 查看设置"
echo "2. 手动运行: x-ui show 查看当前配置"
echo "3. 通过浏览器访问面板进行手动配置"
echo "4. 一旦能登录，通过F12查看实际的API端点"

echo ""
echo "=== 重定向追踪和认证破解工具完成 ==="
