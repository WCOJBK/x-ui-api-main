#!/bin/bash

echo "=== 3X-UI 数据库查找和初始化工具 ==="
echo "查找或创建x-ui数据库文件"

# 可能的数据库位置
POSSIBLE_DB_PATHS=(
    "/usr/local/x-ui/x-ui.db"
    "/etc/x-ui/x-ui.db"
    "/var/lib/x-ui/x-ui.db"
    "/opt/x-ui/x-ui.db"
    "/usr/local/x-ui/bin/x-ui.db"
    "/root/x-ui.db"
)

echo ""
echo "🔍 1. 查找现有数据库文件..."

FOUND_DB=""
for db_path in "${POSSIBLE_DB_PATHS[@]}"; do
    if [[ -f "$db_path" ]]; then
        echo "✅ 找到数据库: $db_path"
        FOUND_DB="$db_path"
        break
    else
        echo "❌ 不存在: $db_path"
    fi
done

if [[ -n "$FOUND_DB" ]]; then
    echo ""
    echo "✅ 使用现有数据库: $FOUND_DB"
    DB_PATH="$FOUND_DB"
else
    echo ""
    echo "⚠️ 未找到现有数据库，需要创建新的"
    
    # 选择默认位置
    DB_PATH="/usr/local/x-ui/x-ui.db"
    echo "📍 将在以下位置创建数据库: $DB_PATH"
fi

echo ""
echo "🔍 2. 检查x-ui服务进程..."

# 查看x-ui进程信息
X_UI_PROCESSES=$(ps aux | grep x-ui | grep -v grep)
if [[ -n "$X_UI_PROCESSES" ]]; then
    echo "✅ x-ui进程正在运行:"
    echo "$X_UI_PROCESSES"
    
    # 查看进程使用的文件
    X_UI_PID=$(pgrep x-ui | head -1)
    if [[ -n "$X_UI_PID" ]]; then
        echo ""
        echo "🔍 进程 $X_UI_PID 打开的文件:"
        lsof -p "$X_UI_PID" 2>/dev/null | grep -E "\\.db$" || echo "未找到数据库文件"
    fi
else
    echo "❌ x-ui进程未运行"
fi

echo ""
echo "🔍 3. 检查配置文件..."

CONFIG_FILE="/etc/x-ui/x-ui.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    echo "✅ 配置文件存在: $CONFIG_FILE"
    
    # 查看配置文件中的数据库路径
    echo "📋 配置文件内容:"
    cat "$CONFIG_FILE" 2>/dev/null || echo "读取配置文件失败"
else
    echo "❌ 配置文件不存在: $CONFIG_FILE"
fi

echo ""
echo "🔍 4. 查找系统中所有的x-ui.db文件..."
find / -name "x-ui.db" -type f 2>/dev/null | head -10

echo ""
echo "🛠️ 5. 停止服务进行数据库操作..."
systemctl stop x-ui 2>/dev/null || true
sleep 2

echo ""
echo "🔧 6. 确保目录存在..."
mkdir -p "$(dirname "$DB_PATH")"
mkdir -p "/etc/x-ui"

if [[ ! -f "$DB_PATH" ]]; then
    echo ""
    echo "🆕 7. 创建新的数据库..."
    
    # 创建数据库和表结构
    sqlite3 "$DB_PATH" << 'EOF'
-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    login_secret TEXT DEFAULT ''
);

-- 创建设置表
CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL
);

-- 创建入站表
CREATE TABLE IF NOT EXISTS inbounds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    up INTEGER DEFAULT 0,
    down INTEGER DEFAULT 0,
    total INTEGER DEFAULT 0,
    remark TEXT DEFAULT '',
    enable INTEGER DEFAULT 1,
    expiry_time INTEGER DEFAULT 0,
    listen TEXT DEFAULT '',
    port INTEGER DEFAULT 0,
    protocol TEXT DEFAULT '',
    settings TEXT DEFAULT '',
    stream_settings TEXT DEFAULT '',
    tag TEXT DEFAULT '',
    sniffing TEXT DEFAULT ''
);

-- 插入默认用户
INSERT OR REPLACE INTO users (id, username, password, login_secret) 
VALUES (1, 'admin', 'admin', '');

-- 插入基本设置
INSERT OR REPLACE INTO settings (key, value) VALUES ('secretEnable', 'false');
INSERT OR REPLACE INTO settings (key, value) VALUES ('webListen', '');
INSERT OR REPLACE INTO settings (key, value) VALUES ('webPort', '2053');
INSERT OR REPLACE INTO settings (key, value) VALUES ('webCertFile', '');
INSERT OR REPLACE INTO settings (key, value) VALUES ('webKeyFile', '');
INSERT OR REPLACE INTO settings (key, value) VALUES ('webBasePath', '/');
INSERT OR REPLACE INTO settings (key, value) VALUES ('sessionMaxAge', '60');

EOF
    
    if [[ $? -eq 0 ]]; then
        echo "✅ 数据库创建成功"
    else
        echo "❌ 数据库创建失败"
        exit 1
    fi
else
    echo ""
    echo "📋 7. 修复现有数据库..."
    
    # 确保表结构存在
    sqlite3 "$DB_PATH" << 'EOF'
-- 确保用户表存在
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    login_secret TEXT DEFAULT ''
);

-- 确保设置表存在
CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL
);
EOF

    # 重置用户和设置
    sqlite3 "$DB_PATH" << 'EOF'
-- 重置用户
DELETE FROM users;
INSERT INTO users (id, username, password, login_secret) VALUES (1, 'admin', 'admin', '');

-- 禁用secret功能
DELETE FROM settings WHERE key IN ('secret', 'secretEnable', 'loginSecret');
INSERT INTO settings (key, value) VALUES ('secretEnable', 'false');
EOF

    echo "✅ 数据库修复完成"
fi

echo ""
echo "🔍 8. 验证数据库内容..."

echo "📋 用户表:"
sqlite3 "$DB_PATH" "SELECT id, username, password, login_secret FROM users;" 2>/dev/null || echo "查询用户表失败"

echo ""
echo "📋 设置表:"
sqlite3 "$DB_PATH" "SELECT key, value FROM settings;" 2>/dev/null || echo "查询设置表失败"

echo ""
echo "🔧 9. 创建配置文件..."

# 创建或更新配置文件
cat > "/etc/x-ui/x-ui.conf" << EOF
# x-ui configuration file
# Database path
database_path=$DB_PATH

# Web settings
web_listen=
web_port=2053
web_cert_file=
web_key_file=
web_base_path=/

# Session settings
session_max_age=60

# Security settings
secret_enable=false
EOF

echo "✅ 配置文件已创建"

echo ""
echo "🚀 10. 重新启动服务..."
systemctl start x-ui

echo ""
echo "⏳ 等待服务启动..."
sleep 5

echo ""
echo "🔍 11. 验证服务状态..."
if systemctl is-active --quiet x-ui; then
    echo "✅ x-ui服务启动成功"
    
    # 获取服务器IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "103.189.140.156")
    
    echo ""
    echo "🧪 12. 测试登录功能..."
    
    BASE_URL="http://${SERVER_IP}:2053"
    
    # 测试面板访问
    PANEL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/" --connect-timeout 10)
    echo "📊 面板访问状态码: $PANEL_RESPONSE"
    
    if [[ "$PANEL_RESPONSE" == "200" ]]; then
        echo "✅ 面板访问正常"
        
        # 测试登录
        LOGIN_DATA='{"username":"admin","password":"admin"}'
        LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
            -H "Content-Type: application/json" \
            -d "$LOGIN_DATA" \
            --connect-timeout 10)
        
        echo ""
        echo "🔐 登录测试结果:"
        echo "📋 响应: $LOGIN_RESPONSE"
        
        if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
            echo "✅ 登录成功！"
        else
            echo "⚠️ 登录失败，但面板可访问"
        fi
        
    else
        echo "⚠️ 面板访问异常"
    fi
    
    echo ""
    echo "📋 服务状态详情:"
    systemctl status x-ui --no-pager -l
    
else
    echo "❌ x-ui服务启动失败"
    echo ""
    echo "📋 错误日志:"
    journalctl -u x-ui -n 10 --no-pager
fi

echo ""
echo "🎯 最终结果总结:"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  📊 3X-UI 数据库初始化和修复完成                      ║"
echo "║                                                        ║"
echo "║  📍 数据库位置: $DB_PATH"
echo "║  🔧 配置文件: /etc/x-ui/x-ui.conf                      ║"

if systemctl is-active --quiet x-ui; then
    echo "║  ✅ 服务状态: 正常运行                                 ║"
    echo "║                                                        ║"
    echo "║  🌐 面板地址: $BASE_URL/                      ║"
    echo "║  🔑 登录凭据: admin / admin                            ║"
    echo "║  🔐 Secret: 已禁用                                    ║"
else
    echo "║  ❌ 服务状态: 启动失败                                 ║"
fi

echo "║                                                        ║"
echo "║  📋 请通过浏览器访问面板进行测试                       ║"
echo "╚════════════════════════════════════════════════════════╝"

echo ""
echo "🌟 下一步操作:"
echo "1. 🌐 浏览器访问: $BASE_URL/"
echo "2. 🔑 使用凭据登录: admin / admin"
echo "3. ⚙️ 在面板中修改用户名密码(可选)"
echo "4. 📊 开始配置入站和代理规则"

echo ""
echo "=== 数据库查找和初始化工具完成 ==="
