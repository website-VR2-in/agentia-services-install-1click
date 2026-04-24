#!/bin/bash

# Agentia AI Platform - 1-Click Install Script v0.973
# Production-Ready AI Factory Dashboard

echo "🚀 Agentia AI Platform - 1-Click Install"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run as root. Use regular user."
    exit 1
fi

# Check prerequisites
check_prerequisite() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ Missing prerequisite: $2"
        echo "   Please install: $3"
        exit 1
    fi
    echo "✅ $2 installed"
}

echo "Checking prerequisites..."
check_prerequisite "git" "Git" "sudo apt install git"
check_prerequisite "python3" "Python 3" "sudo apt install python3"
check_prerequisite "pip3" "pip3" "sudo apt install python3-pip"
check_prerequisite "docker" "Docker" "See: https://docs.docker.com/engine/install/"
check_prerequisite "docker" "Docker Compose" "sudo apt install docker-compose-plugin"

echo ""
echo "Installing Agentia AI Platform..."
echo ""

# Create project directory
AGENTIA_DIR="~/agentia"
if [ -d "$AGENTIA_DIR" ]; then
    echo "⚠️  Agentia directory already exists: $AGENTIA_DIR"
    read -p "Overwrite? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    rm -rf "$AGENTIA_DIR"
fi

mkdir -p "$AGENTIA_DIR"
cd "$AGENTIA_DIR" || exit 1

echo "✅ Created project directory"

# Clone repository
echo "Cloning repository..."
if git clone https://github.com/website-VR2-in/agentia-services-install-1click.git .; then
    echo "✅ Repository cloned"
else
    echo "❌ Failed to clone repository"
    exit 1
fi

# Install Python dependencies
echo "Installing Python dependencies..."
if pip3 install flask psutil gunicorn; then
    echo "✅ Python dependencies installed"
else
    echo "❌ Failed to install Python dependencies"
    exit 1
fi

# Start production server
echo "Starting production server..."
cd blueberry || exit 1
if ./start_production.sh > /tmp/agentia-install.log 2>&1 & then
    echo "✅ Production server started"
    echo "   Access dashboard at: http://localhost:23450"
else
    echo "❌ Failed to start production server"
    echo "   Check logs: /tmp/agentia-install.log"
    exit 1
fi

echo ""
echo "🎉 Installation Complete!"
echo "================================"
echo ""
echo "🌐 Dashboard URL: http://localhost:23450"
echo "📊 API Endpoint: http://localhost:23450/api/metrics"
echo "📄 Documentation: file://$AGENTIA_DIR/README.md"
echo ""
echo "Next steps:"
echo "1. Open dashboard in browser: firefox http://localhost:23450 &"
echo "2. Start Docker services: cd ~/agentia && docker compose up -d"
echo "3. Launch models: agentia model use qwen3-8b"
echo ""
echo "💡 Tip: Check installation log at /tmp/agentia-install.log"
echo ""

# Open dashboard in browser
read -p "Open dashboard in browser? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    firefox http://localhost:23450 &
fi

echo "✨ Enjoy your AI Factory!"
