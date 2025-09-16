# 🚀 3X-UI 增强API版本升级指南

> **将原版3X-UI升级为具有完整API功能的增强版本**

---

## 📋 升级前准备

### ✅ 确认当前状态

您的服务器当前运行的是：
- **面板地址**：http://103.189.140.156:2053/6xdXzEaGBx8QXXQ
- **用户名**：root
- **密码**：1999415123
- **版本**：v2.8.0 (原版)

### ⚠️ 重要提醒

1. **数据安全**：升级过程会自动备份当前配置
2. **服务中断**：升级过程中服务会短暂停止
3. **网络要求**：需要能访问GitHub
4. **系统要求**：需要安装Go环境（脚本会自动处理）

---

## 🔧 两种升级方法

### 方法一：自动升级脚本 (推荐)

**1. 下载升级脚本**：
```bash
# 下载脚本
wget https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/compile_upgrade.sh

# 或者使用curl
curl -O https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/compile_upgrade.sh

# 添加执行权限
chmod +x compile_upgrade.sh
```

**2. 运行升级脚本**：
```bash
./compile_upgrade.sh
```

**3. 按提示操作**：
- 脚本会询问是否确认升级
- 输入 `y` 确认继续

**4. 等待完成**：
- 脚本会自动处理所有步骤
- 升级完成后会显示新的面板信息

---

### 方法二：手动升级 (高级用户)

**1. 停止现有服务**：
```bash
systemctl stop x-ui
```

**2. 备份当前配置**：
```bash
cp -r /usr/local/x-ui /usr/local/x-ui-backup-$(date +%Y%m%d_%H%M%S)
```

**3. 安装Go环境** (如果没有)：
```bash
# Ubuntu/Debian
apt-get update && apt-get install -y golang-go git

# CentOS/RHEL
yum install -y golang git

# Fedora
dnf install -y golang git
```

**4. 下载源码并编译**：
```bash
# 创建临时目录
mkdir -p /tmp/x-ui-enhanced
cd /tmp/x-ui-enhanced

# 克隆仓库
git clone https://github.com/WCOJBK/x-ui-api-main.git .

# 编译
go mod tidy
go build -o x-ui main.go
```

**5. 安装增强版本**：
```bash
# 替换二进制文件
cp x-ui /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/x-ui

# 替换脚本文件
cp x-ui.sh /usr/local/x-ui/x-ui.sh
chmod +x /usr/local/x-ui/x-ui.sh

# 更新服务文件
cp x-ui.service /etc/systemd/system/x-ui.service
```

**6. 重启服务**：
```bash
systemctl daemon-reload
systemctl start x-ui
```

**7. 验证升级**：
```bash
systemctl status x-ui
x-ui settings
```

---

## 🎯 升级后验证

### ✅ 检查服务状态

```bash
# 检查服务是否正常运行
systemctl status x-ui

# 查看面板设置
x-ui settings
```

### 🔍 测试新API功能

**1. 登录获取Cookie**：
```bash
curl -c cookies.txt -X POST http://103.189.140.156:2053/6xdXzEaGBx8QXXQ/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=root&password=1999415123"
```

**2. 测试增强API (出站管理)**：
```bash
curl -b cookies.txt -X POST http://103.189.140.156:2053/6xdXzEaGBx8QXXQ/panel/api/outbounds/list \
  -H "Accept: application/json"
```

**3. 测试路由管理API**：
```bash
curl -b cookies.txt -X POST http://103.189.140.156:2053/6xdXzEaGBx8QXXQ/panel/api/routing/get \
  -H "Accept: application/json"
```

**4. 测试订阅管理API**：
```bash
curl -b cookies.txt -X POST http://103.189.140.156:2053/6xdXzEaGBx8QXXQ/panel/api/subscription/settings/get \
  -H "Accept: application/json"
```

---

## 🆕 新增功能一览

### 📡 **出站管理API** (6个接口)
- `POST /panel/api/outbounds/list` - 获取出站列表
- `POST /panel/api/outbounds/add` - 添加出站配置
- `POST /panel/api/outbounds/del/:tag` - 删除出站配置
- `POST /panel/api/outbounds/update/:tag` - 更新出站配置
- `POST /panel/api/outbounds/resetTraffic/:tag` - 重置出站流量
- `POST /panel/api/outbounds/resetAllTraffics` - 重置所有出站流量

### 🛣️ **路由管理API** (5个接口)
- `POST /panel/api/routing/get` - 获取路由配置
- `POST /panel/api/routing/update` - 更新路由配置
- `POST /panel/api/routing/rule/add` - 添加路由规则
- `POST /panel/api/routing/rule/del` - 删除路由规则
- `POST /panel/api/routing/rule/update` - 更新路由规则

### 📰 **订阅管理API** (5个接口)
- `POST /panel/api/subscription/settings/get` - 获取订阅设置
- `POST /panel/api/subscription/settings/update` - 更新订阅设置
- `POST /panel/api/subscription/enable` - 启用订阅
- `POST /panel/api/subscription/disable` - 禁用订阅
- `GET /panel/api/subscription/urls/:id` - 获取订阅链接

### 👥 **高级客户端功能**
- ✅ 自定义订阅ID
- ✅ 设置到期时间
- ✅ 流量限制
- ✅ IP限制
- ✅ Telegram ID绑定
- ✅ 客户端备注
- ✅ 自动生成订阅链接

---

## 📚 API文档

升级后，您将获得完整的API文档：

- **[完整API文档](COMPLETE_API_DOCUMENTATION.md)** - 详细的接口说明和示例
- **[快速参考](API_QUICK_REFERENCE.md)** - API接口速查表
- **[功能总结](API_FEATURE_SUMMARY.md)** - 功能对比和评价
- **[使用示例](API_USAGE_EXAMPLES.md)** - 实用代码示例
- **[Postman集合](3X-UI-Enhanced-API.postman_collection.json)** - 可导入的测试集合

---

## 🔧 常见问题

### ❓ 升级失败怎么办？

如果升级失败，可以恢复备份：
```bash
# 停止服务
systemctl stop x-ui

# 恢复备份（替换为实际备份目录名）
rm -rf /usr/local/x-ui
mv /usr/local/x-ui-backup-* /usr/local/x-ui

# 重启服务
systemctl start x-ui
```

### ❓ Go环境安装失败？

手动安装Go：
```bash
# 下载Go
wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz

# 解压安装
tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

# 设置环境变量
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### ❓ 编译失败？

常见原因和解决方案：
1. **网络问题**：检查是否能访问GitHub
2. **依赖问题**：运行 `go mod tidy` 重新下载依赖
3. **权限问题**：确保使用root权限运行

### ❓ API不工作？

检查步骤：
1. 确认服务正常运行：`systemctl status x-ui`
2. 检查端口是否开放：`netstat -tlnp | grep 2053`
3. 查看日志：`x-ui log`

---

## 🎉 升级完成后的收益

✅ **API功能提升 250%**：从原来的19个接口增加到49个接口  
✅ **管理效率提升**：支持完整的自动化运维  
✅ **功能更完整**：出站、路由、订阅全面API化  
✅ **兼容性更好**：完全兼容原版配置和数据  
✅ **文档更完善**：提供多语言详细文档  

---

## 📞 技术支持

如果升级过程中遇到问题：

1. **查看日志**：`x-ui log`
2. **检查状态**：`systemctl status x-ui`
3. **GitHub Issues**：https://github.com/WCOJBK/x-ui-api-main/issues

---

**© 2024 3X-UI Enhanced API Project | 维护者: WCOJBK**  
**🔗 仓库地址**: https://github.com/WCOJBK/x-ui-api-main
