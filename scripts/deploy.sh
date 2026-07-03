#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$0")
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
APP_DIR="/opt/books-app"

if [ "$EUID" -ne 0 ]; then
  exit 1
fi

cd $ROOT_DIR/frontend
npm install
npm run build

rm -rf /tmp/astronova_backup
mkdir -p /tmp/astronova_backup
cp -r $APP_DIR/frontend/dist /tmp/astronova_backup/frontend_dist 2>/dev/null || true
cp -r $APP_DIR/backend/app /tmp/astronova_backup/backend_app 2>/dev/null || true
cp $APP_DIR/backend/requirements.txt /tmp/astronova_backup/requirements.txt 2>/dev/null || true

rm -rf $APP_DIR/frontend/dist
cp -r dist $APP_DIR/frontend/
chown -R booksapp:booksapp $APP_DIR/frontend

cd $ROOT_DIR/backend
cp -r app requirements.txt $APP_DIR/backend/
chown -R booksapp:booksapp $APP_DIR/backend

sudo -u booksapp bash << 'EOF'
cd /opt/books-app/backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt
EOF

systemctl restart books-app.service

sleep 3
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)

if [ "$HEALTH_STATUS" -eq 200 ]; then
    rm -rf /tmp/astronova_backup
else
    journalctl -u books-app.service -n 20 --no-pager
    
    rm -rf $APP_DIR/frontend/dist $APP_DIR/backend/app
    cp -r /tmp/astronova_backup/frontend_dist $APP_DIR/frontend/dist 2>/dev/null || true
    cp -r /tmp/astronova_backup/backend_app $APP_DIR/backend/app 2>/dev/null || true
    cp /tmp/astronova_backup/requirements.txt $APP_DIR/backend/requirements.txt 2>/dev/null || true
    chown -R booksapp:booksapp $APP_DIR
    
    sudo -u booksapp bash << 'EOF'
cd /opt/books-app/backend
source venv/bin/activate
pip install -r requirements.txt
EOF
    systemctl restart books-app.service
    exit 1
fi
