# Books App Deployment

Deployment setup for the AstroNova Books App on Ubuntu 22.04.

## Structure
- `backend/`: FastAPI app
- `frontend/`: Vue app
- `scripts/install.sh`: Installs system dependencies and sets up nginx/systemd
- `scripts/deploy.sh`: Builds and deploys the app
- `nginx.conf`: Reverse proxy config
- `books-app.service`: Systemd service

## How to deploy

1. Clone to server:
   ```bash
   git clone https://github.com/manojcsuresh/astronova_assigment2.git assignment_2
   cd assignment_2
   ```

2. Run install script:
   ```bash
   sudo ./scripts/install.sh
   ```

3. Deploy the application:
   ```bash
   sudo ./scripts/deploy.sh
   ```

## Logs and Management
- Start/stop: `sudo systemctl restart books-app.service`
- Check logs: `sudo journalctl -u books-app.service -f`

## Rollback
The `deploy.sh` script automatically creates a backup of the current deployment in `/tmp/astronova_backup` and will restore it if the health check fails after deployment.
