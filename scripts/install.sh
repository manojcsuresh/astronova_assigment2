#!/bin/bash
set -e

echo "=========================================="
echo " Books Application - Initial Server Setup "
echo "=========================================="

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)"
  exit 1
fi

echo "1. Installing Prerequisites..."
apt-get update
apt-get install -y python3 python3-pip python3-venv nodejs npm nginx curl git

# Install a more recent version of Node.js if necessary (Ubuntu 22.04 default is v12, but we need 18+)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo "2. Creating Application User..."
if ! id "booksapp" &>/dev/null; then
    useradd -m -s /bin/bash booksapp
    echo "User 'booksapp' created."
else
    echo "User 'booksapp' already exists."
fi

echo "3. Creating Directory Structure..."
mkdir -p /opt/books-app/backend
mkdir -p /opt/books-app/frontend
chown -R booksapp:booksapp /opt/books-app
chmod -R 755 /opt/books-app

echo "4. Copying Initial Configuration Files..."
# Assume the script is run from the assignment_2 directory
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

echo "5. Restarting Nginx..."
nginx -t
systemctl restart nginx

echo "Server setup completed successfully!"
echo "You can now run deploy.sh to build and deploy the application."
