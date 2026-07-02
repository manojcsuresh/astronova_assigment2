#!/bin/bash
set -e

echo "=========================================="
echo " Books Application - Deployment Script "
echo "=========================================="

# Determine the directory from where the script is executed
SCRIPT_DIR=$(dirname "$0")
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
APP_DIR="/opt/books-app"

# Ensure the script is run with sudo for copying files to /opt and restarting services
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)"
  exit 1
fi

echo "1. Building Frontend..."
cd $ROOT_DIR/frontend
npm install
npm run build

echo "2. Copying Frontend Files to Server Directory..."
rm -rf $APP_DIR/frontend/dist
cp -r dist $APP_DIR/frontend/
chown -R booksapp:booksapp $APP_DIR/frontend

echo "3. Setting up Backend..."
cd $ROOT_DIR/backend
cp -r app requirements.txt $APP_DIR/backend/
chown -R booksapp:booksapp $APP_DIR/backend

echo "4. Creating Virtual Environment and Installing Dependencies..."
# Run as the booksapp user
sudo -u booksapp bash << 'EOF'
cd /opt/books-app/backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt
EOF

echo "5. Restarting Systemd Service..."
systemctl restart books-app.service

echo "6. Verifying Application Health..."
sleep 3 # Wait for the application to start
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)

if [ "$HEALTH_STATUS" -eq 200 ]; then
    echo "Application health check passed (HTTP 200)!"
else
    echo "Warning: Application health check returned HTTP $HEALTH_STATUS."
    echo "Fetching logs for debugging:"
    journalctl -u books-app.service -n 20 --no-pager
    exit 1
fi

echo "=========================================="
echo " Deployment Successful!"
echo " Application is running at: http://$(hostname -I | awk '{print $1}')"
echo "=========================================="
