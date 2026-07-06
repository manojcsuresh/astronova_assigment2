# Screenshots

This directory contains screenshots demonstrating the live deployment.

## Required Screenshots

Please capture and commit the following screenshots from the live server:

### 1. systemctl-status.png
```bash
sudo systemctl status books-app.service
```
Take a screenshot of the terminal output showing the service as active/running.

### 2. journalctl-logs.png
```bash
sudo journalctl -u books-app.service -n 30 --no-pager
```
Take a screenshot showing the last 30 lines of application logs.

### 3. nginx-status.png
```bash
sudo systemctl status nginx
```
Take a screenshot showing Nginx is active and running.

### 4. frontend-ui.png
Open `http://<server-ip>` in a browser and take a screenshot of the AstroNova frontend.

### 5. api-call.png
```bash
curl -s http://<server-ip>/api/books | python3 -m json.tool
```
Take a screenshot of the terminal output showing the JSON response.

## How to Take Screenshots

### From SSH terminal (use script + screenshot tool):
```bash
# Option 1: Use the `script` command to capture terminal output
script -q /dev/null -c "sudo systemctl status books-app.service" > systemctl-status.txt

# Option 2: If using a terminal emulator, use its built-in screenshot feature

# Option 3: Use `gnome-screenshot` or `scrot` on a desktop environment
```

### From browser:
Use your browser's built-in screenshot tool or press `Ctrl+Shift+S` (Firefox) or install a screenshot extension.
