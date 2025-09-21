# 3X-UI Enhanced - Advanced Web Panel

[![GitHub release](https://img.shields.io/github/v/release/WCOJBK/x-ui-api-main)](https://github.com/WCOJBK/x-ui-api-main/releases)
[![GitHub downloads](https://img.shields.io/github/downloads/WCOJBK/x-ui-api-main/total)](https://github.com/WCOJBK/x-ui-api-main/releases)
[![Docker pulls](https://img.shields.io/docker/pulls/WCOJBK/3x-ui)](https://hub.docker.com/r/WCOJBK/3x-ui)
[![Go version](https://img.shields.io/github/go-mod/go-version/WCOJBK/x-ui-api-main)](https://golang.org/)
[![License](https://img.shields.io/badge/license-GPL%20V3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)

[English](README.md) | [中文](README.zh_CN.md) | [Español](README.es_ES.md) | [فارسی](README.fa_IR.md) | [Русский](README.ru_RU.md)

**An Advanced Web Panel Built on Xray Core with Enhanced API Features**

> **免责声明 / Disclaimer:** 本项目仅用于个人学习和交流，请勿用于非法用途，请勿在生产环境中使用。
> This project is only for personal learning and communication, please do not use it for illegal purposes, please do not use it in a production environment.

## ✨ 主要特性 / Key Features

### 🚀 核心功能 / Core Features
- **现代化 Web 界面** - 支持深色/浅色主题，响应式设计
- **多用户多协议** - 支持 VMESS, VLESS, Trojan, Shadowsocks, WireGuard 等
- **高级路由功能** - 支持复杂的路由规则和负载均衡
- **实时监控** - 系统状态监控，流量统计，在线用户追踪
- **证书管理** - 自动申请和续期 SSL 证书 (ACME)
- **Telegram 机器人** - 完整的 Telegram 机器人集成

### 🛡️ 安全特性 / Security Features
- **IP 限制** - 基于 Fail2ban 的智能 IP 限制
- **防火墙管理** - UFW 防火墙集成管理
- **SSH 端口转发** - 安全的面板访问
- **Web 基础路径** - 自定义 Web 路径增强安全性

### 🔧 增强功能 / Enhanced Features
- **RESTful API** - 完整的 API 接口用于自动化管理
- **数据库备份** - 自动化数据库备份和恢复
- **地理位置数据** - 支持多种 GEO 数据源
- **性能优化** - BBR 拥塞控制，系统性能调优

## 🚀 快速安装 / Quick Installation

### 一键安装 / One-Click Install
```bash
curl -fsSL https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/quick-install.sh | bash
```

### Docker 部署 / Docker Deployment
```bash
# Using docker-compose
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main
docker-compose up -d

# Using docker run
docker run -d \
  --name 3x-ui \
  --restart unless-stopped \
  --network host \
  -v $PWD/db/:/etc/x-ui/ \
  -v $PWD/cert/:/root/cert/ \
  ghcr.io/WCOJBK/3x-ui:latest
```

### 手动安装 / Manual Installation
```bash
# 1. 下载最新版本 / Download latest release
wget https://github.com/WCOJBK/x-ui-api-main/releases/latest/download/x-ui-linux-amd64.tar.gz

# 2. 解压并安装 / Extract and install
tar -xzf x-ui-linux-amd64.tar.gz
cd x-ui-linux-amd64
sudo ./install.sh

# 3. 启动服务 / Start service
sudo systemctl start x-ui
sudo systemctl enable x-ui
```

## 🖥️ 支持的系统 / Supported Systems

### 操作系统 / Operating Systems
- **Ubuntu** 20.04+ (推荐 / Recommended)
- **Debian** 11+ (推荐 / Recommended)
- **CentOS** 8+
- **RHEL** 8+
- **Fedora** 36+
- **Arch Linux**
- **Alpine Linux**
- **OpenSUSE**

### 系统架构 / Architectures
- **amd64** (x86_64) - Intel/AMD 64-bit
- **arm64** (aarch64) - 64-bit ARM (Apple M1, 树莓派4等)
- **armv7** - 32-bit ARMv7 (树莓派3等)
- **armv6** - 32-bit ARMv6 (树莓派Zero等)
- **armv5** - 32-bit ARMv5 (legacy ARM)
- **386** - 32-bit x86
- **s390x** - IBM System z

## 📚 管理指南 / Management Guide

### 基本命令 / Basic Commands
```bash
# 管理菜单 / Management menu
x-ui

# 服务管理 / Service management
systemctl start x-ui     # 启动服务 / Start service
systemctl stop x-ui      # 停止服务 / Stop service
systemctl restart x-ui   # 重启服务 / Restart service
systemctl status x-ui    # 查看状态 / Check status

# 配置管理 / Configuration management
x-ui settings            # 查看当前设置 / View current settings
x-ui update              # 更新到最新版本 / Update to latest version
x-ui log                 # 查看日志 / View logs
```

### 默认配置 / Default Configuration
- **Web 端口** / Web Port: `2053`
- **用户名** / Username: `admin`
- **密码** / Password: `admin`
- **Web 根路径** / Web Base Path: `/`

⚠️ **重要提醒 / Important:** 首次安装后请立即更改默认用户名和密码！
Please change the default username and password immediately after first installation!

## 🛠️ 高级配置 / Advanced Configuration

### SSL 证书 / SSL Certificate
```bash
# 自动申请 Let's Encrypt 证书 / Auto apply Let's Encrypt certificate
x-ui cert

# Cloudflare DNS 证书 / Cloudflare DNS certificate
x-ui cloudflare
```

### IP 限制 / IP Limiting
```bash
# 配置 IP 限制 / Configure IP limiting
x-ui iplimit

# 查看封禁日志 / View ban logs
x-ui banlog
```

### Telegram 机器人 / Telegram Bot
1. 创建机器人: https://t.me/BotFather
2. 获取机器人令牌和聊天ID
3. 在面板中配置机器人设置

### 防火墙配置 / Firewall Configuration
```bash
# 防火墙管理 / Firewall management
x-ui firewall

# 开放端口 / Open ports
ufw allow 2053/tcp
ufw allow 80/tcp
ufw allow 443/tcp
```

## 🔌 API 接口 / API Interface

### 认证 / Authentication
```bash
# 登录获取 cookie / Login to get cookie
curl -X POST "http://your-server:2053/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

### 常用接口 / Common APIs
```bash
# 获取所有入站 / Get all inbounds
GET /panel/api/inbounds/list

# 添加入站 / Add inbound
POST /panel/api/inbounds/add

# 获取系统状态 / Get system status
GET /panel/api/inbounds/getClientTraffics/:email

# 重置流量 / Reset traffic
POST /panel/api/inbounds/resetAllTraffics
```

详细 API 文档请查看: [API Documentation](https://documenter.getpostman.com/view/your-collection-id)

## 🏗️ 开发指南 / Development Guide

### 本地开发 / Local Development
```bash
# 克隆项目 / Clone project
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 安装依赖 / Install dependencies
go mod tidy

# 运行开发服务器 / Run development server
go run main.go
```

### 构建项目 / Build Project
```bash
# 构建所有架构 / Build for all architectures
./build-release.sh

# 构建指定架构 / Build for specific architecture
./build-release.sh amd64 arm64

# 构建单个架构 / Build single architecture
./build-single.sh amd64
```

### Docker 构建 / Docker Build
```bash
# 构建 Docker 镜像 / Build Docker image
docker build -t 3x-ui .

# 多架构构建 / Multi-architecture build
docker buildx build --platform linux/amd64,linux/arm64 -t 3x-ui .
```

## 📈 性能优化 / Performance Optimization

### 系统优化 / System Optimization
```bash
# 启用 BBR / Enable BBR
x-ui bbr

# 系统调优 / System tuning
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
sysctl -p
```

### 监控建议 / Monitoring Recommendations
- 使用 `htop` 监控 CPU 和内存使用
- 使用 `iotop` 监控磁盘 I/O
- 使用 `netstat` 监控网络连接
- 定期检查日志文件大小

## 🔧 故障排除 / Troubleshooting

### 常见问题 / Common Issues

#### 服务无法启动 / Service Won't Start
```bash
# 检查日志 / Check logs
journalctl -u x-ui -f

# 检查端口占用 / Check port usage
netstat -tulpn | grep :2053

# 检查配置文件 / Check configuration
x-ui settings
```

#### 面板无法访问 / Panel Not Accessible
```bash
# 检查防火墙 / Check firewall
ufw status
iptables -L

# 检查监听地址 / Check listen address
ss -tulpn | grep :2053
```

#### 证书问题 / Certificate Issues
```bash
# 检查证书状态 / Check certificate status
x-ui cert -show

# 重新申请证书 / Reapply certificate
x-ui cert -renew
```

## 🤝 贡献指南 / Contributing

我们欢迎所有形式的贡献！/ We welcome all forms of contributions!

### 如何贡献 / How to Contribute
1. Fork 本项目 / Fork the project
2. 创建特性分支 / Create feature branch (`git checkout -b feature/AmazingFeature`)
3. 提交更改 / Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 / Push to branch (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request / Open a Pull Request

### 开发规范 / Development Guidelines
- 遵循 Go 代码规范
- 添加适当的注释
- 编写单元测试
- 更新相关文档

## 📄 许可证 / License

本项目基于 [GPL-3.0 License](LICENSE) 开源协议。
This project is licensed under the [GPL-3.0 License](LICENSE).

## 🙏 致谢 / Acknowledgments

- [Xray-core](https://github.com/XTLS/Xray-core) - 核心代理软件
- [3x-ui](https://github.com/MHSanaei/3x-ui) - 原始项目基础
- [v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat) - 路由规则数据

## 🆘 获取帮助 / Getting Help

- **GitHub Issues**: [Issues](https://github.com/WCOJBK/x-ui-api-main/issues)
- **Discussions**: [Discussions](https://github.com/WCOJBK/x-ui-api-main/discussions)
- **Telegram**: [@your_telegram_group](https://t.me/your_telegram_group)

---

### Star History

[![Star History Chart](https://api.star-history.com/svg?repos=WCOJBK/x-ui-api-main&type=Date)](https://star-history.com/#WCOJBK/x-ui-api-main&Date)

---

**如果这个项目对你有帮助，请给它一个 ⭐️**
**If this project helps you, please give it a ⭐️**
