#!/bin/sh

# OpenWrt specific installation script for komari-agent
# Optimized for mt7621 based devices

# Color definitions for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${NC} $1"
}

log_config() {
    echo -e "${CYAN}[CONFIG]${NC} $1"
}

# Default values
service_name="komari-agent"
target_dir="/opt/komari"
github_proxy=""
install_version=""
need_vnstat=false

# Parse install-specific arguments
komari_args=""
while [ $# -gt 0 ]; do
    case $1 in
        --install-dir)
            target_dir="$2"
            shift 2
            ;;
        --install-service-name)
            service_name="$2"
            shift 2
            ;;
        --install-ghproxy)
            github_proxy="$2"
            shift 2
            ;;
        --install-version)
            install_version="$2"
            shift 2
            ;;
        --month-rotate)
            need_vnstat=true
            komari_args="$komari_args $1"
            shift
            ;;
        --install*)
            log_warning "Unknown install parameter: $1"
            shift
            ;;
        *)
            # Non-install arguments go to komari_args
            komari_args="$komari_args $1"
            shift
            ;;
    esac
done

# Remove leading space from komari_args if present
komari_args="${komari_args# }"

komari_agent_path="${target_dir}/agent"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log_error "Please run as root"
    exit 1
fi

echo -e "${WHITE}===========================================${NC}"
echo -e "${WHITE} Komari Agent OpenWrt Installation Script ${NC}"
echo -e "${WHITE} Optimized for mt7621 devices ${NC}"
echo -e "${WHITE}===========================================${NC}"
echo ""
log_config "Installation configuration:" 
log_config "  Service name: ${GREEN}$service_name${NC}"
log_config "  Install directory: ${GREEN}$target_dir${NC}"
log_config "  GitHub proxy: ${GREEN}${github_proxy:-"(direct)"}${NC}"
log_config "  Binary arguments: ${GREEN}$komari_args${NC}"
if [ -n "$install_version" ]; then
    log_config "  Specified agent version: ${GREEN}$install_version${NC}"
else
    log_config "  Agent version: ${GREEN}Latest${NC}"
fi
if [ "$need_vnstat" = true ]; then
    log_config "  vnstat installation: ${GREEN}Required (--month-rotate detected)${NC}"
else
    log_config "  vnstat installation: ${GREEN}Not required${NC}"
fi
echo ""

# Function to uninstall the previous installation
uninstall_previous() {
    log_step "Checking for previous installation..."
    
    # Stop and disable service if it exists
    if [ -f "/etc/init.d/${service_name}" ]; then
        log_info "Stopping and disabling existing service..."
        /etc/init.d/${service_name} stop
        /etc/init.d/${service_name} disable
        rm -f "/etc/init.d/${service_name}"
    fi
    
    # Remove old binary if it exists
    if [ -f "$komari_agent_path" ]; then
        log_info "Removing old binary..."
        rm -f "$komari_agent_path"
    fi
}

# Function to install dependencies
install_dependencies() {
    log_step "Checking and installing dependencies..."

    local deps="curl"
    local missing_deps=""
    for cmd in $deps; do
        if ! command -v $cmd >/dev/null 2>&1; then
            missing_deps="$missing_deps $cmd"
        fi
    done
    
    if [ -n "$missing_deps" ]; then
        # OpenWrt uses opkg package manager
        if command -v opkg >/dev/null 2>&1; then
            log_info "Using opkg to install dependencies..."
            opkg update
            opkg install $missing_deps
        else
            log_error "opkg package manager not found. This script is designed for OpenWrt."
            exit 1
        fi
        
        # Verify installation
        for cmd in $missing_deps; do
            if ! command -v $cmd >/dev/null 2>&1; then
                log_error "Failed to install $cmd"
                exit 1
            fi
        done
        log_success "Dependencies installed successfully"
    else
        log_success "Dependencies already satisfied"
    fi
}

# Function to install vnstat if needed
install_vnstat() {
    if [ "$need_vnstat" = true ]; then
        log_step "Checking and installing vnstat for --month-rotate functionality..."
        
        if command -v vnstat >/dev/null 2>&1; then
            log_success "vnstat is already installed"
            return
        fi
        
        log_info "vnstat not found, installing..."
        
        # Install vnstat using opkg for OpenWrt
        if command -v opkg >/dev/null 2>&1; then
            log_info "Using opkg to install vnstat..."
            opkg update
            opkg install vnstat
        else
            log_error "Failed to find opkg package manager"
            log_error "Please install vnstat manually to use --month-rotate functionality"
            exit 1
        fi
        
        # Verify installation
        if command -v vnstat >/dev/null 2>&1; then
            log_success "vnstat installed successfully"
            
            # Create initial database for vnstat
            # Find all physical network interfaces
            interfaces=""
            for iface in $(ls /sys/class/net/); do
                # Skip loopback and virtual interfaces
                if [ "$iface" != "lo" ] && ! echo "$iface" | grep -qE "^(br|veth|docker|cni|virbr|vmbr)"; then
                    interfaces="$interfaces $iface"
                fi
            done
            
            # Create database for each interface
            for iface in $interfaces; do
                vnstat -u -i $iface
            done
            
            # Start vnstat service if available
            if [ -f /etc/init.d/vnstat ]; then
                /etc/init.d/vnstat enable
                /etc/init.d/vnstat start
            fi
        else
            log_error "Failed to install vnstat"
            exit 1
        fi
    fi
}

# Uninstall previous installation
uninstall_previous

# Install dependencies
install_dependencies

# Install vnstat if needed
install_vnstat

# Detect architecture
arch=$(uname -m)
case $arch in
    x86_64)
        arch="amd64"
        ;;
    aarch64)
        arch="arm64"
        ;;
    armv7l)
        arch="armv7"
        ;;
    mipsel)
        arch="mipsle"
        ;;
    *)
        log_error "Unsupported architecture: $arch"
        exit 1
        ;;
esac
log_info "Detected architecture: ${GREEN}$arch${NC}"

version_to_install="latest"
if [ -n "$install_version" ]; then
    log_info "Attempting to install specified version: ${GREEN}$install_version${NC}"
    version_to_install="$install_version"
else
    log_info "No version specified, installing the latest version."
fi

# Construct download URL
file_name="komari-agent-linux-${arch}"
if [ "$version_to_install" = "latest" ]; then
    download_path="latest/download"
else
    download_path="download/${version_to_install}"
fi

if [ -n "$github_proxy" ]; then
    # Use proxy for GitHub releases
    download_url="${github_proxy}/https://github.com/komari-monitor/komari-agent/releases/${download_path}/${file_name}"
else
    # Direct access to GitHub releases
    download_url="https://github.com/komari-monitor/komari-agent/releases/${download_path}/${file_name}"
fi

# Create installation directory
log_step "Creating installation directory: ${GREEN}$target_dir${NC}"
mkdir -p "$target_dir"

# Download binary
if [ -n "$github_proxy" ]; then
    log_step "Downloading $file_name via proxy..."
    log_info "URL: ${CYAN}$download_url${NC}"
else
    log_step "Downloading $file_name directly..."
    log_info "URL: ${CYAN}$download_url${NC}"
fi

if ! curl -L -o "$komari_agent_path" "$download_url"; then
    log_error "Download failed"
    # Try with wget as fallback (common in OpenWrt)
    if command -v wget >/dev/null 2>&1; then
        log_info "Trying with wget..."
        if ! wget -O "$komari_agent_path" "$download_url"; then
            log_error "wget download also failed"
            exit 1
        fi
    else
        exit 1
    fi
fi

# Set executable permissions
chmod +x "$komari_agent_path"
log_success "Komari-agent installed to ${GREEN}$komari_agent_path${NC}"

# Configure procd service (OpenWrt)
log_step "Configuring OpenWrt service..."
service_file="/etc/init.d/${service_name}"
cat > "$service_file" << EOF
#!/bin/sh /etc/rc.common

START=99
STOP=10

USE_PROCD=1

PROG="${komari_agent_path}"
ARGS="${komari_args}"

start_service() {
    procd_open_instance
    procd_set_param command \$PROG \$ARGS
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param user root
    procd_close_instance
}

stop_service() {
    killall \$(basename \$PROG)
}

reload_service() {
    stop
    start
}
EOF

# Set permissions and enable service
chmod +x "$service_file"
/etc/init.d/${service_name} enable
/etc/init.d/${service_name} start
log_success "OpenWrt service configured and started"

# Create simple config file for easy management
config_file="${target_dir}/config.txt"
echo "# Komari Agent Configuration for OpenWrt"
cat > "$config_file" << EOF
# Komari Agent Configuration for OpenWrt
# Installation directory: $target_dir
# Service name: $service_name
# Arguments: $komari_args
# Installation date: $(date)

# To modify the agent arguments, edit the service file:
# vi /etc/init.d/${service_name}
# Then restart the service:
# /etc/init.d/${service_name} restart

# To check the service status:
# /etc/init.d/${service_name} status

# To uninstall:
# /etc/init.d/${service_name} stop
# /etc/init.d/${service_name} disable
# rm -rf $target_dir
# rm -f /etc/init.d/${service_name}
EOF

log_success "Configuration file created at ${GREEN}$config_file${NC}"

echo ""
echo -e "${WHITE}===========================================${NC}"
log_success "Komari-agent installation completed!"
log_config "Service: ${GREEN}$service_name${NC}"
log_config "Arguments: ${GREEN}$komari_args${NC}"
echo -e "${WHITE}===========================================${NC}"