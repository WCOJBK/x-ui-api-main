# 3X-UI Enhanced API 安装指南

## 📦 GitHub项目地址
```
https://github.com/your-username/3x-ui-enhanced-api
```

## 🚀 一键安装命令

### 方法1：直接安装（推荐）
```bash
bash <(curl -Ls https://raw.githubusercontent.com/your-username/3x-ui-enhanced-api/main/install_enhanced_api.sh)
```

### 方法2：手动下载安装
```bash
# 1. 下载项目文件
wget -O /tmp/install_enhanced_api.sh https://raw.githubusercontent.com/your-username/3x-ui-enhanced-api/main/install_enhanced_api.sh

# 2. 赋予执行权限
chmod +x /tmp/install_enhanced_api.sh

# 3. 运行安装脚本
sudo /tmp/install_enhanced_api.sh
```

## ✅ 安装验证

安装完成后运行以下命令验证：

```bash
# 下载测试脚本
wget -O test_api.sh https://raw.githubusercontent.com/your-username/3x-ui-enhanced-api/main/api_test_examples.sh
chmod +x test_api.sh

# 运行测试（替换为您的面板地址和凭据）
./test_api.sh --url http://your-server:2053 --user admin --pass your-password
```

## 🔧 故障排除

如遇到问题，请查看详细文档：
- [完整文档](README_Enhanced_API.md)
- [问题反馈](https://github.com/your-username/3x-ui-enhanced-api/issues)
