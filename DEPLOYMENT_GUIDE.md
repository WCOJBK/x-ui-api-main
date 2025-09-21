# 3X-UI 部署指南 / Deployment Guide

本文档提供了在云服务器上部署 3X-UI 的完整指南。
This document provides a complete guide for deploying 3X-UI on cloud servers.

## 📋 系统要求 / System Requirements

### 最低配置 / Minimum Requirements
- **CPU**: 1 vCPU
- **内存 / RAM**: 512MB
- **存储 / Storage**: 1GB 可用空间
- **网络 / Network**: 1Mbps 带宽

### 推荐配置 / Recommended Requirements
- **CPU**: 2+ vCPU
- **内存 / RAM**: 1GB+
- **存储 / Storage**: 5GB+ SSD
- **网络 / Network**: 10Mbps+ 带宽

## 🚀 快速部署 / Quick Deployment

### 方式一：一键安装脚本 / Method 1: One-Click Install Script

```bash
# 下载并执行安装脚本 / Download and execute install script
curl -fsSL https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/quick-install.sh | bash
```

该脚本会自动：
The script will automatically:
- 检测系统类型和架构
- 安装必要的依赖
- 下载最新版本
- 配置系统服务
- 生成安全的随机凭据

### 方式二：Docker 部署 / Method 2: Docker Deployment

```bash
# 克隆项目 / Clone project
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 使用 Docker Compose / Using Docker Compose
docker-compose up -d

# 或者直接运行 / Or run directly
docker run -d \
  --name 3x-ui \
  --restart unless-stopped \
  --network host \
  -v $PWD/db/:/etc/x-ui/ \
  -v $PWD/cert/:/root/cert/ \
  -e XRAY_VMESS_AEAD_FORCED=false \
  ghcr.io/WCOJBK/3x-ui:latest
```

### 方式三：手动部署 / Method 3: Manual Deployment

```bash
# 1. 创建工作目录 / Create working directory
sudo mkdir -p /opt/3x-ui
cd /opt/3x-ui

# 2. 下载对应架构的版本 / Download version for your architecture
# For amd64 (most common)
wget https://github.com/WCOJBK/x-ui-api-main/releases/latest/download/x-ui-linux-amd64.tar.gz

# For ARM64 (Apple M1, modern ARM servers)
# wget https://github.com/WCOJBK/x-ui-api-main/releases/latest/download/x-ui-linux-arm64.tar.gz

# For ARMv7 (Raspberry Pi 3/4)
# wget https://github.com/WCOJBK/x-ui-api-main/releases/latest/download/x-ui-linux-armv7.tar.gz

# 3. 解压并安装 / Extract and install
tar -xzf x-ui-linux-amd64.tar.gz
cd x-ui-linux-amd64
sudo ./install.sh

# 4. 启动服务 / Start service
sudo systemctl start x-ui
sudo systemctl enable x-ui
```

## 🔧 配置指南 / Configuration Guide

### 初始设置 / Initial Setup

1. **访问面板 / Access Panel**
   ```bash
   # 查看当前配置 / View current configuration
   x-ui settings
   ```

2. **修改默认凭据 / Change Default Credentials**
   ```bash
   # 通过管理菜单 / Through management menu
   x-ui
   # 选择 "Reset Username & Password"
   
   # 或直接命令行 / Or directly via command line
   /usr/local/x-ui/x-ui setting -username "your_username" -password "your_password"
   ```

3. **配置安全端口 / Configure Secure Port**
   ```bash
   /usr/local/x-ui/x-ui setting -port 10086
   systemctl restart x-ui
   ```

4. **设置 Web 基础路径 / Set Web Base Path**
   ```bash
   /usr/local/x-ui/x-ui setting -webBasePath "/your_secret_path"
   systemctl restart x-ui
   ```

### SSL 证书配置 / SSL Certificate Configuration

#### 自动申请 Let's Encrypt 证书 / Auto Apply Let's Encrypt Certificate
```bash
# 通过管理菜单 / Through management menu
x-ui
# 选择 "SSL Certificate Management" -> "Get SSL"

# 或者使用内置 ACME / Or use built-in ACME
x-ui cert
```

#### 使用 Cloudflare DNS 证书 / Using Cloudflare DNS Certificate
```bash
# 通过管理菜单 / Through management menu
x-ui
# 选择 "Cloudflare SSL Certificate"

# 需要准备 / You need to prepare:
# - Cloudflare 注册邮箱 / Cloudflare registered email
# - Cloudflare Global API Key
# - 域名必须通过 Cloudflare 解析 / Domain must be resolved through Cloudflare
```

### 防火墙配置 / Firewall Configuration

```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 10086/tcp # 你的面板端口 / Your panel port
sudo ufw enable

# CentOS/RHEL/Fedora
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=10086/tcp
sudo firewall-cmd --reload

# 或使用内置防火墙管理 / Or use built-in firewall management
x-ui firewall
```

## 🛡️ 安全配置 / Security Configuration

### IP 限制 / IP Limiting

```bash
# 安装和配置 Fail2ban / Install and configure Fail2ban
x-ui iplimit

# 手动配置 / Manual configuration
# 1. 选择 "Install Fail2ban and configure IP Limit"
# 2. 设置封禁时间 / Set ban duration (default: 30 minutes)
# 3. 配置日志路径 / Configure log path
```

### SSH 端口转发 / SSH Port Forwarding

如果你想通过 SSH 隧道安全访问面板：
If you want to securely access the panel through SSH tunnel:

```bash
# 1. 设置监听地址为本地 / Set listen address to local
/usr/local/x-ui/x-ui setting -listenIP 127.0.0.1
systemctl restart x-ui

# 2. 在本地机器上建立 SSH 隧道 / Establish SSH tunnel on local machine
ssh -L 8080:127.0.0.1:10086 user@your_server_ip

# 3. 在本地浏览器访问 / Access in local browser
# http://localhost:8080/your_secret_path
```

### Nginx 反向代理 / Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name your_domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your_domain.com;
    
    ssl_certificate /path/to/certificate.pem;
    ssl_certificate_key /path/to/private.key;
    
    location /your_secret_path {
        proxy_pass http://127.0.0.1:10086;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 📊 监控和维护 / Monitoring and Maintenance

### 系统监控 / System Monitoring

```bash
# 查看服务状态 / Check service status
systemctl status x-ui

# 查看实时日志 / View real-time logs
journalctl -u x-ui -f

# 查看系统资源 / Check system resources
htop
df -h
free -m
```

### 定期维护 / Regular Maintenance

```bash
# 更新到最新版本 / Update to latest version
x-ui update

# 清理日志文件 / Clean log files
journalctl --vacuum-time=7d

# 备份数据库 / Backup database
cp /etc/x-ui/x-ui.db /backup/x-ui-$(date +%Y%m%d).db

# 重启服务 / Restart service (if needed)
systemctl restart x-ui
```

### 性能优化 / Performance Optimization

```bash
# 启用 BBR 拥塞控制 / Enable BBR congestion control
x-ui bbr

# 系统调优 / System tuning
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf
sysctl -p
```

## 🔧 故障排除 / Troubleshooting

### 常见问题 / Common Issues

#### 问题1: 面板无法访问 / Issue 1: Panel Not Accessible

```bash
# 检查服务状态 / Check service status
systemctl status x-ui

# 检查端口占用 / Check port usage
ss -tulpn | grep :10086

# 检查防火墙 / Check firewall
ufw status
iptables -L
```

#### 问题2: 服务启动失败 / Issue 2: Service Start Failed

```bash
# 查看详细错误日志 / View detailed error logs
journalctl -u x-ui -n 50

# 检查配置文件 / Check configuration file
/usr/local/x-ui/x-ui setting -show true

# 重置配置 / Reset configuration
/usr/local/x-ui/x-ui setting -reset
```

#### 问题3: SSL 证书问题 / Issue 3: SSL Certificate Issues

```bash
# 检查证书状态 / Check certificate status
/usr/local/x-ui/x-ui setting -getCert true

# 重新申请证书 / Reapply certificate
x-ui cert

# 检查域名解析 / Check domain resolution
nslookup your_domain.com
```

### 日志分析 / Log Analysis

```bash
# 查看访问日志 / View access logs
tail -f /var/log/x-ui/access.log

# 查看错误日志 / View error logs
tail -f /var/log/x-ui/error.log

# 查看 Fail2ban 日志 / View Fail2ban logs
x-ui banlog
```

## 📱 Telegram 机器人配置 / Telegram Bot Configuration

### 创建机器人 / Create Bot

1. 联系 [@BotFather](https://t.me/BotFather)
2. 发送 `/newbot` 创建新机器人
3. 设置机器人名称和用户名
4. 获取机器人令牌 (Token)

### 获取聊天ID / Get Chat ID

1. 联系 [@userinfobot](https://t.me/userinfobot)
2. 发送任意消息获取你的用户ID
3. 或者创建群组并邀请机器人获取群组ID

### 配置机器人 / Configure Bot

```bash
# 通过管理菜单配置 / Configure through management menu
x-ui
# 选择相应的 Telegram 机器人选项

# 或直接命令行配置 / Or configure directly via command line
/usr/local/x-ui/x-ui setting -tgbottoken "YOUR_BOT_TOKEN"
/usr/local/x-ui/x-ui setting -tgbotchatid "YOUR_CHAT_ID"
/usr/local/x-ui/x-ui setting -enabletgbot true
```

## 🌐 云服务器提供商配置 / Cloud Provider Configuration

### AWS EC2

```bash
# 安全组配置 / Security Group Configuration
# Inbound Rules:
# - SSH (22) from your IP
# - HTTP (80) from anywhere (0.0.0.0/0)
# - HTTPS (443) from anywhere (0.0.0.0/0)
# - Custom TCP (10086) from your IP

# 用户数据脚本 / User Data Script
#!/bin/bash
curl -fsSL https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/quick-install.sh | bash
```

### Google Cloud Platform

```bash
# 防火墙规则 / Firewall Rules
gcloud compute firewall-rules create allow-x-ui \
    --allow tcp:80,tcp:443,tcp:10086 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow X-UI Panel"
```

### DigitalOcean

```bash
# 初始化脚本 / Initialization Script
#!/bin/bash
apt update && apt upgrade -y
curl -fsSL https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/quick-install.sh | bash
```

### Vultr

```bash
# 启动脚本 / Startup Script
#!/bin/bash
yum update -y
curl -fsSL https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/quick-install.sh | bash
```

## 📚 其他资源 / Additional Resources

- **官方文档 / Official Documentation**: [GitHub Repository](https://github.com/WCOJBK/x-ui-api-main)
- **API 文档 / API Documentation**: [Postman Collection](https://documenter.getpostman.com/view/your-collection)
- **社区支持 / Community Support**: [GitHub Discussions](https://github.com/WCOJBK/x-ui-api-main/discussions)
- **问题反馈 / Issue Reporting**: [GitHub Issues](https://github.com/WCOJBK/x-ui-api-main/issues)

---

**免责声明 / Disclaimer**: 请确保遵守当地法律法规，本项目仅供学习交流使用。
Please ensure compliance with local laws and regulations. This project is for educational purposes only.
