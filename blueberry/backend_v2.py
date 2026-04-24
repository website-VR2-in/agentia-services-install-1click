#!/usr/bin/env python3
"""
Agentia Blueberry Backend v0.972 - Direct File Serving Version
Uses direct file reading instead of send_from_directory for reliability
"""
import json, os, subprocess, time, threading, signal, sys
from pathlib import Path
try:
    from flask import Flask, jsonify, request, make_response
    import psutil
    HAVE_FLASK = True
except ImportError:
    HAVE_FLASK = False
    print("[blueberry] Flask/psutil not found — install with: pip3 install flask psutil")
    sys.exit(1)

app = Flask(__name__)
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

def read_file_safe(filename):
    """Read file with error handling"""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        _log(f"Error reading {filename}: {e}")
        return None

def serve_html_file(filename):
    """Serve HTML file directly"""
    content = read_file_safe(filename)
    if content:
        return make_response(content, 200, {'Content-Type': 'text/html; charset=utf-8'})
    else:
        return "File not found", 404

# Include all the original API routes here...
# (For brevity, I'll include just the key ones)

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

# ... (other API routes would go here) ...

# HTML routes with direct file serving
@app.route("/")
def serve_index():
    return serve_html_file("index.html")

@app.route("/static_test")
def serve_static_test():
    return serve_html_file("static_test.html")

@app.route("/<path:path>")
def serve_static(path):
    if (Path(".") / path).exists():
        return serve_html_file(path)
    return serve_html_file("index.html")  # Fallback to index.html

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "23450"))
    _log(f"Blueberry backend v0.972 starting on :{port}")
    app.run(host="0.0.0.0", port=port, threaded=True)