# Agentia AI Platform v0.973

![Agentia Logo](https://via.placeholder.com/150?text=Agentia+AI)

**Production-Ready AI Factory Dashboard with Model Management**

## 🚀 Quick Start

### Prerequisites
- Python 3.12+
- Docker & Docker Compose
- Node.js (for frontend build, if needed)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/your-repo/agentia.git
cd agentia

# Install dependencies
pip3 install -r requirements.txt

# Start the production server
cd blueberry
./start_production.sh

# Access the dashboard
# Open: http://localhost:23450
```

## 🎯 Architecture

### Port Configuration (v0.973)

| Service | Port | Status |
|---------|------|--------|
| **Blueberry Dashboard** | 23450 | ✅ Production |
| **Open WebUI** | 23451 | ✅ Frontend |
| **Langfuse** | 23452 | ✅ Analytics |
| **LiteLLM API** | 12341 | ✅ Model Router |
| **vLLM Qwen3-8B** | 12342 | ⏳ Model Service |
| **vLLM Gemma4-26B** | 12343 | ⏳ Model Service |
| **vLLM Other** | 12344 | ⏳ Model Service |

### Technology Stack

- **Backend**: Flask + Gunicorn (4 workers)
- **Frontend**: Vanilla HTML/CSS/JS
- **Models**: vLLM with LiteLLM router
- **Monitoring**: Built-in metrics dashboard
- **Containerization**: Docker Compose

## 📋 Features

### Dashboard
- **Real-time Metrics**: CPU, RAM, GPU, Disk monitoring
- **Model Management**: Start/stop models dynamically
- **Service Discovery**: Auto-detect running services
- **Scheduler Integration**: Work hours awareness
- **Log Viewer**: Built-in log access

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/metrics` | GET | System metrics JSON |
| `/api/models` | GET | Model status and info |
| `/api/state` | POST | Change model state |
| `/api/exec` | POST | Execute model actions |
| `/api/scheduler` | GET | Scheduler information |
| `/api/log` | GET | Access logs |
| `/api/services` | GET | Discover running services |

### Model Management

```bash
# List available models
agentia model list

# Start a model
agentia model use qwen3-8b

# Stop a model
agentia model stop qwen3-8b

# Check model status
curl http://localhost:23450/api/models
```

## 🔧 Configuration

### Environment Variables

```bash
# Blueberry Dashboard
export PORT=23450
export LITELLM_PORT=12341
export STATE_FILE=~/agentia/data/model-state.json

# Start with custom config
PORT=23450 LITELLM_PORT=12341 ./start_production.sh
```

### Model Configuration

Edit `data/model-state.json`:

```json
{
  "models": {
    "qwen3-8b": {
      "state": "auto",
      "container": "vllm-qwen3-8b",
      "port": 12342,
      "always_on": true
    }
  }
}
```

## 🚀 Production Deployment

### Gunicorn Configuration

The production server uses Gunicorn with optimized settings:

```bash
# Start production server
./blueberry/start_production.sh

# Configuration:
# - 4 worker processes
# - 300s timeout
# - Increased buffers for large responses
# - Proper request limits
```

### Docker Services

```bash
# Start all services
cd agentia
docker compose up -d

# Check service status
docker compose ps

# View logs
docker compose logs -f
```

## 📊 Monitoring

### Built-in Metrics

Access real-time metrics at: `http://localhost:23450/api/metrics`

```json
{
  "cpu": {"pct": 4.5},
  "ram": {"pct": 5.8, "used_gb": 6.6, "total_gb": 130.6},
  "gpu": {"pct": 3.0, "temp_c": 52.0},
  "disk": {"pct": 29.5, "used_gb": 275.6, "total_gb": 982.8},
  "ts": 1777013617
}
```

### Service Health

```bash
# Check if services are responding
curl -s http://localhost:23450/api/services

# Check Gunicorn status
ps aux | grep gunicorn

# Check listening ports
netstat -tuln | grep -E "(23450|1234)"
```

## 🔍 Troubleshooting

### Common Issues

#### Gunicorn not starting
```bash
# Check logs
cat blueberry/production.log

# Check port conflicts
lsof -i :23450

# Kill conflicting processes
kill -9 $(lsof -t -i :23450)
```

#### API returns empty response
```bash
# Check Gunicorn logs
 tail -50 blueberry/production.log

# Test Flask directly
cd blueberry
python3 -c "from backend import app; print(app.test_client().get('/api/metrics').data)"
```

#### Models not responding
```bash
# Check model containers
docker ps | grep vllm

# Check model logs
docker logs vllm-qwen3-8b

# Restart model
agentia model restart qwen3-8b
```

## 📈 Development

### Running in Development Mode

```bash
# Start Flask development server (for testing only)
cd blueberry
python3 backend.py

# Note: Development server is not stable for production
```

### Building Frontend

If index.html needs building:

```bash
cd blueberry
npm install
npm run build
```

## 🎉 Version History

### v0.973 (Current)
- **Production server** with Gunicorn (4 workers)
- **Complete port migration** (1234*/2345* ranges)
- **Fixed static file serving** (direct file reading)
- **Resolved system conflicts** (systemd, ports)
- **Comprehensive documentation**

### v0.972
- Diagnostic testing and analysis
- Static content verification
- Gunicorn configuration improvements

### v0.971
- Docker service fixes
- Port conflict resolution
- System stability improvements

### v0.97
- Initial port migration
- Configuration updates
- Service discovery updates

## 📚 Documentation

- `CHANGES-v0.97.md` - Port migration details
- `FINAL-SUMMARY-v0.973.md` - Complete summary
- `TEST-LINKS.html` - Interactive test page
- `SERVICE-INVESTIGATION-v0.973.md` - Technical analysis

## 🤝 Contributing

```bash
# Fork the repository
# Create feature branch
git checkout -b feature/your-feature

# Commit changes
git commit -m "Add your feature"

# Push to branch
git push origin feature/your-feature

# Open pull request
```

## 📜 License

MIT License - See LICENSE file for details

## 🎯 Roadmap

### v0.974 (Next)
- Complete Docker service migration
- Full model service testing
- End-to-end functionality verification
- Production deployment guide
- Monitoring and logging setup

### Future
- Model autoscaling
- Advanced monitoring dashboard
- User authentication
- Multi-tenancy support
- GPU resource management

---

**Agentia AI Platform** © 2026 | Version 0.973 | Production Ready 🚀