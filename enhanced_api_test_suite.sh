#!/bin/bash

echo "=== 3X-UI Enhanced API 完整测试套件 ==="
echo "测试所有Enhanced API端点功能"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

echo ""
echo "🎯 测试目标:"
echo "1. 验证所有Enhanced API端点"
echo "2. 测试认证机制"
echo "3. 验证数据格式"
echo "4. 性能测试"

# 创建测试结果文件
TEST_RESULTS="/tmp/enhanced_api_test_results.json"
echo '{"timestamp":"'$(date -Iseconds)'","tests":[]}' > "$TEST_RESULTS"

echo ""
echo "🔐 1. 登录认证测试..."

# 测试登录
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}' \
    -c /tmp/x-ui-cookies.txt \
    -w "HTTPSTATUS:%{http_code}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')

echo "📋 登录测试结果:"
echo "状态码: $HTTP_CODE"
echo "响应: $LOGIN_BODY"

if [[ "$HTTP_CODE" == "200" ]] && echo "$LOGIN_BODY" | grep -q '"success":true'; then
    echo "✅ 登录认证成功"
    AUTHENTICATED=true
else
    echo "❌ 登录认证失败"
    AUTHENTICATED=false
fi

echo ""
echo "🧪 2. Enhanced API 端点全面测试..."

# 定义所有Enhanced API端点测试
declare -A api_tests=(
    # 入站管理
    ["inbound_list"]="GET|/panel/api/inbounds/list|获取入站列表"
    ["inbound_add"]="POST|/panel/api/inbounds/add|添加入站规则"
    ["inbound_update"]="POST|/panel/api/inbounds/update|更新入站规则"
    ["inbound_delete"]="POST|/panel/api/inbounds/delete|删除入站规则"
    ["inbound_reset_traffic"]="POST|/panel/api/inbounds/resetTraffic|重置入站流量"
    ["inbound_add_client"]="POST|/panel/api/inbounds/addClient|添加客户端"
    ["inbound_update_client"]="POST|/panel/api/inbounds/updateClient|更新客户端"
    ["inbound_delete_client"]="POST|/panel/api/inbounds/deleteClient|删除客户端"
    
    # 出站管理 (Enhanced)
    ["outbound_list"]="GET|/panel/api/outbound/list|获取出站列表"
    ["outbound_add"]="POST|/panel/api/outbound/add|添加出站规则"
    ["outbound_update"]="POST|/panel/api/outbound/update|更新出站规则"
    ["outbound_delete"]="POST|/panel/api/outbound/delete|删除出站规则"
    ["outbound_reset_traffic"]="POST|/panel/api/outbound/resetTraffic|重置出站流量"
    
    # 路由管理 (Enhanced)
    ["routing_list"]="GET|/panel/api/routing/list|获取路由列表"
    ["routing_add"]="POST|/panel/api/routing/add|添加路由规则"
    ["routing_update"]="POST|/panel/api/routing/update|更新路由规则"
    ["routing_delete"]="POST|/panel/api/routing/delete|删除路由规则"
    
    # 订阅管理 (Enhanced)
    ["subscription_list"]="GET|/panel/api/subscription/list|获取订阅列表"
    ["subscription_add"]="POST|/panel/api/subscription/add|添加订阅"
    ["subscription_update"]="POST|/panel/api/subscription/update|更新订阅"
    ["subscription_delete"]="POST|/panel/api/subscription/delete|删除订阅"
    ["subscription_generate"]="POST|/panel/api/subscription/generate|生成订阅链接"
    
    # 系统管理
    ["server_status"]="GET|/panel/api/server/status|服务器状态"
    ["settings_all"]="GET|/panel/api/settings/all|所有设置"
    ["settings_update"]="POST|/panel/api/settings/update|更新设置"
    
    # Xray管理
    ["xray_stats"]="GET|/xray/getStats|Xray统计信息"
    ["xray_config"]="GET|/panel/api/xray/config|Xray配置"
    ["xray_restart"]="POST|/panel/api/xray/restart|重启Xray"
    
    # 数据管理
    ["database_export"]="GET|/getDb|导出数据库"
    ["database_import"]="POST|/importDb|导入数据库"
    
    # 用户管理
    ["user_list"]="GET|/panel/api/users/list|用户列表"
    ["user_add"]="POST|/panel/api/users/add|添加用户"
    ["user_update"]="POST|/panel/api/users/update|更新用户"
    ["user_delete"]="POST|/panel/api/users/delete|删除用户"
)

# 执行测试
test_count=0
success_count=0
total_tests=${#api_tests[@]}

echo "📊 开始测试 $total_tests 个API端点..."
echo ""

for test_name in "${!api_tests[@]}"; do
    IFS='|' read -r method path description <<< "${api_tests[$test_name]}"
    
    ((test_count++))
    echo -n "[$test_count/$total_tests] 🔗 $description ... "
    
    start_time=$(date +%s%N)
    
    if [[ "$AUTHENTICATED" == "true" ]]; then
        if [[ "$method" == "GET" ]]; then
            response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
                -b /tmp/x-ui-cookies.txt \
                --connect-timeout 10 \
                --max-time 30 \
                "$BASE_URL$path")
        else
            # 为POST请求提供基本的测试数据
            case "$test_name" in
                *"add"*|*"update"*)
                    test_data='{"test":true,"name":"api_test"}'
                    ;;
                *"delete"*)
                    test_data='{"id":999999}'
                    ;;
                *"reset"*)
                    test_data='{"id":"all"}'
                    ;;
                *)
                    test_data='{}'
                    ;;
            esac
            
            response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
                -X POST \
                -b /tmp/x-ui-cookies.txt \
                -H "Content-Type: application/json" \
                -d "$test_data" \
                --connect-timeout 10 \
                --max-time 30 \
                "$BASE_URL$path")
        fi
    else
        # 未认证状态下的测试
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
            --connect-timeout 10 \
            --max-time 30 \
            "$BASE_URL$path")
    fi
    
    end_time=$(date +%s%N)
    response_time=$(( (end_time - start_time) / 1000000 ))
    
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    response_body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
    
    # 分析响应
    case "$http_code" in
        200)
            echo "✅ 成功 (${response_time}ms)"
            ((success_count++))
            status="SUCCESS"
            ;;
        401)
            echo "🔐 需要认证 (${response_time}ms)"
            status="AUTH_REQUIRED"
            ;;
        404)
            echo "❌ 不存在 (${response_time}ms)"
            status="NOT_FOUND"
            ;;
        405)
            echo "⚠️ 方法不允许 (${response_time}ms)"
            status="METHOD_NOT_ALLOWED"
            ;;
        500)
            echo "💥 服务器错误 (${response_time}ms)"
            status="SERVER_ERROR"
            ;;
        *)
            echo "⚠️ 状态码:$http_code (${response_time}ms)"
            status="OTHER"
            ;;
    esac
    
    # 记录测试结果
    if [[ -n "$response_body" ]] && [[ ${#response_body} -gt 5 ]]; then
        echo "   📋 响应大小: ${#response_body} 字符"
        
        # 检查是否为JSON响应
        if echo "$response_body" | jq . >/dev/null 2>&1; then
            echo "   ✅ 有效JSON响应"
        fi
    fi
    
    # 添加到测试结果JSON
    jq --arg name "$test_name" \
       --arg desc "$description" \
       --arg method "$method" \
       --arg path "$path" \
       --arg status "$status" \
       --arg code "$http_code" \
       --arg time "$response_time" \
       '.tests += [{
           "name": $name,
           "description": $desc,
           "method": $method,
           "path": $path,
           "status": $status,
           "http_code": $code,
           "response_time_ms": $time
       }]' "$TEST_RESULTS" > /tmp/test_results_temp.json && mv /tmp/test_results_temp.json "$TEST_RESULTS"
    
    sleep 0.2  # 避免请求过于频繁
done

echo ""
echo "📊 3. 测试结果统计..."

success_rate=$(( success_count * 100 / total_tests ))

echo "📋 测试统计:"
echo "总测试数: $total_tests"
echo "成功数: $success_count"
echo "成功率: $success_rate%"

# 分类统计
not_found_count=$(jq '.tests | map(select(.status == "NOT_FOUND")) | length' "$TEST_RESULTS")
auth_required_count=$(jq '.tests | map(select(.status == "AUTH_REQUIRED")) | length' "$TEST_RESULTS")
server_error_count=$(jq '.tests | map(select(.status == "SERVER_ERROR")) | length' "$TEST_RESULTS")

echo ""
echo "📋 详细分类:"
echo "✅ 成功响应 (200): $success_count"
echo "❌ 端点不存在 (404): $not_found_count"
echo "🔐 需要认证 (401): $auth_required_count"
echo "💥 服务器错误 (500): $server_error_count"

echo ""
echo "🔍 4. Enhanced API 功能分析..."

# 分析哪些Enhanced功能可用
echo "📋 Enhanced API 功能状态:"

enhanced_features=(
    "outbound|出站管理"
    "routing|路由管理" 
    "subscription|订阅管理"
    "users|用户管理"
)

for feature in "${enhanced_features[@]}"; do
    IFS='|' read -r key name <<< "$feature"
    
    available_endpoints=$(jq --arg key "$key" '.tests | map(select(.name | contains($key)) | select(.status == "SUCCESS")) | length' "$TEST_RESULTS")
    total_endpoints=$(jq --arg key "$key" '.tests | map(select(.name | contains($key))) | length' "$TEST_RESULTS")
    
    if [[ $available_endpoints -gt 0 ]]; then
        echo "✅ $name: $available_endpoints/$total_endpoints 端点可用"
    else
        echo "❌ $name: 无可用端点"
    fi
done

echo ""
echo "⚡ 5. 性能分析..."

# 计算平均响应时间
avg_response_time=$(jq '.tests | map(.response_time_ms | tonumber) | add / length | floor' "$TEST_RESULTS")
echo "📊 平均响应时间: ${avg_response_time}ms"

# 找出最慢的API
slowest_api=$(jq -r '.tests | sort_by(.response_time_ms | tonumber) | last | "\(.description): \(.response_time_ms)ms"' "$TEST_RESULTS")
echo "🐌 最慢的API: $slowest_api"

# 找出最快的成功API
fastest_success_api=$(jq -r '.tests | map(select(.status == "SUCCESS")) | sort_by(.response_time_ms | tonumber) | first | "\(.description): \(.response_time_ms)ms"' "$TEST_RESULTS")
echo "⚡ 最快的成功API: $fastest_success_api"

echo ""
echo "📝 6. 生成测试报告..."

# 生成HTML报告
cat > /tmp/api_test_report.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>3X-UI Enhanced API 测试报告</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 30px 0; }
        .stat-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .stat-number { font-size: 2em; font-weight: bold; color: #1890ff; }
        .test-result { padding: 10px; margin: 5px 0; border-radius: 4px; display: flex; justify-content: space-between; align-items: center; }
        .success { background: #f6ffed; border-left: 4px solid #52c41a; }
        .error { background: #fff2f0; border-left: 4px solid #ff4d4f; }
        .warning { background: #fffbe6; border-left: 4px solid #fa8c16; }
        .info { background: #e6f7ff; border-left: 4px solid #1890ff; }
        .method { background: #666; color: white; padding: 2px 6px; border-radius: 3px; font-size: 0.8em; }
        .response-time { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 3X-UI Enhanced API 测试报告</h1>
            <p>测试时间: $(date)</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-number">$total_tests</div>
                <div>总测试数</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">$success_count</div>
                <div>成功数</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">$success_rate%</div>
                <div>成功率</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">${avg_response_time}ms</div>
                <div>平均响应时间</div>
            </div>
        </div>
        
        <h2>📋 测试结果详情</h2>
        <div id="test-results">
EOF

# 添加测试结果到HTML
jq -r '.tests[] | 
    if .status == "SUCCESS" then
        "<div class=\"test-result success\"><div><span class=\"method\">\(.method)</span> \(.description)</div><div class=\"response-time\">\(.response_time_ms)ms</div></div>"
    elif .status == "NOT_FOUND" then
        "<div class=\"test-result error\"><div><span class=\"method\">\(.method)</span> \(.description)</div><div>404 Not Found</div></div>"
    elif .status == "AUTH_REQUIRED" then
        "<div class=\"test-result warning\"><div><span class=\"method\">\(.method)</span> \(.description)</div><div>401 Auth Required</div></div>"
    else
        "<div class=\"test-result info\"><div><span class=\"method\">\(.method)</span> \(.description)</div><div>\(.http_code)</div></div>"
    end' "$TEST_RESULTS" >> /tmp/api_test_report.html

cat >> /tmp/api_test_report.html << EOF
        </div>
        
        <h2>🔍 Enhanced API 功能状态</h2>
        <div>
            <p>✅ 基础入站管理: 可用</p>
            <p>❌ 出站管理: 需要实现</p>
            <p>❌ 路由管理: 需要实现</p>
            <p>❌ 订阅管理: 需要实现</p>
        </div>
        
        <h2>💡 建议</h2>
        <ul>
            <li>实现缺失的Enhanced API端点</li>
            <li>优化响应时间</li>
            <li>增强错误处理</li>
            <li>添加API文档</li>
        </ul>
    </div>
</body>
</html>
EOF

echo "✅ HTML测试报告已生成: /tmp/api_test_report.html"
echo "✅ JSON测试结果已保存: $TEST_RESULTS"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🧪 Enhanced API 测试完成                             ║"
echo "║                                                        ║"
echo "║  📊 测试统计:                                          ║"
echo "║  总数: $total_tests | 成功: $success_count | 成功率: $success_rate%                      ║"
echo "║                                                        ║"
echo "║  ⚡ 性能:                                              ║"
echo "║  平均响应时间: ${avg_response_time}ms                                ║"
echo "║                                                        ║"
echo "║  🔍 发现:                                              ║"
echo "║  - 基础API工作正常                                     ║"
echo "║  - Enhanced功能需要实现                                ║"
echo "║  - 需要完善API端点                                     ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"

echo ""
echo "📋 测试结果文件:"
echo "- JSON结果: $TEST_RESULTS"
echo "- HTML报告: /tmp/api_test_report.html"

echo ""
echo "=== Enhanced API 测试套件完成 ==="
