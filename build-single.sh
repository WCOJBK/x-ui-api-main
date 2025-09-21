#!/bin/bash

# Build x-ui binary for single architecture
set -e

ARCH=$1
if [ -z "$ARCH" ]; then
    echo "Usage: $0 <architecture>"
    exit 1
fi

VERSION=$(cat config/version 2>/dev/null || echo "2.5.2")
BUILD_TIME=$(date '+%Y%m%d_%H%M%S')
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LD_FLAGS="-w -s -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME} -X main.commitSha=${COMMIT_SHA}"

echo "Building x-ui for $ARCH..."

# Set architecture-specific variables
case $ARCH in
    "amd64") 
        export GOARCH="amd64"
        export CC="gcc"
        ;;
    "386") 
        export GOARCH="386"
        export CC="gcc"
        ;;
    "arm64") 
        export GOARCH="arm64"
        export CC="aarch64-linux-gnu-gcc"
        ;;
    "armv7") 
        export GOARCH="arm"
        export GOARM="7"
        export CC="arm-linux-gnueabihf-gcc"
        ;;
    "armv6") 
        export GOARCH="arm"
        export GOARM="6"
        export CC="arm-linux-gnueabihf-gcc"
        ;;
    "armv5") 
        export GOARCH="arm"
        export GOARM="5"
        export CC="arm-linux-gnueabihf-gcc"
        ;;
    "s390x") 
        export GOARCH="s390x"
        export CC="gcc"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

export GOOS="linux"
export CGO_ENABLED=1

# Create build directory
mkdir -p build

# Build the binary
echo "Compiling with GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=$CGO_ENABLED CC=$CC"
go build -ldflags="${LD_FLAGS}" -o build/x-ui-linux-${ARCH} main.go

if [ $? -eq 0 ]; then
    echo "✓ Binary built successfully: build/x-ui-linux-${ARCH}"
    ls -la build/x-ui-linux-${ARCH}
else
    echo "✗ Build failed"
    exit 1
fi
