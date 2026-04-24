#!/usr/bin/env python3
"""
Agentia Blueberry Backend v0.973 (Consolidation & Git Ready)
Provides /api/metrics, /api/models, /api/state, /api/exec for the dashboard.
"""
import json, os, subprocess, time, threading, signal, sys
from pathlib import Path
try:
    from flask import Flask, jsonify, request, send_from_directory, make_response
    import psutil
    HAVE_FLASK = True
except ImportError:
    HAVE_FLASK = False
    print("[blueberry] Flask/psutil not found — install with: pip3 install flask psutil")
    sys.exit(1)

app = Flask(__name__, static_folder=".", static_url_path="")
STATE_FILE = os.environ.get("STATE_FILE", os.path.expanduser("~/agentia/data/model-state.json"))
LITELLM_PORT = int(os.environ.get("LITELLM_PORT", "12341"))
LOG_LINES = []
MAX_LOG = 200

def _log(msg):
    ts = time.strftime("%H:%M:%S")
    entry = f"[{ts}] {msg}"
    LOG_LINES.append(entry)
    if len(LOG_LINES) > MAX_LOG:
        LOG_LINES.pop(0)
    print(entry)

def read_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except Exception:
        return {"models": {}}

def write_state(s):
    with open(STATE_FILE, "w") as f:
        json.dump(s, f, indent=2)

def gpu_metrics():
    try:
        r = subprocess.run(
            ["nvidia-smi","--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=3)
        if r.returncode == 0:
            parts = [p.strip() for p in r.stdout.strip().split(",")]
            if len(parts) >= 4:
                util = float(parts[0]) if parts[0] not in ("[N/A]","N/A") else None
                used = float(parts[1]) if parts[1] not in ("[N/A]","N/A") else None
                total = float(parts[2]) if parts[2] not in ("[N/A]","N/A") else None
                temp = float(parts[3]) if parts[3] not in ("[N/A]","N/A") else None
                pct = (used/total*100) if (used and total) else util
                return {"pct": round(pct, 1) if pct is not None else 0,
                        "used_mb": used, "total_mb": total, "temp_c": temp}
    except Exception:
        pass
    return {"pct": 0, "used_mb": None, "total_mb": None, "temp_c": None}

def disk_metrics():
    try:
        u = psutil.disk_usage(os.path.expanduser("~"))
        return {"pct": round(u.percent, 1), "used_gb": round(u.used/1e9,1), "total_gb": round(u.total/1e9,1)}
    except Exception:
        return {"pct": 0}

@app.route("/api/metrics")
def metrics():
    cpu = round(psutil.cpu_percent(interval=0.2), 1)
    ram = psutil.virtual_memory()
    gpu = gpu_metrics()
    disk = disk_metrics()
    return jsonify({
        "cpu":  {"pct": cpu},
        "ram":  {"pct": round(ram.percent, 1), "used_gb": round(ram.used/1e9,1), "total_gb": round(ram.total/1e9,1)},
        "gpu":  gpu,
        "disk": disk,
        "ts":   int(time.time())
    })

@app.route("/api/models")
def models_status():
    state = read_state()
    result = []
    try:
        ps_out = subprocess.run(["docker","ps","--format","{{.Names}}|{{.Status}}"],
                                capture_output=True, text=True, timeout=5).stdout
        running = {}
        for line in ps_out.strip().splitlines():
            if "|" in line:
                name, status = line.split("|", 1)
                running[name.strip()] = status.strip()
    except Exception:
        running = {}

    for model_id, info in state.get("models", {}).items():
        cname = info.get("container", "")
        is_running = cname in running
        port = info.get("port", 0)
        tok_s = None
        if is_running and port:
            try:
                r = subprocess.run(
                    ["curl","-sf","--max-time","1",f"http://localhost:{port}/metrics"],
                    capture_output=True, text=True, timeout=2)
                for line in r.stdout.splitlines():
                    if "vllm:generation_tokens_total" in line and not line.startswith("#"):
                        tok_s = float(line.split()[-1])
            except Exception:
                pass
        result.append({
            "id": model_id,
            "container": cname,
            "state": info.get("state","auto"),
            "always_on": info.get("always_on", False),
            "running": is_running,
            "port": port,
            "tok_s": tok_s
        })
    return jsonify(result)

@app.route("/api/state", methods=["POST"])
def set_model_state():
    data = request.get_json() or {}
    model_id = data.get("model")
    new_state = data.get("state")  # "on" | "auto" | "off"
    if not model_id or new_state not in ("on", "auto", "off"):
        return jsonify({"error": "bad request"}), 400
    s = read_state()
    if model_id not in s.get("models", {}):
        return jsonify({"error": "model not found"}), 404
    s["models"][model_id]["state"] = new_state
    write_state(s)
    _log(f"State: {model_id} → {new_state}")
    return jsonify({"ok": True, "model": model_id, "state": new_state})

@app.route("/api/exec", methods=["POST"])
def exec_model():
    data = request.get_json() or {}
    action = data.get("action")  # "start" | "stop"
    model_id = data.get("model")
    s = read_state()
    info = s.get("models", {}).get(model_id)
    if not info:
        return jsonify({"error": "model not found"}), 404
    cname = info["container"]
    if action == "stop":
        subprocess.run(["docker","stop",cname], capture_output=True, timeout=30)
        subprocess.run(["docker","rm",cname], capture_output=True, timeout=10)
        _log(f"Stopped {cname}")
        return jsonify({"ok": True, "action": "stop", "container": cname})
    elif action == "start":
        _log(f"Start {model_id} — use agentia model use {model_id}")
        return jsonify({"ok": True, "action": "start", "hint": f"agentia model use {model_id}"})
    return jsonify({"error": "unknown action"}), 400

@app.route("/api/scheduler")
def scheduler_info():
    import datetime
    now = datetime.datetime.now()
    hour = now.hour; dow = now.weekday()  # 0=Mon
    work_hours = (9 <= hour < 13) or (15 <= hour < 18)
    work_day = dow < 5
    in_work = work_hours and work_day
    return jsonify({
        "in_work_hours": in_work,
        "current_time": now.strftime("%H:%M"),
        "day_name": ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][dow],
        "work_windows": "09:00-13:00 and 15:00-18:00 Mon-Fri",
        "priority": "coding+chat" if in_work else "light models"
    })

@app.route("/api/log")
def get_log():
    return jsonify(LOG_LINES[-50:])

@app.route("/api/services")
def discover_services():
    """Discover running services on known ports"""
    port_names = {
        12341: "LiteLLM", 12342: "vLLM Qwen3", 12343: "vLLM Gemma4",
        12344: "vLLM Swap", 23451: "Open WebUI", 23452: "Langfuse",
        23453: "Paperclip", 11434: "Ollama", 3000: "Grafana",
        8888: "Jupyter", 6006: "TensorBoard"
    }
    found = []
    import socket
    for port, name in port_names.items():
        try:
            s = socket.socket()
            s.settimeout(0.15)
            s.connect(("127.0.0.1", port))
            s.close()
            found.append({"port": port, "name": name, "active": True})
        except Exception:
            pass
    return jsonify(found)

@app.route("/")
def serve_index():
    # Direct file serving (Gunicorn-compatible)
    try:
        with open("index.html", "r", encoding="utf-8") as f:
            content = f.read()
        return make_response(content, 200, {"Content-Type": "text/html; charset=utf-8"})
    except Exception as e:
        app.logger.error(f"Error serving index.html: {e}")
        return f"Error serving index.html: {e}", 500

@app.route("/static_test")
def serve_static_test():
    try:
        return send_from_directory(app.static_folder, "static_test.html")
    except Exception as e:
        app.logger.error(f"Error serving static_test.html: {e}")
        return "Error serving static_test.html", 500

@app.route("/<path:path>")
def serve_static(path):
    if (Path(app.static_folder) / path).exists():
        return send_from_directory(app.static_folder, path)
    return send_from_directory(app.static_folder, "index.html")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "23450"))
    _log(f"Blueberry backend starting on :{port}")
    app.run(host="0.0.0.0", port=port, threaded=True)
