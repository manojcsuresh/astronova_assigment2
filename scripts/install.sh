#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  exit 1
fi

apt-get update
apt-get install -y python3 python3-pip python3-venv nodejs npm nginx curl git

curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

if ! id "booksapp" &>/dev/null; then
    useradd -m -s /bin/bash booksapp
fi

mkdir -p /opt/books-app/backend
mkdir -p /opt/books-app/frontend
chown -R booksapp:booksapp /opt/books-app
chmod -R 755 /opt/books-app

SCRIPT_DIR=$(dirname "$0")
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

cp $ROOT_DIR/nginx.conf /etc/nginx/sites-available/books-app
ln -sf /etc/nginx/sites-available/books-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

cp $ROOT_DIR/books-app.service /etc/systemd/system/
cp $ROOT_DIR/backend.env /opt/books-app/
chown booksapp:booksapp /opt/books-app/backend.env
chmod 600 /opt/books-app/backend.env

systemctl daemon-reload
systemctl enable books-app.service

nginx -t
systemctl restart nginx
