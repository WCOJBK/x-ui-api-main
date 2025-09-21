# 3X-UI Enhanced API - 真实项目

## 🚀 快速开始

```bash
# 一键构建运行
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/build_and_run.sh)

# API测试  
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/test_real_api.sh)
```

## 📊 Enhanced API

- **出站管理**: `/panel/api/outbounds/*` 🆕
- **路由管理**: `/panel/api/routing/*` 🆕  
- **订阅管理**: `/panel/api/subscription/*` 🆕
- **入站管理**: `/panel/api/inbounds/*` ✅

## 💡 项目说明

这是基于**真正的3X-UI源码**构建的Enhanced API项目:
- 使用用户提供的完整`web/`源码目录
- 包含真实的控制器: `outbound.go`, `routing.go`, `subscription.go`
- 基于真正的`main.go`和`go.mod`依赖
- 保留原生3X-UI的完整功能和界面

**🎯 访问**: `http://your-server:2053/` (admin/admin)
