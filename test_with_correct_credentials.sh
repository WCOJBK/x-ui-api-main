#!/bin/bash

echo "=== 3X-UI Enhanced API 正确凭据测试工具 ==="
echo "使用用户手动设置的正确凭据: root / 1999415123"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

# 使用用户刚刚设置的正确凭据！
USERNAME="root"
PASSWORD="1999415123"
SECRET="Nx0DwQXXO4yd1U5floQAjJJHQWstblr5"

echo ""
echo "🎯 使用用户刚刚通过x-ui脚本设置的正确凭据："
echo "👤 用户名: ${USERNAME}"
echo "🔑 密码: ${PASSWORD}"
echo "🔐 Secret: ${SECRET}"

echo ""
echo "🌐 服务器信息："
echo "🔗 面板地址: ${BASE_URL}/"

echo ""
echo "🧪 1. 检查secret状态..."

# 检查secret状态
SECRET_STATUS=$(curl -s -X POST "${BASE_URL}/getSecretStatus" \
    -H "Content-Type: application/json" \
    --connect-timeout 10)

echo "📋 Secret状态响应: $SECRET_STATUS"

# 解析secret状态
if echo "$SECRET_STATUS" | grep -q '"success":true'; then
    SECRET_ENABLED=$(echo "$SECRET_STATUS" | grep -oE '"obj":(true|false)' | cut -d: -f2)
    echo "✅ Secret状态: secretEnable = $SECRET_ENABLED"
else
    echo "❌ 无法获取secret状态，假设为false"
    SECRET_ENABLED="false"
fi

echo ""
echo "🧪 2. 使用正确凭据测试登录..."

# 基于secret状态选择登录方式
if [[ "$SECRET_ENABLED" == "true" ]]; then
    echo "🔐 Secret已启用，测试包含loginSecret的登录..."
    LOGIN_TESTS=(
        "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\",\"loginSecret\":\"${SECRET}\"}"
        "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\",\"secret\":\"${SECRET}\"}"
    )
else
    echo "🔐 Secret未启用，测试不含secret的登录..."
    LOGIN_TESTS=(
        "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}"
    )
fi

SUCCESSFUL_LOGIN=""
SESSION_COOKIES=""

for i in "${!LOGIN_TESTS[@]}"; do
    LOGIN_DATA="${LOGIN_TESTS[$i]}"
    echo ""
    echo "🔐 测试登录方式 $((i+1))..."
    echo "📋 请求数据: $LOGIN_DATA"
    
    # 保存cookies
    COOKIE_JAR="/tmp/x-ui-cookies-$$.txt"
    
    LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/login" \
        -H "Content-Type: application/json" \
        -d "$LOGIN_DATA" \
        -c "$COOKIE_JAR" \
        --connect-timeout 10)
    
    echo "📋 响应: $LOGIN_RESPONSE"
    
    if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
        echo "🎉 登录成功！"
        SUCCESSFUL_LOGIN="$LOGIN_DATA"
        SESSION_COOKIES="-b $COOKIE_JAR"
        break
    elif echo "$LOGIN_RESPONSE" | grep -q '"success":false'; then
        ERROR_MSG=$(echo "$LOGIN_RESPONSE" | grep -o '"msg":"[^"]*"' | cut -d'"' -f4)
        echo "❌ 登录失败: $ERROR_MSG"
    else
        echo "❓ 未知响应格式"
    fi
done

echo ""
echo "🧪 3. 验证数据库状态..."

echo "📋 检查数据库中的实际用户信息:"
if command -v sqlite3 >/dev/null 2>&1; then
    echo "当前数据库用户:"
    sqlite3 /etc/x-ui/x-ui.db "SELECT id, username, password FROM users;" 2>/dev/null || echo "数据库查询失败"
    
    echo ""
    echo "当前数据库设置:"
    sqlite3 /etc/x-ui/x-ui.db "SELECT key, value FROM settings WHERE key IN ('secret', 'sessionMaxAge', 'tgBotEnable');" 2>/dev/null || echo "设置查询失败"
else
    echo "⚠️  sqlite3未安装，无法直接查询数据库"
fi

echo ""
echo "🧪 4. 如果登录成功，测试Enhanced API..."

if [[ -n "$SUCCESSFUL_LOGIN" ]]; then
    echo "✅ 登录成功！凭据: ${USERNAME} / ${PASSWORD}"
    echo "🔐 使用的登录数据: $SUCCESSFUL_LOGIN"
    
    echo ""
    echo "🎯 测试Enhanced API端点..."
    
    # API端点列表
    API_ENDPOINTS=(
        "/panel/api/server/status::获取服务器状态"
        "/panel/api/inbounds/list::获取入站列表"
        "/panel/api/outbound/list::Enhanced - 获取出站列表"
        "/panel/api/routing/list::Enhanced - 获取路由列表" 
        "/panel/api/subscription/list::Enhanced - 获取订阅列表"
        "/api/server/status::备用API - 服务器状态"
        "/api/inbounds/list::备用API - 入站列表"
    )
    
    WORKING_APIS=0
    TOTAL_APIS=${#API_ENDPOINTS[@]}
    
    for endpoint_info in "${API_ENDPOINTS[@]}"; do
        endpoint=$(echo "$endpoint_info" | cut -d':' -f1)
        description=$(echo "$endpoint_info" | cut -d':' -f3)
        
        echo ""
        echo "🔍 测试: $description"
        echo "🔗 端点: $endpoint"
        
        # 使用session cookies进行API调用
        API_RESPONSE=$(curl -s -X GET "${BASE_URL}${endpoint}" \
            $SESSION_COOKIES \
            -H "Content-Type: application/json" \
            --connect-timeout 10)
        
        # 截取响应避免过长
        SHORT_RESPONSE=$(echo "$API_RESPONSE" | head -c 300)
        echo "📋 响应预览: ${SHORT_RESPONSE}..."
        
        if echo "$API_RESPONSE" | grep -q '"success":true'; then
            echo "✅ API正常工作"
            ((WORKING_APIS++))
        elif echo "$API_RESPONSE" | grep -q '"success":false'; then
            echo "⚠️  API可访问但返回错误"
        elif echo "$API_RESPONSE" | grep -q "404 page not found"; then
            echo "❌ API端点不存在"
        elif echo "$API_RESPONSE" | grep -q -E '(<!DOCTYPE|<html|<head)'; then
            echo "🔄 返回HTML页面（可能需要重新登录）"
        else
            echo "❓ 未知响应类型"
        fi
    done
    
    echo ""
    echo "📊 API测试总结:"
    echo "✅ 工作的API: $WORKING_APIS / $TOTAL_APIS"
    echo "📈 成功率: $(( WORKING_APIS * 100 / TOTAL_APIS ))%"
    
    # 清理cookie文件
    rm -f "$COOKIE_JAR" 2>/dev/null
    
else
    echo "❌ 登录仍然失败，需要进一步诊断"
    
    echo ""
    echo "🔧 额外诊断步骤..."
    
    # 检查服务状态
    echo "📋 检查x-ui服务状态:"
    systemctl status x-ui --no-pager -l || echo "无法获取服务状态"
    
    echo ""
    echo "📋 检查最近的服务日志:"
    journalctl -u x-ui -n 10 --no-pager || echo "无法获取日志"
    
    echo ""
    echo "🔍 手动验证步骤:"
    echo "1. 检查面板是否可以通过浏览器访问: ${BASE_URL}/"
    echo "2. 尝试在浏览器中使用凭据: ${USERNAME} / ${PASSWORD}"
    echo "3. 如果浏览器可以登录，检查浏览器F12网络选项卡的实际请求"
    echo "4. 可能需要重新运行 x-ui 管理脚本重置凭据"
fi

echo ""
echo "🧪 5. 测试浏览器访问..."

echo "🌐 测试面板主页访问:"
HOME_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" "${BASE_URL}/" --connect-timeout 10)
HTTP_CODE=$(echo "$HOME_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
echo "📋 主页HTTP状态码: $HTTP_CODE"

if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✅ 面板主页正常访问"
    echo "💡 建议通过浏览器访问: ${BASE_URL}/"
    echo "🔑 使用凭据: ${USERNAME} / ${PASSWORD}"
else
    echo "❌ 面板主页访问异常"
fi

echo ""
echo "📊 最终诊断报告..."

if [[ -n "$SUCCESSFUL_LOGIN" ]]; then
    echo ""
    echo "🎉🎉🎉 成功！Enhanced API系统正常运行！🎉🎉🎉"
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║  🚀 3X-UI Enhanced API 登录成功！             ║"
    echo "║  📱 面板: ${BASE_URL}/                     ║"
    echo "║  🔑 凭据: ${USERNAME} / ${PASSWORD}           ║"
    echo "║  ⚡ 状态: 登录验证成功                         ║"
    echo "║  🎯 API: $WORKING_APIS/$TOTAL_APIS 个端点可用                        ║"
    echo "╚════════════════════════════════════════════════╝"
    
    echo ""
    echo "🎊 下一步操作："
    echo "✅ 通过浏览器访问面板进行配置"
    echo "✅ 添加inbound和outbound配置"
    echo "✅ 使用Enhanced API进行高级管理"
    echo "✅ 测试代理连接功能"
    
else
    echo "❌ 登录问题仍需解决"
    echo ""
    echo "🔧 建议的解决步骤："
    echo "1. 确认通过x-ui脚本重置的凭据确实是: ${USERNAME} / ${PASSWORD}"
    echo "2. 通过浏览器直接访问: ${BASE_URL}/"
    echo "3. 如果浏览器能登录，问题可能在API调用格式"
    echo "4. 如果浏览器也不能登录，重新运行 x-ui 脚本重置凭据"
    echo "5. 检查防火墙和端口设置"
fi

echo ""
echo "=== 正确凭据测试工具完成 ==="
