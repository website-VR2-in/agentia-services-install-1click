#!/bin/bash

# Agentia AI Platform - Fresh Install Script v1.0
# Comprehensive installation with all features
# Research-based reconstruction of 2000-line install script

echo "🚀 Agentia AI Platform - Fresh Install"
echo "======================================"
echo ""

# Safety checks
if [ "$EUID" -eq 0 ]; then
    echo "❌ Do not run as root. Use regular user with sudo privileges."
    exit 1
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install package if missing
install_package() {
    if ! command_exists "$1"; then
        log "Installing $2..."
        if command_exists "apt-get"; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq "$1" >/dev/null 2>&1
        elif command_exists "yum"; then
            sudo yum install -y -q "$1" >/dev/null 2>&1
        elif command_exists "brew"; then
            brew install "$1" >/dev/null 2>&1
        else
            error "Package manager not found. Cannot install $2."
            exit 1
        fi
        if command_exists "$1"; then
            success "$2 installed"
        else
            error "Failed to install $2"
            exit 1
        fi
    else
        log "$2 already installed"
    fi
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        DISTRO="unknown"
        VERSION="unknown"
    fi
}

# Main installation
detect_distro
log "Detected: $DISTRO $VERSION"

# Install prerequisites
log "Installing prerequisites..."
install_package "git" "Git"
install_package "python3" "Python 3"
install_package "pip" "pip"
install_package "docker.io" "Docker" || install_package "docker" "Docker"
install_package "docker-compose" "Docker Compose" || install_package "docker-compose-plugin" "Docker Compose Plugin"
install_package "curl" "cURL"
install_package "wget" "wget"
install_package "htop" "htop"
install_package "net-tools" "net-tools"
install_package "build-essential" "build-essential"
install_package "python3-dev" "python3-dev"
install_package "python3-venv" "python3-venv"

# Install Python packages
log "Installing Python packages..."
pip3 install --upgrade pip >/dev/null 2>&1
pip3 install flask psutil gunicorn requests >/dev/null 2>&1

# Create project directory
AGENTIA_DIR="~/agentia"
if [ -d "$AGENTIA_DIR" ]; then
    warning "Agentia directory already exists: $AGENTIA_DIR"
    read -p "Overwrite existing installation? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Backing up existing installation..."
        mv "$AGENTIA_DIR" "${AGENTIA_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    else
        log "Using existing installation"
    fi
fi

mkdir -p "$AGENTIA_DIR"
cd "$AGENTIA_DIR" || exit 1

# Clone repository
log "Cloning Agentia repository..."
if git clone https://github.com/website-VR2-in/agentia-services-install-1click.git . >/dev/null 2>&1; then
    success "Repository cloned successfully"
else
    error "Failed to clone repository"
    exit 1
fi

# Set up virtual environment
log "Setting up Python virtual environment..."
python3 -m venv venv >/dev/null 2>&1
source venv/bin/activate
pip3 install --upgrade pip >/dev/null 2>&1
pip3 install -r requirements.txt >/dev/null 2>&1
deactivate

# Configure Docker
log "Configuring Docker..."
sudo systemctl enable docker >/dev/null 2>&1
sudo systemctl start docker >/dev/null 2>&1
sudo usermod -aG docker "$USER" >/dev/null 2>&1

# Install NVIDIA Container Toolkit for GPU support
if command_exists "nvidia-smi"; then
    log "NVIDIA GPU detected. Installing container toolkit..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
      && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt-get update -qq
    sudo apt-get install -y -qq nvidia-container-toolkit >/dev/null 2>&1
    sudo systemctl restart docker >/dev/null 2>&1
    success "NVIDIA Container Toolkit installed"
fi

# Start production server
log "Starting production server..."
cd blueberry || exit 1
./start_production.sh > /tmp/agentia-install.log 2>&1 &

# Wait for server to start
sleep 5

# Verify installation
if curl -s http://localhost:23450/api/metrics >/dev/null 2>&1; then
    success "Production server started successfully"
    success "Dashboard available at: http://localhost:23450"
else
    warning "Server started but not responding yet"
    warning "Check logs: /tmp/agentia-install.log"
fi

# Start Docker services
log "Starting Docker services..."
cd ..
docker compose up -d >/dev/null 2>&1

# Install additional tools
log "Installing additional tools..."
install_package "tmux" "tmux"
install_package "jq" "jq"
install_package "tree" "tree"

# Configure system limits
log "Configuring system limits..."
echo "fs.file-max = 100000" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p >/dev/null 2>&1

# Set up monitoring
log "Setting up monitoring..."
mkdir -p logs
 touch logs/install-$(date +%Y%m%d-%H%M%S).log

# Create aliases
log "Creating useful aliases..."
echo "" >> ~/.bashrc
echo "# Agentia aliases" >> ~/.bashrc
echo "alias agentia-start='cd ~/agentia/blueberry && ./start_production.sh'" >> ~/.bashrc
echo "alias agentia-logs='tail -f ~/agentia/blueberry/production.log'" >> ~/.bashrc
echo "alias agentia-test='curl http://localhost:23450/api/metrics | jq'" >> ~/.bashrc
source ~/.bashrc

# Final verification
log "Running final verification..."
if curl -s http://localhost:23450/api/metrics | grep -q "cpu"; then
    success "✅ All systems operational"
    success "✅ API endpoints responding"
    success "✅ Installation complete"
else
    warning "⚠️  Some services still starting"
    warning "⚠️  Please wait 30 seconds and refresh"
fi

echo ""
echo "🎉 Agentia AI Platform Installation Complete!"
echo "============================================"
echo ""
echo "📊 Dashboard: http://localhost:23450"
echo "📊 API: http://localhost:23450/api/metrics"
echo "📊 Docs: file://$AGENTIA_DIR/README.md"
echo ""
echo "🚀 Quick Commands:"
echo "   agentia-start     - Start production server"
echo "   agentia-logs      - View server logs"
echo "   agentia-test      - Test API endpoints"
echo ""
echo "💡 Next Steps:"
echo "   1. docker compose ps          - Check Docker services"
echo "   2. agentia model use qwen3-8b - Start a model"
echo "   3. Check README.md           - Full documentation"
echo ""
echo "✨ Enjoy your AI Factory!"
