#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${blue}=== 修复Ubuntu包管理器卡住问题 ===${plain}"

# 1. 强制终止可能卡住的进程
echo -e "${yellow}步骤1: 终止可能冲突的进程...${plain}"
pkill -f unattended-upgr || true
pkill -f apt || true
pkill -f dpkg || true

# 2. 移除锁文件
echo -e "${yellow}步骤2: 清理包管理器锁文件...${plain}"
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/dpkg/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/apt/lists/lock

# 3. 重新配置dpkg
echo -e "${yellow}步骤3: 重新配置dpkg...${plain}"
dpkg --configure -a

# 4. 修复可能损坏的包
echo -e "${yellow}步骤4: 修复可能损坏的包...${plain}"
apt-get -f install -y

# 5. 更新包索引
echo -e "${yellow}步骤5: 更新包索引...${plain}"
apt-get clean
apt-get update

echo -e "${green}✅ 包管理器问题已修复！${plain}"
echo -e "${blue}现在可以重新运行安装脚本了${plain}"
