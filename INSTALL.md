# 🚀 Agentia v0.973 - Installation Guide

## 📋 Installation Methods

### Method 1: Quick Start (Recommended)

```bash
# Clone the repository
git clone https://github.com/website-VR2-in/agentia-services-install-1click.git
data

# Navigate to the directory
cd agentia-services-install-1click

# Start the production server
cd blueberry
./start_production.sh

# Access the dashboard at: http://localhost:23450
```

### Method 2: Full Installation (From Scratch)

```bash
# 1. Create project directory
mkdir -p ~/agentia
cd ~/agentia

# 2. Clone the repository
git clone https://github.com/website-VR2-in/agentia-services-install-1click.git .

# 3. Install Python dependencies
pip3 install flask psutil gunicorn

# 4. Start the production server
cd blueberry
./start_production.sh

# 5. Access the dashboard at: http://localhost:23450
```

## 🎯 Detailed Installation Steps

### 1. Prerequisites

Ensure you have the following installed:

```bash
# Python 3.12+
python3 --version

# Git
git --version

# Docker & Docker Compose
docker --version
docker compose version

# pip
pip3 --version
```

### 2. Clone the Repository

```bash
git clone https://github.com/website-VR2-in/agentia-services-install-1click.git
cd agentia-services-install-1click
```

### 3. Install Dependencies

```bash
# Install Python packages
pip3 install flask psutil gunicorn

# Or use requirements.txt
pip3 install -r requirements.txt
```

### 4. Start the Production Server

```bash
cd blueberry
./start_production.sh
```

This will start Gunicorn with 4 workers on port 23450.

### 5. Verify Installation

```bash
# Check if Gunicorn is running
ps aux | grep gunicorn

# Test API endpoints
curl http://localhost:23450/api/metrics

# Test static content
curl http://localhost:23450/static_test

# Open in browser
firefox http://localhost:23450 &
```

## 🚀 Starting Additional Services

### Docker Services

```bash
# Start all Docker services
cd ~/agentia
docker compose up -d

# Check service status
docker compose ps

# Verify services
curl http://localhost:23451  # Open WebUI
curl http://localhost:23452  # Langfuse
```

### Model Services

```bash
# Start LiteLLM (model router)
agentia model use qwen3-8b

# Verify model API
curl http://localhost:12341/v1/models

# Start additional models as needed
agentia model use gemma4-26b
```

## 📋 Configuration

### Port Configuration

All services use the new port scheme:

| Service | Port |
|---------|------|
| Blueberry Dashboard | 23450 |
| Open WebUI | 23451 |
| Langfuse | 23452 |
| LiteLLM API | 12341 |
| vLLM Models | 12342-12344 |

### Environment Variables

Configure through environment variables:

```bash
# Set custom ports
export PORT=23450
export LITELLM_PORT=12341

# Start with custom configuration
./start_production.sh
```

## 🔧 Troubleshooting

### Gunicorn Not Starting

```bash
# Check for port conflicts
lsof -i :23450

# Kill conflicting processes
kill -9 $(lsof -t -i :23450)

# Restart Gunicorn
./start_production.sh
```

### API Returns Empty Response

```bash
# Check Gunicorn logs
tail -50 blueberry/production.log

# Test Flask directly
python3 -c "from backend import app; print(app.test_client().get('/api/metrics').data)"
```

### Docker Services Not Starting

```bash
# Check Docker status
systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Start services
docker compose up -d
```

## 📊 Verification

### Check Service Status

```bash
# Gunicorn processes
ps aux | grep gunicorn | grep -v grep

# Listening ports
netstat -tuln | grep -E "(23450|1234)"

# Docker containers
docker ps

# API health check
curl -s http://localhost:23450/api/metrics | python3 -m json.tool
```

### Expected Output

```json
{
  "cpu": {"pct": 4.5},
  "ram": {"pct": 5.8, "used_gb": 6.6, "total_gb": 130.6},
  "gpu": {"pct": 3.0, "temp_c": 52.0},
  "disk": {"pct": 29.5, "used_gb": 275.6, "total_gb": 982.8},
  "ts": 1777013617
}
```

## 🎉 Complete!

Your Agentia v0.973 installation is now complete with:

✅ **Production-ready Gunicorn server**
✅ **All API endpoints functional**
✅ **Static file serving working**
✅ **Port migration complete**
✅ **Comprehensive documentation**

**Access the dashboard at:** `http://localhost:23450`

For advanced configuration and troubleshooting, refer to:
- `README.md` - Complete documentation
- `FINAL-SUMMARY-v0.973.md` - Technical details
- `TEST-LINKS.html` - Interactive test page

**Enjoy your AI Factory!** 🚀