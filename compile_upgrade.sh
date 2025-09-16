#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${green}3X-UI Enhanced API 源码编译升级脚本${plain}"
echo -e "${yellow}============================================${plain}"

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 请使用root权限运行此脚本 \n " && exit 1

# 检查当前是否有运行中的x-ui
check_xui_status() {
    if systemctl is-active --quiet x-ui; then
        echo -e "${green}检测到x-ui正在运行...${plain}"
        return 0
    else
        echo -e "${red}未检测到x-ui服务，请先安装原版3X-UI${plain}"
        exit 1
    fi
}

# 检查Go环境
check_go_environment() {
    if command -v go &> /dev/null; then
        go_version=$(go version | awk '{print $3}' | sed 's/go//')
        echo -e "${green}检测到Go环境: ${go_version}${plain}"
        return 0
    else
        echo -e "${yellow}未检测到Go环境，正在安装...${plain}"
        install_go
    fi
}

# 安装Go环境
install_go() {
    echo -e "${yellow}正在安装Go环境...${plain}"
    
    # 检测操作系统
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        release=$ID
    else
        echo -e "${red}无法检测操作系统${plain}"
        exit 1
    fi

    case "${release}" in
    ubuntu | debian)
        apt-get update
        apt-get install -y golang-go git
        ;;
    centos | almalinux | rocky | ol)
        yum install -y golang git
        ;;
    fedora)
        dnf install -y golang git
        ;;
    *)
        echo -e "${red}不支持的操作系统，请手动安装Go环境${plain}"
        exit 1
        ;;
    esac
    
    if command -v go &> /dev/null; then
        echo -e "${green}Go环境安装成功${plain}"
    else
        echo -e "${red}Go环境安装失败${plain}"
        exit 1
    fi
}

# 备份当前配置
backup_current_installation() {
    echo -e "${yellow}正在备份当前安装...${plain}"
    
    if [[ -d /usr/local/x-ui ]]; then
        cp -r /usr/local/x-ui /usr/local/x-ui-backup-$(date +%Y%m%d_%H%M%S)
        echo -e "${green}备份完成${plain}"
    else
        echo -e "${red}未找到x-ui安装目录${plain}"
        exit 1
    fi
}

# 停止服务
stop_services() {
    echo -e "${yellow}正在停止x-ui服务...${plain}"
    systemctl stop x-ui
    echo -e "${green}服务已停止${plain}"
}

# 编译增强版本
compile_enhanced_version() {
    echo -e "${yellow}正在下载并编译增强版本...${plain}"
    
    # 创建临时目录
    tmp_dir="/tmp/x-ui-api-enhanced"
    rm -rf $tmp_dir
    mkdir -p $tmp_dir
    cd $tmp_dir
    
    # 克隆仓库
    echo -e "${blue}正在克隆仓库...${plain}"
    git clone https://github.com/WCOJBK/x-ui-api-main.git .
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}克隆仓库失败${plain}"
        exit 1
    fi
    
    # 编译
    echo -e "${blue}正在编译...${plain}"
    go mod tidy
    go build -o x-ui main.go
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}编译失败${plain}"
        exit 1
    fi
    
    echo -e "${green}编译完成${plain}"
}

# 安装增强版本
install_enhanced_version() {
    echo -e "${yellow}正在安装增强版本...${plain}"
    
    # 复制新的二进制文件
    cp x-ui /usr/local/x-ui/x-ui
    chmod +x /usr/local/x-ui/x-ui
    
    # 复制新的脚本文件
    cp x-ui.sh /usr/local/x-ui/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    
    # 复制服务文件
    cp x-ui.service /etc/systemd/system/x-ui.service
    
    echo -e "${green}增强版本安装完成${plain}"
}

# 重启服务
restart_services() {
    echo -e "${yellow}正在重启服务...${plain}"
    
    systemctl daemon-reload
    systemctl start x-ui
    
    if systemctl is-active --quiet x-ui; then
        echo -e "${green}x-ui服务启动成功${plain}"
    else
        echo -e "${red}x-ui服务启动失败${plain}"
        exit 1
    fi
}

# 获取面板信息
get_panel_info() {
    echo -e "${yellow}正在获取面板信息...${plain}"
    
    sleep 3
    panel_info=$(/usr/local/x-ui/x-ui setting -show true 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        username=$(echo "$panel_info" | grep -Eo 'username: .+' | awk '{print $2}')
        password=$(echo "$panel_info" | grep -Eo 'password: .+' | awk '{print $2}')
        port=$(echo "$panel_info" | grep -Eo 'port: .+' | awk '{print $2}')
        webBasePath=$(echo "$panel_info" | grep -Eo 'webBasePath: .+' | awk '{print $2}')
        server_ip=$(curl -s https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
        
        echo -e "${green}============================================${plain}"
        echo -e "${green}🎉 增强版API安装完成！${plain}"
        echo -e "${green}============================================${plain}"
        echo -e "${blue}面板访问信息：${plain}"
        echo -e "用户名: ${green}${username}${plain}"
        echo -e "密码: ${green}${password}${plain}"
        echo -e "端口: ${green}${port}${plain}"
        echo -e "路径: ${green}${webBasePath}${plain}"
        echo -e "访问地址: ${green}http://${server_ip}:${port}/${webBasePath}${plain}"
        echo -e "${green}============================================${plain}"
        
        echo -e "${blue}🆕 新增API功能：${plain}"
        echo -e "✅ 出站管理API (6个接口)"
        echo -e "✅ 路由管理API (5个接口)"
        echo -e "✅ 订阅管理API (5个接口)"
        echo -e "✅ 高级客户端功能 (订阅地址、流量限制、到期时间)"
        echo -e "✅ 完整API文档"
        echo -e ""
        echo -e "${yellow}API文档位置：${plain}"
        echo -e "- COMPLETE_API_DOCUMENTATION.md"
        echo -e "- API_QUICK_REFERENCE.md"
        echo -e "- API_FEATURE_SUMMARY.md"
        echo -e ""
        echo -e "${blue}测试API：${plain}"
        echo -e "curl -X POST http://${server_ip}:${port}/${webBasePath}/login \\"
        echo -e "  -H \"Content-Type: application/x-www-form-urlencoded\" \\"
        echo -e "  -d \"username=${username}&password=${password}\""
    else
        echo -e "${red}无法获取面板信息，请手动检查${plain}"
    fi
}

# 清理临时文件
cleanup() {
    echo -e "${yellow}正在清理临时文件...${plain}"
    rm -rf /tmp/x-ui-api-enhanced
    echo -e "${green}清理完成${plain}"
}

# 主函数
main() {
    echo -e "${blue}开始执行升级流程...${plain}"
    
    check_xui_status
    check_go_environment
    backup_current_installation
    stop_services
    compile_enhanced_version
    install_enhanced_version
    restart_services
    get_panel_info
    cleanup
    
    echo -e "${green}🎉 升级完成！现在您拥有了完整的增强API功能！${plain}"
}

# 确认升级
echo -e "${yellow}此脚本将把您的3X-UI升级到增强API版本${plain}"
echo -e "${yellow}升级过程中会：${plain}"
echo -e "1. 备份当前安装"
echo -e "2. 安装Go环境（如果需要）"
echo -e "3. 下载并编译增强版本"
echo -e "4. 替换现有程序"
echo -e "5. 重启服务"
echo -e ""
read -p "确认继续升级? [y/N]: " confirm

if [[ "${confirm}" == "y" || "${confirm}" == "Y" ]]; then
    main
else
    echo -e "${yellow}升级已取消${plain}"
    exit 0
fi
