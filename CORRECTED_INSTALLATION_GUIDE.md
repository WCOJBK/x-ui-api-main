# ✅ 修正后的 3X-UI 安装指南

## 🔧 问题说明

用户反馈的404错误是由于README文件中使用了错误的仓库地址导致的。

**错误地址**:
```bash
https://raw.githubusercontent.com/WCOJBK/3x-ui-api/master/install.sh
```

**正确地址**:
```bash
https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/master/install.sh
```

---

## ✅ 正确的安装方法

### 1. 快速安装 (推荐)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/master/install.sh)
```

### 2. 安装指定版本

```bash
VERSION=v1.7.9 && bash <(curl -Ls "https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/$VERSION/install.sh") $VERSION
```

### 3. Docker 安装

```bash
# 克隆仓库
git clone https://github.com/WCOJBK/x-ui-api-main.git
cd x-ui-api-main

# 启动服务
docker compose up -d
```

### 4. 手动下载安装

```bash
# 检测架构
ARCH=$(uname -m)
case "${ARCH}" in
  x86_64 | x64 | amd64) XUI_ARCH="amd64" ;;
  i*86 | x86) XUI_ARCH="386" ;;
  armv8* | armv8 | arm64 | aarch64) XUI_ARCH="arm64" ;;
  armv7* | armv7) XUI_ARCH="armv7" ;;
  armv6* | armv6) XUI_ARCH="armv6" ;;
  armv5* | armv5) XUI_ARCH="armv5" ;;
  *) XUI_ARCH="amd64" ;;
esac

# 下载安装包
wget https://github.com/WCOJBK/x-ui-api-main/releases/latest/download/x-ui-linux-${XUI_ARCH}.tar.gz

# 安装
cd /root/
rm -rf x-ui/ /usr/local/x-ui/ /usr/bin/x-ui
tar zxvf x-ui-linux-${XUI_ARCH}.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
mv x-ui/ /usr/local/
systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui
```

---

## 🔗 仓库地址确认

**正确的仓库地址**: https://github.com/WCOJBK/x-ui-api-main

**安装脚本位置**: https://github.com/WCOJBK/x-ui-api-main/blob/main/install.sh

---

## 📋 已修正的文件

✅ **README.md** - 英文版  
✅ **README.zh_CN.md** - 中文版  
✅ **README.es_ES.md** - 西班牙语版  
✅ **README.fa_IR.md** - 波斯语版  
✅ **README.ru_RU.md** - 俄语版  
✅ **COMPLETE_API_DOCUMENTATION.md** - API文档  
✅ **API_QUICK_REFERENCE.md** - 快速参考  
✅ **API_FEATURE_SUMMARY.md** - 功能总结  

---

## ✅ 验证安装

安装完成后，可以通过以下命令验证：

```bash
# 查看服务状态
systemctl status x-ui

# 查看面板信息
x-ui show

# 查看日志
x-ui log
```

---

## 🎉 问题已解决

所有README文件中的仓库地址已经从错误的 `WCOJBK/3x-ui-api` 修正为正确的 `WCOJBK/x-ui-api-main`。

现在您可以使用修正后的安装命令正常安装3X-UI了！

**© 2024 3X-UI Enhanced API Project**
