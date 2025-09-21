#!/bin/bash

# 3X-UI 完整系统安装脚本（原生 + 增强API）
# Complete 3X-UI System Installation Script (Native + Enhanced API)
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检测系统
detect_system() {
    if [[ -f /etc/redhat-release ]]; then
        SYSTEM="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        SYSTEM="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        SYSTEM="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        SYSTEM="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        SYSTEM="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        SYSTEM="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        SYSTEM="centos"
    else
        log_error "不支持的系统版本"
        exit 1
    fi
    log_success "检测到系统: $SYSTEM"
}

# 更新系统包
update_system() {
    log_info "更新系统包..."
    
    case "$SYSTEM" in
        ubuntu|debian)
            apt-get update -y
            apt-get install -y curl wget unzip tar
            ;;
        centos)
            yum update -y
            yum install -y curl wget unzip tar
            ;;
    esac
    
    log_success "系统包更新完成"
}

# 检查现有3X-UI安装
check_existing_3xui() {
    if systemctl list-unit-files | grep -q "x-ui.service"; then
        log_warning "检测到已安装的3X-UI服务"
        
        read -p "是否要重新安装3X-UI？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "将重新安装3X-UI..."
            # 停止现有服务
            systemctl stop x-ui 2>/dev/null || true
            systemctl disable x-ui 2>/dev/null || true
            REINSTALL_3XUI=true
        else
            log_info "跳过3X-UI安装，直接安装增强API..."
            REINSTALL_3XUI=false
        fi
    else
        REINSTALL_3XUI=true
    fi
}

# 安装原生3X-UI
install_native_3xui() {
    if [[ "$REINSTALL_3XUI" == true ]]; then
        log_info "正在安装原生3X-UI..."
        
        # 下载并执行官方安装脚本
        bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
        
        # 等待服务启动
        sleep 10
        
        # 验证安装
        if systemctl is-active --quiet x-ui; then
            log_success "3X-UI安装成功"
            
            # 获取端口信息
            X_UI_PORT=$(x-ui setting -show | grep -i port | awk '{print $NF}' || echo "2053")
            log_info "3X-UI面板端口: $X_UI_PORT"
            
        else
            log_error "3X-UI安装失败"
            log_info "请检查安装日志: journalctl -u x-ui"
            exit 1
        fi
    else
        log_info "使用现有的3X-UI安装"
        
        # 检查服务状态
        if ! systemctl is-active --quiet x-ui; then
            log_info "启动现有的3X-UI服务..."
            systemctl start x-ui
        fi
        
        X_UI_PORT=$(x-ui setting -show | grep -i port | awk '{print $NF}' 2>/dev/null || echo "2053")
    fi
}

# 安装增强API
install_enhanced_api() {
    log_info "正在安装增强API扩展..."
    
    # 下载增强API安装脚本
    ENHANCED_SCRIPT="/tmp/install_enhanced_api.sh"
    curl -fsSL https://raw.githubusercontent.com/your-username/3x-ui-enhanced-api/main/install_enhanced_api.sh > "$ENHANCED_SCRIPT"
    
    if [[ -f "$ENHANCED_SCRIPT" ]]; then
        chmod +x "$ENHANCED_SCRIPT"
        
        # 运行增强API安装脚本
        bash "$ENHANCED_SCRIPT"
        
        # 清理临时文件
        rm -f "$ENHANCED_SCRIPT"
        
        log_success "增强API安装完成"
    else
        log_error "无法下载增强API安装脚本"
        log_warning "您可以稍后手动安装增强API"
        return 1
    fi
}

# 验证完整安装
verify_installation() {
    log_info "验证安装结果..."
    
    # 检查3X-UI服务状态
    if systemctl is-active --quiet x-ui; then
        log_success "3X-UI服务运行正常"
    else
        log_error "3X-UI服务异常"
        return 1
    fi
    
    # 检查面板访问
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${X_UI_PORT:-2053}" | grep -q "200\|30[0-9]"; then
        log_success "3X-UI面板可正常访问"
    else
        log_warning "3X-UI面板可能未完全启动，请稍后检查"
    fi
    
    # 下载并运行API测试
    log_info "下载API测试脚本..."
    TEST_SCRIPT="/tmp/api_test.sh"
    if curl -fsSL https://raw.githubusercontent.com/your-username/3x-ui-enhanced-api/main/api_test_examples.sh > "$TEST_SCRIPT"; then
        chmod +x "$TEST_SCRIPT"
        log_success "API测试脚本已下载到: $TEST_SCRIPT"
        log_info "您可以稍后使用以下命令测试API功能:"
        echo "  $TEST_SCRIPT --url http://your-server:${X_UI_PORT:-2053} --user admin --pass your-password"
    else
        log_warning "无法下载API测试脚本"
    fi
}

# 显示完成信息
show_completion_info() {
    local server_ip
    server_ip=$(curl -s ipv4.icanhazip.com 2>/dev/null || echo "your-server-ip")
    
    echo
    log_success "=========================================="
    log_success "   3X-UI 完整系统安装完成！"
    log_success "=========================================="
    echo
    log_info "📊 访问信息："
    echo "   面板地址: http://${server_ip}:${X_UI_PORT:-2053}"
    echo "   默认用户: admin"
    echo "   默认密码: admin"
    echo
    log_info "🚀 增强API端点："
    echo "   统计API: /panel/api/enhanced/stats/"
    echo "   批量API: /panel/api/enhanced/batch/"
    echo "   监控API: /panel/api/enhanced/monitor/"
    echo
    log_info "🧪 测试API功能："
    echo "   /tmp/api_test.sh --url http://${server_ip}:${X_UI_PORT:-2053}"
    echo
    log_info "📚 更多信息："
    echo "   项目地址: https://github.com/your-username/3x-ui-enhanced-api"
    echo "   问题反馈: https://github.com/your-username/3x-ui-enhanced-api/issues"
    echo
    log_warning "⚠️  重要提醒："
    echo "   1. 请及时修改默认密码"
    echo "   2. 配置防火墙规则"
    echo "   3. 定期备份数据库"
    echo
}

# 错误处理
cleanup() {
    log_warning "安装过程中断，正在清理..."
    rm -f /tmp/install_enhanced_api.sh
    rm -f /tmp/api_test.sh
}

# 主函数
main() {
    echo "=========================================="
    echo "   3X-UI Complete System Installer"
    echo "   完整系统安装器 v1.0.0"
    echo "   (原生3X-UI + 增强API扩展)"
    echo "=========================================="
    echo
    
    # 设置错误处理
    trap cleanup EXIT
    
    # 检查权限
    check_root
    
    # 检测系统
    detect_system
    
    # 更新系统
    update_system
    
    # 检查现有安装
    check_existing_3xui
    
    # 确认安装
    echo
    log_warning "即将安装完整的3X-UI系统："
    echo "  ✅ 原生3X-UI面板"
    echo "  ✅ 增强API扩展"
    echo "  ✅ 自动配置和测试"
    echo
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    # 执行安装
    install_native_3xui
    install_enhanced_api
    verify_installation
    show_completion_info
    
    log_success "🎉 完整系统安装成功！"
}

# 执行主函数
main "$@"
