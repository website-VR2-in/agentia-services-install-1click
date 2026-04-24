# Agentia v0.97 - Port Update

## Summary
This version updates all ports to use a more organized numbering scheme:
- **VLLM Models**: 1234* range (12341-12344)
- **Frontend Services**: 2345* range (23450-23453)

## Changes Made

### 1. Blueberry Backend (`blueberry/backend.py`)
- **Default PORT**: Changed from `44440` to `23450`
- **LiteLLM PORT**: Changed from `33331` to `12341`
- **Service Discovery Ports**:
  - LiteLLM: `33331` → `12341`
  - vLLM Qwen3: `33332` → `12342`
  - vLLM Gemma4: `33333` → `12343`
  - vLLM Swap: `33334` → `12344`
  - Open WebUI: `44441` → `23451`
  - Langfuse: `44442` → `23452`
  - Paperclip: `44443` → `23453`

### 2. Model State (`data/model-state.json`)
- **Qwen3-8B**: Port `33332` → `12342`
- **Gemma4-26B**: Port `33333` → `12343`
- **Devstral-24B**: Port `33334` → `12344`
- **Nemotron-120B**: Port `33334` → `12344`

### 3. Docker Compose (`docker-compose.yml`)
- **Langfuse**: Port mapping `44442:3000` → `23452:3000`
- **Open WebUI**: Port mapping `44441:8080` → `23451:8080`
- **Open WebUI API URL**: `http://host.docker.internal:33331/v1` → `http://host.docker.internal:12341/v1`
- **Langfuse URL**: `http://localhost:44442` → `http://localhost:23452`

## Migration Notes

1. **Stop all running services** before applying this update
2. **Update Docker containers** with the new port mappings:
   ```bash
   cd ~/agentia
   docker-compose down
   docker-compose up -d
   ```

3. **Restart Blueberry backend**:
   ```bash
   cd ~/agentia/blueberry
   python3 backend.py
   ```

4. **Verify services** are running on new ports:
   - Blueberry Dashboard: `http://localhost:23450`
   - Open WebUI: `http://localhost:23451`
   - Langfuse: `http://localhost:23452`
   - LiteLLM API: `http://localhost:12341`

## Testing

The configuration has been updated but not yet tested. Please verify:
1. All services start correctly
2. API endpoints are accessible on new ports
3. Model inference works through the new LiteLLM port
4. Dashboard displays metrics correctly

## Rollback

If issues occur, revert by:
1. Restoring from backup
2. Or manually changing ports back to original values
3. Restarting all services