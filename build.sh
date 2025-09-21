#!/bin/bash

# 3X-UI Linux Build Script
# This script builds 3x-ui for various Linux architectures

set -e

VERSION=$(cat config/version)
BUILD_TIME=$(date '+%Y%m%d%H%M%S')
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LD_FLAGS="-w -s -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME} -X main.commitSha=${COMMIT_SHA}"

echo "Building 3x-ui v${VERSION}"
echo "Build time: ${BUILD_TIME}"
echo "Commit: ${COMMIT_SHA}"

# Create build directory
mkdir -p build

# Build for different architectures
build_for_arch() {
    local arch=$1
    local goos="linux"
    
    echo "Building for ${arch}..."
    
    # Set architecture-specific variables
    case ${arch} in
        "amd64")
            GOARCH="amd64"
            ;;
        "386") 
            GOARCH="386"
            ;;
        "arm64")
            GOARCH="arm64"
            ;;
        "armv7")
            GOARCH="arm"
            GOARM="7"
            export GOARM
            ;;
        "armv6")
            GOARCH="arm" 
            GOARM="6"
            export GOARM
            ;;
        "armv5")
            GOARCH="arm"
            GOARM="5" 
            export GOARM
            ;;
        "s390x")
            GOARCH="s390x"
            ;;
        *)
            echo "Unsupported architecture: ${arch}"
            return 1
            ;;
    esac
    
    # Build the binary
    CGO_ENABLED=1 GOOS=${goos} GOARCH=${GOARCH} go build -ldflags="${LD_FLAGS}" -o build/x-ui-${goos}-${arch} main.go
    
    if [ $? -eq 0 ]; then
        echo "✓ Built x-ui-${goos}-${arch}"
    else
        echo "✗ Failed to build x-ui-${goos}-${arch}"
        return 1
    fi
}

# Download Xray binaries for each architecture
download_xray() {
    local arch=$1
    
    case ${arch} in
        "amd64")
            XRAY_ARCH="64"
            ;;
        "386")
            XRAY_ARCH="32"
            ;;
        "arm64")
            XRAY_ARCH="arm64-v8a"
            ;;
        "armv7")
            XRAY_ARCH="arm32-v7a"
            ;;
        "armv6")
            XRAY_ARCH="arm32-v6"
            ;;
        "armv5")
            XRAY_ARCH="arm32-v5"
            ;;
        "s390x")
            XRAY_ARCH="s390x"
            ;;
        *)
            echo "Unsupported Xray architecture: ${arch}"
            return 1
            ;;
    esac
    
    echo "Downloading Xray for ${arch}..."
    mkdir -p build/bin
    cd build/bin
    
    # Download and extract Xray
    wget -q "https://github.com/XTLS/Xray-core/releases/download/v25.1.30/Xray-linux-${XRAY_ARCH}.zip"
    unzip -q "Xray-linux-${XRAY_ARCH}.zip"
    rm -f "Xray-linux-${XRAY_ARCH}.zip" geoip.dat geosite.dat
    mv xray "xray-linux-${arch}"
    chmod +x "xray-linux-${arch}"
    
    cd ../../
}

# Download geo files
download_geo_files() {
    echo "Downloading geo files..."
    cd build/bin
    
    # Download various geo datasets
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
    wget -q -O geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
    wget -q -O geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
    wget -q -O geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q -O geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat
    
    cd ../../
}

# Create release package for an architecture
create_package() {
    local arch=$1
    local package_name="x-ui-linux-${arch}"
    
    echo "Creating package for ${arch}..."
    
    # Create package directory
    mkdir -p build/${package_name}/bin
    mkdir -p build/${package_name}/web
    
    # Copy files
    cp build/x-ui-linux-${arch} build/${package_name}/x-ui
    cp build/bin/xray-linux-${arch} build/${package_name}/bin/
    cp -r build/bin/*.dat build/${package_name}/bin/ 2>/dev/null || true
    cp -r web build/${package_name}/
    cp x-ui.service build/${package_name}/
    cp x-ui.sh build/${package_name}/
    
    # Make executables
    chmod +x build/${package_name}/x-ui
    chmod +x build/${package_name}/bin/xray-linux-${arch}
    chmod +x build/${package_name}/x-ui.sh
    
    # Create tar.gz
    cd build
    tar -czf ${package_name}.tar.gz ${package_name}/
    rm -rf ${package_name}/
    cd ..
    
    echo "✓ Created ${package_name}.tar.gz"
}

# Main build process
main() {
    # Check if Go is available
    if ! command -v go &> /dev/null; then
        echo "Go is not installed. Please install Go 1.23+ and try again."
        exit 1
    fi
    
    # Check Go version
    GO_VERSION=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+')
    if [[ $(echo "${GO_VERSION} < 1.20" | bc -l) -eq 1 ]]; then
        echo "Go version ${GO_VERSION} is too old. Please use Go 1.20 or newer."
        exit 1
    fi
    
    echo "Using Go version: $(go version)"
    
    # Clean previous builds
    rm -rf build/*
    
    # Download geo files once
    mkdir -p build/bin
    download_geo_files
    
    # Supported architectures
    ARCHITECTURES=("amd64" "386" "arm64" "armv7" "armv6" "armv5" "s390x")
    
    # Build for each architecture if no specific arch provided
    if [ $# -eq 0 ]; then
        echo "Building for all supported architectures..."
        for arch in "${ARCHITECTURES[@]}"; do
            build_for_arch ${arch} && download_xray ${arch} && create_package ${arch}
        done
    else
        # Build for specific architectures
        for arch in "$@"; do
            if [[ " ${ARCHITECTURES[@]} " =~ " ${arch} " ]]; then
                build_for_arch ${arch} && download_xray ${arch} && create_package ${arch}
            else
                echo "Unsupported architecture: ${arch}"
                echo "Supported architectures: ${ARCHITECTURES[*]}"
                exit 1
            fi
        done
    fi
    
    echo ""
    echo "Build completed! Generated files:"
    ls -la build/*.tar.gz
}

# Show usage
usage() {
    echo "Usage: $0 [architecture...]"
    echo ""
    echo "Supported architectures:"
    echo "  amd64   - 64-bit x86 (most common)"
    echo "  386     - 32-bit x86" 
    echo "  arm64   - 64-bit ARM (modern ARM devices)"
    echo "  armv7   - 32-bit ARMv7 (older ARM devices)"
    echo "  armv6   - 32-bit ARMv6 (very old ARM devices)"
    echo "  armv5   - 32-bit ARMv5 (legacy ARM devices)"
    echo "  s390x   - IBM System z"
    echo ""
    echo "Examples:"
    echo "  $0                # Build for all architectures"
    echo "  $0 amd64          # Build only for amd64"
    echo "  $0 amd64 arm64    # Build for amd64 and arm64"
}

# Handle help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@"
