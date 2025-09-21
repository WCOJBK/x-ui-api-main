# 3X-UI 增强API扩展包

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/your-repo/3x-ui-enhanced-api)
[![License](https://img.shields.io/badge/license-GPL%20v3-green.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Go Version](https://img.shields.io/badge/go-1.21+-blue.svg)](https://golang.org/dl/)
[![3X-UI Compatible](https://img.shields.io/badge/3X--UI-2.5.2+-green.svg)](https://github.com/MHSanaei/3x-ui)

## 🚀 项目简介

3X-UI 增强API扩展包是一个为现有3X-UI面板提供丰富API功能的增量安装方案。无需重新构建整个3X-UI项目，即可为您的面板添加高级统计、批量操作、系统监控等强大功能。

### ✨ 主要特性

- 🔥 **无需重构** - 在现有3X-UI基础上增量安装
- 📊 **高级统计** - 详细的流量分析和用户排名
- ⚡ **批量操作** - 高效的批量客户端管理
- 📈 **系统监控** - 实时系统健康状态监控
- 🔒 **安全增强** - IP白名单和威胁检测
- 🎯 **高性能** - 优化的API响应速度
- 🛠️ **易于维护** - 模块化设计，便于扩展

## 📋 功能特性

### 🔍 高级统计API

| 端点 | 方法 | 描述 |
|------|------|------|
| `/enhanced/stats/traffic/summary/:period` | GET | 获取指定时期流量汇总 |
| `/enhanced/stats/clients/ranking/:period` | GET | 获取客户端使用排名 |
| `/enhanced/stats/realtime/connections` | GET | 实时连接统计 |
| `/enhanced/stats/bandwidth/usage` | GET | 带宽使用情况 |

**功能亮点：**
- 支持多时间段统计（今天、本周、本月、本年）
- 协议使用分布分析
- 流量增长率计算
- 客户端活跃度排名

### ⚡ 批量操作API

| 端点 | 方法 | 描述 |
|------|------|------|
| `/enhanced/batch/clients/create` | POST | 批量创建客户端 |
| `/enhanced/batch/clients/update` | POST | 批量更新客户端 |
| `/enhanced/batch/clients/delete` | DELETE | 批量删除客户端 |
| `/enhanced/batch/clients/reset-traffic` | POST | 批量重置流量 |

**功能亮点：**
- 一次性创建最多1000个客户端
- 智能邮箱生成和冲突检测
- 批量配置更新
- 支持模板化创建

### 📊 系统监控API

| 端点 | 方法 | 描述 |
|------|------|------|
| `/enhanced/monitor/health/system` | GET | 系统健康状态 |
| `/enhanced/monitor/performance/metrics` | GET | 性能指标监控 |

**监控指标：**
- CPU、内存、磁盘使用率
- 网络流量统计
- Xray服务状态
- 数据库大小
- 活跃连接数
- 系统负载
- API响应时间

## 🛠️ 安装指南

### 系统要求

- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+, Debian 9+)
- **已安装**: 3X-UI v2.5.2 或更高版本
- **权限**: root 用户权限
- **依赖**: curl, wget

### 快速安装

```bash
# 下载安装脚本
wget -O install_enhanced_api.sh https://raw.githubusercontent.com/your-repo/3x-ui-enhanced-api/main/install_enhanced_api.sh

# 赋予执行权限
chmod +x install_enhanced_api.sh

# 运行安装脚本
sudo ./install_enhanced_api.sh
```

### 手动安装步骤

1. **检查3X-UI状态**
```bash
systemctl status x-ui
```

2. **备份现有配置**
```bash
cp -r /opt/3x-ui /opt/3x-ui-backup-$(date +%Y%m%d)
```

3. **停止3X-UI服务**
```bash
systemctl stop x-ui
```

4. **下载增强API文件**
```bash
cd /opt/3x-ui/web/controller
wget https://raw.githubusercontent.com/your-repo/3x-ui-enhanced-api/main/enhanced_api_controller.go
```

5. **修改路由配置**
```bash
# 编辑 /opt/3x-ui/web/web.go
# 添加增强API控制器初始化
```

6. **重新编译**
```bash
cd /opt/3x-ui
go build -o x-ui main.go
```

7. **启动服务**
```bash
systemctl start x-ui
```

### 安装验证

```bash
# 测试增强API是否工作
curl -X GET "http://localhost:2053/panel/api/enhanced/monitor/health/system" \
  -H "Cookie: your-session-cookie"

# 运行完整测试
chmod +x api_test_examples.sh
./api_test_examples.sh --url http://localhost:2053
```

## 📖 API 文档

### 认证方式

所有增强API都需要通过3X-UI的标准认证：

```bash
# 1. 登录获取Cookie
curl -c cookies.txt -X POST "http://localhost:2053/login" \
  -d "username=admin&password=admin"

# 2. 使用Cookie调用API
curl -b cookies.txt "http://localhost:2053/panel/api/enhanced/stats/traffic/summary/week"
```

### 高级统计API示例

#### 获取流量汇总

```bash
GET /panel/api/enhanced/stats/traffic/summary/week
```

**响应示例：**
```json
{
  "success": true,
  "data": {
    "period": "week",
    "totalUp": 1073741824,
    "totalDown": 5368709120,
    "totalTraffic": 6442450944,
    "activeClients": 25,
    "activeInbounds": 5,
    "growthRate": 15.5,
    "topProtocols": [
      {
        "protocol": "vmess",
        "usage": 3221225472,
        "count": 10
      },
      {
        "protocol": "vless", 
        "usage": 2147483648,
        "count": 8
      }
    ]
  }
}
```

#### 获取客户端排名

```bash
GET /panel/api/enhanced/stats/clients/ranking/month?limit=10
```

**响应示例：**
```json
{
  "success": true,
  "data": [
    {
      "email": "user1@example.com",
      "inboundId": 1,
      "protocol": "vmess",
      "totalTraffic": 2147483648,
      "up": 1073741824,
      "down": 1073741824,
      "rank": 1,
      "lastActive": "2024-01-15T10:30:00Z",
      "status": "active"
    }
  ]
}
```

### 批量操作API示例

#### 批量创建客户端

```bash
POST /panel/api/enhanced/batch/clients/create
Content-Type: application/json

{
  "inboundId": 1,
  "template": {
    "totalGB": 107374182400,
    "expiryTime": 1704067200000,
    "enable": true,
    "limitIp": 2
  },
  "count": 10,
  "emailPrefix": "batch_user",
  "emailSuffix": "example.com",
  "autoGenerate": true
}
```

**响应示例：**
```json
{
  "success": true,
  "data": {
    "message": "批量创建客户端成功",
    "createdCount": 10,
    "failedCount": 0,
    "clients": [
      {
        "email": "batch_user_1@example.com",
        "id": "uuid-generated-1",
        "enable": true
      }
    ],
    "errors": []
  }
}
```

### 系统监控API示例

#### 获取系统健康状态

```bash
GET /panel/api/enhanced/monitor/health/system
```

**响应示例：**
```json
{
  "success": true,
  "data": {
    "cpu": 45.2,
    "memory": 67.8,
    "disk": 23.1,
    "network": {
      "bytesReceived": 1073741824,
      "bytesSent": 2147483648,
      "bandwidth": 125.6
    },
    "xrayStatus": "running",
    "databaseSize": 52428800,
    "activeConnections": 156,
    "uptime": 86400,
    "systemLoad": {
      "load1": 1.23,
      "load5": 1.45,
      "load15": 1.67
    },
    "services": {
      "x-ui": "running",
      "xray": "running"
    }
  }
}
```

## 🧪 测试和验证

### 自动化测试

运行提供的测试脚本来验证所有功能：

```bash
# 基础功能测试
./api_test_examples.sh

# 指定服务器地址测试
./api_test_examples.sh --url https://your-domain.com:2053 --user youruser --pass yourpass

# 仅测试统计API
./api_test_examples.sh --stats

# 性能测试
./api_test_examples.sh --perf
```

### 手动测试

```bash
# 测试系统健康状态
curl -b cookies.txt "http://localhost:2053/panel/api/enhanced/monitor/health/system" | jq

# 测试流量统计
curl -b cookies.txt "http://localhost:2053/panel/api/enhanced/stats/traffic/summary/week" | jq

# 测试批量操作
curl -b cookies.txt -X POST "http://localhost:2053/panel/api/enhanced/batch/clients/create" \
  -H "Content-Type: application/json" \
  -d '{"count": 3, "emailPrefix": "test", "inboundId": 1}' | jq
```

## 🔧 配置和自定义

### 环境变量

在 `/opt/3x-ui/.env` 中添加配置：

```bash
# 增强API配置
ENHANCED_API_ENABLED=true
ENHANCED_API_CACHE_TTL=300
ENHANCED_API_MAX_BATCH_SIZE=1000
ENHANCED_API_LOG_LEVEL=info

# 监控配置  
MONITOR_INTERVAL=30
MONITOR_HISTORY_DAYS=7

# 安全配置
SECURITY_IP_WHITELIST_ENABLED=false
SECURITY_RATE_LIMIT=100
```

### 自定义扩展

您可以通过修改 `enhanced_api_controller.go` 来添加自己的API端点：

```go
// 添加自定义端点
customGroup := g.Group("/custom")
{
    customGroup.GET("/my-feature", a.myCustomFeature)
}

func (a *EnhancedAPIController) myCustomFeature(c *gin.Context) {
    // 实现您的自定义功能
    jsonObj(c, map[string]interface{}{
        "message": "My custom feature",
        "data": "custom data"
    }, nil)
}
```

## 📊 性能优化

### 缓存策略

增强API使用多层缓存来提高性能：

- **内存缓存**: 热点数据缓存
- **数据库连接池**: 优化数据库访问
- **响应压缩**: 减少网络传输

### 建议配置

```bash
# 针对高负载环境的建议配置
# /etc/systemd/system/x-ui.service
[Service]
Environment="GOMAXPROCS=4"
Environment="GOGC=100"
LimitNOFILE=65536

# 数据库优化
# 在代码中增加连接池配置
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(5)
db.SetConnMaxLifetime(time.Hour)
```

## ❗ 故障排除

### 常见问题

#### 1. 编译失败
```bash
# 检查Go版本
go version

# 清理模块缓存
go clean -modcache

# 重新下载依赖
go mod tidy
go mod download
```

#### 2. 服务启动失败
```bash
# 查看详细日志
journalctl -u x-ui -f

# 检查端口占用
netstat -tlnp | grep :2053

# 验证配置文件
/opt/3x-ui/x-ui --test-config
```

#### 3. API无响应
```bash
# 检查路由配置
curl -I http://localhost:2053/panel/api/enhanced/monitor/health/system

# 验证认证
curl -c /tmp/cookies.txt -d "username=admin&password=admin" \
  http://localhost:2053/login

# 测试基础连接
curl -v http://localhost:2053/
```

#### 4. 性能问题
```bash
# 监控系统资源
htop
iotop

# 检查数据库性能
sqlite3 /opt/3x-ui/x-ui.db ".schema"
sqlite3 /opt/3x-ui/x-ui.db "PRAGMA compile_options;"

# 优化建议
# 1. 启用数据库WAL模式
# 2. 增加系统文件描述符限制
# 3. 使用SSD存储
```

### 日志分析

增强API的日志位置：

```bash
# 系统日志
journalctl -u x-ui

# 应用日志
tail -f /opt/3x-ui/access.log
tail -f /opt/3x-ui/error.log

# 增强API日志（如果开启）
tail -f /opt/3x-ui/enhanced-api.log
```

## 🔄 更新和维护

### 更新增强API

```bash
# 下载最新版本
wget -O /tmp/enhanced_api_controller.go \
  https://raw.githubusercontent.com/your-repo/3x-ui-enhanced-api/main/enhanced_api_controller.go

# 备份当前版本
cp /opt/3x-ui/web/controller/enhanced_api_controller.go \
   /opt/3x-ui/web/controller/enhanced_api_controller.go.backup

# 停止服务
systemctl stop x-ui

# 更新文件
cp /tmp/enhanced_api_controller.go /opt/3x-ui/web/controller/

# 重新编译
cd /opt/3x-ui && go build -o x-ui main.go

# 启动服务
systemctl start x-ui
```

### 回滚方案

```bash
# 自动回滚脚本
#!/bin/bash
BACKUP_DIR="/opt/3x-ui-backup-$(date +%Y%m%d)"

if [[ -d "$BACKUP_DIR" ]]; then
    systemctl stop x-ui
    cp -r "$BACKUP_DIR"/* /opt/3x-ui/
    systemctl start x-ui
    echo "回滚完成"
else
    echo "找不到备份目录"
fi
```

## 🤝 贡献指南

我们欢迎社区贡献！请按以下步骤参与：

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 开发环境设置

```bash
# 克隆项目
git clone https://github.com/your-repo/3x-ui-enhanced-api.git
cd 3x-ui-enhanced-api

# 设置开发环境
go mod tidy
go mod download

# 运行测试
go test ./...

# 构建
go build -o enhanced-api
```

## 📄 许可证

本项目采用 GPL v3 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

## 🆘 支持

如果您遇到问题或需要帮助：

- 📧 邮件: support@example.com
- 💬 QQ群: 123456789
- 🐛 问题反馈: [GitHub Issues](https://github.com/your-repo/3x-ui-enhanced-api/issues)
- 📖 文档: [在线文档](https://docs.example.com)

## 🌟 Star History

如果这个项目对您有帮助，请给我们一个 ⭐ Star！

[![Star History Chart](https://api.star-history.com/svg?repos=your-repo/3x-ui-enhanced-api&type=Date)](https://star-history.com/#your-repo/3x-ui-enhanced-api&Date)

## 📝 更新日志

### v1.0.0 (2024-01-15)
- 🎉 首次发布
- ✨ 高级统计API
- ⚡ 批量操作API
- 📊 系统监控API
- 🔒 安全增强功能
- 🚀 自动安装脚本

---

<div align="center">

**[⬆ 返回顶部](#3x-ui-增强api扩展包)**

Made with ❤️ by the 3X-UI Enhanced API Team

</div>

