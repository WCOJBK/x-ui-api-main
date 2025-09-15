# 3X-UI API 使用指南

## API 概述

本项目已增强API功能，支持通过编程方式管理VLESS-XTLS-uTLS-REALITY节点，包括：

- ✅ 入站配置管理（支持VLESS-REALITY）
- ✅ 出站规则配置
- ✅ 路由规则配置
- ✅ 订阅链接管理
- ✅ 客户端流量限制
- ✅ 到期时间设置
- ✅ 个性化订阅地址

## 认证

所有API请求需要先登录获取session：

```bash
curl -X POST "http://your-server:2053/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin"
  }' \
  -c cookies.txt
```

## 1. 添加VLESS-XTLS-uTLS-REALITY入站

### 基础入站配置

```bash
curl -X POST "http://your-server:2053/panel/api/inbounds/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "enable": true,
    "port": 443,
    "protocol": "vless",
    "settings": "{\"clients\":[],\"decryption\":\"none\",\"fallbacks\":[]}",
    "streamSettings": "{\"network\":\"tcp\",\"security\":\"reality\",\"realitySettings\":{\"show\":false,\"dest\":\"www.microsoft.com:443\",\"xver\":0,\"serverNames\":[\"www.microsoft.com\"],\"privateKey\":\"YOUR-PRIVATE-KEY\",\"publicKey\":\"YOUR-PUBLIC-KEY\",\"minClientVer\":\"\",\"maxClientVer\":\"\",\"maxTimeDiff\":0,\"shortIds\":[\"\"]}}",
    "tag": "vless-reality-443",
    "sniffing": "{\"enabled\":true,\"destOverride\":[\"http\",\"tls\"]}"
  }'
```

## 2. 添加高级客户端（支持流量限制、到期时间、订阅地址）

### 添加带完整功能的客户端

```bash
curl -X POST "http://your-server:2053/panel/api/inbounds/addClientAdvanced" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "inboundId": 1,
    "email": "user@example.com",
    "uuid": "12345678-1234-1234-1234-123456789012",
    "flow": "xtls-rprx-vision",
    "limitIp": 2,
    "totalGB": 107374182400,
    "expiryTime": 1735689600000,
    "enable": true,
    "tgId": 123456789,
    "subId": "custom-sub-id",
    "comment": "用户备注信息",
    "reset": 0
  }'
```

**参数说明：**
- `limitIp`: IP连接数限制
- `totalGB`: 流量限制（字节，107374182400 = 100GB）
- `expiryTime`: 到期时间（毫秒时间戳）
- `subId`: 自定义订阅ID（可选，不提供则自动生成）
- `tgId`: Telegram用户ID（可选）

**响应示例：**
```json
{
  "success": true,
  "msg": "",
  "obj": {
    "client": {
      "id": "12345678-1234-1234-1234-123456789012",
      "email": "user@example.com",
      "totalGB": 107374182400,
      "expiryTime": 1735689600000,
      "enable": true,
      "subId": "custom-sub-id"
    },
    "subscription": {
      "normalSub": "http://your-server:2096/sub/custom-sub-id",
      "jsonSub": "http://your-server:2096/json/custom-sub-id"
    }
  }
}
```

## 3. 获取客户端详细信息

```bash
curl -X GET "http://your-server:2053/panel/api/inbounds/client/details/user@example.com" \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

**响应示例：**
```json
{
  "success": true,
  "msg": "",
  "obj": {
    "traffic": {
      "email": "user@example.com",
      "up": 1024000,
      "down": 2048000,
      "total": 107374182400,
      "expiryTime": 1735689600000,
      "enable": true
    },
    "subscription": {
      "normalSub": "http://your-server:2096/sub/user@example.com",
      "jsonSub": "http://your-server:2096/json/user@example.com"
    }
  }
}
```

## 4. 更新客户端高级设置

```bash
curl -X POST "http://your-server:2053/panel/api/inbounds/client/update/user@example.com" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "totalGB": 214748364800,
    "expiryTime": 1767225600000,
    "enable": true,
    "comment": "更新后的备注"
  }'
```

## 5. 添加出站规则

### 直连出站
```bash
curl -X POST "http://your-server:2053/panel/api/outbounds/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "tag": "direct",
    "protocol": "freedom",
    "settings": {}
  }'
```

### 代理出站
```bash
curl -X POST "http://your-server:2053/panel/api/outbounds/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "tag": "proxy-out",
    "protocol": "vless",
    "settings": {
      "vnext": [
        {
          "address": "upstream.server.com",
          "port": 443,
          "users": [
            {
              "id": "upstream-uuid",
              "encryption": "none",
              "flow": "xtls-rprx-vision"
            }
          ]
        }
      ]
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "fingerprint": "chrome",
        "serverName": "www.microsoft.com",
        "publicKey": "UPSTREAM-PUBLIC-KEY"
      }
    }
  }'
```

## 6. 添加路由规则

### 国内网站直连
```bash
curl -X POST "http://your-server:2053/panel/api/routing/rule/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "type": "field",
    "outboundTag": "direct",
    "domain": [
      "geosite:cn",
      "geosite:geolocation-cn"
    ]
  }'
```

### 国内IP直连
```bash
curl -X POST "http://your-server:2053/panel/api/routing/rule/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "type": "field",
    "outboundTag": "direct",
    "ip": [
      "geoip:cn",
      "geoip:private"
    ]
  }'
```

### 广告拦截
```bash
curl -X POST "http://your-server:2053/panel/api/routing/rule/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "type": "field",
    "outboundTag": "block",
    "domain": [
      "geosite:category-ads-all"
    ]
  }'
```

### BT流量拦截
```bash
curl -X POST "http://your-server:2053/panel/api/routing/rule/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "type": "field",
    "outboundTag": "block",
    "protocol": ["bittorrent"]
  }'
```

## 7. 订阅功能

### 获取订阅设置
```bash
curl -X POST "http://your-server:2053/panel/api/subscription/settings/get" \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

### 获取指定入站的订阅链接
```bash
curl -X GET "http://your-server:2053/panel/api/subscription/urls/1" \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

## 8. 流量管理

### 重置客户端流量
```bash
curl -X POST "http://your-server:2053/panel/api/inbounds/1/resetClientTraffic/user@example.com" \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

### 获取在线客户端
```bash
curl -X POST "http://your-server:2053/panel/api/inbounds/onlines" \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

## 完整部署脚本示例

```bash
#!/bin/bash

SERVER="your-server.com"
PORT="2053"
PANEL_URL="http://${SERVER}:${PORT}"

# 登录
echo "正在登录..."
curl -X POST "${PANEL_URL}/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin"}' \
  -c cookies.txt -s

# 添加VLESS-Reality入站
echo "添加VLESS-Reality入站..."
INBOUND_RESPONSE=$(curl -X POST "${PANEL_URL}/panel/api/inbounds/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt -s \
  -d '{
    "enable": true,
    "port": 443,
    "protocol": "vless",
    "settings": "{\"clients\":[],\"decryption\":\"none\",\"fallbacks\":[]}",
    "streamSettings": "{\"network\":\"tcp\",\"security\":\"reality\",\"realitySettings\":{\"show\":false,\"dest\":\"www.microsoft.com:443\",\"xver\":0,\"serverNames\":[\"www.microsoft.com\"],\"privateKey\":\"YOUR-PRIVATE-KEY\",\"publicKey\":\"YOUR-PUBLIC-KEY\",\"shortIds\":[\"\"]}}",
    "tag": "vless-reality-443",
    "sniffing": "{\"enabled\":true,\"destOverride\":[\"http\",\"tls\"]}"
  }')

# 提取入站ID
INBOUND_ID=$(echo $INBOUND_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)
echo "入站ID: $INBOUND_ID"

# 添加高级客户端
echo "添加高级客户端..."
UUID=$(uuidgen)
EXPIRY_TIME=$(($(date +%s + 86400 * 30) * 1000)) # 30天后过期

curl -X POST "${PANEL_URL}/panel/api/inbounds/addClientAdvanced" \
  -H "Content-Type: application/json" \
  -b cookies.txt -s \
  -d "{
    \"inboundId\": $INBOUND_ID,
    \"email\": \"user@example.com\",
    \"uuid\": \"$UUID\",
    \"flow\": \"xtls-rprx-vision\",
    \"limitIp\": 2,
    \"totalGB\": 107374182400,
    \"expiryTime\": $EXPIRY_TIME,
    \"enable\": true,
    \"comment\": \"API创建的用户\"
  }" | jq '.'

# 添加路由规则
echo "添加路由规则..."

# 直连出站
curl -X POST "${PANEL_URL}/panel/api/outbounds/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt -s \
  -d '{"tag": "direct", "protocol": "freedom", "settings": {}}'

# 拦截出站
curl -X POST "${PANEL_URL}/panel/api/outbounds/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt -s \
  -d '{"tag": "block", "protocol": "blackhole", "settings": {}}'

# 国内直连规则
curl -X POST "${PANEL_URL}/panel/api/routing/rule/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt -s \
  -d '{"type": "field", "outboundTag": "direct", "domain": ["geosite:cn"]}'

# 广告拦截规则
curl -X POST "${PANEL_URL}/panel/api/routing/rule/add" \
  -H "Content-Type: application/json" \
  -b cookies.txt -s \
  -d '{"type": "field", "outboundTag": "block", "domain": ["geosite:category-ads-all"]}'

echo "部署完成！"
echo "用户UUID: $UUID"
echo "到期时间: $(date -d @$((EXPIRY_TIME/1000)) '+%Y-%m-%d %H:%M:%S')"

# 清理
rm cookies.txt
```

## 错误处理

API调用可能返回以下错误：

- `400`: 请求参数错误
- `401`: 未认证或认证失败
- `500`: 服务器内部错误

错误响应格式：
```json
{
  "success": false,
  "msg": "错误详细信息",
  "obj": null
}
```

## 时间戳转换

JavaScript:
```javascript
// 当前时间后30天
const expiryTime = Date.now() + (30 * 24 * 60 * 60 * 1000);
```

Python:
```python
import time
# 当前时间后30天
expiry_time = int((time.time() + (30 * 24 * 60 * 60)) * 1000)
```

## 流量单位转换

- 1GB = 1,073,741,824 字节
- 10GB = 10,737,418,240 字节  
- 100GB = 107,374,182,400 字节
- 1TB = 1,099,511,627,776 字节
