#!/bin/bash

echo "=== 3X-UI Enhanced API 完整功能测试脚本 ==="
echo "测试所有Enhanced API端点和功能"

# 服务器信息
SERVER_IP="103.189.140.156"
BASE_URL="http://${SERVER_IP}:2053"
PANEL_API_BASE="$BASE_URL/panel/api"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 统计变量
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试结果记录
declare -a TEST_RESULTS=()

# 函数：打印标题
print_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} ${1}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}\n"
}

# 函数：打印子标题
print_subheader() {
    echo -e "\n${CYAN}🔍 ${1}${NC}"
    echo "────────────────────────────────────────────────────────"
}

# 函数：测试API端点
test_api() {
    local method="$1"
    local endpoint="$2"
    local description="$3"
    local data="$4"
    local expected_status="$5"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "\n${BLUE}🧪 测试: ${description}${NC}"
    echo -e "   ${YELLOW}方法:${NC} $method"
    echo -e "   ${YELLOW}端点:${NC} $endpoint"
    
    # 构建curl命令
    if [[ "$method" == "POST" && -n "$data" ]]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$PANEL_API_BASE$endpoint" 2>/dev/null)
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" \
            "$PANEL_API_BASE$endpoint" 2>/dev/null)
    fi
    
    # 解析响应
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
    
    # 检查状态码
    if [[ "$http_code" == "$expected_status" ]]; then
        echo -e "   ${GREEN}✅ 状态码: $http_code${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✅ $description - HTTP $http_code")
    else
        echo -e "   ${RED}❌ 状态码: $http_code (期望: $expected_status)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("❌ $description - HTTP $http_code (期望: $expected_status)")
    fi
    
    # 显示响应体（截取前200字符）
    if [[ ${#body} -gt 0 ]]; then
        echo -e "   ${YELLOW}响应:${NC} ${body:0:200}$([ ${#body} -gt 200 ] && echo "...")"
    fi
    
    # 解析JSON响应（如果是JSON）
    if [[ "$body" =~ ^\{.*\}$ ]] && command -v jq >/dev/null 2>&1; then
        success=$(echo "$body" | jq -r '.success // empty' 2>/dev/null)
        message=$(echo "$body" | jq -r '.message // empty' 2>/dev/null)
        data_field=$(echo "$body" | jq -r '.data // empty' 2>/dev/null)
        
        if [[ "$success" == "true" ]]; then
            echo -e "   ${GREEN}🎯 业务状态: 成功${NC}"
        elif [[ "$success" == "false" ]]; then
            echo -e "   ${RED}⚠️  业务状态: 失败${NC}"
        fi
        
        if [[ -n "$message" && "$message" != "null" ]]; then
            echo -e "   ${CYAN}💬 消息: $message${NC}"
        fi
        
        if [[ -n "$data_field" && "$data_field" != "null" ]]; then
            echo -e "   ${PURPLE}📊 数据字段存在${NC}"
        fi
    fi
}

# 函数：测试登录功能
test_login() {
    print_subheader "登录功能测试"
    
    # 测试正确登录
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${BLUE}🧪 测试: 正确的用户名密码登录${NC}"
    
    login_data='{"username":"admin","password":"admin"}'
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$login_data" \
        "$BASE_URL/login" 2>/dev/null)
    
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
    
    if [[ "$http_code" == "200" ]]; then
        echo -e "   ${GREEN}✅ 登录请求: HTTP $http_code${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✅ 登录功能 - HTTP $http_code")
        
        # 检查响应内容
        if [[ "$body" =~ "success.*true" ]]; then
            echo -e "   ${GREEN}🎯 登录成功${NC}"
        else
            echo -e "   ${YELLOW}⚠️  登录响应: $body${NC}"
        fi
    else
        echo -e "   ${RED}❌ 登录请求: HTTP $http_code${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("❌ 登录功能 - HTTP $http_code")
    fi
    
    # 测试错误登录
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${BLUE}🧪 测试: 错误的用户名密码${NC}"
    
    wrong_data='{"username":"wrong","password":"wrong"}'
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$wrong_data" \
        "$BASE_URL/login" 2>/dev/null)
    
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
    
    if [[ "$http_code" == "200" && "$body" =~ "success.*false" ]]; then
        echo -e "   ${GREEN}✅ 错误登录正确被拒绝${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✅ 错误登录拒绝 - 正确行为")
    else
        echo -e "   ${RED}❌ 错误登录处理异常${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("❌ 错误登录处理 - 异常行为")
    fi
}

# 函数：生成测试数据
generate_test_data() {
    # 入站测试数据
    INBOUND_ADD_DATA='{
        "port": 8080,
        "protocol": "vmess",
        "settings": "{\"clients\":[{\"id\":\"uuid-test\",\"alterId\":0}]}",
        "tag": "test-inbound",
        "remark": "API测试入站",
        "enable": true
    }'
    
    # 出站测试数据
    OUTBOUND_ADD_DATA='{
        "name": "test-outbound",
        "protocol": "freedom",
        "settings": "{}",
        "tag": "test-out"
    }'
    
    # 路由测试数据
    ROUTING_ADD_DATA='{
        "name": "test-routing",
        "domain": ["example.com"],
        "outbound": "direct"
    }'
    
    # 订阅测试数据
    SUBSCRIPTION_ADD_DATA='{
        "name": "test-subscription",
        "inbounds": [1, 2]
    }'
}

# 开始测试
print_header "🚀 3X-UI Enhanced API 完整功能测试开始"

echo -e "${CYAN}📋 测试信息：${NC}"
echo "🌐 服务器: $SERVER_IP:2053"
echo "🔗 API基础URL: $PANEL_API_BASE"
echo "⏰ 开始时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 1. 基础连接测试
print_subheader "基础连接测试"

TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "\n${BLUE}🧪 测试: 面板首页访问${NC}"
homepage_response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/" 2>/dev/null)
homepage_code=$(echo "$homepage_response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)

if [[ "$homepage_code" == "200" ]]; then
    echo -e "   ${GREEN}✅ 首页访问: HTTP $homepage_code${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS+=("✅ 首页访问 - HTTP $homepage_code")
else
    echo -e "   ${RED}❌ 首页访问: HTTP $homepage_code${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TEST_RESULTS+=("❌ 首页访问 - HTTP $homepage_code")
fi

# 2. 登录功能测试
test_login

# 3. 生成测试数据
generate_test_data

# 4. 入站管理API测试
print_subheader "入站管理API测试"

test_api "GET" "/inbounds/list" "获取入站列表" "" "200"
test_api "POST" "/inbounds/add" "添加入站" "$INBOUND_ADD_DATA" "200"
test_api "POST" "/inbounds/update" "更新入站" "$INBOUND_ADD_DATA" "200"
test_api "POST" "/inbounds/delete" "删除入站" '{"id":1}' "200"

# 5. 出站管理API测试
print_subheader "出站管理API测试"

test_api "GET" "/outbound/list" "获取出站列表" "" "200"
test_api "POST" "/outbound/add" "添加出站" "$OUTBOUND_ADD_DATA" "200"
test_api "POST" "/outbound/update" "更新出站" "$OUTBOUND_ADD_DATA" "200"
test_api "POST" "/outbound/delete" "删除出站" '{"id":1}' "200"
test_api "POST" "/outbound/resetTraffic" "重置出站流量" '{"tag":"direct"}' "200"

# 6. 路由管理API测试
print_subheader "路由管理API测试"

test_api "GET" "/routing/list" "获取路由列表" "" "200"
test_api "POST" "/routing/add" "添加路由" "$ROUTING_ADD_DATA" "200"
test_api "POST" "/routing/update" "更新路由" "$ROUTING_ADD_DATA" "200"
test_api "POST" "/routing/delete" "删除路由" '{"id":1}' "200"

# 7. 订阅管理API测试
print_subheader "订阅管理API测试"

test_api "GET" "/subscription/list" "获取订阅列表" "" "200"
test_api "POST" "/subscription/add" "添加订阅" "$SUBSCRIPTION_ADD_DATA" "200"
test_api "POST" "/subscription/update" "更新订阅" "$SUBSCRIPTION_ADD_DATA" "200"
test_api "POST" "/subscription/delete" "删除订阅" '{"id":1}' "200"
test_api "POST" "/subscription/generate" "生成订阅链接" '{"id":1}' "200"

# 8. 服务器状态API测试
print_subheader "服务器状态API测试"

test_api "GET" "/server/status" "获取服务器状态" "" "200"

# 9. 额外功能测试
print_subheader "额外功能测试"

# 测试不存在的端点
test_api "GET" "/nonexistent" "不存在的端点" "" "404"

# 测试错误的HTTP方法
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "\n${BLUE}🧪 测试: 错误的HTTP方法${NC}"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X DELETE "$PANEL_API_BASE/inbounds/list" 2>/dev/null)
http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)

if [[ "$http_code" == "404" || "$http_code" == "405" ]]; then
    echo -e "   ${GREEN}✅ 错误方法正确拒绝: HTTP $http_code${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS+=("✅ 错误HTTP方法拒绝 - HTTP $http_code")
else
    echo -e "   ${RED}❌ 错误方法处理异常: HTTP $http_code${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TEST_RESULTS+=("❌ 错误HTTP方法处理 - HTTP $http_code")
fi

# 10. 性能测试
print_subheader "性能测试"

echo -e "\n${BLUE}🧪 测试: API响应时间${NC}"
start_time=$(date +%s.%3N)
curl -s "$PANEL_API_BASE/server/status" > /dev/null
end_time=$(date +%s.%3N)
response_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")

if [[ "$response_time" != "N/A" ]]; then
    echo -e "   ${GREEN}⚡ 响应时间: ${response_time}秒${NC}"
    if (( $(echo "$response_time < 1.0" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "   ${GREEN}✅ 响应速度优秀${NC}"
    else
        echo -e "   ${YELLOW}⚠️  响应较慢${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  无法测量响应时间${NC}"
fi

# 生成测试报告
print_header "📊 测试报告"

echo -e "${CYAN}📈 总体统计：${NC}"
echo "🔢 总测试数量: $TOTAL_TESTS"
echo -e "✅ 通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "❌ 失败测试: ${RED}$FAILED_TESTS${NC}"

success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
echo -e "📊 成功率: ${GREEN}${success_rate}%${NC}"

echo -e "\n${CYAN}📋 详细结果：${NC}"
for result in "${TEST_RESULTS[@]}"; do
    echo "   $result"
done

# 结论
echo -e "\n${PURPLE}🎯 测试结论：${NC}"

if [[ $success_rate -ge 90 ]]; then
    echo -e "${GREEN}🎉 优秀！您的3X-UI Enhanced API运行完美！${NC}"
    echo -e "${GREEN}✨ 所有主要功能都正常工作${NC}"
elif [[ $success_rate -ge 70 ]]; then
    echo -e "${YELLOW}👍 良好！大部分功能正常，有少量问题${NC}"
    echo -e "${YELLOW}🔧 建议检查失败的测试项目${NC}"
else
    echo -e "${RED}⚠️  需要注意！多个功能存在问题${NC}"
    echo -e "${RED}🛠️  建议检查服务配置和日志${NC}"
fi

echo -e "\n${CYAN}🚀 Enhanced API功能特色：${NC}"
echo "✅ 完整的入站管理 (4个端点)"
echo "✅ 强大的出站管理 (5个端点)"  
echo "✅ 灵活的路由管理 (4个端点)"
echo "✅ 便捷的订阅管理 (5个端点)"
echo "✅ 实时的服务器状态 (1个端点)"
echo "✅ 安全的用户认证"
echo "✅ 标准的REST API设计"

echo -e "\n${PURPLE}📚 API文档和使用示例：${NC}"
echo "🔗 入站API: /panel/api/inbounds/*"
echo "🔗 出站API: /panel/api/outbound/*"
echo "🔗 路由API: /panel/api/routing/*"
echo "🔗 订阅API: /panel/api/subscription/*"
echo "🔗 状态API: /panel/api/server/status"

echo -e "\n⏰ 测试完成时间: $(date '+%Y-%m-%d %H:%M:%S')"

print_header "🎊 3X-UI Enhanced API 完整功能测试完成 🎊"

# 生成JSON格式的测试报告（可选）
if command -v jq >/dev/null 2>&1; then
    echo -e "\n${BLUE}📄 生成JSON测试报告...${NC}"
    
    cat > /tmp/api_test_report.json << EOF
{
    "test_summary": {
        "total_tests": $TOTAL_TESTS,
        "passed_tests": $PASSED_TESTS,
        "failed_tests": $FAILED_TESTS,
        "success_rate": $success_rate,
        "test_time": "$(date '+%Y-%m-%d %H:%M:%S')"
    },
    "server_info": {
        "server_ip": "$SERVER_IP",
        "port": "2053",
        "base_url": "$BASE_URL"
    },
    "api_endpoints": {
        "inbound_management": 4,
        "outbound_management": 5,
        "routing_management": 4,
        "subscription_management": 5,
        "server_status": 1,
        "authentication": 1
    }
}
EOF
    
    echo -e "✅ JSON报告已保存到: ${GREEN}/tmp/api_test_report.json${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "🎯 使用curl命令测试单个API的示例："
echo ""
echo "# 获取服务器状态"
echo "curl -X GET '$PANEL_API_BASE/server/status'"
echo ""
echo "# 获取入站列表"
echo "curl -X GET '$PANEL_API_BASE/inbounds/list'"
echo ""
echo "# 添加出站"
echo "curl -X POST '$PANEL_API_BASE/outbound/add' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"name\":\"test\",\"protocol\":\"freedom\"}'"
echo "════════════════════════════════════════════════════════"
