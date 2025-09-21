#!/bin/bash

# 3X-UI 增强API测试脚本
# Enhanced API Test Script for 3X-UI

# 配置变量
BASE_URL="http://localhost:2053"  # 修改为你的3X-UI地址
USERNAME="admin"                  # 修改为你的用户名
PASSWORD="admin"                  # 修改为你的密码

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 登录获取Cookie
login() {
    log_info "正在登录..."
    
    COOKIE_FILE="/tmp/xui-cookies.txt"
    
    LOGIN_RESPONSE=$(curl -s -c "$COOKIE_FILE" -X POST \
        "$BASE_URL/login" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$USERNAME&password=$PASSWORD")
    
    if [[ $? -eq 0 ]]; then
        log_success "登录成功"
        return 0
    else
        log_error "登录失败"
        return 1
    fi
}

# 测试高级统计API
test_enhanced_stats() {
    echo "=========================================="
    log_info "测试高级统计API"
    echo "=========================================="
    
    # 测试流量汇总
    log_info "测试流量汇总API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/stats/traffic/summary/week" \
        -H "Accept: application/json" | jq '.' || echo "Raw response received"
    
    echo
    
    # 测试客户端排名
    log_info "测试客户端排名API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/stats/clients/ranking/month" \
        -H "Accept: application/json" | jq '.' || echo "Raw response received"
    
    echo
    
    # 测试实时连接
    log_info "测试实时连接API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/stats/realtime/connections" \
        -H "Accept: application/json" | jq '.' || echo "Raw response received"
    
    echo
    
    # 测试带宽使用
    log_info "测试带宽使用API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/stats/bandwidth/usage" \
        -H "Accept: application/json" | jq '.' || echo "Raw response received"
    
    echo
}

# 测试批量操作API
test_batch_operations() {
    echo "=========================================="
    log_info "测试批量操作API"
    echo "=========================================="
    
    # 测试批量创建客户端
    log_info "测试批量创建客户端API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/batch/clients/create" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -X POST \
        -d '{
            "count": 3,
            "emailPrefix": "test_user",
            "inboundId": 1
        }' | jq '.' || echo "Raw response received"
    
    echo
    
    # 测试批量更新客户端
    log_info "测试批量更新客户端API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/batch/clients/update" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -X POST \
        -d '{
            "clients": ["test_user_1", "test_user_2"],
            "updates": {"enable": true}
        }' | jq '.' || echo "Raw response received"
    
    echo
    
    # 测试批量重置流量
    log_info "测试批量重置流量API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/batch/clients/reset-traffic" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -X POST \
        -d '{
            "clients": ["test_user_1", "test_user_2"]
        }' | jq '.' || echo "Raw response received"
    
    echo
}

# 测试监控API
test_monitoring() {
    echo "=========================================="
    log_info "测试系统监控API"
    echo "=========================================="
    
    # 测试系统健康状态
    log_info "测试系统健康状态API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/monitor/health/system" \
        -H "Accept: application/json" | jq '.' || echo "Raw response received"
    
    echo
    
    # 测试性能指标
    log_info "测试性能指标API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/monitor/performance/metrics" \
        -H "Accept: application/json" | jq '.' || echo "Raw response received"
    
    echo
}

# 测试原有API兼容性
test_original_api_compatibility() {
    echo "=========================================="
    log_info "测试原有API兼容性"
    echo "=========================================="
    
    # 测试获取入站列表
    log_info "测试获取入站列表API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/inbounds/list" \
        -H "Accept: application/json" \
        -X POST | jq '.' || echo "Raw response received"
    
    echo
    
    # 测试创建备份
    log_info "测试创建备份API..."
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/createbackup" \
        -H "Accept: application/json" | jq '.' || echo "Raw response received"
    
    echo
}

# 性能测试
performance_test() {
    echo "=========================================="
    log_info "性能测试"
    echo "=========================================="
    
    log_info "测试API响应时间..."
    
    # 测试统计API响应时间
    TIME_START=$(date +%s%N)
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/stats/traffic/summary/week" \
        -H "Accept: application/json" > /dev/null
    TIME_END=$(date +%s%N)
    
    RESPONSE_TIME=$(( (TIME_END - TIME_START) / 1000000 ))
    log_info "统计API响应时间: ${RESPONSE_TIME}ms"
    
    # 测试监控API响应时间
    TIME_START=$(date +%s%N)
    curl -s -b "$COOKIE_FILE" \
        "$BASE_URL/panel/api/enhanced/monitor/health/system" \
        -H "Accept: application/json" > /dev/null
    TIME_END=$(date +%s%N)
    
    RESPONSE_TIME=$(( (TIME_END - TIME_START) / 1000000 ))
    log_info "监控API响应时间: ${RESPONSE_TIME}ms"
    
    echo
}

# 清理函数
cleanup() {
    if [[ -f "$COOKIE_FILE" ]]; then
        rm -f "$COOKIE_FILE"
        log_info "清理临时文件完成"
    fi
}

# 显示使用说明
show_usage() {
    echo "3X-UI 增强API测试脚本"
    echo
    echo "使用方法:"
    echo "  $0 [选项]"
    echo
    echo "选项:"
    echo "  --url URL       设置3X-UI地址 (默认: http://localhost:2053)"
    echo "  --user USER     设置用户名 (默认: admin)"
    echo "  --pass PASS     设置密码 (默认: admin)"
    echo "  --stats         仅测试统计API"
    echo "  --batch         仅测试批量操作API"
    echo "  --monitor       仅测试监控API"
    echo "  --compat        仅测试原有API兼容性"
    echo "  --perf          仅运行性能测试"
    echo "  --help          显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0 --url http://your-server:2053 --user myuser --pass mypass"
    echo "  $0 --stats"
    echo "  $0 --perf"
}

# 主函数
main() {
    # 解析命令行参数
    STATS_ONLY=false
    BATCH_ONLY=false
    MONITOR_ONLY=false
    COMPAT_ONLY=false
    PERF_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --url)
                BASE_URL="$2"
                shift 2
                ;;
            --user)
                USERNAME="$2"
                shift 2
                ;;
            --pass)
                PASSWORD="$2"
                shift 2
                ;;
            --stats)
                STATS_ONLY=true
                shift
                ;;
            --batch)
                BATCH_ONLY=true
                shift
                ;;
            --monitor)
                MONITOR_ONLY=true
                shift
                ;;
            --compat)
                COMPAT_ONLY=true
                shift
                ;;
            --perf)
                PERF_ONLY=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "=========================================="
    echo "     3X-UI Enhanced API Test Script"
    echo "     增强API功能测试脚本"
    echo "=========================================="
    echo "目标地址: $BASE_URL"
    echo "用户名: $USERNAME"
    echo "=========================================="
    echo
    
    # 检查依赖
    if ! command -v curl &> /dev/null; then
        log_error "curl 命令不存在，请先安装 curl"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq 命令不存在，JSON输出将不会格式化"
        log_warning "建议安装 jq: apt-get install jq 或 yum install jq"
    fi
    
    # 登录
    if ! login; then
        log_error "登录失败，请检查用户名密码和服务器地址"
        exit 1
    fi
    
    # 设置清理函数
    trap cleanup EXIT
    
    # 根据参数执行相应测试
    if [[ "$STATS_ONLY" == true ]]; then
        test_enhanced_stats
    elif [[ "$BATCH_ONLY" == true ]]; then
        test_batch_operations
    elif [[ "$MONITOR_ONLY" == true ]]; then
        test_monitoring
    elif [[ "$COMPAT_ONLY" == true ]]; then
        test_original_api_compatibility
    elif [[ "$PERF_ONLY" == true ]]; then
        performance_test
    else
        # 执行所有测试
        test_enhanced_stats
        test_batch_operations
        test_monitoring
        test_original_api_compatibility
        performance_test
    fi
    
    echo "=========================================="
    log_success "所有测试完成！"
    echo "=========================================="
}

# 执行主函数
main "$@"

