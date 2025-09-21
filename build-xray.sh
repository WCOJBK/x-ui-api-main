#!/bin/bash

# Download Xray binary for specific architecture
set -e

ARCH=$1
if [ -z "$ARCH" ]; then
    echo "Usage: $0 <architecture>"
    echo "Supported architectures: amd64, 386, arm64, armv7, armv6, armv5, s390x"
    exit 1
fi

# Map architecture names
case $ARCH in
    "amd64") XRAY_ARCH="64" ;;
    "386") XRAY_ARCH="32" ;;
    "arm64") XRAY_ARCH="arm64-v8a" ;;
    "armv7") XRAY_ARCH="arm32-v7a" ;;
    "armv6") XRAY_ARCH="arm32-v6" ;;
    "armv5") XRAY_ARCH="arm32-v5" ;;
    "s390x") XRAY_ARCH="s390x" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Downloading Xray for $ARCH (${XRAY_ARCH})..."

# Create directories
mkdir -p build/bin

# Download Xray
cd build/bin
wget -q "https://github.com/XTLS/Xray-core/releases/download/v25.1.30/Xray-linux-${XRAY_ARCH}.zip"
unzip -q "Xray-linux-${XRAY_ARCH}.zip"
rm "Xray-linux-${XRAY_ARCH}.zip"
mv xray "xray-linux-${ARCH}"
chmod +x "xray-linux-${ARCH}"

# Download geo files if not exists
if [ ! -f "geoip.dat" ]; then
    echo "Downloading geo files..."
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
    wget -q -O geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
    wget -q -O geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
    wget -q -O geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q -O geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat
fi

cd ../../
echo "✓ Xray downloaded for $ARCH"
