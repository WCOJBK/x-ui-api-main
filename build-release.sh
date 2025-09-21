#!/bin/bash

# 3X-UI Release Build Script
# This script creates optimized release builds for Linux deployment

set -e

# Configuration
PROJECT_NAME="3x-ui"
VERSION=$(cat config/version)
BUILD_TIME=$(date '+%Y%m%d_%H%M%S')
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DIR="release"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} 3X-UI Release Build v${VERSION}${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Build time: ${BUILD_TIME}"
echo -e "Commit: ${COMMIT_SHA}"
echo ""

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    rm -rf temp_build/
}
trap cleanup EXIT

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check Go
    if ! command -v go &> /dev/null; then
        echo -e "${RED}Error: Go is not installed${NC}"
        exit 1
    fi
    
    # Check Go version
    GO_VERSION=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+' | head -1)
    echo "Go version: ${GO_VERSION}"
    
    # Check required tools
    for tool in wget unzip tar; do
        if ! command -v ${tool} &> /dev/null; then
            echo -e "${RED}Error: ${tool} is not installed${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✓ Prerequisites check passed${NC}"
    echo ""
}

# Build configuration
setup_build_env() {
    echo -e "${BLUE}Setting up build environment...${NC}"
    
    # Clean and create directories
    rm -rf ${BUILD_DIR}
    mkdir -p ${BUILD_DIR}
    mkdir -p temp_build
    
    # Set build flags
    export CGO_ENABLED=1
    export LD_FLAGS="-w -s -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME} -X main.commitSha=${COMMIT_SHA}"
    
    echo -e "${GREEN}✓ Build environment ready${NC}"
    echo ""
}

# Download dependencies
download_dependencies() {
    local arch=$1
    echo -e "${BLUE}Downloading dependencies for ${arch}...${NC}"
    
    # Create temp directory for this architecture
    mkdir -p temp_build/${arch}
    cd temp_build/${arch}
    
    # Map architecture names for Xray downloads
    case ${arch} in
        "amd64") XRAY_ARCH="64" ;;
        "386") XRAY_ARCH="32" ;;
        "arm64") XRAY_ARCH="arm64-v8a" ;;
        "armv7") XRAY_ARCH="arm32-v7a" ;;
        "armv6") XRAY_ARCH="arm32-v6" ;;
        "armv5") XRAY_ARCH="arm32-v5" ;;
        "s390x") XRAY_ARCH="s390x" ;;
        *) 
            echo -e "${RED}Unsupported architecture: ${arch}${NC}"
            cd ../../
            return 1
            ;;
    esac
    
    # Download Xray core
    echo "  Downloading Xray core (${XRAY_ARCH})..."
    wget -q "https://github.com/XTLS/Xray-core/releases/download/v25.1.30/Xray-linux-${XRAY_ARCH}.zip" || {
        echo -e "${RED}Failed to download Xray core for ${arch}${NC}"
        cd ../../
        return 1
    }
    
    unzip -q "Xray-linux-${XRAY_ARCH}.zip"
    rm "Xray-linux-${XRAY_ARCH}.zip"
    mv xray "xray-linux-${arch}"
    chmod +x "xray-linux-${arch}"
    
    cd ../../
    echo -e "${GREEN}✓ Dependencies downloaded for ${arch}${NC}"
}

# Download geo files (only once)
download_geo_files() {
    echo -e "${BLUE}Downloading geo files...${NC}"
    
    cd temp_build
    
    # Download geo datasets
    echo "  Downloading Loyalsoldier geo files..."
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
    
    echo "  Downloading Iran geo files..."
    wget -q -O geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat
    wget -q -O geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat
    
    echo "  Downloading Russia geo files..."
    wget -q -O geoip_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -q -O geosite_RU.dat https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat
    
    cd ..
    echo -e "${GREEN}✓ Geo files downloaded${NC}"
}

# Build binary for specific architecture
build_binary() {
    local arch=$1
    echo -e "${BLUE}Building binary for ${arch}...${NC}"
    
    # Set architecture-specific variables
    case ${arch} in
        "amd64") export GOARCH="amd64" ;;
        "386") export GOARCH="386" ;;
        "arm64") export GOARCH="arm64" ;;
        "armv7") export GOARCH="arm"; export GOARM="7" ;;
        "armv6") export GOARCH="arm"; export GOARM="6" ;;
        "armv5") export GOARCH="arm"; export GOARM="5" ;;
        "s390x") export GOARCH="s390x" ;;
        *)
            echo -e "${RED}Unsupported architecture: ${arch}${NC}"
            return 1
            ;;
    esac
    
    export GOOS="linux"
    
    # Build the binary
    echo "  Compiling x-ui binary..."
    go build -ldflags="${LD_FLAGS}" -o temp_build/${arch}/x-ui main.go
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Binary built successfully for ${arch}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to build binary for ${arch}${NC}"
        return 1
    fi
}

# Create release package
create_package() {
    local arch=$1
    local package_name="${PROJECT_NAME}-linux-${arch}"
    
    echo -e "${BLUE}Creating release package for ${arch}...${NC}"
    
    # Create package structure
    mkdir -p ${BUILD_DIR}/${package_name}/bin
    
    # Copy main binary
    cp temp_build/${arch}/x-ui ${BUILD_DIR}/${package_name}/
    chmod +x ${BUILD_DIR}/${package_name}/x-ui
    
    # Copy Xray binary
    cp temp_build/${arch}/xray-linux-${arch} ${BUILD_DIR}/${package_name}/bin/
    chmod +x ${BUILD_DIR}/${package_name}/bin/xray-linux-${arch}
    
    # Copy geo files
    cp temp_build/*.dat ${BUILD_DIR}/${package_name}/bin/
    
    # Copy web assets
    cp -r web ${BUILD_DIR}/${package_name}/
    
    # Copy service files
    cp x-ui.service ${BUILD_DIR}/${package_name}/
    cp x-ui.sh ${BUILD_DIR}/${package_name}/
    chmod +x ${BUILD_DIR}/${package_name}/x-ui.sh
    
    # Copy documentation
    cp README.md ${BUILD_DIR}/${package_name}/ 2>/dev/null || true
    cp LICENSE ${BUILD_DIR}/${package_name}/ 2>/dev/null || true
    
    # Create version info
    cat > ${BUILD_DIR}/${package_name}/VERSION << EOF
Version: ${VERSION}
Build Time: ${BUILD_TIME}
Commit: ${COMMIT_SHA}
Architecture: ${arch}
EOF
    
    # Create installation script
    cat > ${BUILD_DIR}/${package_name}/install.sh << 'EOF'
#!/bin/bash

# Simple installation script for 3x-ui
set -e

echo "Installing 3x-ui..."

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Stop existing service
systemctl stop x-ui 2>/dev/null || true

# Create installation directory
mkdir -p /usr/local/x-ui

# Copy files
cp -rf * /usr/local/x-ui/

# Install service
cp /usr/local/x-ui/x-ui.service /etc/systemd/system/
cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui
chmod +x /usr/bin/x-ui
chmod +x /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/bin/xray-linux-*

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable x-ui

echo "Installation completed!"
echo "Use 'systemctl start x-ui' to start the service"
echo "Use 'x-ui' command for management"
EOF
    chmod +x ${BUILD_DIR}/${package_name}/install.sh
    
    # Create compressed archive
    cd ${BUILD_DIR}
    echo "  Creating compressed archive..."
    tar -czf ${package_name}.tar.gz ${package_name}/
    
    # Calculate file size and checksum
    local file_size=$(du -h ${package_name}.tar.gz | cut -f1)
    local file_hash=$(sha256sum ${package_name}.tar.gz | cut -d' ' -f1)
    
    # Clean up directory
    rm -rf ${package_name}/
    cd ..
    
    echo -e "${GREEN}✓ Package created: ${package_name}.tar.gz (${file_size})${NC}"
    echo "  SHA256: ${file_hash}"
    
    return 0
}

# Generate checksums file
generate_checksums() {
    echo -e "${BLUE}Generating checksums...${NC}"
    
    cd ${BUILD_DIR}
    sha256sum *.tar.gz > checksums.sha256
    cd ..
    
    echo -e "${GREEN}✓ Checksums generated${NC}"
}

# Main build process
main() {
    local architectures=("$@")
    
    # Default to common architectures if none specified
    if [ ${#architectures[@]} -eq 0 ]; then
        architectures=("amd64" "arm64" "armv7")
        echo -e "${YELLOW}No architectures specified, building for: ${architectures[*]}${NC}"
        echo ""
    fi
    
    check_prerequisites
    setup_build_env
    download_geo_files
    
    # Build for each architecture
    local success_count=0
    local total_count=${#architectures[@]}
    
    for arch in "${architectures[@]}"; do
        echo -e "${YELLOW}Building for ${arch}...${NC}"
        echo "----------------------------------------"
        
        if download_dependencies ${arch} && build_binary ${arch} && create_package ${arch}; then
            ((success_count++))
        else
            echo -e "${RED}Failed to build for ${arch}${NC}"
        fi
        
        echo ""
    done
    
    # Generate checksums
    if [ ${success_count} -gt 0 ]; then
        generate_checksums
    fi
    
    # Summary
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} Build Summary${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Successful builds: ${success_count}/${total_count}"
    echo ""
    
    if [ ${success_count} -gt 0 ]; then
        echo -e "${GREEN}Generated files:${NC}"
        ls -la ${BUILD_DIR}/*.tar.gz
        echo ""
        echo -e "${GREEN}Checksums:${NC}"
        cat ${BUILD_DIR}/checksums.sha256
    else
        echo -e "${RED}No successful builds generated${NC}"
        exit 1
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [architecture...]"
    echo ""
    echo "Creates optimized release builds for production deployment."
    echo ""
    echo "Supported architectures:"
    echo "  amd64   - 64-bit x86 (Intel/AMD)"
    echo "  386     - 32-bit x86"
    echo "  arm64   - 64-bit ARM (modern ARM devices, Apple M1, etc.)"
    echo "  armv7   - 32-bit ARMv7 (Raspberry Pi 2/3/4, etc.)"
    echo "  armv6   - 32-bit ARMv6 (Raspberry Pi Zero, etc.)"
    echo "  armv5   - 32-bit ARMv5 (legacy ARM devices)"
    echo "  s390x   - IBM System z"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build for common architectures (amd64, arm64, armv7)"
    echo "  $0 amd64              # Build only for amd64"
    echo "  $0 amd64 arm64        # Build for amd64 and arm64"
    echo "  $0 amd64 arm64 armv7  # Build for multiple architectures"
}

# Handle help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@"
