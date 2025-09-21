#!/bin/bash

echo "=== 3X-UI Enhanced API 验证测试脚本 ==="
echo "基于原本3X-UI架构的Enhanced API功能验证"
echo ""

# 服务器配置（用户需要修改）
SERVER_IP="localhost"  # 修改为您的服务器IP
PORT="2053"           # 修改为您的面板端口
USERNAME="admin"      # 修改为您的用户名
PASSWORD="admin"      # 修改为您的密码

BASE_URL="http://${SERVER_IP}:${PORT}"
API_BASE="${BASE_URL}/panel/api"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "🧪 测试: $description ... "
    
    local url="${API_BASE}${endpoint}"
    local response
    local http_code
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url" \
            -H "Content-Type: application/json" \
            --connect-timeout 10)
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data" \
            --connect-timeout 10)
    fi
    
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    response_body=$(echo "$response" | sed -E 's/HTTPSTATUS:[0-9]*$//')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✅ 成功${NC} (HTTP $http_code)"
        if [ ! -z "$response_body" ] && [ "$response_body" != "{}" ]; then
            echo "   📋 响应: $(echo "$response_body" | cut -c1-100)..."
        fi
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ 失败${NC} (HTTP $http_code)"
        if [ ! -z "$response_body" ]; then
            echo "   📋 错误: $(echo "$response_body" | cut -c1-100)..."
        fi
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# 登录测试（如果需要认证）
test_login() {
    echo "🔐 测试登录功能..."
    local login_data="{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}"
    
    local response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "${BASE_URL}/login" \
        -H "Content-Type: application/json" \
        -d "$login_data" \
        --connect-timeout 10)
    
    local http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    local response_body=$(echo "$response" | sed -E 's/HTTPSTATUS:[0-9]*$//')
    
    if [ "$http_code" = "200" ]; then
        echo -e "✅ 登录成功 ${GREEN}$response_body${NC}"
    else
        echo -e "⚠️  登录测试: HTTP $http_code - ${YELLOW}可能需要在实际环境中手动登录${NC}"
    fi
    echo ""
}

# 显示API路径映射
show_api_mapping() {
    echo "📋 Enhanced API 路径映射："
    echo "┌─────────────────────────────────────────────────┐"
    echo "│  功能           │  API路径                      │"
    echo "├─────────────────────────────────────────────────┤"
    echo "│  入站管理       │  /panel/api/inbounds/*        │"
    echo "│  🆕 出站管理    │  /panel/api/outbound/*        │"
    echo "│  🆕 路由管理    │  /panel/api/routing/*         │"
    echo "│  🆕 订阅管理    │  /panel/api/subscription/*    │"
    echo "└─────────────────────────────────────────────────┘"
    echo ""
}

# 主测试流程
main() {
    echo "🌐 服务器: $BASE_URL"
    echo "🔗 API基础路径: $API_BASE"
    echo ""
    
    show_api_mapping
    
    # 基础连接测试
    echo "🔍 基础连接测试"
    echo "────────────────────────────────────────"
    test_endpoint "GET" "" "面板根路径访问" ""
    
    # 登录测试
    test_login
    
    # 入站API测试 (原本功能)
    echo "📥 入站管理API测试"
    echo "────────────────────────────────────────"
    test_endpoint "GET" "/inbounds/list" "获取入站列表" ""
    
    # Enhanced API测试 - 出站管理 (新功能)
    echo "📤 🆕 出站管理API测试 (Enhanced功能)"
    echo "────────────────────────────────────────"
    test_endpoint "POST" "/outbound/list" "获取出站列表" "{}"
    test_endpoint "POST" "/outbound/add" "添加出站配置" '{"tag":"test-outbound","protocol":"freedom","settings":{}}'
    test_endpoint "POST" "/outbound/del/test-outbound" "删除出站配置" "{}"
    
    # Enhanced API测试 - 路由管理 (新功能)
    echo "🛣️  🆕 路由管理API测试 (Enhanced功能)"
    echo "────────────────────────────────────────"
    test_endpoint "POST" "/routing/get" "获取路由配置" "{}"
    test_endpoint "POST" "/routing/update" "更新路由配置" '{"domainStrategy":"AsIs","rules":[]}'
    
    # Enhanced API测试 - 订阅管理 (新功能)
    echo "📋 🆕 订阅管理API测试 (Enhanced功能)"
    echo "────────────────────────────────────────"
    test_endpoint "POST" "/subscription/settings/get" "获取订阅设置" "{}"
    test_endpoint "POST" "/subscription/enable" "启用订阅" "{}"
    test_endpoint "GET" "/subscription/urls/1" "获取订阅链接" ""
    
    # 显示测试结果
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                    📊 测试报告                           ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    printf "║  总测试数: %-3d  |  成功: %-3d  |  失败: %-3d       ║\n" $TOTAL_TESTS $PASSED_TESTS $FAILED_TESTS
    echo "╠══════════════════════════════════════════════════════════╣"
    
    local success_rate=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi
    
    printf "║  成功率: %d%%                                         ║\n" $success_rate
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ $success_rate -ge 80 ]; then
        echo -e "🎉 ${GREEN}测试结果优秀！Enhanced API功能正常工作${NC}"
    elif [ $success_rate -ge 60 ]; then
        echo -e "⚠️  ${YELLOW}测试结果良好，部分功能可能需要检查${NC}"
    else
        echo -e "❌ ${RED}测试结果需要改进，请检查服务器状态和API实现${NC}"
    fi
    echo ""
    
    # 使用指南
    echo "📚 Enhanced API 功能说明："
    echo "✅ 入站管理: 原本3X-UI功能，管理Xray入站配置"
    echo "🆕 出站管理: Enhanced功能，管理上游代理和出站规则"
    echo "🆕 路由管理: Enhanced功能，配置流量路由策略"
    echo "🆕 订阅管理: Enhanced功能，生成和管理用户订阅"
    echo ""
    echo "🔧 使用方法："
    echo "1. 修改脚本开头的服务器配置"
    echo "2. 确保3X-UI服务正在运行"
    echo "3. 在浏览器中登录面板进行完整管理"
    echo ""
    echo "🌐 管理界面访问:"
    echo "   原本3X-UI面板: $BASE_URL/panel"
    echo "   Enhanced API文档: 通过面板中的Xray配置访问出站和路由管理"
}

# 检查curl是否可用
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ 错误: curl 未安装，请先安装 curl${NC}"
    exit 1
fi

# 显示帮助信息
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h     显示此帮助信息"
    echo ""
    echo "配置:"
    echo "  在脚本开头修改 SERVER_IP, PORT, USERNAME, PASSWORD"
    echo ""
    echo "示例:"
    echo "  $0                    # 运行完整测试"
    echo ""
    exit 0
fi

# 运行主程序
main

echo "=== Enhanced API验证测试完成 ==="
