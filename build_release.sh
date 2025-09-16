#!/bin/bash

# 3X-UI Enhanced API Release Build Script
# This script builds binaries for multiple architectures and creates release packages

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Version information
VERSION=${1:-"v1.0.0"}
BUILD_TIME=$(date '+%Y-%m-%d %H:%M:%S')
GIT_COMMIT=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -e "${BLUE}=== 3X-UI Enhanced API Release Builder ===${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Build Time: ${BUILD_TIME}${NC}"
echo -e "${YELLOW}Git Commit: ${GIT_COMMIT}${NC}"
echo -e "${YELLOW}Git Branch: ${GIT_BRANCH}${NC}"
echo ""

# Clean previous builds
echo -e "${BLUE}Cleaning previous builds...${NC}"
rm -rf dist/
mkdir -p dist/

# Build information
LDFLAGS="-s -w -X main.version=${VERSION} -X 'main.buildTime=${BUILD_TIME}' -X main.gitCommit=${GIT_COMMIT}"

# Supported platforms
declare -a PLATFORMS=(
    "linux/amd64"
    "linux/386" 
    "linux/arm64"
    "linux/arm"
    "linux/armv5"
    "linux/armv6"
    "linux/armv7"
    "linux/s390x"
    "linux/mips64"
    "linux/mips64le"
    "linux/mips"
    "linux/mipsle"
    "freebsd/amd64"
    "freebsd/386"
    "freebsd/arm64"
    "freebsd/arm"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
    "windows/386"
    "windows/arm64"
)

echo -e "${BLUE}Building for ${#PLATFORMS[@]} platforms...${NC}"

for platform in "${PLATFORMS[@]}"; do
    IFS='/' read -ra PLATFORM_SPLIT <<< "$platform"
    GOOS=${PLATFORM_SPLIT[0]}
    GOARCH=${PLATFORM_SPLIT[1]}
    
    echo -e "${YELLOW}Building for $GOOS/$GOARCH...${NC}"
    
    output_name="x-ui"
    if [ $GOOS = "windows" ]; then
        output_name+='.exe'
    fi
    
    # Special handling for different ARM versions
    case $GOARCH in
        "armv5")
            GOARM=5
            GOARCH=arm
            ;;
        "armv6") 
            GOARM=6
            GOARCH=arm
            ;;
        "armv7")
            GOARM=7  
            GOARCH=arm
            ;;
        *)
            unset GOARM
            ;;
    esac
    
    # Build directory
    build_dir="dist/x-ui-${GOOS}-${GOARCH}"
    if [ ! -z "$GOARM" ]; then
        build_dir="dist/x-ui-${GOOS}-armv${GOARM}"
    fi
    
    mkdir -p $build_dir/bin
    
    # Build binary
    if [ ! -z "$GOARM" ]; then
        env GOOS=$GOOS GOARCH=$GOARCH GOARM=$GOARM go build -ldflags "$LDFLAGS" -o $build_dir/$output_name main.go
    else
        env GOOS=$GOOS GOARCH=$GOARCH go build -ldflags "$LDFLAGS" -o $build_dir/$output_name main.go
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to build for $GOOS/$GOARCH${NC}"
        continue
    fi
    
    # Copy additional files
    cp x-ui.sh $build_dir/
    cp x-ui.service $build_dir/
    cp LICENSE $build_dir/
    cp README.md $build_dir/
    cp -r web/html $build_dir/web/
    cp -r web/assets $build_dir/web/
    
    # Create README for this build
    cat > $build_dir/README_BUILD.txt << EOF
3X-UI Enhanced API ${VERSION}
============================

Build Information:
- Platform: ${GOOS}/${GOARCH}
- Version: ${VERSION}  
- Build Time: ${BUILD_TIME}
- Git Commit: ${GIT_COMMIT}
- Git Branch: ${GIT_BRANCH}

Installation:
1. Extract this package to /usr/local/
2. Run: chmod +x x-ui x-ui.sh
3. Copy x-ui.service to /etc/systemd/system/
4. Run: systemctl daemon-reload && systemctl enable x-ui && systemctl start x-ui

For detailed documentation, see:
- https://github.com/WCOJBK/x-ui-api-main/blob/main/COMPLETE_API_DOCUMENTATION.md
- https://github.com/WCOJBK/x-ui-api-main/blob/main/README.md

EOF
    
    # Create archive
    archive_name="x-ui-${GOOS}-${GOARCH}"
    if [ ! -z "$GOARM" ]; then
        archive_name="x-ui-${GOOS}-armv${GOARM}"
    fi
    
    cd dist
    if [ $GOOS = "windows" ]; then
        # Create ZIP for Windows
        zip -r "${archive_name}.zip" "${archive_name##*/}/"
        echo -e "${GREEN}✓ Created ${archive_name}.zip${NC}"
    else
        # Create TAR.GZ for Unix-like systems
        tar -czf "${archive_name}.tar.gz" "${archive_name##*/}/"
        echo -e "${GREEN}✓ Created ${archive_name}.tar.gz${NC}"
    fi
    cd ..
    
    # Clean up build directory
    rm -rf $build_dir
done

echo ""
echo -e "${GREEN}=== Build Summary ===${NC}"
echo -e "${BLUE}Release packages created in dist/ directory:${NC}"
ls -la dist/ | grep -E '\.(tar\.gz|zip)$'

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Create a new release on GitHub"
echo -e "2. Upload the packages from dist/ directory"
echo -e "3. Write release notes using the template below"
echo ""

# Generate release notes template  
cat > RELEASE_NOTES_TEMPLATE.md << 'EOF'
# 🚀 3X-UI Enhanced API v1.0.0

> **Major Update: Complete API Enhancement with 49 Endpoints**

---

## 📋 What's New in v1.0.0

### 🆕 **New API Modules**
- **📡 Outbound Management** - 6 new endpoints for managing outbound configurations
- **🛣️ Routing Management** - 5 new endpoints for dynamic routing rules  
- **📰 Subscription Management** - 5 new endpoints for subscription handling
- **👥 Advanced Client Features** - Enhanced client management with custom settings

### 📊 **API Growth**
- **Total Endpoints**: 49 (vs 19 in original) - **+157% increase**
- **Management Modules**: 5 (vs 2 in original)
- **New Features**: 25+ advanced features

### 🔧 **Technical Improvements**
- ✅ Complete source code enhancement
- ✅ Advanced client features (traffic limits, expiry, custom subscription URLs)
- ✅ Multi-language documentation (EN, CN, ES, FA, RU)
- ✅ Postman collection for API testing
- ✅ Docker support
- ✅ Comprehensive error handling

---

## 📥 **Installation**

### Quick Install (Recommended)
```bash
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/install_enhanced.sh)
```

### Manual Download
Choose your platform from the assets below:
- **Linux AMD64**: `x-ui-linux-amd64.tar.gz`
- **Linux ARM64**: `x-ui-linux-arm64.tar.gz`
- **Linux ARM v7**: `x-ui-linux-armv7.tar.gz`
- **Windows AMD64**: `x-ui-windows-amd64.zip`
- **Other platforms**: See full list in assets

---

## 🆕 **New API Endpoints**

### 📡 **Outbound Management**
- `POST /panel/api/outbounds/list` - List all outbounds
- `POST /panel/api/outbounds/add` - Add new outbound
- `POST /panel/api/outbounds/del/:tag` - Delete outbound
- `POST /panel/api/outbounds/update/:tag` - Update outbound
- `POST /panel/api/outbounds/resetTraffic/:tag` - Reset traffic
- `POST /panel/api/outbounds/resetAllTraffics` - Reset all traffic

### 🛣️ **Routing Management** 
- `POST /panel/api/routing/get` - Get routing config
- `POST /panel/api/routing/update` - Update routing
- `POST /panel/api/routing/rule/add` - Add routing rule
- `POST /panel/api/routing/rule/del` - Delete routing rule
- `POST /panel/api/routing/rule/update` - Update routing rule

### 📰 **Subscription Management**
- `POST /panel/api/subscription/settings/get` - Get subscription settings
- `POST /panel/api/subscription/settings/update` - Update settings
- `POST /panel/api/subscription/enable` - Enable subscription
- `POST /panel/api/subscription/disable` - Disable subscription  
- `GET /panel/api/subscription/urls/:id` - Get subscription URLs

### 👥 **Enhanced Inbound Management**
- `POST /panel/api/inbounds/addClientAdvanced` - Add client with advanced features
- `GET /panel/api/inbounds/client/details/:email` - Get client details
- `POST /panel/api/inbounds/client/update/:email` - Update client settings

---

## 📚 **Documentation**

- **[Complete API Documentation](COMPLETE_API_DOCUMENTATION.md)** - Detailed API reference
- **[Quick Reference Guide](API_QUICK_REFERENCE.md)** - API endpoints summary
- **[Installation Guide](UPGRADE_TO_ENHANCED_API.md)** - Step-by-step installation
- **[Postman Collection](3X-UI-Enhanced-API.postman_collection.json)** - Ready-to-use API tests

---

## 🔄 **Upgrade from Original 3X-UI**

If you're running the original 3X-UI, use our upgrade script:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/compile_upgrade.sh)
```

---

## 🐛 **Bug Fixes & Improvements**

- ✅ Fixed installation script download sources
- ✅ Improved error handling in API responses  
- ✅ Enhanced database migration process
- ✅ Better session management
- ✅ Optimized client traffic tracking
- ✅ Improved Xray core integration

---

## 🙏 **Acknowledgments**

Special thanks to:
- **MHSanaei** - Original 3X-UI creator
- **alireza0** - Important contributions  
- **WCOJBK** - Enhanced API development and maintenance

---

## 📞 **Support**

- **Documentation**: https://github.com/WCOJBK/x-ui-api-main
- **Issues**: https://github.com/WCOJBK/x-ui-api-main/issues
- **Discussions**: https://github.com/WCOJBK/x-ui-api-main/discussions

---

**Full Changelog**: https://github.com/WCOJBK/x-ui-api-main/compare/v0.0.0...v1.0.0
EOF

echo -e "${GREEN}✅ Release notes template created: RELEASE_NOTES_TEMPLATE.md${NC}"
echo -e "${BLUE}📦 Total build artifacts: $(ls dist/*.tar.gz dist/*.zip 2>/dev/null | wc -l)${NC}"
