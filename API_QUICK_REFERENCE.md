# 3X-UI API 快速参考指南

> **基础URL**: `http://your-server:port`  
> **认证方式**: Session Cookie (通过 `/login` 获取)

## 🔐 认证

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | `/login` | 登录获取session |

## 🌐 入站管理 API

**Base**: `/panel/api/inbounds`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET    | `/list` | 获取入站列表 |
| GET    | `/get/:id` | 获取单个入站 |
| POST   | `/add` | 添加入站 |
| POST   | `/update/:id` | 更新入站 |
| POST   | `/del/:id` | 删除入站 |

### 客户端管理

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | `/addClient` | 添加客户端(基础) |
| POST   | `/addClientAdvanced` ⭐ | 添加客户端(高级) |
| GET    | `/client/details/:email` ⭐ | 获取客户端详情 |
| POST   | `/client/update/:email` ⭐ | 更新客户端设置 |
| POST   | `/:id/delClient/:clientId` | 删除客户端 |
| POST   | `/updateClient/:clientId` | 更新客户端(基础) |

### 流量管理

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET    | `/getClientTraffics/:email` | 获取客户端流量(邮箱) |
| GET    | `/getClientTrafficsById/:id` | 获取客户端流量(ID) |
| POST   | `/:id/resetClientTraffic/:email` | 重置客户端流量 |
| POST   | `/resetAllTraffics` | 重置所有入站流量 |
| POST   | `/resetAllClientTraffics/:id` | 重置入站内所有客户端流量 |

### IP管理

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | `/clientIps/:email` | 获取客户端IP |
| POST   | `/clearClientIps/:email` | 清理客户端IP |

### 其他操作

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | `/onlines` | 获取在线用户 |
| POST   | `/delDepletedClients/:id` | 删除流量耗尽客户端 |

## 🚀 出站管理 API ⭐

**Base**: `/panel/api/outbounds`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | `/list` | 获取出站列表 |
| POST   | `/add` | 添加出站 |
| POST   | `/update/:tag` | 更新出站 |
| POST   | `/del/:tag` | 删除出站 |
| POST   | `/resetTraffic/:tag` | 重置出站流量 |
| POST   | `/resetAllTraffics` | 重置所有出站流量 |

## 🛤️ 路由管理 API ⭐

**Base**: `/panel/api/routing`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | `/get` | 获取路由配置 |
| POST   | `/update` | 更新路由配置 |
| POST   | `/rule/add` | 添加路由规则 |
| POST   | `/rule/del` | 删除路由规则 |
| POST   | `/rule/update` | 更新路由规则 |

## 📡 订阅管理 API ⭐

**Base**: `/panel/api/subscription`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | `/settings/get` | 获取订阅设置 |
| POST   | `/settings/update` | 更新订阅设置 |
| POST   | `/enable` | 启用订阅服务 |
| POST   | `/disable` | 禁用订阅服务 |
| GET    | `/urls/:id` | 获取订阅链接 |

## 🎯 备份管理 API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET    | `/panel/api/createbackup` | 创建备份并发送给管理员 |

---

## ⭐ 高级功能特性

### addClientAdvanced 请求格式
```json
{
  "inboundId": 1,
  "email": "user@example.com",
  "flow": "xtls-rprx-vision",
  "limitIp": 2,
  "totalGB": 107374182400,
  "expiryTime": 1735689600000,
  "enable": true,
  "subId": "custom-subscription-id",
  "tgId": 123456789,
  "comment": "VIP用户"
}
```

### client/details 响应格式
```json
{
  "success": true,
  "obj": {
    "email": "user@example.com",
    "uuid": "client-uuid",
    "subscriptionUrl": "http://server/sub/custom-id",
    "jsonSubscriptionUrl": "http://server/json/custom-id",
    "totalGB": 107374182400,
    "usedTraffic": 12345678,
    "expiryTime": 1735689600000,
    "limitIp": 2,
    "enable": true
  }
}
```

---

## 🔧 快速示例

### 登录
```bash
curl -c cookies.txt -X POST "http://server:2053/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

### 添加高级客户端
```bash
curl -b cookies.txt -X POST "http://server:2053/panel/api/inbounds/addClientAdvanced" \
  -H "Content-Type: application/json" \
  -d '{
    "inboundId": 1,
    "email": "user@example.com",
    "flow": "xtls-rprx-vision",
    "limitIp": 2,
    "totalGB": 107374182400,
    "enable": true
  }'
```

### 获取客户端详情
```bash
curl -b cookies.txt "http://server:2053/panel/api/inbounds/client/details/user@example.com"
```

---

**⭐ 标记为新增或增强功能**

**© 2024 3X-UI Enhanced API**  
**仓库**: https://github.com/WCOJBK/x-ui-api-main
