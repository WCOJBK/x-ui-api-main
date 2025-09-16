#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "arch: $(arch)"

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

if [[ "${release}" == "arch" ]]; then
    echo "Your OS is Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "Your OS is Parch Linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "Your OS is Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "Your OS is Armbian"
elif [[ "${release}" == "alpine" ]]; then
    echo "Your OS is Alpine Linux"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "Your OS is OpenSUSE Tumbleweed"
elif [[ "${release}" == "openEuler" ]]; then
    if [[ ${os_version} -lt 2203 ]]; then
        echo -e "${red} Please use OpenEuler 22.03 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use CentOS 8 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 2004 ]]; then
        echo -e "${red} Please use Ubuntu 20 or higher version!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} Please use Fedora 36 or higher version!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "amzn" ]]; then
    if [[ ${os_version} != "2023" ]]; then
        echo -e "${red} Please use Amazon Linux 2023!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} Please use Debian 11 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 80 ]]; then
        echo -e "${red} Please use AlmaLinux 8.0 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use Rocky Linux 8 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ol" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use Oracle Linux 8 or higher ${plain}\n" && exit 1
    fi
else
    echo -e "${red}Your operating system is not supported by this script.${plain}\n"
    echo "Please ensure you are using one of the following supported operating systems:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- OpenEuler 22.03+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 8.0+"
    echo "- Rocky Linux 8+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    echo "- Amazon Linux 2023"
    exit 1
fi

install_base() {
    echo -e "${blue}Installing system dependencies...${plain}"
    case "${release}" in
    ubuntu | debian | armbian)
        # Handle package lock issues
        if pgrep -f unattended-upgr >/dev/null 2>&1; then
            echo -e "${yellow}Waiting for automatic updates to complete...${plain}"
            while pgrep -f unattended-upgr >/dev/null 2>&1; do
                sleep 5
            done
        fi
        
        apt-get update && apt-get install -y -q wget curl tar tzdata golang-go git
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata golang git
        ;;
    fedora | amzn)
        dnf -y update && dnf install -y -q wget curl tar tzdata golang git
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata go git
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone go git
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata golang-go git
        ;;
    esac
    
    # Verify Go installation
    if ! command -v go &> /dev/null; then
        echo -e "${red}Go installation failed${plain}"
        exit 1
    fi
    
    echo -e "${green}Go version: $(go version)${plain}"
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

config_after_install() {
    local existing_username=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'username: .+' | awk '{print $2}')
    local existing_password=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'password: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local server_ip=$(curl -s https://api.ipify.org)

    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_username" == "admin" && "$existing_password" == "admin" ]]; then
            local config_webBasePath=$(gen_random_string 15)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            read -p "Would you like to customize the Panel Port settings? (If not, a random port will be applied) [y/n]: " config_confirm
            if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
                read -p "Please set up the panel port: " config_port
                echo -e "${yellow}Your Panel Port is: ${config_port}${plain}"
            else
                local config_port=$(shuf -i 1024-62000 -n 1)
                echo -e "${yellow}Generated random port: ${config_port}${plain}"
            fi

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
            echo -e "This is a fresh installation, generating random login info for security concerns:"
            echo -e "###############################################"
            echo -e "${green}Username: ${config_username}${plain}"
            echo -e "${green}Password: ${config_password}${plain}"
            echo -e "${green}Port: ${config_port}${plain}"
            echo -e "${green}WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}Access URL: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}If you forgot your login info, you can type 'x-ui settings' to check${plain}"
        else
            local config_webBasePath=$(gen_random_string 15)
            echo -e "${yellow}WebBasePath is missing or too short. Generating a new one...${plain}"
            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
            echo -e "${green}New WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}Access URL: http://${server_ip}:${existing_port}/${config_webBasePath}${plain}"
        fi
    else
        if [[ "$existing_username" == "admin" && "$existing_password" == "admin" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            echo -e "${yellow}Default credentials detected. Security update required...${plain}"
            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}"
            echo -e "Generated new random login credentials:"
            echo -e "###############################################"
            echo -e "${green}Username: ${config_username}${plain}"
            echo -e "${green}Password: ${config_password}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}If you forgot your login info, you can type 'x-ui settings' to check${plain}"
        else
            echo -e "${green}Username, Password, and WebBasePath are properly set. Exiting...${plain}"
        fi
    fi

    /usr/local/x-ui/x-ui migrate
}

install_x-ui_enhanced() {
    echo -e "${green}=== 3X-UI Enhanced API Installation ===${plain}"
    
    cd /usr/local/
    
    # Remove existing installation
    if [[ -e /usr/local/x-ui/ ]]; then
        echo -e "${yellow}Stopping existing x-ui service...${plain}"
        systemctl stop x-ui
        echo -e "${yellow}Backing up existing installation...${plain}"
        mv /usr/local/x-ui /usr/local/x-ui-backup-$(date +%Y%m%d_%H%M%S)
    fi
    
    # Create temp directory for compilation
    tmp_dir="/tmp/x-ui-enhanced"
    rm -rf $tmp_dir
    mkdir -p $tmp_dir
    cd $tmp_dir
    
    # Clone the enhanced repository
    echo -e "${blue}Downloading enhanced version source code (with compatibility fixes)...${plain}"
    git clone https://github.com/WCOJBK/x-ui-api-main.git .
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}Failed to clone enhanced repository${plain}"
        exit 1
    fi
    
    # Build the enhanced version
    echo -e "${blue}Compiling enhanced version...${plain}"
    echo -e "${yellow}This may take a few minutes...${plain}"
    
    # Set Go environment
    export GOPROXY=https://goproxy.cn,direct
    export GOSUMDB=sum.golang.org
    
    go mod tidy
    if [[ $? -ne 0 ]]; then
        echo -e "${red}Failed to download dependencies${plain}"
        exit 1
    fi
    
    go build -ldflags="-s -w" -o x-ui main.go
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}Failed to compile enhanced version${plain}"
        echo -e "${yellow}This may be due to Xray-core version compatibility issues${plain}"
        echo -e "${yellow}Attempting to use a stable Go module version...${plain}"
        
        # Try to use more stable dependencies
        go mod edit -go=1.21
        go mod tidy
        go build -ldflags="-s -w" -o x-ui main.go
        
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Compilation failed even with stable dependencies${plain}"
            echo -e "${yellow}Please check the GitHub repository for updates or use the upgrade script instead${plain}"
            exit 1
        fi
    fi
    
    # Create installation directory
    mkdir -p /usr/local/x-ui/bin
    
    # Copy compiled binary
    cp x-ui /usr/local/x-ui/x-ui
    chmod +x /usr/local/x-ui/x-ui
    
    # Copy shell script
    cp x-ui.sh /usr/local/x-ui/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    
    # Download xray binary (use original source since we only enhance the panel)
    echo -e "${blue}Downloading xray core...${plain}"
    XRAY_VERSION=$(curl -Ls "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -n "$XRAY_VERSION" ]]; then
        wget -N --no-check-certificate -O /tmp/Xray-linux-$(arch).zip https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-$(arch).zip
        if [[ $? -eq 0 ]]; then
            unzip -o /tmp/Xray-linux-$(arch).zip -d /usr/local/x-ui/bin/
            mv /usr/local/x-ui/bin/xray /usr/local/x-ui/bin/xray-linux-$(arch)
            chmod +x /usr/local/x-ui/bin/xray-linux-$(arch)
            rm /tmp/Xray-linux-$(arch).zip
        else
            echo -e "${yellow}Warning: Failed to download Xray core, using existing version${plain}"
        fi
    fi
    
    # Copy service file
    cp x-ui.service /etc/systemd/system/
    
    # Install management script
    cp x-ui.sh /usr/bin/x-ui
    chmod +x /usr/bin/x-ui
    
    echo -e "${green}Enhanced version compiled and installed successfully!${plain}"
    
    # Clean up temp directory
    cd /
    rm -rf $tmp_dir
    
    # Configure after installation
    config_after_install
    
    # Start services
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    
    # Verify installation
    sleep 5
    if systemctl is-active --quiet x-ui; then
        echo -e "${green}=== Installation Complete ===${plain}"
        echo -e ""
        echo -e "${blue}🎉 3X-UI Enhanced API v1.0.0 installation finished!${plain}"
        echo -e ""
        echo -e "${yellow}🆕 New API Features:${plain}"
        echo -e "✅ Outbound Management API (6 endpoints)"
        echo -e "✅ Routing Management API (5 endpoints)"  
        echo -e "✅ Subscription Management API (5 endpoints)"
        echo -e "✅ Advanced Client Features (custom subscriptions, traffic limits, expiry)"
        echo -e "✅ Total: 49 API endpoints (vs 19 in original)"
        echo -e "✅ Fixed Xray-core compatibility issues"
    else
        echo -e "${red}Warning: x-ui service failed to start${plain}"
        echo -e "${yellow}Please check the logs: journalctl -u x-ui --no-pager${plain}"
    fi
    
    echo -e ""
    echo -e "┌───────────────────────────────────────────────────────┐
│  ${blue}x-ui control menu usages (subcommands):${plain}              │
│                                                       │
│  ${blue}x-ui${plain}              - Admin Management Script          │
│  ${blue}x-ui start${plain}        - Start                            │
│  ${blue}x-ui stop${plain}         - Stop                             │
│  ${blue}x-ui restart${plain}      - Restart                          │
│  ${blue}x-ui status${plain}       - Current Status                   │
│  ${blue}x-ui settings${plain}     - Current Settings                 │
│  ${blue}x-ui enable${plain}       - Enable Autostart on OS Startup   │
│  ${blue}x-ui disable${plain}      - Disable Autostart on OS Startup  │
│  ${blue}x-ui log${plain}          - Check logs                       │
│  ${blue}x-ui banlog${plain}       - Check Fail2ban ban logs          │
│  ${blue}x-ui update${plain}       - Update                           │
│  ${blue}x-ui legacy${plain}       - legacy version                   │
│  ${blue}x-ui install${plain}      - Install                          │
│  ${blue}x-ui uninstall${plain}    - Uninstall                        │
└───────────────────────────────────────────────────────┘"
}

echo -e "${green}Running Enhanced 3X-UI Installation (Fixed Version)...${plain}"
install_base
install_x-ui_enhanced $1
