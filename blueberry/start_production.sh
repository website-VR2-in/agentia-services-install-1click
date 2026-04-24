#!/bin/bash

# Agentia Blueberry Production Server v0.972
# Uses Gunicorn for reliable WSGI serving

echo "🚀 Starting Agentia Blueberry v0.972 Production Server"
echo "📍 Port: 23450"
echo "🔧 Server: Gunicorn with 4 workers"

cd "$(dirname "$0")" || exit 1

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    echo "🐍 Activating virtual environment..."
    source venv/bin/activate
fi

# Check if gunicorn is installed
if ! command -v gunicorn &> /dev/null; then
    echo "❌ Error: Gunicorn not found. Please install with: pip install gunicorn"
    exit 1
fi

# Check if port is available
if lsof -Pi :23450 -sTCP:LISTEN -t >/dev/null; then
    echo "❌ Error: Port 23450 is already in use"
    echo "Running processes on port 23450:"
    lsof -i :23450
    exit 1
fi

echo "✅ Starting Gunicorn server..."
echo "📝 Logs will be written to: production.log"
echo "🌐 Access the dashboard at: http://localhost:23450"
echo "📊 API endpoints: http://localhost:23450/api/*"
echo ""

# Start Gunicorn
exec gunicorn \
    -w 4 \
    -b 0.0.0.0:23450 \
    --access-logfile production.log \
    --error-logfile production.log \
    --timeout 120 \
    --keep-alive 5 \
    backend:app