# Agentia v0.971 - Port Migration & Docker Fix

## 🎯 Version Update from v0.97 to v0.971

**Reason for Update**: 
- v0.97 had port configuration changes but incomplete service migration
- v0.971 consolidates all fixes and provides clear migration path

## ✅ What's Working in v0.971

### Blueberry Dashboard (Port 23450)
- **Status**: ✅ **FULLY FUNCTIONAL**
- **URL**: `http://localhost:23450`
- **All API Endpoints**: Verified working
- **Frontend**: Serving `index.html` correctly

### Configuration Files Updated
1. **`blueberry/backend.py`** - v0.971 with port 23450
2. **`data/model-state.json`** - Models on 12342-12344
3. **`docker-compose.yml`** - Frontend services on 23451-23452

## 🔧 Issues Identified and Resolved

### 1. Systemd Service Conflict ✅ FIXED
**Problem**: User-level systemd service (`agentia-blueberry.service`) was interfering
**Solution**: 
- Stopped and disabled the service
- Removed service file from `~/.config/systemd/user/`
- Reloaded systemd daemon

### 2. Port Configuration ✅ COMPLETE
- **VLLM Models**: 12341-12344 (was 33331-33334)
- **Frontend Services**: 23450-23453 (was 44440-44443)
- **All files updated** with new port numbers

### 3. Process Management ✅ PARTIAL
- **Blueberry backend**: Running successfully on 23450
- **Old processes**: Some still running (44440, 44441) - requires root to clean up
- **Docker services**: Need restart to use new ports

## 🚀 Migration Checklist for v0.971

### Step 1: Cleanup Old Processes (Requires Root)
```bash
# Kill old HTTP server on 44440
sudo kill -9 $(sudo lsof -t -i :44440)

# Docker containers using old ports
docker-compose down
```

### Step 2: Restart Docker Services
```bash
cd ~/agentia
docker-compose up -d
```

### Step 3: Verify New Services
```bash
# Blueberry Dashboard
curl http://localhost:23450/api/metrics

# Open WebUI (after docker restart)
curl http://localhost:23451

# Langfuse (after docker restart)  
curl http://localhost:23452
```

### Step 4: Update Model Launch Scripts
Ensure all model launch commands use new ports:
- Qwen3-8B: `--port 12342`
- Gemma4-26B: `--port 12343`
- Other models: `--port 12344`

## 📊 Current Service Status

| Service | Old Port | New Port | Status | Notes |
|---------|----------|----------|--------|-------|
| **Blueberry Dashboard** | 44440 | 23450 | ✅ **WORKING** | Fully functional |
| Open WebUI | 44441 | 23451 | ⏳ Pending | Needs `docker-compose up` |
| Langfuse | 44442 | 23452 | ⏳ Pending | Needs `docker-compose up` |
| LiteLLM API | 33331 | 12341 | ⏳ Pending | Needs service restart |
| vLLM Models | 33332-4 | 12342-4 | ⏳ Pending | Needs model restart |

## 🔍 Verification Commands

```bash
# Check Blueberry is working
curl -s http://localhost:23450/api/metrics | python3 -m json.tool

# Check which ports are listening
netstat -tuln | grep -E "(2345|1234)"

# Check for old processes
ps aux | grep -E "(44440|44441)" | grep -v grep

# Check Docker containers
docker ps
```

## 📝 Files Modified in v0.971

1. **`blueberry/backend.py`**
   - Version: v0.971
   - Default PORT: 23450
   - LiteLLM PORT: 12341
   - Service discovery ports updated

2. **`data/model-state.json`**
   - All model ports updated to 1234* range

3. **`docker-compose.yml`**
   - Open WebUI: 23451
   - Langfuse: 23452
   - API URLs updated

## 🎯 Key Achievement

**Blueberry Dashboard v0.971 is fully functional on port 23450** with:
- All API endpoints working
- Correct port configuration
- Clean systemd integration
- Proper static file serving

## 🔄 Rollback Instructions

If needed, revert to v0.96 by:
1. Restore files from backup
2. `docker-compose down && docker-compose up -d`
3. Restart all services

## 📈 Next Version: v0.972

Planned improvements:
- Complete Docker service migration
- Automated cleanup of old processes
- Health checks for all services
- Unified service management script