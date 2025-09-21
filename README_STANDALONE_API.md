# 🚀 3X-UI 独立增强API服务

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/WCOJBK/x-ui-api-main)
[![License](https://img.shields.io/badge/license-GPL%20v3-green.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Go Version](https://img.shields.io/badge/go-1.21+-blue.svg)](https://golang.org/dl/)
[![3X-UI Compatible](https://img.shields.io/badge/3X--UI-all%20versions-green.svg)](https://github.com/MHSanaei/3x-ui)

## 💡 **项目简介**

这是一个专为**二进制安装版本3X-UI**设计的独立增强API服务。无需修改现有3X-UI源码，通过独立服务的方式为您的3X-UI面板添加强大的增强功能。

### ✨ **核心特性**

- 🔥 **完全独立** - 不修改现有3X-UI，零风险安装
- 📊 **数据集成** - 直接读取3X-UI数据库，提供真实数据
- ⚡ **高性能** - Go语言开发，轻量级高并发
- 🎯 **易管理** - systemd服务管理，开机自启
- 🛡️ **安全可靠** - 完整的错误处理和清理机制
- 🌐 **跨平台** - 支持x64、ARM64等多种架构

## 🎯 **适用场景**

✅ **二进制安装的3X-UI** (官方一键脚本安装)  
✅ **Docker部署的3X-UI**  
✅ **不想修改源码的用户**  
✅ **需要保持原版稳定性**  

## 📊 **功能特性**

### 🔍 **高级统计API**

| 端点 | 方法 | 描述 | 数据来源 |
|------|------|------|----------|
| `/stats/traffic/summary/:period` | GET | 流量汇总统计 | 真实数据库 |
| `/stats/clients/ranking/:period` | GET | 客户端排名 | 真实数据库 |
| `/stats/realtime/connections` | GET | 实时连接数 | 系统统计 |
| `/stats/bandwidth/usage` | GET | 带宽使用情况 | 实时计算 |

**支持时间周期：** `today` | `week` | `month` | `year`

### ⚡ **批量操作API**

| 端点 | 方法 | 描述 | 限制 |
|------|------|------|------|
| `/batch/clients/create` | POST | 批量创建客户端 | 1-100个 |
| `/batch/clients/update` | POST | 批量更新配置 | 支持模板 |
| `/batch/clients/delete` | DELETE | 批量删除客户端 | 安全确认 |
| `/batch/clients/reset-traffic` | POST | 批量重置流量 | 支持筛选 |

### 📈 **系统监控API**

| 端点 | 方法 | 描述 | 监控项 |
|------|------|------|--------|
| `/monitor/health/system` | GET | 系统健康状态 | CPU/内存/磁盘 |
| `/monitor/performance/metrics` | GET | 性能指标 | 响应时间/QPS |

## 🚀 **一键安装**

### **安装命令**

```bash
# 方法1：直接安装（推荐）
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/install_standalone_enhanced_api.sh)

# 方法2：自定义端口安装
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/install_standalone_enhanced_api.sh) --port 9090

# 方法3：手动下载安装
wget https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/install_standalone_enhanced_api.sh
chmod +x install_standalone_enhanced_api.sh
sudo ./install_standalone_enhanced_api.sh
```

### **系统要求**

- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+, Debian 9+)
- **已安装**: 3X-UI (任意版本)
- **权限**: root权限
- **端口**: 8080端口可用 (可自定义)
- **依赖**: curl, wget (脚本自动安装)

## 📖 **使用文档**

### **安装后验证**

```bash
# 1. 检查服务状态
systemctl status x-ui-enhanced-api

# 2. 运行功能测试
/tmp/test_enhanced_api.sh

# 3. 快速健康检查
curl http://localhost:8080/health
```

### **API调用示例**

#### **获取流量统计**
```bash
# 获取本周流量汇总
curl "http://your-server:8080/panel/api/enhanced/stats/traffic/summary/week"

# 响应示例
{
  "success": true,
  "data": {
    "period": "week",
    "totalUp": 1073741824,
    "totalDown": 5368709120,
    "totalTraffic": 6442450944,
    "activeClients": 25,
    "growthRate": 15.5,
    "topProtocols": [...]
  }
}
```

#### **获取客户端排名**
```bash
# 获取月度客户端排名
curl "http://your-server:8080/panel/api/enhanced/stats/clients/ranking/month"

# 响应示例
{
  "success": true,
  "data": [
    {
      "email": "user1@example.com",
      "totalTraffic": 2147483648,
      "rank": 1,
      "status": "active"
    }
  ]
}
```

#### **批量创建客户端**
```bash
# 批量创建5个客户端
curl -X POST "http://your-server:8080/panel/api/enhanced/batch/clients/create" \
  -H "Content-Type: application/json" \
  -d '{
    "count": 5,
    "emailPrefix": "batch_user",
    "inboundId": 1,
    "template": {
      "totalGB": 107374182400,
      "expiryTime": 1704067200000,
      "enable": true
    }
  }'
```

#### **获取系统健康状态**
```bash
# 获取系统监控信息
curl "http://your-server:8080/panel/api/enhanced/monitor/health/system"

# 响应示例
{
  "success": true,
  "data": {
    "cpu": 45.2,
    "memory": 67.8,
    "disk": 23.1,
    "xrayStatus": "running",
    "activeConnections": 156
  }
}
```

## 🔧 **服务管理**

### **常用命令**

```bash
# 查看服务状态
systemctl status x-ui-enhanced-api

# 重启服务
systemctl restart x-ui-enhanced-api

# 停止服务
systemctl stop x-ui-enhanced-api

# 查看实时日志
journalctl -u x-ui-enhanced-api -f

# 查看错误日志
journalctl -u x-ui-enhanced-api --since "1 hour ago"
```

### **配置文件位置**

```bash
# 服务文件
/etc/systemd/system/x-ui-enhanced-api.service

# 程序目录
/opt/x-ui-enhanced-api/

# 可执行文件
/opt/x-ui-enhanced-api/x-ui-enhanced-api
```

### **端口配置**

```bash
# 修改端口 (修改后需要重启服务)
sudo nano /etc/systemd/system/x-ui-enhanced-api.service

# 找到这行并修改端口号
Environment=API_PORT=8080

# 重新加载并重启
sudo systemctl daemon-reload
sudo systemctl restart x-ui-enhanced-api
```

## 📊 **性能特性**

### **资源占用**

- **内存占用**: ~20MB
- **CPU占用**: <1%
- **磁盘空间**: ~50MB
- **启动时间**: <3秒

### **性能指标**

- **并发支持**: 1000+ 连接
- **响应时间**: <50ms (平均)
- **QPS能力**: 500+ 请求/秒
- **数据库查询**: 优化索引，<10ms

## 🛡️ **安全特性**

### **访问控制**
- CORS跨域配置
- 请求频率限制
- 输入参数验证
- 错误信息过滤

### **数据安全**
- 只读数据库访问
- 敏感信息脱敏
- 日志安全记录
- 异常状态监控

## 🔍 **故障排除**

### **常见问题**

#### **1. 服务启动失败**
```bash
# 检查端口占用
netstat -tlnp | grep 8080

# 查看详细错误
journalctl -u x-ui-enhanced-api --no-pager

# 检查Go环境
/usr/local/go/bin/go version
```

#### **2. API无法访问**
```bash
# 检查防火墙
sudo ufw status
sudo iptables -L | grep 8080

# 检查服务监听
ss -tlnp | grep 8080

# 测试本地访问
curl -I http://localhost:8080/health
```

#### **3. 数据库连接失败**
```bash
# 检查3X-UI数据库
ls -la /usr/local/x-ui/x-ui.db

# 检查数据库权限
sudo chmod 644 /usr/local/x-ui/x-ui.db

# 重启增强API服务
sudo systemctl restart x-ui-enhanced-api
```

## 📈 **更新升级**

### **版本更新**

```bash
# 备份当前版本
sudo systemctl stop x-ui-enhanced-api
sudo cp -r /opt/x-ui-enhanced-api /opt/x-ui-enhanced-api.backup

# 重新运行安装脚本
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/install_standalone_enhanced_api.sh)
```

### **卸载服务**

```bash
# 停止并删除服务
sudo systemctl stop x-ui-enhanced-api
sudo systemctl disable x-ui-enhanced-api
sudo rm -f /etc/systemd/system/x-ui-enhanced-api.service
sudo systemctl daemon-reload

# 删除程序文件
sudo rm -rf /opt/x-ui-enhanced-api

# 删除测试脚本
sudo rm -f /tmp/test_enhanced_api.sh
```

## 🤝 **社区支持**

### **获取帮助**

- 📧 **问题反馈**: [GitHub Issues](https://github.com/WCOJBK/x-ui-api-main/issues)
- 📖 **使用文档**: [项目Wiki](https://github.com/WCOJBK/x-ui-api-main/wiki)
- 💬 **讨论交流**: [GitHub Discussions](https://github.com/WCOJBK/x-ui-api-main/discussions)

### **贡献代码**

1. Fork项目到您的GitHub
2. 创建功能分支: `git checkout -b feature/amazing-feature`
3. 提交修改: `git commit -m 'Add amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 提交PR: 创建Pull Request

## 📄 **开源协议**

本项目采用 [GPL v3.0](LICENSE) 开源协议。

## 🌟 **Star历史**

如果这个项目对您有帮助，请给我们一个 ⭐ Star！

[![Stargazers over time](https://starchart.cc/WCOJBK/x-ui-api-main.svg)](https://starchart.cc/WCOJBK/x-ui-api-main)

## 📝 **更新日志**

### v2.0.0 (2024-01-21)
- 🎉 **新增**: 独立增强API服务
- 📊 **新增**: 真实数据库集成
- ⚡ **新增**: 批量操作API
- 📈 **新增**: 系统监控API  
- 🛡️ **新增**: 完整错误处理
- 🚀 **新增**: 自动化部署脚本

### v1.0.0 (2024-01-15)
- 🎉 首次发布基础版本

---

<div align="center">

**[⬆ 返回顶部](#-3x-ui-独立增强api服务)**

Made with ❤️ by [WCOJBK](https://github.com/WCOJBK)

</div>
