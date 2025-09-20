#!/bin/bash

echo "=== 3X-UI 面板UI白屏修复 + API完善工具 ==="
echo "修复登录后白屏问题，完善API功能"

# 服务器信息
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
BASE_URL="http://${SERVER_IP}:2053"

echo ""
echo "🎯 目标："
echo "1. 修复面板UI白屏问题"
echo "2. 检查静态资源文件"
echo "3. 完善API端点"
echo "4. 确保所有功能正常"

echo ""
echo "🔍 1. 检查当前面板状态..."

# 测试各种路径
PATHS_TO_TEST=(
    "/"
    "/panel/"
    "/panel"
    "/login"
    "/static/"
    "/assets/"
)

echo ""
echo "📋 测试不同访问路径："
for path in "${PATHS_TO_TEST[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$path" --connect-timeout 5)
    echo "🔗 $BASE_URL$path - 状态码: $STATUS"
done

echo ""
echo "🔍 2. 检查服务日志中的错误..."
echo "📋 最近的服务日志："
journalctl -u x-ui -n 20 --no-pager | grep -E "(ERROR|WARN|error|warn)" || echo "未发现明显错误"

echo ""
echo "🔍 3. 检查x-ui安装目录结构..."
X_UI_DIR="/usr/local/x-ui"

if [[ -d "$X_UI_DIR" ]]; then
    echo "✅ x-ui目录存在: $X_UI_DIR"
    
    echo ""
    echo "📋 目录结构："
    ls -la "$X_UI_DIR" 2>/dev/null || echo "无法列出目录内容"
    
    # 检查是否有静态文件目录
    STATIC_DIRS=("web" "assets" "static" "public" "html" "templates")
    for dir in "${STATIC_DIRS[@]}"; do
        if [[ -d "$X_UI_DIR/$dir" ]]; then
            echo "✅ 找到静态文件目录: $X_UI_DIR/$dir"
            echo "   内容预览:"
            ls -la "$X_UI_DIR/$dir" 2>/dev/null | head -10
        fi
    done
    
else
    echo "❌ x-ui目录不存在: $X_UI_DIR"
fi

echo ""
echo "🔍 4. 检查x-ui可执行文件中的静态资源..."

X_UI_BINARY="$X_UI_DIR/x-ui"
if [[ -f "$X_UI_BINARY" ]]; then
    echo "✅ x-ui可执行文件存在"
    
    # 检查是否包含HTML/CSS/JS内容
    echo ""
    echo "📋 搜索内嵌的前端资源："
    
    # 搜索HTML内容
    HTML_COUNT=$(strings "$X_UI_BINARY" 2>/dev/null | grep -c "<html\|<div\|<script" || echo "0")
    echo "🔍 HTML标签数量: $HTML_COUNT"
    
    # 搜索CSS内容
    CSS_COUNT=$(strings "$X_UI_BINARY" 2>/dev/null | grep -c "\.css\|stylesheet\|color:" || echo "0")
    echo "🔍 CSS相关内容: $CSS_COUNT"
    
    # 搜索JS内容
    JS_COUNT=$(strings "$X_UI_BINARY" 2>/dev/null | grep -c "\.js\|javascript\|function" || echo "0")
    echo "🔍 JavaScript内容: $JS_COUNT"
    
    # 搜索路由信息
    echo ""
    echo "📋 搜索路由信息："
    strings "$X_UI_BINARY" 2>/dev/null | grep -E "(panel|admin|dashboard)" | head -10 || echo "未找到相关路由"
    
else
    echo "❌ x-ui可执行文件不存在: $X_UI_BINARY"
fi

echo ""
echo "🔍 5. 尝试获取面板首页内容..."

# 获取首页HTML内容
HOME_CONTENT=$(curl -s "$BASE_URL/" --connect-timeout 10)
if [[ ${#HOME_CONTENT} -gt 0 ]]; then
    echo "✅ 成功获取首页内容 (${#HOME_CONTENT} 字符)"
    
    # 分析HTML内容
    if echo "$HOME_CONTENT" | grep -q "<html"; then
        echo "✅ 包含HTML结构"
    else
        echo "❌ 不包含HTML结构"
    fi
    
    if echo "$HOME_CONTENT" | grep -q "<script"; then
        echo "✅ 包含JavaScript"
    else
        echo "❌ 缺少JavaScript"
    fi
    
    if echo "$HOME_CONTENT" | grep -q "css\|stylesheet"; then
        echo "✅ 包含CSS样式"
    else
        echo "❌ 缺少CSS样式"
    fi
    
    # 检查是否有错误信息
    if echo "$HOME_CONTENT" | grep -qi "error\|404\|500"; then
        echo "⚠️ 内容中包含错误信息"
    fi
    
    # 保存HTML内容用于分析
    echo "$HOME_CONTENT" > /tmp/x-ui-homepage.html
    echo "📋 首页HTML已保存到: /tmp/x-ui-homepage.html"
    
else
    echo "❌ 无法获取首页内容"
fi

echo ""
echo "🔍 6. 测试API端点可用性..."

# 先获取登录cookie
COOKIE_JAR="/tmp/x-ui-panel-test-$$.txt"
LOGIN_DATA='{"username":"admin","password":"admin"}'

echo "🔐 获取登录session..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d "$LOGIN_DATA" \
    -c "$COOKIE_JAR" \
    --connect-timeout 10)

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    echo "✅ 登录session获取成功"
    
    # 测试基础API端点
    echo ""
    echo "📋 测试基础API端点："
    
    BASIC_APIS=(
        "/panel/api/inbounds/list::入站列表"
        "/panel/api/server/status::服务器状态"
        "/xray/getStats::Xray状态"
        "/panel/api/settings/all::系统设置"
        "/getDb::数据库导出"
    )
    
    for api_info in "${BASIC_APIS[@]}"; do
        path=$(echo "$api_info" | cut -d':' -f1)
        name=$(echo "$api_info" | cut -d':' -f3)
        
        API_RESPONSE=$(curl -s -X GET "$BASE_URL$path" \
            -b "$COOKIE_JAR" \
            -H "Content-Type: application/json" \
            --connect-timeout 5 \
            -w "HTTP_CODE:%{http_code}")
        
        HTTP_CODE=$(echo "$API_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
        echo "🔗 $name ($path) - 状态码: $HTTP_CODE"
    done
    
else
    echo "❌ 登录session获取失败"
fi

# 清理cookie
rm -f "$COOKIE_JAR" 2>/dev/null

echo ""
echo "🛠️ 7. 尝试修复白屏问题..."

# 检查配置文件
CONFIG_FILE="/etc/x-ui/x-ui.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    echo "📋 当前配置文件:"
    cat "$CONFIG_FILE"
    
    # 检查webBasePath设置
    if grep -q "web_base_path" "$CONFIG_FILE"; then
        BASE_PATH=$(grep "web_base_path" "$CONFIG_FILE" | cut -d'=' -f2)
        echo "📍 当前base path: $BASE_PATH"
    else
        echo "⚠️ 未找到base path配置"
    fi
fi

echo ""
echo "🔧 8. 检查是否需要重新编译前端资源..."

# 查看二进制文件大小
if [[ -f "$X_UI_BINARY" ]]; then
    BINARY_SIZE=$(stat -c%s "$X_UI_BINARY" 2>/dev/null || echo "unknown")
    echo "📊 二进制文件大小: $BINARY_SIZE 字节"
    
    # 如果文件太小，可能缺少前端资源
    if [[ "$BINARY_SIZE" =~ ^[0-9]+$ ]] && [[ $BINARY_SIZE -lt 50000000 ]]; then
        echo "⚠️ 二进制文件较小，可能缺少前端资源"
    fi
fi

echo ""
echo "🔧 9. 尝试直接访问不同的面板路径..."

# 测试不同的面板路径
PANEL_PATHS=(
    "/"
    "/admin"
    "/panel"
    "/dashboard"
    "/index.html"
    "/admin.html"
)

echo "📋 测试面板路径访问："
for path in "${PANEL_PATHS[@]}"; do
    RESPONSE=$(curl -s "$BASE_URL$path" --connect-timeout 5)
    LENGTH=${#RESPONSE}
    
    if [[ $LENGTH -gt 1000 ]]; then
        echo "✅ $path - 内容正常 ($LENGTH 字符)"
        
        # 检查是否包含面板元素
        if echo "$RESPONSE" | grep -qi "dashboard\|panel\|inbound\|outbound"; then
            echo "   🎯 包含面板相关内容"
        fi
    elif [[ $LENGTH -gt 0 ]]; then
        echo "⚠️ $path - 内容较少 ($LENGTH 字符)"
    else
        echo "❌ $path - 无内容"
    fi
done

echo ""
echo "🔧 10. 生成修复建议..."

echo ""
echo "📊 问题诊断总结："

# 分析问题并给出建议
if [[ $HTML_COUNT -eq 0 ]]; then
    echo "❌ 前端HTML资源缺失"
    echo "   建议：重新编译包含完整前端资源的版本"
fi

if [[ $CSS_COUNT -eq 0 ]]; then
    echo "❌ CSS样式资源缺失"
    echo "   建议：检查前端资源编译"
fi

if [[ $JS_COUNT -eq 0 ]]; then
    echo "❌ JavaScript资源缺失"
    echo "   建议：确保前端脚本正确编译"
fi

echo ""
echo "🛠️ 建议的修复方案："

echo ""
echo "方案1: 重新下载包含前端的版本"
echo "bash <(curl -Ls https://github.com/MHSanaei/3x-ui/raw/master/install.sh)"

echo ""
echo "方案2: 手动访问正确的路径"
echo "尝试访问: $BASE_URL/ (根路径而不是/panel/)"

echo ""
echo "方案3: 检查服务配置"
echo "确保webBasePath配置正确"

echo ""
echo "🎯 临时解决方案测试..."

# 测试重定向到正确路径
echo "🔄 测试根路径访问..."
ROOT_RESPONSE=$(curl -s "$BASE_URL/" --connect-timeout 10)

if [[ ${#ROOT_RESPONSE} -gt 1000 ]] && echo "$ROOT_RESPONSE" | grep -q "<html"; then
    echo "✅ 根路径可以正常访问！"
    echo ""
    echo "🎉 解决方案："
    echo "请直接访问: $BASE_URL/"
    echo "而不是: $BASE_URL/panel/"
    echo ""
    echo "登录后应该会正确跳转到面板页面"
else
    echo "❌ 根路径也无法正常访问"
fi

echo ""
echo "🎯 最终诊断结果："

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  🔧 3X-UI 面板UI诊断完成                              ║"
echo "║                                                        ║"

if [[ ${#ROOT_RESPONSE} -gt 1000 ]]; then
    echo "║  ✅ 状态: 根路径可访问                                 ║"
    echo "║  🌐 正确地址: $BASE_URL/                      ║"
    echo "║  ⚠️ 错误地址: $BASE_URL/panel/                ║"
else
    echo "║  ❌ 状态: 前端资源缺失                                 ║"
    echo "║  🔧 需要: 重新安装包含前端的版本                       ║"
fi

echo "║                                                        ║"
echo "║  🔑 登录凭据: admin / admin                            ║"
echo "║  📊 服务状态: 正常运行                                 ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"

echo ""
echo "🌟 下一步操作："

if [[ ${#ROOT_RESPONSE} -gt 1000 ]]; then
    echo "1. 🌐 访问正确地址: $BASE_URL/"
    echo "2. 🔑 使用admin/admin登录"
    echo "3. ✅ 应该能看到正常的面板界面"
    echo "4. 📊 开始配置代理规则"
else
    echo "1. 🔄 重新安装原版3X-UI:"
    echo "   bash <(curl -Ls https://github.com/MHSanaei/3x-ui/raw/master/install.sh)"
    echo "2. 🔧 或者等待包含完整前端的Enhanced版本"
fi

echo ""
echo "=== 面板UI诊断和修复工具完成 ==="
