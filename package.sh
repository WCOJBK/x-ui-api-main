#!/bin/bash

# Create release package for specific architecture
set -e

ARCH=$1
VERSION=${2:-"v2.5.2"}

if [ -z "$ARCH" ]; then
    echo "Usage: $0 <architecture> [version]"
    exit 1
fi

echo "Creating package for $ARCH..."

PACKAGE_NAME="x-ui-linux-${ARCH}"
BUILD_TIME=$(date '+%Y%m%d_%H%M%S')
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Create package directory
mkdir -p release/${PACKAGE_NAME}/bin

# Copy main binary
if [ ! -f "build/x-ui-linux-${ARCH}" ]; then
    echo "Error: Binary build/x-ui-linux-${ARCH} not found"
    exit 1
fi

cp build/x-ui-linux-${ARCH} release/${PACKAGE_NAME}/x-ui
chmod +x release/${PACKAGE_NAME}/x-ui

# Copy Xray binary
if [ ! -f "build/bin/xray-linux-${ARCH}" ]; then
    echo "Error: Xray binary build/bin/xray-linux-${ARCH} not found"
    exit 1
fi

cp build/bin/xray-linux-${ARCH} release/${PACKAGE_NAME}/bin/
chmod +x release/${PACKAGE_NAME}/bin/xray-linux-${ARCH}

# Copy geo files
cp build/bin/*.dat release/${PACKAGE_NAME}/bin/ 2>/dev/null || true

# Copy web assets
if [ -d "web" ]; then
    cp -r web release/${PACKAGE_NAME}/
else
    echo "Warning: web directory not found"
fi

# Copy service files
cp x-ui.service release/${PACKAGE_NAME}/ 2>/dev/null || echo "Warning: x-ui.service not found"
cp x-ui.sh release/${PACKAGE_NAME}/ 2>/dev/null || echo "Warning: x-ui.sh not found"
chmod +x release/${PACKAGE_NAME}/x-ui.sh 2>/dev/null || true

# Copy documentation
cp README*.md release/${PACKAGE_NAME}/ 2>/dev/null || true
cp LICENSE release/${PACKAGE_NAME}/ 2>/dev/null || true

# Create version info
cat > release/${PACKAGE_NAME}/VERSION << EOF
Version: ${VERSION}
Build Time: ${BUILD_TIME}
Commit: ${COMMIT_SHA}
Architecture: ${ARCH}
EOF

# Create installation script
cat > release/${PACKAGE_NAME}/install.sh << 'EOF'
#!/bin/bash

# 3X-UI Installation Script
set -e

echo "Installing 3x-ui..."

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Please use: sudo ./install.sh"
   exit 1
fi

# Stop existing service
echo "Stopping existing service..."
systemctl stop x-ui 2>/dev/null || true

# Create installation directory
echo "Creating installation directory..."
mkdir -p /usr/local/x-ui

# Backup existing installation
if [ -d "/usr/local/x-ui" ] && [ "$(ls -A /usr/local/x-ui)" ]; then
    echo "Backing up existing installation..."
    mv /usr/local/x-ui /usr/local/x-ui.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    mkdir -p /usr/local/x-ui
fi

# Copy files
echo "Installing files..."
cp -rf * /usr/local/x-ui/

# Set permissions
chmod +x /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/bin/xray-linux-* 2>/dev/null || true
chmod +x /usr/local/x-ui/x-ui.sh 2>/dev/null || true

# Install service file
echo "Installing systemd service..."
cp /usr/local/x-ui/x-ui.service /etc/systemd/system/ 2>/dev/null || true

# Install management script
cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui 2>/dev/null || true
chmod +x /usr/bin/x-ui 2>/dev/null || true

# Reload systemd and enable service
echo "Configuring service..."
systemctl daemon-reload
systemctl enable x-ui

echo ""
echo "=============================================="
echo "  3X-UI Installation Completed!"
echo "=============================================="
echo ""
echo "Management Commands:"
echo "  systemctl start x-ui     - Start service"
echo "  systemctl stop x-ui      - Stop service"
echo "  systemctl restart x-ui   - Restart service"
echo "  systemctl status x-ui    - Check status"
echo "  x-ui                     - Management menu"
echo ""
echo "Next steps:"
echo "1. Start the service: systemctl start x-ui"
echo "2. Access the web panel (default: http://your-ip:2053)"
echo "3. Use 'x-ui' command for advanced management"
echo ""
EOF

chmod +x release/${PACKAGE_NAME}/install.sh

# Create uninstall script
cat > release/${PACKAGE_NAME}/uninstall.sh << 'EOF'
#!/bin/bash

# 3X-UI Uninstallation Script
set -e

echo "Uninstalling 3x-ui..."

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Please use: sudo ./uninstall.sh"
   exit 1
fi

# Stop and disable service
echo "Stopping service..."
systemctl stop x-ui 2>/dev/null || true
systemctl disable x-ui 2>/dev/null || true

# Remove service file
echo "Removing service files..."
rm -f /etc/systemd/system/x-ui.service
systemctl daemon-reload
systemctl reset-failed 2>/dev/null || true

# Remove installation directory
echo "Removing installation files..."
rm -rf /usr/local/x-ui

# Remove management script
rm -f /usr/bin/x-ui

echo ""
echo "3X-UI has been completely uninstalled."
echo ""
EOF

chmod +x release/${PACKAGE_NAME}/uninstall.sh

# Create compressed archive
echo "Creating compressed archive..."
cd release
tar -czf ${PACKAGE_NAME}.tar.gz ${PACKAGE_NAME}/

# Calculate file info
FILE_SIZE=$(du -h ${PACKAGE_NAME}.tar.gz | cut -f1)
FILE_HASH=$(sha256sum ${PACKAGE_NAME}.tar.gz | cut -d' ' -f1)

# Clean up directory
rm -rf ${PACKAGE_NAME}/
cd ..

echo "✓ Package created: release/${PACKAGE_NAME}.tar.gz"
echo "  Size: ${FILE_SIZE}"
echo "  SHA256: ${FILE_HASH}"
