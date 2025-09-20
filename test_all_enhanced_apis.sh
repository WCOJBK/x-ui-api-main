#!/bin/bash

echo "=== 3X-UI Enhanced API 全面测试工具 ==="
echo "测试所有API端点和前端功能"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

echo ""
echo "🎯 测试目标："
echo "1. 验证所有Enhanced API端点"
echo "2. 测试前端路由功能"
echo "3. 检查静态资源加载"
echo "4. 性能测试和错误诊断"

echo ""
echo "🔍 1. 服务状态检查..."

# 检查服务状态
if systemctl is-active x-ui >/dev/null 2>&1; then
    echo "✅ x-ui 服务运行正常"
else
    echo "❌ x-ui 服务未运行"
    systemctl start x-ui
    sleep 3
fi

# 检查端口监听
if netstat -tlnp 2>/dev/null | grep -q ":2053 " || ss -tlnp 2>/dev/null | grep -q ":2053 "; then
    echo "✅ 端口2053 正常监听"
else
    echo "❌ 端口2053 未监听"
fi

echo ""
echo "🌐 2. 前端路径测试..."

declare -a paths=(
    "/|根路径"
    "/panel/|Panel路径"
    "/panel|Panel无斜杠"
    "/login|登录页面"
    "/assets/|静态资源目录"
    "/assets/vue/vue.min.js|Vue.js"
    "/assets/ant-design-vue/antd.min.css|Ant Design CSS"
    "/assets/axios/axios.min.js|Axios"
)

echo "📋 测试前端路径："
for path_info in "${paths[@]}"; do
    IFS='|' read -r path name <<< "$path_info"

    if [[ "$path" == "/assets/"* ]]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -I "$BASE_URL$path" --connect-timeout 5)
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL$path" --connect-timeout 5)
    fi

    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)

    if [[ "$http_code" == "200" ]]; then
        echo "✅ $name - $http_code"
    elif [[ "$http_code" == "301" ]] || [[ "$http_code" == "302" ]]; then
        echo "🔄 $name - $http_code (重定向)"
    elif [[ "$http_code" == "404" ]]; then
        echo "❌ $name - $http_code (不存在)"
    else
        echo "⚠️ $name - $http_code"
    fi
done

echo ""
echo "🔐 3. 登录认证测试..."

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
    echo "✅ 登录成功"
    AUTHENTICATED=true
else
    echo "❌ 登录失败"
    AUTHENTICATED=false
fi

echo ""
echo "🧪 4. Enhanced API 端点全面测试..."

# 定义所有API端点测试
declare -A api_tests=(
    # 基础入站管理
    ["inbound_list"]="GET|/panel/api/inbounds/list|获取入站列表"
    ["inbound_add"]="POST|/panel/api/inbounds/add|添加入站规则"
    ["inbound_update"]="POST|/panel/api/inbounds/update|更新入站规则"
    ["inbound_delete"]="POST|/panel/api/inbounds/delete|删除入站规则"
    ["inbound_reset_traffic"]="POST|/panel/api/inbounds/resetTraffic|重置入站流量"

    # Enhanced 出站管理
    ["outbound_list"]="GET|/panel/api/outbound/list|获取出站列表"
    ["outbound_add"]="POST|/panel/api/outbound/add|添加出站规则"
    ["outbound_update"]="POST|/panel/api/outbound/update|更新出站规则"
    ["outbound_delete"]="POST|/panel/api/outbound/delete|删除出站规则"
    ["outbound_reset_traffic"]="POST|/panel/api/outbound/resetTraffic|重置出站流量"

    # Enhanced 路由管理
    ["routing_list"]="GET|/panel/api/routing/list|获取路由列表"
    ["routing_add"]="POST|/panel/api/routing/add|添加路由规则"
    ["routing_update"]="POST|/panel/api/routing/update|更新路由规则"
    ["routing_delete"]="POST|/panel/api/routing/delete|删除路由规则"

    # Enhanced 订阅管理
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
)

# 执行测试
test_count=0
success_count=0
total_tests=${#api_tests[@]}

echo "📊 开始测试 $total_tests 个API端点..."
echo ""

# 创建测试结果文件
echo '{"timestamp":"'$(date -Iseconds)'","tests":[]}' > /tmp/enhanced_api_test_results.json

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
                    test_data='{"test":true,"name":"api_test_'${test_name}'","protocol":"vmess"}'
                    ;;
                *"delete"*)
                    test_data='{"id":999999}'
                    ;;
                *"reset"*)
                    test_data='{"id":"all"}'
                    ;;
                *"generate"*)
                    test_data='{"id":1}'
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

    # 添加到JSON结果
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
       }]' /tmp/enhanced_api_test_results.json > /tmp/test_results_temp.json && mv /tmp/test_results_temp.json /tmp/enhanced_api_test_results.json

    sleep 0.2
done

echo ""
echo "📊 5. 测试结果统计..."

success_rate=$(( success_count * 100 / total_tests ))

echo "📋 测试统计:"
echo "总测试数: $total_tests"
echo "成功数: $success_count"
echo "成功率: $success_rate%"

# 分类统计
not_found_count=$(jq '.tests | map(select(.status == "NOT_FOUND")) | length' /tmp/enhanced_api_test_results.json)
auth_required_count=$(jq '.tests | map(select(.status == "AUTH_REQUIRED")) | length' /tmp/enhanced_api_test_results.json)
server_error_count=$(jq '.tests | map(select(.status == "SERVER_ERROR")) | length' /tmp/enhanced_api_test_results.json)

echo ""
echo "📋 详细分类:"
echo "✅ 成功响应 (200): $success_count"
echo "❌ 端点不存在 (404): $not_found_count"
echo "🔐 需要认证 (401): $auth_required_count"
echo "💥 服务器错误 (500): $server_error_count"

echo ""
echo "🔍 6. Enhanced 功能分析..."

# 分析哪些Enhanced功能可用
echo "📋 Enhanced API 功能状态:"

enhanced_features=(
    "outbound|出站管理"
    "routing|路由管理"
    "subscription|订阅管理"
)

for feature in "${enhanced_features[@]}"; do
    IFS='|' read -r key name <<< "$feature"

    available_endpoints=$(jq --arg key "$key" '.tests | map(select(.name | contains($key)) | select(.status == "SUCCESS")) | length' /tmp/enhanced_api_test_results.json)
    total_endpoints=$(jq --arg key "$key" '.tests | map(select(.name | contains($key))) | length' /tmp/enhanced_api_test_results.json)

    if [[ $available_endpoints -gt 0 ]]; then
        echo "✅ $name: $available_endpoints/$total_endpoints 端点可用"
    else
        echo "❌ $name: 无可用端点"
    fi
done

echo ""
echo "⚡ 7. 性能分析..."

# 计算平均响应时间
avg_response_time=$(jq '.tests | map(.response_time_ms | tonumber) | add / length | floor' /tmp/enhanced_api_test_results.json)
echo "📊 平均响应时间: ${avg_response_time}ms"

# 找出最慢的API
slowest_api=$(jq -r '.tests | sort_by(.response_time_ms | tonumber) | last | "\(.description): \(.response_time_ms)ms"' /tmp/enhanced_api_test_results.json)
echo "🐌 最慢的API: $slowest_api"

# 找出最快的成功API
fastest_success_api=$(jq -r '.tests | map(select(.status == "SUCCESS")) | sort_by(.response_time_ms | tonumber) | first | "\(.description): \(.response_time_ms)ms"' /tmp/enhanced_api_test_results.json)
echo "⚡ 最快的成功API: $fastest_success_api"

echo ""
echo "📊 8. 生成修复建议..."

if [[ $success_rate -lt 50 ]]; then
    echo "❌ 发现严重问题，需要重新编译"
    echo "🔧 建议运行重新编译工具："
    echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/recompile_complete_enhanced_api.sh)"
elif [[ $not_found_count -gt 0 ]]; then
    echo "⚠️ 发现API端点缺失"
    echo "🔧 建议检查编译配置或重新编译"
else
    echo "✅ API功能基本正常"
fi

echo ""
echo "🎯 9. 创建测试报告..."

# 生成HTML报告
cat > /tmp/comprehensive_test_report.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>3X-UI Enhanced API 全面测试报告</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .stats { display: grid; grid-template-columns: repeat(5, 1fr); gap: 20px; margin: 30px 0; }
        .stat-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .stat-number { font-size: 2em; font-weight: bold; color: #1890ff; }
        .test-result { padding: 10px; margin: 5px 0; border-radius: 4px; display: flex; justify-content: space-between; align-items: center; }
        .success { background: #f6ffed; border-left: 4px solid #52c41a; }
        .error { background: #fff2f0; border-left: 4px solid #ff4d4f; }
        .warning { background: #fffbe6; border-left: 4px solid #fa8c16; }
        .info { background: #e6f7ff; border-left: 4px solid #1890ff; }
        .method { background: #666; color: white; padding: 2px 6px; border-radius: 3px; font-size: 0.8em; }
        .response-time { color: #666; font-size: 0.9em; }
        .section { margin: 40px 0; }
        .section h2 { border-bottom: 2px solid #1890ff; padding-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 3X-UI Enhanced API 全面测试报告</h1>
            <p>测试时间: $(date)</p>
            <p>服务器: $BASE_URL</p>
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
            <div class="stat-card">
                <div class="stat-number">$not_found_count</div>
                <div>缺失端点</div>
            </div>
        </div>

        <div class="section">
            <h2>📋 API测试结果详情</h2>
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
    end' /tmp/enhanced_api_test_results.json >> /tmp/comprehensive_test_report.html

cat >> /tmp/comprehensive_test_report.html << EOF
            </div>
        </div>

        <div class="section">
            <h2>🔍 前端路径测试结果</h2>
EOF

# 添加前端路径测试结果
for path_info in "${paths[@]}"; do
    IFS='|' read -r path name <<< "$path_info"

    if [[ "$path" == "/assets/"* ]]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -I "$BASE_URL$path" --connect-timeout 5)
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL$path" --connect-timeout 5)
    fi

    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)

    if [[ "$http_code" == "200" ]]; then
        echo "<div class=\"test-result success\"><div>$name ($path)</div><div>$http_code OK</div></div>" >> /tmp/comprehensive_test_report.html
    elif [[ "$http_code" == "301" ]] || [[ "$http_code" == "302" ]]; then
        echo "<div class=\"test-result warning\"><div>$name ($path)</div><div>$http_code Redirect</div></div>" >> /tmp/comprehensive_test_report.html
    elif [[ "$http_code" == "404" ]]; then
        echo "<div class=\"test-result error\"><div>$name ($path)</div><div>$http_code Not Found</div></div>" >> /tmp/comprehensive_test_report.html
    else
        echo "<div class=\"test-result info\"><div>$name ($path)</div><div>$http_code</div></div>" >> /tmp/comprehensive_test_report.html
    fi
done

cat >> /tmp/comprehensive_test_report.html << EOF
        </div>

        <div class="section">
            <h2>💡 问题分析与建议</h2>
            <div class="test-result info">
                <div>测试覆盖了 $total_tests 个API端点，成功率 $success_rate%</div>
                <div>发现 $not_found_count 个缺失端点，$auth_required_count 个需要认证</div>
            </div>
EOF

if [[ $success_rate -lt 50 ]]; then
    cat >> /tmp/comprehensive_test_report.html << EOF
            <div class="test-result error">
                <div>❌ 发现严重问题：API成功率过低</div>
                <div>建议重新编译包含完整Enhanced API功能</div>
            </div>
EOF
elif [[ $not_found_count -gt 0 ]]; then
    cat >> /tmp/comprehensive_test_report.html << EOF
            <div class="test-result warning">
                <div>⚠️ 发现API端点缺失：$not_found_count 个端点不存在</div>
                <div>建议检查编译配置或重新编译</div>
            </div>
EOF
else
    cat >> /tmp/comprehensive_test_report.html << EOF
            <div class="test-result success">
                <div>✅ API功能基本正常</div>
                <div>所有核心功能都正常工作</div>
            </div>
EOF
fi

cat >> /tmp/comprehensive_test_report.html << EOF
        </div>

        <div class="section">
            <h2>🚀 下一步行动</h2>
            <div class="test-result info">
                <div>1. 检查测试报告中的错误端点</div>
                <div>2. 根据建议进行修复</div>
                <div>3. 重新运行测试验证修复效果</div>
            </div>
        </div>
    </div>
</body>
</html>
EOF

echo "✅ 综合测试报告已生成: /tmp/comprehensive_test_report.html"
echo "✅ JSON测试结果: /tmp/enhanced_api_test_results.json"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🧪 Enhanced API 全面测试完成                         ║"
echo "║                                                        ║"
echo "║  📊 测试统计:                                          ║"
echo "║  总数: $total_tests | 成功: $success_count | 成功率: $success_rate%                      ║"
echo "║                                                        ║"
echo "║  ⚡ 性能:                                              ║"
echo "║  平均响应时间: ${avg_response_time}ms                                ║"
echo "║                                                        ║"
echo "║  🔍 发现问题:                                          ║"
echo "║  - 前端路径测试完成                                   ║"
echo "║  - API端点测试完成                                     ║"
echo "║  - 生成了详细的测试报告                               ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"

echo ""
echo "📋 测试报告文件:"
echo "- HTML报告: /tmp/comprehensive_test_report.html"
echo "- JSON结果: /tmp/enhanced_api_test_results.json"

echo ""
echo "🌐 查看测试报告:"
echo "firefox /tmp/comprehensive_test_report.html"

echo ""
echo "🔧 如果发现API端点缺失，请运行重新编译工具："
echo "bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/recompile_complete_enhanced_api.sh)"

echo ""
echo "=== Enhanced API 全面测试完成 ==="
