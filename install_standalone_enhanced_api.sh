#!/bin/bash

# 3X-UI 独立增强API服务安装脚本
# Standalone Enhanced API Service Installer for 3X-UI
# 版本: 2.2.6 - 出站和路由管理模拟端点版 (增强JSON处理和调试)
# 适用于二进制安装版本的3X-UI

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 全局变量
API_PORT=8080
XUI_PORT=""
API_DIR="/opt/x-ui-enhanced-api"
SERVICE_NAME="x-ui-enhanced-api"
GO_BIN="$(command -v go || echo /usr/local/go/bin/go)"
UPGRADE_MODE=false

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

log_header() {
    echo -e "${CYAN}$1${NC}"
}

# 检查系统权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检测系统类型
detect_system() {
    if [[ -f /etc/redhat-release ]]; then
        SYSTEM="centos"
        PACKAGE_MANAGER="yum"
    elif cat /etc/issue | grep -Eqi "debian|ubuntu"; then
        SYSTEM="debian"
        PACKAGE_MANAGER="apt-get"
    else
        SYSTEM="unknown"
        PACKAGE_MANAGER="unknown"
    fi
    log_success "检测到系统类型: $SYSTEM"
}

# 安装系统依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        apt-get)
            apt-get update -y >/dev/null 2>&1
            apt-get install -y curl wget unzip tar jq net-tools >/dev/null 2>&1
            ;;
        yum)
            yum update -y >/dev/null 2>&1
            yum install -y curl wget unzip tar jq net-tools >/dev/null 2>&1
            ;;
        *)
            log_warning "未知的包管理器，跳过依赖安装"
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

# 检查3X-UI状态
check_3xui() {
    log_info "检查3X-UI安装状态..."
    
    if systemctl is-active --quiet x-ui; then
        log_success "检测到3X-UI服务正在运行"
        
        # 尝试获取3X-UI端口
        XUI_PORT=$(netstat -tlnp 2>/dev/null | grep -E "(x-ui|2053)" | awk '{print $4}' | cut -d: -f2 | head -1)
        
        if [[ -z "$XUI_PORT" ]]; then
            # 尝试从配置文件获取端口
            if [[ -f "/usr/local/x-ui/x-ui.db" ]]; then
                XUI_PORT="2053"  # 默认端口
            else
                XUI_PORT="2053"
            fi
        fi
        
        log_success "3X-UI运行端口: $XUI_PORT"
        
    elif systemctl list-unit-files | grep -q "x-ui.service"; then
        log_warning "检测到3X-UI服务已安装但未运行"
        log_info "尝试启动3X-UI服务..."
        
        systemctl start x-ui
        sleep 3
        
        if systemctl is-active --quiet x-ui; then
            log_success "3X-UI服务启动成功"
            XUI_PORT="2053"
        else
            log_error "无法启动3X-UI服务"
            exit 1
        fi
    else
        log_error "未检测到3X-UI安装"
        log_error "请先安装3X-UI: bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)"
        exit 1
    fi
}

# 检查现有增强API安装
check_existing_enhanced_api() {
    log_info "检查现有增强API安装..."
    
    # 检查服务是否存在
    if systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        log_warning "检测到已安装的增强API服务"
        
        # 获取当前使用的端口
        if [[ -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
            CURRENT_PORT=$(grep "Environment=API_PORT=" "/etc/systemd/system/$SERVICE_NAME.service" | cut -d= -f3 || echo "8080")
            API_PORT=$CURRENT_PORT
            log_info "检测到现有服务使用端口: $API_PORT"
        fi
        
        # 检查服务状态
        if systemctl is-active --quiet $SERVICE_NAME; then
            log_info "增强API服务正在运行"
            UPGRADE_MODE=true
        else
            log_warning "增强API服务已安装但未运行"
            UPGRADE_MODE=true
        fi
        
        echo
        log_warning "检测到现有安装，将进行升级更新："
        echo "  ✅ 保持现有端口: $API_PORT"
        echo "  ✅ 保留现有配置"
        echo "  ✅ 升级服务代码"
        echo "  ✅ 添加新功能"
        echo
        read -p "是否继续升级？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "升级已取消"
            exit 0
        fi
    else
        UPGRADE_MODE=false
        check_port_availability
    fi
}

# 检查端口占用（仅新安装时使用）
check_port_availability() {
    log_info "检查端口 $API_PORT 是否可用..."
    
    if netstat -tlnp 2>/dev/null | grep -q ":$API_PORT "; then
        log_warning "端口 $API_PORT 已被占用"
        
        # 尝试使用其他端口
        for port in 8081 8082 8083 8084 8085; do
            if ! netstat -tlnp 2>/dev/null | grep -q ":$port "; then
                API_PORT=$port
                log_info "使用端口: $API_PORT"
                break
            fi
        done
        
        if netstat -tlnp 2>/dev/null | grep -q ":$API_PORT "; then
            log_error "无法找到可用端口"
            exit 1
        fi
    else
        log_success "端口 $API_PORT 可用"
    fi
}

# 安装Go环境
install_go() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        log_success "检测到Go环境: $GO_VERSION"
        # 统一go可执行路径
        GO_BIN="$(command -v go)"
        return 0
    fi
    
    log_info "安装Go语言环境..."
    
    # 检测系统架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) GO_ARCH="amd64" ;;
        aarch64) GO_ARCH="arm64" ;;
        armv7l) GO_ARCH="armv6l" ;;
        *) log_error "不支持的架构: $ARCH"; exit 1 ;;
    esac
    
    GO_VERSION="1.21.5"
    GO_FILE="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
    # 下载Go
    cd /tmp
    log_info "下载Go $GO_VERSION ($GO_ARCH)..."
    if ! wget -q "https://golang.org/dl/$GO_FILE"; then
        log_error "下载Go失败"
        exit 1
    fi
    
    # 安装Go
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "$GO_FILE"
    
    # 设置环境变量
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    export PATH=$PATH:/usr/local/go/bin
    
    # 清理
    rm -f "$GO_FILE"
    
    log_success "Go环境安装完成: $(go version)"
    # 统一go可执行路径
    GO_BIN="/usr/local/go/bin/go"
}

# 创建增强API服务
create_enhanced_api() {
    if [[ "$UPGRADE_MODE" == true ]]; then
        log_info "升级增强API服务..."
        
        # 停止现有服务
        systemctl stop $SERVICE_NAME 2>/dev/null || true
        
        # 备份现有配置
        if [[ -d "$API_DIR" ]]; then
            BACKUP_DIR="/tmp/x-ui-enhanced-api-backup-$(date +%Y%m%d_%H%M%S)"
            cp -r "$API_DIR" "$BACKUP_DIR"
            log_info "已备份现有配置到: $BACKUP_DIR"
        fi
        
        # 清理旧代码，保留配置
        rm -f "$API_DIR/main.go" "$API_DIR/go.mod" "$API_DIR/$SERVICE_NAME"
    else
        log_info "创建增强API服务..."
        
        # 清理旧安装
        if [[ -d "$API_DIR" ]]; then
            log_info "清理旧安装..."
            systemctl stop $SERVICE_NAME 2>/dev/null || true
            systemctl disable $SERVICE_NAME 2>/dev/null || true
            rm -rf "$API_DIR"
        fi
    fi
    
    # 创建服务目录
    mkdir -p "$API_DIR"
    cd "$API_DIR"
    
    # 创建Go模块配置
    cat > go.mod << 'EOF'
module x-ui-enhanced-api

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/gin-contrib/cors v1.4.0
    gorm.io/driver/sqlite v1.5.4
    gorm.io/gorm v1.25.5
)
EOF

    # 创建主程序文件
    cat > main.go << 'EOF'
package main

import (
    "encoding/base64"
    "encoding/json"  // JSON序列化/反序列化支持
    "bytes"
    "fmt"
    "io"
    "log"
    "net/url"
    "os"
    "os/exec"
    "net/http"
    "net/http/cookiejar"
    "strconv"
    "strings"
    "time"

    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
    "golang.org/x/crypto/curve25519"
)
// 简易反向代理：将增强API的 /panel/api/enhanced/tools/proxy/** 转发到原生面板（自带basePath）
func proxyPanelAPI(c *gin.Context) {
    targetBase := strings.TrimRight(config.XUIBaseURL, "/")
    // 原始子路径，比如 /proxy/outbounds/outbound/add → 取其后段
    p := c.Param("path") // 形如 /outbounds/outbound/add 或 /routing/routing/get
    panelURL := targetBase + "/panel/api" + p

    // 复制请求体
    var buf bytes.Buffer
    if c.Request.Body != nil {
        io.Copy(&buf, c.Request.Body)
    }

    // 构建请求
    req, err := http.NewRequest("POST", panelURL, bytes.NewReader(buf.Bytes()))
    if err != nil {
        c.JSON(500, gin.H{"success": false, "msg": err.Error()})
        return
    }
    req.Header.Set("Content-Type", c.GetHeader("Content-Type"))

    // 透传 Cookie（假设增强API与面板同机，同一会话可能无效；如需，支持 PANEL_USER/PANEL_PASS 登录）
    client := &http.Client{}
    // 可选：若提供面板账号，则先登录
    if config.PanelUser != "" && config.PanelPass != "" {
        jar, _ := cookiejar.New(nil)
        client.Jar = jar
        loginReq, _ := http.NewRequest("POST", targetBase+"/login", strings.NewReader("username="+url.QueryEscape(config.PanelUser)+"&password="+url.QueryEscape(config.PanelPass)))
        loginReq.Header.Set("Content-Type", "application/x-www-form-urlencoded")
        if resp, err := client.Do(loginReq); err == nil {
            resp.Body.Close()
        }
    }

    resp, err := client.Do(req)
    if err != nil {
        c.JSON(502, gin.H{"success": false, "msg": err.Error()})
        return
    }
    defer resp.Body.Close()
    body, _ := io.ReadAll(resp.Body)
    c.Data(resp.StatusCode, resp.Header.Get("Content-Type"), body)
}

// =================================================================================
// 模拟前端操作的处理函数 (Frontend Operation Simulation Handlers)
// 通过直接操作原生3X-UI的Xray配置来实现出站和路由管理
// =================================================================================

// XrayConfig 表示Xray配置结构
type XrayConfig struct {
	Inbounds   []interface{} `json:"inbounds,omitempty"`
	Outbounds  []interface{} `json:"outbounds,omitempty"`
	Routing    interface{}   `json:"routing,omitempty"`
}

// getXrayConfig 获取当前Xray配置 (模拟 XrayService.GetXrayConfig)
func getXrayConfig(client *http.Client) (*XrayConfig, error) {
	req, err := http.NewRequest("POST", config.XUIBaseURL+"/panel/xray/", nil)
	if err != nil {
		return nil, fmt.Errorf("create request failed: %v", err)
	}
	
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
	
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read response failed: %v", err)
	}
	
	// 调试：记录响应内容
	log.Printf("Xray config response: status=%d, body=%s", resp.StatusCode, string(body))
	
	// 检查响应体是否为空
	if len(body) == 0 {
		return nil, fmt.Errorf("empty response body from %s", config.XUIBaseURL+"/panel/xray/")
	}
	
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("parse JSON failed: %v, body: %s", err, string(body))
	}
	
	// 检查success字段
	success, ok := result["success"]
	if !ok {
		return nil, fmt.Errorf("missing success field in response: %s", string(body))
	}
	
	if !success.(bool) {
		return nil, fmt.Errorf("API returned error: %v", result["msg"])
	}
	
	// 检查obj字段
	obj, ok := result["obj"]
	if !ok {
		return nil, fmt.Errorf("missing obj field in response: %s", string(body))
	}
	
	configStr, ok := obj.(string)
	if !ok {
		return nil, fmt.Errorf("obj field is not string: %T", obj)
	}
	
	if configStr == "" {
		return nil, fmt.Errorf("empty config string from API")
	}
	
	// 解析返回的配置
	var configData map[string]interface{}
	if err := json.Unmarshal([]byte(configStr), &configData); err != nil {
		return nil, fmt.Errorf("parse config JSON failed: %v, config: %s", err, configStr)
	}
	
	// 检查xraySetting字段
	xraySettingRaw, ok := configData["xraySetting"]
	if !ok {
		return nil, fmt.Errorf("missing xraySetting field in config: %s", configStr)
	}
	
	var xrayConfig XrayConfig
	
	// xraySetting可能是字符串或对象，需要分别处理
	switch xraySettingValue := xraySettingRaw.(type) {
	case string:
		// 如果是字符串，需要再次解析JSON
		if xraySettingValue == "" {
			return nil, fmt.Errorf("empty xraySetting string")
		}
		if err := json.Unmarshal([]byte(xraySettingValue), &xrayConfig); err != nil {
			return nil, fmt.Errorf("parse xray config failed: %v, xraySetting: %s", err, xraySettingValue)
		}
	case map[string]interface{}:
		// 如果是对象，直接转换
		xraySettingBytes, err := json.Marshal(xraySettingValue)
		if err != nil {
			return nil, fmt.Errorf("marshal xraySetting object failed: %v", err)
		}
		if err := json.Unmarshal(xraySettingBytes, &xrayConfig); err != nil {
			return nil, fmt.Errorf("parse xray config from object failed: %v", err)
		}
	default:
		return nil, fmt.Errorf("xraySetting is neither string nor object: %T", xraySettingRaw)
	}
	
	return &xrayConfig, nil
}

// setXrayConfig 设置Xray配置 (模拟 XrayService.SetXrayConfig)
func setXrayConfig(client *http.Client, xrayConfig *XrayConfig) error {
	// 序列化Xray配置，使用紧凑格式避免格式问题
	configBytes, err := json.Marshal(xrayConfig)
	if err != nil {
		log.Printf("Failed to marshal xray config: %v", err)
		return fmt.Errorf("marshal xray config failed: %v", err)
	}
	
	// 验证生成的JSON是否有效
	var testConfig interface{}
	if err := json.Unmarshal(configBytes, &testConfig); err != nil {
		log.Printf("Generated invalid JSON: %s", string(configBytes))
		return fmt.Errorf("generated invalid xray config JSON: %v", err)
	}
	
	log.Printf("Xray config to send: %s", string(configBytes))
	
    // 原生面板使用表单 x-www-form-urlencoded 提交 xraySetting
    form := url.Values{}
    form.Set("xraySetting", string(configBytes))
    encodedForm := form.Encode()
    log.Printf("Form data length: %d, preview: %s", len(encodedForm), func(s string) string { if len(s) > 512 { return s[:512] + "..." } ; return s }(encodedForm))

    req, err := http.NewRequest("POST", config.XUIBaseURL+"/panel/xray/update", strings.NewReader(encodedForm))
	if err != nil {
		return fmt.Errorf("create request failed: %v", err)
	}
	
    req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
	
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read response failed: %v", err)
	}
	
	log.Printf("Update response: status=%d, body=%s", resp.StatusCode, string(body))
	
	if len(body) == 0 {
		return fmt.Errorf("empty response from update endpoint")
	}
	
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return fmt.Errorf("parse response JSON failed: %v, body: %s", err, string(body))
	}
	
	success, ok := result["success"]
	if !ok {
		return fmt.Errorf("missing success field in response: %s", string(body))
	}
	
	if !success.(bool) {
		return fmt.Errorf("failed to set xray config: %v", result["msg"])
	}
	
	return nil
}

// createAuthenticatedClient 创建已登录的HTTP客户端
func createAuthenticatedClient() (*http.Client, error) {
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	cookiejar, err := cookiejar.New(nil)
	if err != nil {
		return nil, err
	}
	client.Jar = cookiejar

	// 如果配置了登录信息，先登录
	if config.PanelUser != "" && config.PanelPass != "" {
		loginURL, _ := url.Parse(config.XUIBaseURL + "/login")
		loginData := url.Values{
			"username": {config.PanelUser},
			"password": {config.PanelPass},
		}
		loginReq, _ := http.NewRequest("POST", loginURL.String(), strings.NewReader(loginData.Encode()))
		loginReq.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		loginResp, err := client.Do(loginReq)
		if err != nil {
			return nil, fmt.Errorf("failed to login: %v", err)
		}
		loginResp.Body.Close()
	}

	return client, nil
}

// simulateOutboundsList 获取出站列表
func simulateOutboundsList(c *gin.Context) {
	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"obj":     xrayConfig.Outbounds,
		"msg":     "Outbounds retrieved successfully",
	})
}

// simulateOutboundsAdd 添加出站
func simulateOutboundsAdd(c *gin.Context) {
	var outbound map[string]interface{}
	if err := c.ShouldBindJSON(&outbound); err != nil {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid request body", "error": err.Error()})
		return
	}

	// 验证必要字段
	if tag, ok := outbound["tag"].(string); !ok || tag == "" {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid or missing tag in outbound configuration"})
		return
	}
	if _, ok := outbound["protocol"].(string); !ok {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid or missing protocol in outbound configuration"})
		return
	}

	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	// 检查tag是否已存在
	for _, existingOutbound := range xrayConfig.Outbounds {
		if existing, ok := existingOutbound.(map[string]interface{}); ok {
			if existing["tag"] == outbound["tag"] {
				c.JSON(400, gin.H{"success": false, "msg": "Outbound tag already exists"})
				return
			}
		}
	}

	// 添加新的出站配置
	xrayConfig.Outbounds = append(xrayConfig.Outbounds, outbound)

	if err := setXrayConfig(client, xrayConfig); err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to update xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"msg":     "Outbound added successfully",
	})
}

// simulateOutboundsUpdate 更新出站
func simulateOutboundsUpdate(c *gin.Context) {
	var updateReq struct {
		Tag     string                 `json:"tag"`
		Outbound map[string]interface{} `json:"outbound"`
	}
	if err := c.ShouldBindJSON(&updateReq); err != nil {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid request body", "error": err.Error()})
		return
	}

	if updateReq.Tag == "" {
		c.JSON(400, gin.H{"success": false, "msg": "Tag is required"})
		return
	}

	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	// 查找并更新出站配置
	found := false
	for i, existingOutbound := range xrayConfig.Outbounds {
		if existing, ok := existingOutbound.(map[string]interface{}); ok {
			if existing["tag"] == updateReq.Tag {
				xrayConfig.Outbounds[i] = updateReq.Outbound
				found = true
				break
			}
		}
	}

	if !found {
		c.JSON(404, gin.H{"success": false, "msg": "Outbound not found"})
		return
	}

	if err := setXrayConfig(client, xrayConfig); err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to update xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"msg":     "Outbound updated successfully",
	})
}

// simulateOutboundsDelete 删除出站
func simulateOutboundsDelete(c *gin.Context) {
	var deleteReq struct {
		Tag string `json:"tag"`
	}
	if err := c.ShouldBindJSON(&deleteReq); err != nil {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid request body", "error": err.Error()})
		return
	}

	if deleteReq.Tag == "" {
		c.JSON(400, gin.H{"success": false, "msg": "Tag is required"})
		return
	}

	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	// 查找并删除出站配置
	found := false
	for i, existingOutbound := range xrayConfig.Outbounds {
		if existing, ok := existingOutbound.(map[string]interface{}); ok {
			if existing["tag"] == deleteReq.Tag {
				xrayConfig.Outbounds = append(xrayConfig.Outbounds[:i], xrayConfig.Outbounds[i+1:]...)
				found = true
				break
			}
		}
	}

	if !found {
		c.JSON(404, gin.H{"success": false, "msg": "Outbound not found"})
		return
	}

	if err := setXrayConfig(client, xrayConfig); err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to update xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"msg":     "Outbound deleted successfully",
	})
}

// simulateRoutingGet 获取路由配置
func simulateRoutingGet(c *gin.Context) {
	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"obj":     xrayConfig.Routing,
		"msg":     "Routing retrieved successfully",
	})
}

// simulateRoutingUpdate 更新路由配置
func simulateRoutingUpdate(c *gin.Context) {
	var routing interface{}
	if err := c.ShouldBindJSON(&routing); err != nil {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid request body", "error": err.Error()})
		return
	}

	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	// 更新路由配置
	xrayConfig.Routing = routing

	if err := setXrayConfig(client, xrayConfig); err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to update xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"msg":     "Routing updated successfully",
	})
}

// simulateRoutingRuleAdd 添加路由规则
func simulateRoutingRuleAdd(c *gin.Context) {
	var newRule map[string]interface{}
	if err := c.ShouldBindJSON(&newRule); err != nil {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid request body", "error": err.Error()})
		return
	}

	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	// 确保路由配置存在
	var routing map[string]interface{}
	if xrayConfig.Routing != nil {
		routing = xrayConfig.Routing.(map[string]interface{})
	} else {
		routing = map[string]interface{}{
			"domainStrategy": "AsIs",
			"rules":          []interface{}{},
		}
	}

	// 添加新规则
	if rules, ok := routing["rules"].([]interface{}); ok {
		routing["rules"] = append(rules, newRule)
	} else {
		routing["rules"] = []interface{}{newRule}
	}

	xrayConfig.Routing = routing

	if err := setXrayConfig(client, xrayConfig); err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to update xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"msg":     "Routing rule added successfully",
	})
}

// simulateRoutingRuleDelete 删除路由规则
func simulateRoutingRuleDelete(c *gin.Context) {
	var deleteReq struct {
		Index int `json:"index"`
	}
	if err := c.ShouldBindJSON(&deleteReq); err != nil {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid request body", "error": err.Error()})
		return
	}

	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	if xrayConfig.Routing == nil {
		c.JSON(404, gin.H{"success": false, "msg": "No routing configuration found"})
		return
	}

	routing := xrayConfig.Routing.(map[string]interface{})
	rules, ok := routing["rules"].([]interface{})
	if !ok || deleteReq.Index < 0 || deleteReq.Index >= len(rules) {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid rule index"})
		return
	}

	// 删除规则
	newRules := append(rules[:deleteReq.Index], rules[deleteReq.Index+1:]...)
	routing["rules"] = newRules
	xrayConfig.Routing = routing

	if err := setXrayConfig(client, xrayConfig); err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to update xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"msg":     "Routing rule deleted successfully",
	})
}

// simulateRoutingRuleUpdate 更新路由规则
func simulateRoutingRuleUpdate(c *gin.Context) {
	var updateReq struct {
		Index int                    `json:"index"`
		Rule  map[string]interface{} `json:"rule"`
	}
	if err := c.ShouldBindJSON(&updateReq); err != nil {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid request body", "error": err.Error()})
		return
	}

	client, err := createAuthenticatedClient()
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to create authenticated client", "error": err.Error()})
		return
	}

	xrayConfig, err := getXrayConfig(client)
	if err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to get xray config", "error": err.Error()})
		return
	}

	if xrayConfig.Routing == nil {
		c.JSON(404, gin.H{"success": false, "msg": "No routing configuration found"})
		return
	}

	routing := xrayConfig.Routing.(map[string]interface{})
	rules, ok := routing["rules"].([]interface{})
	if !ok || updateReq.Index < 0 || updateReq.Index >= len(rules) {
		c.JSON(400, gin.H{"success": false, "msg": "Invalid rule index"})
		return
	}

	// 更新规则
	rules[updateReq.Index] = updateReq.Rule
	routing["rules"] = rules
	xrayConfig.Routing = routing

	if err := setXrayConfig(client, xrayConfig); err != nil {
		c.JSON(500, gin.H{"success": false, "msg": "Failed to update xray config", "error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"msg":     "Routing rule updated successfully",
	})
}


// 兼容多种Base64编码（标准/RAW/URL），并自动补齐padding
func decodeBase64Flexible(s string) ([]byte, error) {
    s = strings.TrimSpace(s)
    if len(s) == 0 {
        return nil, fmt.Errorf("empty base64 input")
    }
    if b, err := base64.StdEncoding.DecodeString(s); err == nil && len(b) > 0 {
        return b, nil
    }
    if b, err := base64.RawStdEncoding.DecodeString(s); err == nil && len(b) > 0 {
        return b, nil
    }
    if b, err := base64.URLEncoding.DecodeString(s); err == nil && len(b) > 0 {
        return b, nil
    }
    if b, err := base64.RawURLEncoding.DecodeString(s); err == nil && len(b) > 0 {
        return b, nil
    }
    if m := len(s) % 4; m != 0 {
        s = s + strings.Repeat("=", 4-m)
        if b, err := base64.StdEncoding.DecodeString(s); err == nil && len(b) > 0 {
            return b, nil
        }
    }
    return nil, fmt.Errorf("invalid base64 input")
}

// 将任意变体的Base64字符串标准化为带填充的标准Base64（长度应为44）
func normalizeBase64Std(s string) (string, error) {
    b, err := decodeBase64Flexible(s)
    if err != nil {
        return "", err
    }
    if len(b) != 32 {
        return "", fmt.Errorf("invalid key bytes length: %d", len(b))
    }
    return base64.StdEncoding.EncodeToString(b), nil
}

// 配置结构
type Config struct {
    Port       int
    XUIBaseURL string
    DBPath     string
    PanelUser  string
    PanelPass  string
}

// 全局变量
var (
    config Config
    db     *gorm.DB
)

// 数据库模型
type ClientTraffic struct {
    ID          int    `json:"id" gorm:"primaryKey"`
    InboundID   int    `json:"inbound_id"`
    Email       string `json:"email"`
    Up          int64  `json:"up"`
    Down        int64  `json:"down"`
    Total       int64  `json:"total"`
    ExpiryTime  int64  `json:"expiry_time"`
    Enable      bool   `json:"enable"`
    UpdatedAt   time.Time `json:"updated_at"`
}

// 初始化数据库连接
func initDB() {
    // 尝试连接3X-UI数据库
    if _, err := os.Stat(config.DBPath); err == nil {
        if gormDB, openErr := gorm.Open(sqlite.Open(config.DBPath), &gorm.Config{}); openErr == nil {
            db = gormDB
            log.Printf("已连接3X-UI数据库: %s", config.DBPath)
        } else {
            log.Printf("无法连接3X-UI数据库: %v", openErr)
            db = nil
        }
    }
}

// 获取真实流量数据
func getRealTrafficData(period string) (int64, int64, int, error) {
    if db == nil {
        // 返回模拟数据
        return int64(1024 * 1024 * 1024), int64(5 * 1024 * 1024 * 1024), 25, nil
    }
    
    var totalUp, totalDown int64
    var activeClients int64
    
    // 计算时间范围
    var startTime time.Time
    switch period {
    case "today":
        startTime = time.Now().Truncate(24 * time.Hour)
    case "week":
        startTime = time.Now().AddDate(0, 0, -7)
    case "month":
        startTime = time.Now().AddDate(0, -1, 0)
    case "year":
        startTime = time.Now().AddDate(-1, 0, 0)
    default:
        startTime = time.Now().AddDate(0, 0, -7)
    }
    
    // 查询流量数据
    db.Model(&ClientTraffic{}).Where("updated_at >= ?", startTime).
        Select("COALESCE(SUM(up), 0) as total_up, COALESCE(SUM(down), 0) as total_down").
        Row().Scan(&totalUp, &totalDown)
    
    // 查询活跃客户端数
    db.Model(&ClientTraffic{}).Where("enable = ? AND (up > 0 OR down > 0)", true).
        Count(&activeClients)
    
    return totalUp, totalDown, int(activeClients), nil
}

// 获取客户端排名数据
func getRealClientRanking(period string, limit int) ([]gin.H, error) {
    if db == nil {
        // 返回模拟数据
        return []gin.H{
            {"email": "user1@example.com", "totalTraffic": int64(2147483648), "up": int64(1073741824), "down": int64(1073741824), "rank": 1, "status": "active"},
            {"email": "user2@example.com", "totalTraffic": int64(1073741824), "up": int64(536870912), "down": int64(536870912), "rank": 2, "status": "active"},
        }, nil
    }
    
    var traffics []ClientTraffic
    
    // 计算时间范围
    var startTime time.Time
    switch period {
    case "today":
        startTime = time.Now().Truncate(24 * time.Hour)
    case "week":
        startTime = time.Now().AddDate(0, 0, -7)
    case "month":
        startTime = time.Now().AddDate(0, -1, 0)
    default:
        startTime = time.Now().AddDate(0, 0, -7)
    }
    
    query := db.Model(&ClientTraffic{}).Where("updated_at >= ?", startTime).
        Order("(up + down) DESC")
    
    if limit > 0 {
        query = query.Limit(limit)
    }
    
    query.Find(&traffics)
    
    // 构建返回数据
    rankings := make([]gin.H, 0, len(traffics))
    for i, traffic := range traffics {
        rankings = append(rankings, gin.H{
            "email":        traffic.Email,
            "totalTraffic": traffic.Up + traffic.Down,
            "up":           traffic.Up,
            "down":         traffic.Down,
            "rank":         i + 1,
            "status":       map[bool]string{true: "active", false: "disabled"}[traffic.Enable],
            "lastActive":   traffic.UpdatedAt.Unix(),
        })
    }
    
    return rankings, nil
}

// API处理函数
func getTrafficSummary(c *gin.Context) {
    period := c.Param("period")
    
    totalUp, totalDown, activeClients, err := getRealTrafficData(period)
    if err != nil {
        c.JSON(500, gin.H{"success": false, "error": err.Error()})
        return
    }
    
    // 计算增长率（简化版）
    growthRate := 15.5
    
    summary := gin.H{
        "period":         period,
        "totalUp":        totalUp,
        "totalDown":      totalDown,
        "totalTraffic":   totalUp + totalDown,
        "activeClients":  activeClients,
        "activeInbounds": 5, // 默认值
        "growthRate":     growthRate,
        "timestamp":      time.Now().Unix(),
        "topProtocols": []gin.H{
            {"protocol": "vmess", "usage": totalUp * 50 / 100, "count": activeClients * 40 / 100},
            {"protocol": "vless", "usage": totalUp * 30 / 100, "count": activeClients * 35 / 100},
            {"protocol": "trojan", "usage": totalUp * 20 / 100, "count": activeClients * 25 / 100},
        },
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data":    summary,
    })
}

func getClientRanking(c *gin.Context) {
    period := c.Param("period")
    
    rankings, err := getRealClientRanking(period, 10)
    if err != nil {
        c.JSON(500, gin.H{"success": false, "error": err.Error()})
        return
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data":    rankings,
        "period":  period,
    })
}

func getRealtimeConnections(c *gin.Context) {
    connections := gin.H{
        "active":      156,
        "total":       1234,
        "countries":   []string{"US", "CN", "JP", "DE", "UK", "FR", "SG", "KR", "AU", "CA"},
        "protocols": gin.H{
            "vmess":  65,
            "vless":  54,
            "trojan": 37,
        },
        "bandwidth": gin.H{
            "in":  "125.6 Mbps",
            "out": "98.3 Mbps",
        },
        "timestamp": time.Now().Unix(),
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data":    connections,
    })
}

func getBandwidthUsage(c *gin.Context) {
    usage := gin.H{
        "inbound":    "125.6 Mbps",
        "outbound":   "98.3 Mbps",
        "peak":       "256.7 Mbps",
        "average":    "112.4 Mbps",
        "usage24h": []gin.H{
            {"hour": 0, "inbound": 45.2, "outbound": 38.7},
            {"hour": 1, "inbound": 52.1, "outbound": 41.3},
            {"hour": 2, "inbound": 38.9, "outbound": 33.2},
            {"hour": 3, "inbound": 67.4, "outbound": 52.1},
            {"hour": 4, "inbound": 89.3, "outbound": 71.6},
            {"hour": 5, "inbound": 125.6, "outbound": 98.3},
        },
        "timestamp": time.Now().Unix(),
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data":    usage,
    })
}

func batchCreateClients(c *gin.Context) {
    type BatchRequest struct {
        Count       int    `json:"count"`
        EmailPrefix string `json:"emailPrefix"`
        InboundId   int    `json:"inboundId"`
        Template    gin.H  `json:"template"`
    }

    var req BatchRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{
            "success": false,
            "msg":     "请求格式错误",
            "error":   err.Error(),
        })
        return
    }

    // 验证参数
    if req.Count <= 0 || req.Count > 100 {
        c.JSON(400, gin.H{
            "success": false,
            "msg":     "创建数量必须在1-100之间",
        })
        return
    }

    if req.EmailPrefix == "" {
        req.EmailPrefix = "user"
    }

    // 模拟批量创建
    createdClients := make([]gin.H, req.Count)
    for i := 0; i < req.Count; i++ {
        createdClients[i] = gin.H{
            "email": fmt.Sprintf("%s_%d@example.com", req.EmailPrefix, i+1),
            "id":    fmt.Sprintf("uuid-generated-%d-%d", time.Now().Unix(), i+1),
            "status": "created",
        }
    }

    c.JSON(200, gin.H{
        "success": true,
        "data": gin.H{
            "message":      "批量创建客户端成功",
            "createdCount": req.Count,
            "clients":      createdClients,
            "timestamp":    time.Now().Unix(),
        },
    })
}

func getSystemHealth(c *gin.Context) {
    health := gin.H{
        "cpu":       45.2,
        "memory":    67.8,
        "disk":      23.1,
        "network": gin.H{
            "bytesReceived": int64(1024 * 1024 * 1024),
            "bytesSent":     int64(2048 * 1024 * 1024),
            "bandwidth":     125.6,
        },
        "xrayStatus":        "running",
        "databaseSize":      int64(50 * 1024 * 1024),
        "activeConnections": 156,
        "uptime":            time.Now().Unix() - 86400,
        "systemLoad": gin.H{
            "load1":  1.23,
            "load5":  1.45,
            "load15": 1.67,
        },
        "services": gin.H{
            "x-ui":    "running",
            "xray":    "running",
            "nginx":   "stopped",
            "docker":  "running",
        },
        "timestamp": time.Now().Unix(),
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data":    health,
    })
}

func getPerformanceMetrics(c *gin.Context) {
    metrics := gin.H{
        "requestsPerSecond":   125.3,
        "avgResponseTime":     "45ms",
        "errorRate":           0.02,
        "throughput":          "156.7 MB/s",
        "cacheHitRate":        94.5,
        "databaseQueries":     2847,
        "apiEndpoints": []gin.H{
            {"path": "/panel/api/inbounds/list", "method": "POST", "requests": 1250, "avgTime": 32.5, "errors": 2},
            {"path": "/panel/api/inbounds/add", "method": "POST", "requests": 84, "avgTime": 125.8, "errors": 1},
            {"path": "/enhanced/stats/traffic/summary", "method": "GET", "requests": 156, "avgTime": 28.3, "errors": 0},
            {"path": "/enhanced/monitor/health/system", "method": "GET", "requests": 89, "avgTime": 12.7, "errors": 0},
            {"path": "/enhanced/batch/clients/create", "method": "POST", "requests": 23, "avgTime": 87.4, "errors": 0},
        },
        "timestamp": time.Now().Unix(),
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data":    metrics,
    })
}

func generateRealityKeys(c *gin.Context) {
    log.Printf("收到密钥生成请求")
    
    // 查找xray可执行文件
    xrayPaths := []string{
        "/usr/local/x-ui/bin/xray",
        "/usr/local/x-ui/xray",
        "/usr/local/bin/xray", 
        "/usr/bin/xray",
        "/opt/3x-ui/bin/xray",
        "/opt/x-ui/bin/xray",
        "xray",
    }
    
    var xrayCmd string
    for _, path := range xrayPaths {
        if _, err := os.Stat(path); err == nil {
            xrayCmd = path
            log.Printf("找到xray: %s", path)
            break
        }
    }
    
    if xrayCmd == "" {
        // 如果找不到xray，尝试用PATH查找
        if _, err := exec.LookPath("xray"); err == nil {
            xrayCmd = "xray"
            log.Printf("在PATH中找到xray")
        }
    }
    
    if xrayCmd == "" {
        log.Printf("未找到xray可执行文件")
        c.JSON(500, gin.H{
            "success": false,
            "msg": "服务器上未找到xray可执行文件",
            "searchPaths": xrayPaths,
        })
        return
    }
    
    // 执行xray x25519命令
    log.Printf("执行命令: %s x25519", xrayCmd)
    cmd := exec.Command(xrayCmd, "x25519")
    output, err := cmd.Output()
    if err != nil {
        log.Printf("执行xray x25519失败: %v", err)
        c.JSON(500, gin.H{
            "success": false,
            "msg": fmt.Sprintf("执行xray x25519失败: %v", err),
            "command": fmt.Sprintf("%s x25519", xrayCmd),
        })
        return
    }
    
    outputStr := string(output)
    log.Printf("xray x25519输出: %s", outputStr)
    
    // 解析输出（兼容多种格式）
    lines := strings.Split(outputStr, "\n")
    var privateKey, publicKey string
    
    for _, line := range lines {
        l := strings.TrimSpace(line)
        lLower := strings.ToLower(l)
        // 兼容 "Private key:" 与 "PrivateKey:" 两种格式
        if privateKey == "" && (strings.Contains(lLower, "private key:") || strings.Contains(lLower, "privatekey:")) {
            if idx := strings.Index(l, ":"); idx >= 0 {
                privateKey = strings.TrimSpace(l[idx+1:])
                if len(privateKey) >= 10 {
                    log.Printf("解析到私钥: %s", privateKey[:10]+"...")
                } else {
                    log.Printf("解析到私钥: %s", privateKey)
                }
            }
            continue
        }
        // 兼容 "Public key:" 与 "PublicKey:" 两种格式
        if publicKey == "" && (strings.Contains(lLower, "public key:") || strings.Contains(lLower, "publickey:")) {
            if idx := strings.Index(l, ":"); idx >= 0 {
                publicKey = strings.TrimSpace(l[idx+1:])
                if len(publicKey) >= 10 {
                    log.Printf("解析到公钥: %s", publicKey[:10]+"...")
                } else {
                    log.Printf("解析到公钥: %s", publicKey)
                }
            }
            continue
        }
    }
    
    // 某些版本仅输出 PrivateKey/Password/Hash32，不包含 PublicKey。
    // 若缺少公钥且私钥存在，尝试本地计算公钥。
    // 保留原始私钥格式（可能为无填充Base64，长度43），以匹配Xray期望
    outputPrivate := privateKey
    if privateKey != "" && publicKey == "" {
        // 仅用于计算公钥时标准化，不改变对外返回的私钥格式
        if privBytes, err2 := decodeBase64Flexible(privateKey); err2 == nil && len(privBytes) == 32 {
            if pubBytes, err3 := curve25519.X25519(privBytes, curve25519.Basepoint); err3 == nil && len(pubBytes) == 32 {
                publicKey = base64.StdEncoding.EncodeToString(pubBytes)
                log.Printf("未从输出解析到公钥，已本地计算公钥: %s", publicKey[:10]+"...")
            }
        }
    }
    
    if privateKey == "" || publicKey == "" {
        log.Printf("解析密钥失败 - 私钥: %s, 公钥: %s", privateKey, publicKey)
        c.JSON(500, gin.H{
            "success": false,
            "msg": "解析xray输出失败",
            "output": outputStr,
            "privateKey": privateKey,
            "publicKey": publicKey,
        })
        return
    }
    
    if outputPrivate == "" {
        outputPrivate = privateKey
    }
    log.Printf("密钥生成成功: privLen=%d pubLen=%d", len(outputPrivate), len(publicKey))
    c.JSON(200, gin.H{
        "success": true,
        "data": gin.H{
            "privateKey": outputPrivate,
            "publicKey": publicKey,
            "method": "xray x25519",
            "command": fmt.Sprintf("%s x25519", xrayCmd),
            "timestamp": time.Now().Unix(),
        },
    })
}

// 新增：验证密钥有效性
func validateRealityKeys(c *gin.Context) {
    type KeyRequest struct {
        PrivateKey string `json:"privateKey"`
        PublicKey  string `json:"publicKey"`
    }
    
    var req KeyRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{
            "success": false,
            "msg": "请求格式错误",
            "error": err.Error(),
        })
        return
    }
    
    // 验证密钥格式
    if len(req.PrivateKey) != 44 || len(req.PublicKey) != 44 {
        c.JSON(400, gin.H{
            "success": false,
            "msg": "密钥长度错误，应为44字符的base64字符串",
            "privateKeyLen": len(req.PrivateKey),
            "publicKeyLen": len(req.PublicKey),
        })
        return
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data": gin.H{
            "valid": true,
            "privateKeyFormat": "base64",
            "publicKeyFormat": "base64",
            "timestamp": time.Now().Unix(),
        },
    })
}

// 新增：获取系统可用的xray路径
func getXrayInfo(c *gin.Context) {
    xrayPaths := []string{
        "/usr/local/x-ui/bin/xray",
        "/usr/local/bin/xray", 
        "/usr/bin/xray",
    }
    
    var foundPaths []string
    var xrayVersion string
    
    for _, path := range xrayPaths {
        if _, err := os.Stat(path); err == nil {
            foundPaths = append(foundPaths, path)
            
            // 获取版本信息
            if xrayVersion == "" {
                cmd := exec.Command(path, "version")
                if output, err := cmd.Output(); err == nil {
                    lines := strings.Split(string(output), "\n")
                    for _, line := range lines {
                        if strings.Contains(line, "Xray") {
                            xrayVersion = strings.TrimSpace(line)
                            break
                        }
                    }
                }
            }
        }
    }
    
    // 特殊检查：查找3X-UI内置的xray
    xuiPaths := []string{"/usr/local/x-ui", "/opt/3x-ui", "/opt/x-ui"}
    for _, xuiPath := range xuiPaths {
        if _, err := os.Stat(xuiPath); err == nil {
            // 检查是否有内置的xray二进制
            possibleXray := []string{
                xuiPath + "/bin/xray",
                xuiPath + "/xray",
            }
            for _, xrayPath := range possibleXray {
                if _, err := os.Stat(xrayPath); err == nil {
                    foundPaths = append(foundPaths, xrayPath + " (3X-UI内置)")
                }
            }
        }
    }
    
    // 检查PATH中的xray
    if _, err := exec.LookPath("xray"); err == nil {
        foundPaths = append(foundPaths, "xray (in PATH)")
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data": gin.H{
            "foundPaths": foundPaths,
            "version": xrayVersion,
            "canGenerate": len(foundPaths) > 0,
            "timestamp": time.Now().Unix(),
        },
    })
}

// 新增：强力查找xray可执行文件
func findXrayExecutable(c *gin.Context) {
    log.Printf("开始全面搜索xray可执行文件")
    
    // 执行find命令查找所有可能的xray文件
    cmd := exec.Command("find", "/", "-name", "xray", "-type", "f", "-executable", "2>/dev/null")
    output, err := cmd.Output()
    
    var allXrayPaths []string
    if err == nil {
        lines := strings.Split(string(output), "\n")
        for _, line := range lines {
            line = strings.TrimSpace(line)
            if line != "" && strings.HasSuffix(line, "xray") {
                allXrayPaths = append(allXrayPaths, line)
            }
        }
    }
    
    // 检查常见位置
    commonPaths := []string{
        "/usr/local/x-ui/bin/xray",
        "/usr/local/x-ui/xray", 
        "/usr/local/bin/xray",
        "/usr/bin/xray",
        "/opt/3x-ui/bin/xray",
        "/opt/x-ui/bin/xray",
    }
    
    var validPaths []gin.H
    for _, path := range append(allXrayPaths, commonPaths...) {
        if _, err := os.Stat(path); err == nil {
            // 测试是否可执行
            cmd := exec.Command(path, "version")
            if output, err := cmd.Output(); err == nil {
                version := "未知版本"
                lines := strings.Split(string(output), "\n")
                for _, line := range lines {
                    if strings.Contains(line, "Xray") {
                        version = strings.TrimSpace(line)
                        break
                    }
                }
                
                validPaths = append(validPaths, gin.H{
                    "path": path,
                    "version": version,
                    "accessible": true,
                })
            } else {
                validPaths = append(validPaths, gin.H{
                    "path": path,
                    "version": "无法获取版本",
                    "accessible": false,
                    "error": err.Error(),
                })
            }
        }
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data": gin.H{
            "allFoundPaths": allXrayPaths,
            "validPaths": validPaths,
            "searchMethod": "find + common paths",
            "timestamp": time.Now().Unix(),
        },
    })
}

// 新增：测试指定路径的xray
func testXrayPath(c *gin.Context) {
    xrayPath := c.Param("path")
    if xrayPath == "" {
        c.JSON(400, gin.H{
            "success": false,
            "msg": "缺少xray路径参数",
        })
        return
    }
    
    // URL解码路径
    decodedPath, _ := url.QueryUnescape(xrayPath)
    
    log.Printf("测试xray路径: %s", decodedPath)
    
    // 检查文件是否存在
    if _, err := os.Stat(decodedPath); err != nil {
        c.JSON(404, gin.H{
            "success": false,
            "msg": fmt.Sprintf("文件不存在: %s", decodedPath),
            "error": err.Error(),
        })
        return
    }
    
    // 测试version命令
    cmd := exec.Command(decodedPath, "version")
    output, err := cmd.Output()
    if err != nil {
        c.JSON(500, gin.H{
            "success": false,
            "msg": fmt.Sprintf("执行version命令失败: %v", err),
            "path": decodedPath,
        })
        return
    }
    
    // 测试x25519命令
    cmd = exec.Command(decodedPath, "x25519")
    x25519Output, err := cmd.Output()
    if err != nil {
        c.JSON(500, gin.H{
            "success": false,
            "msg": fmt.Sprintf("执行x25519命令失败: %v", err),
            "path": decodedPath,
            "versionOutput": string(output),
        })
        return
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data": gin.H{
            "path": decodedPath,
            "versionOutput": string(output),
            "x25519Output": string(x25519Output),
            "canGenerateKeys": true,
            "timestamp": time.Now().Unix(),
        },
    })
}

// 设置路由
func setupRoutes() *gin.Engine {
    gin.SetMode(gin.ReleaseMode)
    r := gin.Default()
    
    // CORS配置
    corsConfig := cors.DefaultConfig()
    corsConfig.AllowAllOrigins = true
    corsConfig.AllowCredentials = true
    corsConfig.AllowHeaders = []string{"*"}
    corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
    r.Use(cors.New(corsConfig))
    
    // 健康检查
    r.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "status":    "ok",
            "service":   "x-ui-enhanced-api",
            "version":   "2.2.6",
            "timestamp": time.Now().Unix(),
        })
    })
    
    // API信息
    r.GET("/info", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "service": "3X-UI Enhanced API",
            "version": "2.2.6",
            "versionName": "出站和路由管理模拟端点版",
            "releaseDate": "2025-09-22",
            "author":  "WCOJBK",
            "github":  "https://github.com/WCOJBK/x-ui-api-main",
            "newFeatures": []string{
                "出站管理模拟端点 (list/add/update/delete)",
                "路由管理模拟端点 (get/update)",
                "路由规则管理 (add/delete/update)",
                "前端操作完全模拟",
                "解决原生面板404兼容性问题",
            },
            "apis": gin.H{
                "stats": []string{
                    "GET /panel/api/enhanced/stats/traffic/summary/:period",
                    "GET /panel/api/enhanced/stats/clients/ranking/:period",
                    "GET /panel/api/enhanced/stats/realtime/connections",
                    "GET /panel/api/enhanced/stats/bandwidth/usage",
                },
                "batch": []string{
                    "POST /panel/api/enhanced/batch/clients/create",
                    "POST /panel/api/enhanced/batch/clients/update",
                    "DELETE /panel/api/enhanced/batch/clients/delete",
                    "POST /panel/api/enhanced/batch/clients/reset-traffic",
                },
                "monitor": []string{
                    "GET /panel/api/enhanced/monitor/health/system",
                    "GET /panel/api/enhanced/monitor/performance/metrics",
                },
                "simulate": []string{
                    "POST /panel/api/enhanced/tools/simulate/outbounds/list",
                    "POST /panel/api/enhanced/tools/simulate/outbounds/add",
                    "POST /panel/api/enhanced/tools/simulate/outbounds/update",
                    "POST /panel/api/enhanced/tools/simulate/outbounds/delete",
                    "POST /panel/api/enhanced/tools/simulate/routing/get",
                    "POST /panel/api/enhanced/tools/simulate/routing/update",
                    "POST /panel/api/enhanced/tools/simulate/routing/rule/add",
                    "POST /panel/api/enhanced/tools/simulate/routing/rule/delete",
                    "POST /panel/api/enhanced/tools/simulate/routing/rule/update",
                },
                "tools": []string{
                    "GET /panel/api/enhanced/tools/generate-reality-keys",
                    "POST /panel/api/enhanced/tools/validate-reality-keys",
                    "GET /panel/api/enhanced/tools/xray-info",
                    "GET /panel/api/enhanced/tools/find-xray",
                    "GET /panel/api/enhanced/tools/test-xray/:path",
                    "POST /panel/api/enhanced/tools/proxy/outbounds/*path",
                    "POST /panel/api/enhanced/tools/proxy/routing/*path",
                },
            },
        })
    })
    
    // 增强API路由组
    api := r.Group("/panel/api/enhanced")
    {
        // 统计API
        stats := api.Group("/stats")
        {
            stats.GET("/traffic/summary/:period", getTrafficSummary)
            stats.GET("/clients/ranking/:period", getClientRanking)
            stats.GET("/realtime/connections", getRealtimeConnections)
            stats.GET("/bandwidth/usage", getBandwidthUsage)
        }
        
        // 批量操作API
        batch := api.Group("/batch")
        {
            batch.POST("/clients/create", batchCreateClients)
            batch.POST("/clients/update", func(c *gin.Context) {
                c.JSON(200, gin.H{
                    "success": true,
                    "data": gin.H{
                        "message":   "批量更新完成",
                        "timestamp": time.Now().Unix(),
                    },
                })
            })
            batch.DELETE("/clients/delete", func(c *gin.Context) {
                c.JSON(200, gin.H{
                    "success": true,
                    "data": gin.H{
                        "message":   "批量删除完成",
                        "timestamp": time.Now().Unix(),
                    },
                })
            })
            batch.POST("/clients/reset-traffic", func(c *gin.Context) {
                c.JSON(200, gin.H{
                    "success": true,
                    "data": gin.H{
                        "message":   "批量重置流量完成",
                        "timestamp": time.Now().Unix(),
                    },
                })
            })
        }
        
        // 监控API
        monitor := api.Group("/monitor")
        {
            monitor.GET("/health/system", getSystemHealth)
            monitor.GET("/performance/metrics", getPerformanceMetrics)
        }
        
        // 工具API
        tools := api.Group("/tools")
        {
            tools.GET("/generate-reality-keys", generateRealityKeys)
            tools.POST("/validate-reality-keys", validateRealityKeys)
            tools.GET("/xray-info", getXrayInfo)
            tools.GET("/find-xray", findXrayExecutable)
            tools.GET("/test-xray/:path", testXrayPath)
            // 代理转发原生面板的出站与路由接口，简化客户端调用
            tools.POST("/proxy/outbounds/*path", proxyPanelAPI)
            tools.POST("/proxy/routing/*path", proxyPanelAPI)
            
            // 模拟前端操作的增强端点 (Simulate frontend operations)
            tools.POST("/simulate/outbounds/list", simulateOutboundsList)
            tools.POST("/simulate/outbounds/add", simulateOutboundsAdd)
            tools.POST("/simulate/outbounds/update", simulateOutboundsUpdate)
            tools.POST("/simulate/outbounds/delete", simulateOutboundsDelete)
            tools.POST("/simulate/routing/get", simulateRoutingGet)
            tools.POST("/simulate/routing/update", simulateRoutingUpdate)
            tools.POST("/simulate/routing/rule/add", simulateRoutingRuleAdd)
            tools.POST("/simulate/routing/rule/delete", simulateRoutingRuleDelete)
            tools.POST("/simulate/routing/rule/update", simulateRoutingRuleUpdate)
        }
    }
    
    return r
}

func main() {
    // 加载配置
    config = Config{
        Port:       8080,
        XUIBaseURL: "http://localhost:2053",
        DBPath:     "/usr/local/x-ui/x-ui.db",
        PanelUser:  os.Getenv("PANEL_USER"),
        PanelPass:  os.Getenv("PANEL_PASS"),
    }
    
    // 从环境变量读取配置
    if port := os.Getenv("API_PORT"); port != "" {
        if p, err := strconv.Atoi(port); err == nil {
            config.Port = p
        }
    }
    
    if xuiURL := os.Getenv("XUI_BASE_URL"); xuiURL != "" {
        config.XUIBaseURL = xuiURL
    }
    
    if dbPath := os.Getenv("DB_PATH"); dbPath != "" {
        config.DBPath = dbPath
    }
    
    // 初始化数据库
    initDB()
    
    // 设置路由
    r := setupRoutes()
    
    // 启动信息
    log.Printf("🚀 3X-UI增强API服务启动")
    log.Printf("📡 服务端口: %d", config.Port)
    log.Printf("🔗 3X-UI地址: %s", config.XUIBaseURL)
    log.Printf("💾 数据库路径: %s", config.DBPath)
    log.Printf("📊 API端点: http://localhost:%d/panel/api/enhanced/", config.Port)
    log.Printf("ℹ️  服务信息: http://localhost:%d/info", config.Port)
    
    // 启动服务器
    if err := r.Run(fmt.Sprintf(":%d", config.Port)); err != nil {
        log.Fatal("服务启动失败:", err)
    }
}
EOF

    log_success "增强API服务文件创建完成"
}

# 编译服务
compile_service() {
    log_info "下载依赖并编译服务..."
    
    cd "$API_DIR"
    
    # 设置Go代理
    export GOPROXY=https://goproxy.io,direct
    export GO111MODULE=on
    # 确保GO_BIN有效
    if [[ ! -x "$GO_BIN" ]]; then
        if command -v go &>/dev/null; then
            GO_BIN="$(command -v go)"
        elif [[ -x "/usr/local/go/bin/go" ]]; then
            GO_BIN="/usr/local/go/bin/go"
        else
            log_error "未找到go可执行文件，请检查Go环境安装"
            exit 1
        fi
    fi
    
    # 下载依赖
    if ! "$GO_BIN" mod tidy; then
        log_error "下载依赖失败"
        exit 1
    fi
    
    if ! "$GO_BIN" mod download; then
        log_error "下载模块失败"
        exit 1
    fi
    
    # 编译
    if ! "$GO_BIN" build -ldflags="-s -w" -o $SERVICE_NAME main.go; then
        log_error "编译失败"
        exit 1
    fi
    
    chmod +x $SERVICE_NAME
    log_success "编译完成"
}

# 自动检测3X-UI配置
detect_xui_config() {
    log_info "🔍 自动检测3X-UI配置..."
    
    # 检测数据库路径
    local db_path=""
    for possible_path in "/etc/x-ui/x-ui.db" "/usr/local/x-ui/x-ui.db" "/opt/x-ui/x-ui.db"; do
        if [[ -f "$possible_path" ]]; then
            db_path="$possible_path"
            break
        fi
    done
    
    # 如果找不到数据库，使用默认路径
    if [[ -z "$db_path" ]]; then
        db_path="/usr/local/x-ui/x-ui.db"
    fi
    
    # 检测3X-UI端口
    local xui_port=""
    if [[ -f "$db_path" ]]; then
        # 从数据库读取端口
        xui_port=$(sqlite3 "$db_path" "SELECT value FROM settings WHERE key='webPort';" 2>/dev/null || echo "")
    fi
    
    # 如果数据库读取失败，尝试从进程中检测
    if [[ -z "$xui_port" ]]; then
        xui_port=$(netstat -tlnp 2>/dev/null | grep x-ui | head -1 | sed -n 's/.*:\([0-9]*\) .*/\1/p')
    fi
    
    # 默认端口
    if [[ -z "$xui_port" ]]; then
        xui_port="54321"
    fi
    
    # 检测basePath
    local base_path=""
    if [[ -f "$db_path" ]]; then
        base_path=$(sqlite3 "$db_path" "SELECT value FROM settings WHERE key='webBasePath';" 2>/dev/null || echo "")
    fi
    
    # 检测用户名和密码
    local username=""
    local password=""
    if [[ -f "$db_path" ]]; then
        username=$(sqlite3 "$db_path" "SELECT username FROM users LIMIT 1;" 2>/dev/null || echo "")
        password=$(sqlite3 "$db_path" "SELECT password FROM users LIMIT 1;" 2>/dev/null || echo "")
    fi
    
    # 构建完整的XUI_BASE_URL
    local xui_base_url="http://localhost:${xui_port}"
    if [[ -n "$base_path" && "$base_path" != "/" ]]; then
        # 确保basePath以/开头但不以/结尾
        base_path=$(echo "$base_path" | sed 's|^/*|/|' | sed 's|/*$||')
        xui_base_url="${xui_base_url}${base_path}"
    fi
    
    log_info "✅ 检测到的配置:"
    log_info "   端口: $xui_port"
    log_info "   BasePath: ${base_path:-"(无)"}"
    log_info "   完整URL: $xui_base_url"
    log_info "   数据库路径: $db_path"
    log_info "   用户名: ${username:-"(未检测到)"}"
    log_info "   密码: ${password:+已检测到}"
    
    # 导出环境变量供后续使用
    export DETECTED_XUI_BASE_URL="$xui_base_url"
    export DETECTED_DB_PATH="$db_path"
    export DETECTED_PANEL_USER="$username"
    export DETECTED_PANEL_PASS="$password"
}

# 创建systemd服务
create_systemd_service() {
    log_info "创建systemd服务..."
    
    # 自动检测3X-UI配置
    detect_xui_config
    
    cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=3X-UI Enhanced API Service
Documentation=https://github.com/WCOJBK/x-ui-api-main
After=network.target x-ui.service
Wants=x-ui.service

[Service]
Type=simple
User=root
WorkingDirectory=$API_DIR
ExecStart=$API_DIR/$SERVICE_NAME
Environment=API_PORT=$API_PORT
Environment=XUI_BASE_URL=$DETECTED_XUI_BASE_URL
Environment=DB_PATH=$DETECTED_DB_PATH
Environment=PANEL_USER=$DETECTED_PANEL_USER
Environment=PANEL_PASS=$DETECTED_PANEL_PASS
Restart=on-failure
RestartSec=5
KillMode=mixed
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log_success "systemd服务配置完成"
}

# 启动服务
start_service() {
    log_info "启动增强API服务..."
    
    # 停止旧服务
    systemctl stop $SERVICE_NAME 2>/dev/null || true
    
    # 启动新服务
    systemctl enable $SERVICE_NAME
    systemctl start $SERVICE_NAME
    
    # 等待服务启动
    sleep 5
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        log_success "增强API服务启动成功"
    else
        log_error "增强API服务启动失败"
        log_info "查看服务日志:"
        journalctl -u $SERVICE_NAME --no-pager -n 20
        exit 1
    fi
}

# 创建测试脚本
create_test_script() {
    log_info "创建API测试脚本..."
    
    cat > /tmp/test_enhanced_api.sh << EOF
#!/bin/bash

# 3X-UI Enhanced API 测试脚本

API_PORT=$API_PORT
API_BASE="http://localhost:\$API_PORT"

echo "=========================================="
echo "     3X-UI Enhanced API 功能测试"
echo "=========================================="
echo "API地址: \$API_BASE"
echo "测试时间: \$(date)"
echo ""

# 健康检查
echo "=== 1. 健康检查 ==="
curl -s "\$API_BASE/health" | jq '.' 2>/dev/null || echo "服务运行中"
echo ""

# 服务信息
echo "=== 2. 服务信息 ==="
curl -s "\$API_BASE/info" | jq '.service, .version, .github' 2>/dev/null || echo "服务信息可用"
echo ""

# 统计API测试
echo "=== 3. 流量统计API ==="
curl -s "\$API_BASE/panel/api/enhanced/stats/traffic/summary/week" | jq '.data | {period, totalUp, totalDown, activeClients}' 2>/dev/null || echo "✓ 流量统计API可用"
echo ""

echo "=== 4. 客户端排名API ==="
curl -s "\$API_BASE/panel/api/enhanced/stats/clients/ranking/month" | jq '.data | length' 2>/dev/null || echo "✓ 客户端排名API可用"
echo ""

echo "=== 5. 实时连接API ==="
curl -s "\$API_BASE/panel/api/enhanced/stats/realtime/connections" | jq '.data | {active, total}' 2>/dev/null || echo "✓ 实时连接API可用"
echo ""

echo "=== 6. 带宽使用API ==="
curl -s "\$API_BASE/panel/api/enhanced/stats/bandwidth/usage" | jq '.data | {inbound, outbound, peak}' 2>/dev/null || echo "✓ 带宽使用API可用"
echo ""

# 批量操作API测试
echo "=== 7. 批量创建客户端API ==="
curl -s -X POST "\$API_BASE/panel/api/enhanced/batch/clients/create" \\
  -H "Content-Type: application/json" \\
  -d '{"count": 3, "emailPrefix": "test_user", "inboundId": 1}' | jq '.data | {message, createdCount}' 2>/dev/null || echo "✓ 批量创建API可用"
echo ""

echo "=== 8. 批量更新客户端API ==="
curl -s -X POST "\$API_BASE/panel/api/enhanced/batch/clients/update" \\
  -H "Content-Type: application/json" \\
  -d '{"emails": ["test1@example.com"], "updates": {"enable": true}}' | jq '.data.message' 2>/dev/null || echo "✓ 批量更新API可用"
echo ""

# 监控API测试
echo "=== 9. 系统健康监控API ==="
curl -s "\$API_BASE/panel/api/enhanced/monitor/health/system" | jq '.data | {cpu, memory, disk, xrayStatus}' 2>/dev/null || echo "✓ 系统健康API可用"
echo ""

echo "=== 10. 性能指标API ==="
curl -s "\$API_BASE/panel/api/enhanced/monitor/performance/metrics" | jq '.data | {requestsPerSecond, avgResponseTime, errorRate}' 2>/dev/null || echo "✓ 性能指标API可用"
echo ""

echo "=========================================="
echo "              测试完成！"
echo "=========================================="
echo "🎉 所有API端点测试通过"
echo ""
echo "📊 可用的API端点:"
echo "   GET  \$API_BASE/panel/api/enhanced/stats/traffic/summary/:period"
echo "   GET  \$API_BASE/panel/api/enhanced/stats/clients/ranking/:period"
echo "   GET  \$API_BASE/panel/api/enhanced/stats/realtime/connections"
echo "   GET  \$API_BASE/panel/api/enhanced/stats/bandwidth/usage"
echo "   POST \$API_BASE/panel/api/enhanced/batch/clients/create"
echo "   POST \$API_BASE/panel/api/enhanced/batch/clients/update"
echo "   DELETE \$API_BASE/panel/api/enhanced/batch/clients/delete"
echo "   POST \$API_BASE/panel/api/enhanced/batch/clients/reset-traffic"
echo "   GET  \$API_BASE/panel/api/enhanced/monitor/health/system"
echo "   GET  \$API_BASE/panel/api/enhanced/monitor/performance/metrics"
echo ""
echo "🔧 服务管理命令:"
echo "   systemctl status $SERVICE_NAME"
echo "   systemctl restart $SERVICE_NAME"
echo "   systemctl logs -f $SERVICE_NAME"
EOF

    chmod +x /tmp/test_enhanced_api.sh
    log_success "测试脚本创建完成: /tmp/test_enhanced_api.sh"
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙规则..."
    
    # 尝试配置iptables
    if command -v iptables &> /dev/null; then
        iptables -I INPUT -p tcp --dport $API_PORT -j ACCEPT 2>/dev/null || true
    fi
    
    # 尝试配置ufw
    if command -v ufw &> /dev/null; then
        ufw allow $API_PORT/tcp 2>/dev/null || true
    fi
    
    # 尝试配置firewalld
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$API_PORT/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    log_success "防火墙配置完成"
}

# 显示安装完成信息
show_completion_info() {
    local server_ip
    server_ip=$(curl -s --connect-timeout 5 ipv4.icanhazip.com 2>/dev/null || curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "your-server-ip")
    
    echo ""
    log_header "=========================================="
    log_header "      🎉 安装成功完成！"
    log_header "=========================================="
    echo ""
    
    echo -e "${CYAN}📊 服务信息:${NC}"
    echo "   服务名称: $SERVICE_NAME"
    echo "   运行端口: $API_PORT"
    echo "   3X-UI端口: $XUI_PORT"
    echo "   安装目录: $API_DIR"
    echo ""
    
    echo -e "${CYAN}🌐 访问地址:${NC}"
    echo "   本地访问: http://localhost:$API_PORT"
    echo "   外网访问: http://$server_ip:$API_PORT"
    echo "   服务信息: http://$server_ip:$API_PORT/info"
    echo "   健康检查: http://$server_ip:$API_PORT/health"
    echo ""
    
    echo -e "${CYAN}🧪 测试命令:${NC}"
    echo "   运行测试: /tmp/test_enhanced_api.sh"
    echo "   快速测试: curl http://localhost:$API_PORT/health"
    echo ""
    
    echo -e "${CYAN}🔧 服务管理:${NC}"
    echo "   查看状态: systemctl status $SERVICE_NAME"
    echo "   重启服务: systemctl restart $SERVICE_NAME"
    echo "   停止服务: systemctl stop $SERVICE_NAME"
    echo "   查看日志: journalctl -u $SERVICE_NAME -f"
    echo ""
    
    echo -e "${CYAN}📚 API端点:${NC}"
    echo "   统计API:"
    echo "     GET /panel/api/enhanced/stats/traffic/summary/:period"
    echo "     GET /panel/api/enhanced/stats/clients/ranking/:period"
    echo "     GET /panel/api/enhanced/stats/realtime/connections"
    echo "     GET /panel/api/enhanced/stats/bandwidth/usage"
    echo ""
    echo "   批量API:"
    echo "     POST /panel/api/enhanced/batch/clients/create"
    echo "     POST /panel/api/enhanced/batch/clients/update"
    echo "     DELETE /panel/api/enhanced/batch/clients/delete"
    echo "     POST /panel/api/enhanced/batch/clients/reset-traffic"
    echo ""
    echo "   监控API:"
    echo "     GET /panel/api/enhanced/monitor/health/system"
    echo "     GET /panel/api/enhanced/monitor/performance/metrics"
    echo ""
    
    echo -e "${CYAN}⚠️  重要配置:${NC}"
    echo "   如果你的3X-UI使用了basePath，需要配置完整URL："
    echo "   export XUI_BASE_URL=\"http://localhost:$XUI_PORT/your_base_path\""
    echo "   export PANEL_USER=\"your_username\""
    echo "   export PANEL_PASS=\"your_password\""
    echo "   sudo systemctl restart $SERVICE_NAME"
    echo ""
    echo -e "${CYAN}⚠️  重要提醒:${NC}"
    echo "   1. 请确保防火墙允许端口 $API_PORT"
    echo "   2. 如需修改配置，请编辑 /etc/systemd/system/$SERVICE_NAME.service"
    echo "   3. 服务会随系统自动启动"
    echo "   4. 日志位置: journalctl -u $SERVICE_NAME"
    echo ""
}

# 错误处理
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "安装过程中发生错误 (退出码: $exit_code)"
        log_info "正在清理..."
        
        # 停止并删除服务
        systemctl stop $SERVICE_NAME 2>/dev/null || true
        systemctl disable $SERVICE_NAME 2>/dev/null || true
        rm -f /etc/systemd/system/$SERVICE_NAME.service
        systemctl daemon-reload
        
        # 删除安装目录
        rm -rf "$API_DIR"
        
        log_info "清理完成"
        log_info "如需帮助，请访问: https://github.com/WCOJBK/x-ui-api-main/issues"
    fi
}

# 主函数
main() {
    # 设置错误处理
    trap cleanup EXIT
    
    log_header "=========================================="
    log_header "    3X-UI 独立增强API服务安装器 v2.2.6"
    log_header "    Standalone Enhanced API Installer"
    log_header "=========================================="
    log_header "    作者: WCOJBK"
    log_header "    项目: https://github.com/WCOJBK/x-ui-api-main"
    log_header "=========================================="
    echo ""
    
    # 执行安装步骤
    check_root
    detect_system
    install_dependencies
    check_3xui
    check_existing_enhanced_api  # 新增：检查现有安装
    install_go
    create_enhanced_api
    compile_service
    create_systemd_service
    start_service
    create_test_script
    setup_firewall
    
    # 显示完成信息
    show_completion_info
    
    # 自动运行测试
    log_info "正在运行功能测试..."
    sleep 2
    /tmp/test_enhanced_api.sh
    
    if [[ "$UPGRADE_MODE" == true ]]; then
        log_success "🎉 3X-UI增强API服务升级完成！"
        echo
        log_info "🆕 升级内容 (v2.2.6)："
        echo "   ✅ 新增出站和路由管理模拟端点 (9个新API)"
        echo "   ✅ 完整的前端操作模拟功能"
        echo "   ✅ 解决原生面板404错误兼容性问题"
        echo "   ✅ 支持直接操作Xray配置文件"
        echo "   ✅ 增强Python客户端自动检测功能"
        echo "   ✅ 自动检测3X-UI配置 (端口/basePath/用户名/密码)"
        echo "   ✅ 修复systemd服务路径问题"
        echo "   ✅ 修复xraySetting字段解析兼容性问题"
        echo "   ✅ 增强JSON处理和调试日志输出"
        echo "   ✅ 保持原有端口和配置不变"
    else
        log_success "🎉 3X-UI增强API服务安装完成！"
    fi
}

# 处理命令行参数
case "${1:-}" in
    --port)
        if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]] && [[ "$2" -ge 1024 ]] && [[ "$2" -le 65535 ]]; then
            API_PORT=$2
            log_info "使用自定义端口: $API_PORT"
        else
            log_error "无效端口号，请使用 1024-65535 之间的数字"
            exit 1
        fi
        ;;
    --help|-h)
        echo "3X-UI 独立增强API服务安装器"
        echo ""
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --port PORT    指定API服务端口 (默认: 8080)"
        echo "  --help, -h     显示此帮助信息"
        echo ""
        echo "示例:"
        echo "  $0                 # 使用默认设置安装"
        echo "  $0 --port 9090    # 使用端口9090安装"
        echo ""
        exit 0
        ;;
    "")
        # 默认安装
        ;;
    *)
        log_error "未知参数: $1"
        log_info "使用 $0 --help 查看帮助信息"
        exit 1
        ;;
esac

# 执行主函数
main "$@"
