[English](/README.md) | [فارسی](/README.fa_IR.md) | [中文](/README.zh_CN.md) | [Español](/README.es_ES.md) | [Русский](/README.ru_RU.md)

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./media/3x-ui-dark.png">
    <img alt="3x-ui" src="./media/3x-ui-light.png">
  </picture>
</p>

**一个更好的面板 • 基于Xray Core构建**

[![](https://img.shields.io/github/v/release/mhsanaei/3x-ui.svg)](https://github.com/MHSanaei/3x-ui/releases)
[![](https://img.shields.io/github/actions/workflow/status/mhsanaei/3x-ui/release.yml.svg)](#)
[![GO Version](https://img.shields.io/github/go-mod/go-version/mhsanaei/3x-ui.svg)](#)
[![Downloads](https://img.shields.io/github/downloads/mhsanaei/3x-ui/total.svg)](#)
[![License](https://img.shields.io/badge/license-GPL%20V3-blue.svg?longCache=true)](https://www.gnu.org/licenses/gpl-3.0.en.html)

> **Disclaimer:** 此项目仅供个人学习交流，请不要用于非法目的，请不要在生产环境中使用。

**如果此项目对你有用，请给一个**:star2:

<p align="left">
  <a href="https://buymeacoffee.com/mhsanaei" target="_blank">
    <img src="./media/buymeacoffe.png" alt="Image">
  </a>
</p>

- USDT (TRC20): `TXncxkvhkDWGts487Pjqq1qT9JmwRUz8CC`
- MATIC (polygon): `0x41C9548675D044c6Bfb425786C765bc37427256A`
- LTC (Litecoin): `ltc1q2ach7x6d2zq0n4l0t4zl7d7xe2s6fs7a3vspwv`

## 安装 & 升级

```
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

## 安装旧版本 (我们不建议)

要安装您想要的版本，请使用以下安装命令。例如，ver `v1.7.9`:

```
VERSION=v1.7.9 && <(curl -Ls "https://raw.githubusercontent.com/mhsanaei/3x-ui/$VERSION/install.sh") $VERSION
```

### SSL证书

<details>
  <summary>点击查看SSL证书详情</summary>

### ACME

使用ACME管理SSL证书：

1. 确保您的域名正确解析到服务器。
2. 在终端中运行 `x-ui` 命令，然后选择 `SSL证书管理`。
3. 您将看到以下选项：

   - **Get SSL:** 获取SSL证书。
   - **Revoke:** 吊销现有的SSL证书。
   - **Force Renew:** 强制更新SSL证书。
   - **Show Existing Domains:** 显示服务器上所有可用的域证书。  
   - **Set Certificate Paths for the Panel:** 指定用于面板的域证书。

### Certbot

安装并使用Certbot：

```sh
apt-get install certbot -y
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d yourdomain.com
certbot renew --dry-run
```

### Cloudflare

管理脚本内置了Cloudflare的SSL证书申请。要使用此脚本申请证书，您需要以下信息：

- Cloudflare注册的电子邮件
- Cloudflare全局API密钥
- 域名必须通过Cloudflare解析到当前服务器

**如何获取Cloudflare全局API密钥：**

1. 在终端中运行 `x-ui` 命令，然后选择 `Cloudflare SSL证书`。
2. 访问链接：[Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)。
3. 点击“查看全局API密钥”（参见下图）：
   ![](media/APIKey1.PNG)
4. 您可能需要重新验证您的账户。之后将显示API密钥（参见下图）：
   ![](media/APIKey2.png)

使用时，只需输入您的 `域名`、`电子邮件` 和 `API密钥`。如下图所示：
   ![](media/DetailEnter.png)

</details>

## 手动安装 & 升级

<details>
  <summary>点击查看 手动安装 & 升级</summary>

#### 使用

1. 若要将最新版本的压缩包直接下载到服务器，请运行以下命令：

```sh
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


wget https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${XUI_ARCH}.tar.gz
```

2. 下载压缩包后，执行以下命令安装或升级 x-ui：

```sh
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

</details>

## 通过Docker安装

<details>
  <summary>点击查看 通过Docker安装</summary>

#### 使用

1. 安装Docker：

   ```sh
   bash <(curl -sSL https://get.docker.com)
   ```

2. 克隆仓库：

   ```sh
   git clone https://github.com/MHSanaei/3x-ui.git
   cd 3x-ui
   ```

3. 运行服务：

   ```sh
   docker compose up -d
   ```

   或

   ```sh
   docker run -itd \
      -e XRAY_VMESS_AEAD_FORCED=false \
      -v $PWD/db/:/etc/x-ui/ \
      -v $PWD/cert/:/root/cert/ \
      --network=host \
      --restart=unless-stopped \
      --name 3x-ui \
      ghcr.io/mhsanaei/3x-ui:latest
   ```

更新至最新版本

   ```sh
    cd 3x-ui
    docker compose down
    docker compose pull 3x-ui
    docker compose up -d
   ```

从Docker中删除3x-ui

   ```sh
    docker stop 3x-ui
    docker rm 3x-ui
    cd --
    rm -r 3x-ui
   ```

</details>


## Nginx 设置
<details>
  <summary>点击查看 反向代理配置</summary>

#### Nginx反向代理
```nginx
location / {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Range $http_range;
    proxy_set_header If-Range $http_if_range; 
    proxy_redirect off;
    proxy_pass http://127.0.0.1:2053;
}
```

#### Nginx子路径
- 确保 `/sub` 面板设置中的"面板url根路径"一致
- 面板设置中的 `url` 需要以 `/` 结尾   

```nginx
location /sub {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Range $http_range;
    proxy_set_header If-Range $http_if_range; 
    proxy_redirect off;
    proxy_pass http://127.0.0.1:2053;
}
```
</details>

## 建议使用的操作系统

- Ubuntu 20.04+
- Debian 11+
- CentOS 8+
- OpenEuler 22.03+
- Fedora 36+
- Arch Linux
- Parch Linux
- Manjaro
- Armbian
- AlmaLinux 8.0+
- Rocky Linux 8+
- Oracle Linux 8+
- OpenSUSE Tubleweed
- Amazon Linux 2023
- Windows x64

## 支持的架构和设备
<details>
  <summary>点击查看 支持的架构和设备</summary>

我们的平台提供与各种架构和设备的兼容性，确保在各种计算环境中的灵活性。以下是我们支持的关键架构：

- **amd64**: 这种流行的架构是个人计算机和服务器的标准，可以无缝地适应大多数现代操作系统。

- **x86 / i386**: 这种架构在台式机和笔记本电脑中被广泛采用，得到了众多操作系统和应用程序的广泛支持，包括但不限于 Windows、macOS 和 Linux 系统。

- **armv8 / arm64 / aarch64**: 这种架构专为智能手机和平板电脑等当代移动和嵌入式设备量身定制，以 Raspberry Pi 4、Raspberry Pi 3、Raspberry Pi Zero 2/Zero 2 W、Orange Pi 3 LTS 等设备为例。

- **armv7 / arm / arm32**: 作为较旧的移动和嵌入式设备的架构，它仍然广泛用于Orange Pi Zero LTS、Orange Pi PC Plus、Raspberry Pi 2等设备。

- **armv6 / arm / arm32**: 这种架构面向非常老旧的嵌入式设备，虽然不太普遍，但仍在使用中。Raspberry Pi 1、Raspberry Pi Zero/Zero W 等设备都依赖于这种架构。

- **armv5 / arm / arm32**: 它是一种主要与早期嵌入式系统相关的旧架构，目前不太常见，但仍可能出现在早期 Raspberry Pi 版本和一些旧智能手机等传统设备中。
</details>

## Languages

- English（英语）  
- Persian（波斯语）  
- Traditional Chinese（繁体中文）  
- Simplified Chinese（简体中文）  
- Japanese（日语）  
- Russian（俄语）  
- Vietnamese（越南语）  
- Spanish（西班牙语）  
- Indonesian（印尼语）  
- Ukrainian（乌克兰语）  
- Turkish（土耳其语）  
- Português (Brazil)（葡萄牙语（巴西））


## 最新更新 (2025.09.22)

### 🚀 出站和路由管理功能强化

由于原生3X-UI面板的API路由缺失问题，我们在**增强API**中实现了完整的前端操作模拟功能：

#### 📡 新增模拟端点
- **出站管理**: `/panel/api/enhanced/tools/simulate/outbounds/{list,add,update,delete}`  
- **路由管理**: `/panel/api/enhanced/tools/simulate/routing/{get,update}`  
- **路由规则**: `/panel/api/enhanced/tools/simulate/routing/rule/{add,delete,update}`

#### 🔧 技术实现
- **前端操作模拟**: 直接通过 `/panel/xray/` 和 `/panel/xray/update` 端点操作Xray配置
- **配置直接操作**: 绕过缺失的原生API路由，直接读写Xray配置JSON
- **完全兼容**: 支持所有原生面板的出站和路由功能

#### 🎯 Python客户端增强
- **自动增强API检测**: 客户端自动推断增强API地址（端口8080）
- **透明切换**: 出站/路由操作自动使用增强API模拟端点
- **详细调试日志**: 完整的HTTP请求/响应调试信息

#### ⚙️ 升级方法
```bash
# 在服务器上运行升级脚本
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/install_standalone_enhanced_api.sh)

# 配置面板访问信息
export XUI_BASE_URL="http://127.0.0.1:2053/your_base_path"  
export PANEL_USER="your_username"
export PANEL_PASS="your_password"
sudo systemctl restart x-ui-enhanced-api
```

#### ✅ 解决的问题
- ✅ 原生面板404错误: `404 page not found` for `/panel/api/outbounds/`
- ✅ 出站配置无法添加/更新/删除
- ✅ 路由规则管理功能缺失
- ✅ 快速字符串解析HTTP代理配置
- ✅ 完整的GUI图形界面管理

---

## Features

- 系统状态监控
- 在所有入站和客户端中搜索
- 深色/浅色主题
- 支持多用户和多协议
- 支持多种协议，包括 VMess、VLESS、Trojan、Shadowsocks、Dokodemo-door、Socks、HTTP、wireguard
- 支持 XTLS 原生协议，包括 RPRX-Direct、Vision、REALITY
- 流量统计、流量限制、过期时间限制
- 可自定义的 Xray配置模板
- 支持HTTPS访问面板（自建域名+SSL证书）
- 支持一键式SSL证书申请和自动续费
- 更多高级配置项目请参考面板
- 修复了 API 路由（用户设置将使用 API 创建）
- 支持通过面板中提供的不同项目更改配置。
- 支持从面板导出/导入数据库


## 默认面板设置

<details>
  <summary>点击查看默认设置详情</summary>

### 用户名、密码、端口和 Web Base Path

如果您选择不修改这些设置，它们将随机生成（不适用于 Docker）。

**Docker 的默认设置：**
- **用户名：** admin
- **密码：** admin
- **端口：** 2053

### 数据库管理：

  您可以直接在面板中方便地进行数据库备份和还原。

- **数据库路径:**
  - `/etc/x-ui/x-ui.db`

### Web 基础路径

1. **重置 Web 基础路径:**
   - 打开终端。
   - 运行 `x-ui` 命令。
   - 选择 `重置 Web 基础路径` 选项。

2. **生成或自定义路径:**
   - 路径将会随机生成，或者您可以输入自定义路径。

3. **查看当前设置:**
   - 要查看当前设置，请在终端中使用 `x-ui settings` 命令，或在 `x-ui` 面板中点击 `查看当前设置`。

### 安全建议：
- 为了提高安全性，建议在URL结构中使用一个长的随机词。

**示例：**
- `http://ip:port/*webbasepath*/panel`
- `http://domain:port/*webbasepath*/panel`

</details>

## WARP 配置

<details>
  <summary>点击查看 WARP 配置详情</summary>

#### 使用方法

**对于 `v2.1.0` 及之后的版本：**

WARP 已内置，无需额外安装。只需在面板中开启相关配置即可。

</details>

## IP 限制

<details>
  <summary>点击查看 IP 限制详情</summary>

#### 使用方法

**注意:** 当使用 IP 隧道时，IP 限制将无法正常工作。

- **对于 `v1.6.1` 及之前的版本：**
  - IP 限制功能已内置于面板中。

**对于 `v1.7.0` 及更新的版本：**

要启用 IP 限制功能，您需要安装 `fail2ban` 及其所需的文件，步骤如下：

1. 在终端中运行 `x-ui` 命令，然后选择 `IP 限制管理`。
2. 您将看到以下选项：

   - **更改封禁时长:** 调整封禁时长。
   - **解除所有封禁:** 解除当前的所有封禁。
   - **查看日志:** 查看日志。
   - **Fail2ban 状态:** 检查 `fail2ban` 的状态。
   - **重启 Fail2ban:** 重启 `fail2ban` 服务。
   - **卸载 Fail2ban:** 卸载带有配置的 Fail2ban。

3. 在面板中通过设置 `Xray 配置/log/访问日志` 为 `./access.log` 添加访问日志路径，然后保存并重启 Xray。

- **对于 `v2.1.3` 之前的版本：**
  - 您需要在 Xray 配置中手动设置访问日志路径：

    ```sh
    "log": {
      "access": "./access.log",
      "dnsLog": false,
      "loglevel": "warning"
    },
    ```

- **对于 `v2.1.3` 及之后的版本：**
  - 面板中直接提供了配置 `access.log` 的选项。

</details>

## Telegram 机器人

<details>
  <summary>点击查看 Telegram 机器人</summary>

#### 使用

Web 面板通过 Telegram Bot 支持每日流量、面板登录、数据库备份、系统状态、客户端信息等通知和功能。要使用机器人，您需要在面板中设置机器人相关参数，包括：

- 电报令牌
- 管理员聊天 ID
- 通知时间（cron 语法）
- 到期日期通知
- 流量上限通知
- 数据库备份
- CPU 负载通知


**参考：**

- `30 \* \* \* \* \*` - 在每个点的 30 秒处通知
- `0 \*/10 \* \* \* \*` - 每 10 分钟的第一秒通知
- `@hourly` - 每小时通知
- `@daily` - 每天通知 (00:00)
- `@weekly` - 每周通知
- `@every 8h` - 每8小时通知

### Telegram Bot 功能

- 定期报告
- 登录通知
- CPU 阈值通知
- 提前报告的过期时间和流量阈值
- 如果将客户的电报用户名添加到用户的配置中，则支持客户端报告菜单
- 支持使用UUID（VMESS/VLESS）或密码（TROJAN）搜索报文流量报告 - 匿名
- 基于菜单的机器人
- 通过电子邮件搜索客户端（仅限管理员）
- 检查所有入库
- 检查服务器状态
- 检查耗尽的用户
- 根据请求和定期报告接收备份
- 多语言机器人

### 注册 Telegram bot

- 与 [Botfather](https://t.me/BotFather) 对话：
    ![Botfather](./media/botfather.png)

- 使用 /newbot 创建新机器人：你需要提供机器人名称以及用户名，注意名称中末尾要包含“bot”
    ![创建机器人](./media/newbot.png)

- 启动您刚刚创建的机器人。可以在此处找到机器人的链接。
    ![令牌](./media/token.png)

- 输入您的面板并配置 Telegram 机器人设置，如下所示：
    ![面板设置](./media/panel-bot-config.png)

在输入字段编号 3 中输入机器人令牌。
在输入字段编号 4 中输入用户 ID。具有此 id 的 Telegram 帐户将是机器人管理员。 （您可以输入多个，只需将它们用“ ，”分开即可）

- 如何获取TG ID? 使用 [bot](https://t.me/useridinfobot)， 启动机器人，它会给你 Telegram 用户 ID。
![用户 ID](./media/user-id.png)

</details>

## API 路由

<details>
  <summary>点击查看 API 路由</summary>

#### 使用

- [API 文档](https://www.postman.com/hsanaei/3x-ui/collection/q1l5l0u/3x-ui)
- `/login` 使用 `POST` 用户名称 & 密码： `{username: '', password: ''}` 登录
- `/panel/api/inbounds` 以下操作的基础：

|  方法  | 路径                               | 操作                              |
| :----: | ---------------------------------- | --------------------------------- |
| `GET`  | `"/list"`                          | 获取所有入站                      |
| `GET`  | `"/get/:id"`                       | 获取所有入站以及inbound.id        |
| `GET`  | `"/getClientTraffics/:email"`      | 通过电子邮件获取客户端流量        |
| `GET`  | `"/createbackup"`                  | Telegram 机器人向管理员发送备份   |
| `POST` | `"/add"`                           | 添加入站                          |
| `POST` | `"/del/:id"`                       | 删除入站                          |
| `POST` | `"/update/:id"`                    | 更新入站                          |
| `POST` | `"/clientIps/:email"`              | 客户端 IP 地址                    |
| `POST` | `"/clearClientIps/:email"`         | 清除客户端 IP 地址                |
| `POST` | `"/addClient"`                     | 将客户端添加到入站                |
| `POST` | `"/:id/delClient/:clientId"`       | 通过 clientId\* 删除客户端        |
| `POST` | `"/updateClient/:clientId"`        | 通过 clientId\* 更新客户端        |
| `POST` | `"/:id/resetClientTraffic/:email"` | 重置客户端的流量                  |
| `POST` | `"/resetAllTraffics"`              | 重置所有入站的流量                |
| `POST` | `"/resetAllClientTraffics/:id"`    | 重置入站中所有客户端的流量        |
| `POST` | `"/delDepletedClients/:id"`        | 删除入站耗尽的客户端 （-1： all） |
| `POST` | `"/onlines"`                       | 获取在线用户 （ 电子邮件列表 ）   |

\*- `clientId` 项应该使用下列数据

- `client.id`  VMESS and VLESS
- `client.password`  TROJAN
- `client.email`  Shadowsocks

- [<img src="https://run.pstmn.io/button.svg" alt="Run In Postman" style="width: 128px; height: 32px;">](https://app.getpostman.com/run-collection/5146551-dda3cab3-0e33-485f-96f9-d4262f437ac5?action=collection%2Ffork&source=rip_markdown&collection-url=entityId%3D5146551-dda3cab3-0e33-485f-96f9-d4262f437ac5%26entityType%3Dcollection%26workspaceId%3Dd64f609f-485a-4951-9b8f-876b3f917124)
</details>

## 环境变量

<details>
  <summary>点击查看 环境变量</summary>

#### Usage

| 变量           |                      Type                      | 默认          |
| -------------- | :--------------------------------------------: | :------------ |
| XUI_LOG_LEVEL  | `"debug"` \| `"info"` \| `"warn"` \| `"error"` | `"info"`      |
| XUI_DEBUG      |                   `boolean`                    | `false`       |
| XUI_BIN_FOLDER |                    `string`                    | `"bin"`       |
| XUI_DB_FOLDER  |                    `string`                    | `"/etc/x-ui"` |
| XUI_LOG_FOLDER |                    `string`                    | `"/var/log"`  |

例子：

```sh
XUI_BIN_FOLDER="bin" XUI_DB_FOLDER="/etc/x-ui" go build main.go
```

</details>

## 预览

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./media/01-overview-dark.png">
  <img alt="3x-ui" src="./media/01-overview-light.png">
</picture>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./media/02-inbounds-dark.png">
  <img alt="3x-ui" src="./media/02-inbounds-light.png">
</picture>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./media/03-add-inbound-dark.png">
  <img alt="3x-ui" src="./media/03-add-inbound-light.png">
</picture>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./media/04-add-client-dark.png">
  <img alt="3x-ui" src="./media/04-add-client-light.png">
</picture>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./media/05-settings-dark.png">
  <img alt="3x-ui" src="./media/05-settings-light.png">
</picture>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./media/06-configs-dark.png">
  <img alt="3x-ui" src="./media/06-configs-light.png">
</picture>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./media/07-bot-dark.png">
  <img alt="3x-ui" src="./media/07-bot-light.png">
</picture>

## 特别感谢

- [alireza0](https://github.com/alireza0/)

## 致谢

- [Iran v2ray rules](https://github.com/chocolate4u/Iran-v2ray-rules) (License: **GPL-3.0**): _Enhanced v2ray/xray and v2ray/xray-clients routing rules with built-in Iranian domains and a focus on security and adblocking._
- [Russia v2ray rules](https://github.com/runetfreedom/russia-v2ray-rules-dat) (License: **GPL-3.0**): _This repository contains automatically updated V2Ray routing rules based on data on blocked domains and addresses in Russia._

## Star趋势

[![Stargazers over time](https://starchart.cc/MHSanaei/3x-ui.svg?variant=adaptive)](https://starchart.cc/MHSanaei/3x-ui)