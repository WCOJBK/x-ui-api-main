# 3X-UI API 完整对接文档

> **版本**: Enhanced API v1.0  
> **维护者**: WCOJBK  
> **基础路径**: `http://your-server:port`

## 📋 目录

- [认证系统](#认证系统)
- [入站管理 API](#入站管理-api)
- [出站管理 API](#出站管理-api)
- [路由管理 API](#路由管理-api)
- [订阅管理 API](#订阅管理-api)
- [数据模型](#数据模型)
- [错误处理](#错误处理)
- [使用示例](#使用示例)

---

## 🔐 认证系统

### 登录获取Session

**端点**: `POST /login`

**请求格式**:
```json
{
  "username": "admin",
  "password": "admin"
}
```

**响应格式**:
```json
{
  "success": true,
  "msg": "登录成功",
  "obj": null
}
```

**说明**: 登录成功后，服务器会设置 session cookie，后续所有API请求都需要携带此cookie。

---

## 🌐 入站管理 API

**基础路径**: `/panel/api/inbounds`

### 1. 获取入站列表

**端点**: `GET /panel/api/inbounds/list`

**响应**:
```json
{
  "success": true,
  "msg": "",
  "obj": [
    {
      "id": 1,
      "up": 12345678,
      "down": 98765432,
      "total": 0,
      "remark": "vless-reality",
      "enable": true,
      "expiryTime": 0,
      "listen": "",
      "port": 443,
      "protocol": "vless",
      "settings": "{\"clients\":[...],\"decryption\":\"none\",\"fallbacks\":[]}",
      "streamSettings": "{\"network\":\"tcp\",\"security\":\"reality\",...}",
      "tag": "inbound-443",
      "sniffing": "{\"enabled\":true,\"destOverride\":[\"http\",\"tls\"]}",
      "allocate": "{}"
    }
  ]
}
```

### 2. 获取单个入站

**端点**: `GET /panel/api/inbounds/get/:id`

**参数**:
- `id`: 入站ID

### 3. 添加入站

**端点**: `POST /panel/api/inbounds/add`

**请求**:
```json
{
  "enable": true,
  "port": 443,
  "protocol": "vless",
  "settings": "{\"clients\":[],\"decryption\":\"none\",\"fallbacks\":[]}",
  "streamSettings": "{\"network\":\"tcp\",\"security\":\"reality\",\"realitySettings\":{...}}",
  "sniffing": "{\"enabled\":true,\"destOverride\":[\"http\",\"tls\"]}",
  "remark": "VLESS-Reality-443"
}
```

### 4. 更新入站

**端点**: `POST /panel/api/inbounds/update/:id`

**参数**: 
- `id`: 入站ID
- **请求体**: 同添加入站格式

### 5. 删除入站

**端点**: `POST /panel/api/inbounds/del/:id`

**参数**:
- `id`: 入站ID

### 6. 添加客户端（基础版）

**端点**: `POST /panel/api/inbounds/addClient`

**请求**:
```json
{
  "id": 1,
  "settings": "{\"clients\":[{\"id\":\"uuid-here\",\"email\":\"user@example.com\",\"enable\":true}]}"
}
```

### 7. 添加客户端（高级版）⭐

**端点**: `POST /panel/api/inbounds/addClientAdvanced`

**请求**:
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

**响应**:
```json
{
  "success": true,
  "msg": "Client added successfully",
  "obj": {
    "uuid": "generated-uuid",
    "email": "user@example.com",
    "subscriptionUrl": "http://your-server/sub/custom-subscription-id",
    "jsonSubscriptionUrl": "http://your-server/json/custom-subscription-id"
  }
}
```

### 8. 获取客户端详情⭐

**端点**: `GET /panel/api/inbounds/client/details/:email`

**参数**:
- `email`: 客户端邮箱

**响应**:
```json
{
  "success": true,
  "msg": "",
  "obj": {
    "email": "user@example.com",
    "uuid": "client-uuid",
    "enable": true,
    "flow": "xtls-rprx-vision",
    "limitIp": 2,
    "totalGB": 107374182400,
    "usedTraffic": 12345678,
    "expiryTime": 1735689600000,
    "subId": "custom-subscription-id",
    "subscriptionUrl": "http://your-server/sub/custom-subscription-id",
    "jsonSubscriptionUrl": "http://your-server/json/custom-subscription-id",
    "tgId": 123456789,
    "comment": "VIP用户"
  }
}
```

### 9. 更新客户端高级设置⭐

**端点**: `POST /panel/api/inbounds/client/update/:email`

**参数**:
- `email`: 客户端邮箱

**请求**:
```json
{
  "enable": true,
  "limitIp": 3,
  "totalGB": 214748364800,
  "expiryTime": 1767225600000,
  "comment": "VIP用户 - 已升级"
}
```

### 10. 删除客户端

**端点**: `POST /panel/api/inbounds/:id/delClient/:clientId`

**参数**:
- `id`: 入站ID
- `clientId`: 客户端ID (对于VMESS/VLESS是UUID，对于Trojan是password)

### 11. 客户端流量管理

#### 获取客户端流量 (按邮箱)
**端点**: `GET /panel/api/inbounds/getClientTraffics/:email`

#### 获取客户端流量 (按ID)
**端点**: `GET /panel/api/inbounds/getClientTrafficsById/:id`

#### 重置客户端流量
**端点**: `POST /panel/api/inbounds/:id/resetClientTraffic/:email`

#### 重置所有入站流量
**端点**: `POST /panel/api/inbounds/resetAllTraffics`

#### 重置入站内所有客户端流量
**端点**: `POST /panel/api/inbounds/resetAllClientTraffics/:id`

### 12. 客户端IP管理

#### 获取客户端IP
**端点**: `POST /panel/api/inbounds/clientIps/:email`

#### 清理客户端IP
**端点**: `POST /panel/api/inbounds/clearClientIps/:email`

### 13. 其他操作

#### 获取在线用户
**端点**: `POST /panel/api/inbounds/onlines`

#### 删除流量耗尽的客户端
**端点**: `POST /panel/api/inbounds/delDepletedClients/:id`

---

## 🚀 出站管理 API

**基础路径**: `/panel/api/outbounds`

### 1. 获取出站列表

**端点**: `POST /panel/api/outbounds/list`

### 2. 添加出站

**端点**: `POST /panel/api/outbounds/add`

**请求**:
```json
{
  "tag": "proxy-out",
  "protocol": "vless",
  "settings": "{\"vnext\":[{\"address\":\"server.com\",\"port\":443,\"users\":[{\"id\":\"uuid\"}]}]}",
  "streamSettings": "{\"network\":\"tcp\",\"security\":\"reality\",...}"
}
```

### 3. 更新出站

**端点**: `POST /panel/api/outbounds/update/:tag`

### 4. 删除出站

**端点**: `POST /panel/api/outbounds/del/:tag`

### 5. 重置出站流量

**端点**: `POST /panel/api/outbounds/resetTraffic/:tag`

### 6. 重置所有出站流量

**端点**: `POST /panel/api/outbounds/resetAllTraffics`

---

## 🛤️ 路由管理 API

**基础路径**: `/panel/api/routing`

### 1. 获取路由配置

**端点**: `POST /panel/api/routing/get`

### 2. 更新路由配置

**端点**: `POST /panel/api/routing/update`

**请求**:
```json
{
  "domainStrategy": "IPIfNonMatch",
  "rules": [
    {
      "type": "field",
      "outboundTag": "blocked",
      "domain": ["geosite:category-ads-all"]
    }
  ]
}
```

### 3. 添加路由规则

**端点**: `POST /panel/api/routing/rule/add`

**请求**:
```json
{
  "type": "field",
  "outboundTag": "direct",
  "domain": ["geosite:cn"]
}
```

### 4. 删除路由规则

**端点**: `POST /panel/api/routing/rule/del`

### 5. 更新路由规则

**端点**: `POST /panel/api/routing/rule/update`

---

## 📡 订阅管理 API

**基础路径**: `/panel/api/subscription`

### 1. 获取订阅设置

**端点**: `POST /panel/api/subscription/settings/get`

**响应**:
```json
{
  "success": true,
  "msg": "",
  "obj": {
    "enable": true,
    "listen": "0.0.0.0",
    "port": 2096,
    "path": "/sub",
    "jsonPath": "/json"
  }
}
```

### 2. 更新订阅设置

**端点**: `POST /panel/api/subscription/settings/update`

**请求**:
```json
{
  "enable": true,
  "listen": "0.0.0.0",
  "port": 2096,
  "path": "/sub",
  "jsonPath": "/json"
}
```

### 3. 启用订阅服务

**端点**: `POST /panel/api/subscription/enable`

### 4. 禁用订阅服务

**端点**: `POST /panel/api/subscription/disable`

### 5. 获取订阅链接

**端点**: `GET /panel/api/subscription/urls/:id`

**参数**:
- `id`: 入站ID

**响应**:
```json
{
  "success": true,
  "msg": "",
  "obj": {
    "subscriptionUrl": "http://your-server:2096/sub/inbound-id",
    "jsonSubscriptionUrl": "http://your-server:2096/json/inbound-id"
  }
}
```

---

## 🎯 备份管理 API

### 创建备份并发送给管理员

**端点**: `GET /panel/api/createbackup`

**说明**: 创建数据库备份并通过Telegram发送给管理员

---

## 📊 数据模型

### Inbound 模型

```json
{
  "id": 1,
  "up": 0,
  "down": 0,
  "total": 0,
  "remark": "入站备注",
  "enable": true,
  "expiryTime": 0,
  "listen": "",
  "port": 443,
  "protocol": "vless",
  "settings": "{JSON字符串}",
  "streamSettings": "{JSON字符串}",
  "tag": "inbound-443",
  "sniffing": "{JSON字符串}",
  "allocate": "{JSON字符串}"
}
```

### Client 模型

```json
{
  "id": "uuid字符串",
  "security": "none",
  "password": "trojan密码",
  "flow": "xtls-rprx-vision",
  "email": "user@example.com",
  "limitIp": 2,
  "totalGB": 107374182400,
  "expiryTime": 1735689600000,
  "enable": true,
  "tgId": 123456789,
  "subId": "自定义订阅ID",
  "comment": "用户备注",
  "reset": 0
}
```

### OutboundTraffics 模型

```json
{
  "id": 1,
  "tag": "outbound-tag",
  "up": 0,
  "down": 0,
  "total": 0
}
```

---

## ❌ 错误处理

### 标准响应格式

**成功响应**:
```json
{
  "success": true,
  "msg": "操作成功",
  "obj": {...}
}
```

**错误响应**:
```json
{
  "success": false,
  "msg": "错误信息",
  "obj": null
}
```

### 常见错误码

- **401**: 未认证 - 需要重新登录
- **403**: 权限不足
- **404**: 资源不存在
- **500**: 服务器内部错误

---

## 🔧 使用示例

### Node.js 示例

```javascript
const axios = require('axios');

class XUIClient {
  constructor(baseURL) {
    this.client = axios.create({
      baseURL,
      withCredentials: true,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  // 登录
  async login(username, password) {
    const response = await this.client.post('/login', {
      username,
      password,
    });
    return response.data;
  }

  // 获取入站列表
  async getInbounds() {
    const response = await this.client.get('/panel/api/inbounds/list');
    return response.data;
  }

  // 添加高级客户端
  async addClientAdvanced(clientData) {
    const response = await this.client.post('/panel/api/inbounds/addClientAdvanced', clientData);
    return response.data;
  }

  // 获取客户端详情
  async getClientDetails(email) {
    const response = await this.client.get(`/panel/api/inbounds/client/details/${email}`);
    return response.data;
  }
}

// 使用示例
const client = new XUIClient('http://your-server:2053');

async function main() {
  // 登录
  await client.login('admin', 'admin');
  
  // 添加客户端
  const clientResult = await client.addClientAdvanced({
    inboundId: 1,
    email: 'user@example.com',
    flow: 'xtls-rprx-vision',
    limitIp: 2,
    totalGB: 107374182400,
    expiryTime: Date.now() + 30 * 24 * 60 * 60 * 1000, // 30天后过期
    enable: true,
    comment: 'API创建的用户'
  });
  
  console.log('客户端创建结果:', clientResult);
  
  // 获取客户端详情
  const details = await client.getClientDetails('user@example.com');
  console.log('客户端详情:', details);
}

main().catch(console.error);
```

### Python 示例

```python
import requests
import json
from typing import Dict, Any

class XUIClient:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({'Content-Type': 'application/json'})
    
    def login(self, username: str, password: str) -> Dict[str, Any]:
        """登录获取session"""
        response = self.session.post(f'{self.base_url}/login', json={
            'username': username,
            'password': password
        })
        return response.json()
    
    def get_inbounds(self) -> Dict[str, Any]:
        """获取入站列表"""
        response = self.session.get(f'{self.base_url}/panel/api/inbounds/list')
        return response.json()
    
    def add_client_advanced(self, client_data: Dict[str, Any]) -> Dict[str, Any]:
        """添加高级客户端"""
        response = self.session.post(
            f'{self.base_url}/panel/api/inbounds/addClientAdvanced',
            json=client_data
        )
        return response.json()
    
    def get_client_details(self, email: str) -> Dict[str, Any]:
        """获取客户端详情"""
        response = self.session.get(
            f'{self.base_url}/panel/api/inbounds/client/details/{email}'
        )
        return response.json()

# 使用示例
if __name__ == "__main__":
    client = XUIClient('http://your-server:2053')
    
    # 登录
    login_result = client.login('admin', 'admin')
    print('登录结果:', login_result)
    
    # 添加客户端
    client_data = {
        'inboundId': 1,
        'email': 'user@example.com',
        'flow': 'xtls-rprx-vision',
        'limitIp': 2,
        'totalGB': 107374182400,
        'expiryTime': int(time.time() * 1000) + 30 * 24 * 60 * 60 * 1000,  # 30天后过期
        'enable': True,
        'comment': 'Python API创建的用户'
    }
    
    result = client.add_client_advanced(client_data)
    print('客户端创建结果:', result)
    
    # 获取客户端详情
    details = client.get_client_details('user@example.com')
    print('客户端详情:', details)
```

### cURL 示例

```bash
#!/bin/bash

BASE_URL="http://your-server:2053"
USERNAME="admin"
PASSWORD="admin"

# 登录获取cookie
curl -c cookies.txt -X POST "${BASE_URL}/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}"

# 获取入站列表
curl -b cookies.txt -X GET "${BASE_URL}/panel/api/inbounds/list"

# 添加高级客户端
curl -b cookies.txt -X POST "${BASE_URL}/panel/api/inbounds/addClientAdvanced" \
  -H "Content-Type: application/json" \
  -d '{
    "inboundId": 1,
    "email": "user@example.com",
    "flow": "xtls-rprx-vision",
    "limitIp": 2,
    "totalGB": 107374182400,
    "expiryTime": 1735689600000,
    "enable": true,
    "comment": "cURL创建的用户"
  }'

# 获取客户端详情
curl -b cookies.txt -X GET "${BASE_URL}/panel/api/inbounds/client/details/user@example.com"
```

---

## ⚡ 高级功能特性

### 1. 自定义订阅功能
- 支持为每个客户端设置独立的订阅ID
- 自动生成订阅链接和JSON格式链接
- 支持个性化订阅地址

### 2. 流量管理
- 设置客户端流量限制 (totalGB)
- 自动流量统计和限制
- 支持流量重置功能

### 3. 时间管理
- 设置客户端到期时间 (expiryTime)
- 自动过期处理
- 支持批量删除过期客户端

### 4. IP限制
- 限制单个客户端最大并发IP数 (limitIp)
- IP记录和管理
- IP清理功能

### 5. Telegram集成
- 支持Telegram用户ID绑定 (tgId)
- 自动消息通知
- 登录和操作日志推送

---

## 📝 注意事项

1. **认证要求**: 所有API请求都需要先登录获取session cookie
2. **时间格式**: 时间戳使用毫秒级Unix时间戳
3. **流量单位**: 流量以字节为单位
4. **JSON格式**: 配置参数使用JSON字符串格式
5. **重启要求**: 某些操作需要重启Xray服务才能生效

---

## 🆕 版本更新

### v1.0 (Enhanced API)
- ✅ 新增高级客户端管理API
- ✅ 新增出站管理完整API
- ✅ 新增路由管理API
- ✅ 新增订阅管理API
- ✅ 增强客户端功能 (流量限制、到期时间、IP限制等)
- ✅ 支持自定义订阅ID和链接
- ✅ 完善错误处理和响应格式

---

**© 2024 3X-UI Enhanced API | 维护者: WCOJBK**
