# Books Application - Traditional Deployment

This repository contains the setup for a traditional deployment of the AstroNova Books Application on an Ubuntu 22.04 server without Docker or Kubernetes.

## Directory Structure

```
assignment_2/
├── backend/                  # Python FastAPI application source code
├── frontend/                 # Vue.js application source code
├── scripts/                  
│   ├── install.sh            # Server provisioning script
│   └── deploy.sh             # Application build and deployment script
├── backend.env               # Environment variables for the backend
├── books-app.service         # Systemd service configuration
├── nginx.conf                # Nginx reverse proxy configuration
└── README.md                 # This documentation file
```

## Deployment Steps

To deploy this application to a fresh Ubuntu 22.04 server, follow these steps:

1. **Clone the repository** (or copy the files) to the server:
   ```bash
   git clone <repository-url>
   cd astronova/assignment_2
   ```

2. **Provision the Server**:
   Run the installation script to install dependencies (Node.js, Python, Nginx), create the `booksapp` user, set up the directory structure in `/opt/books-app`, and apply configurations.
   ```bash
   sudo ./scripts/install.sh
   ```

3. **Build and Deploy**:
   Run the deployment script to compile the frontend, set up the Python virtual environment, install backend dependencies, and restart the service.
   ```bash
   sudo ./scripts/deploy.sh
   ```

   The script will verify the deployment via a health check endpoint and output the application URL.

## Service Management Commands

The backend is managed as a standard Linux service using `systemd`.

- **View Status**: `sudo systemctl status books-app.service`
- **Start Service**: `sudo systemctl start books-app.service`
- **Stop Service**: `sudo systemctl stop books-app.service`
- **Restart Service**: `sudo systemctl restart books-app.service`
- **View Logs**: `sudo journalctl -u books-app.service -f`

## Nginx Configuration Explanation

Nginx acts as a reverse proxy with the following responsibilities:

- **Serve Frontend**: The static files built by the frontend are served directly from `/opt/books-app/frontend/dist`.
- **SPA Fallback**: Handled using `try_files $uri $uri/ /index.html;` so Vue router works correctly without 404s on page refresh.
- **Proxy API Requests**: Any requests starting with `/api/` or `/health` are proxied to the backend running locally on `http://127.0.0.1:8080`.
- **Performance**: Static asset caching is configured with `Cache-Control` for optimal load times, and Gzip compression is enabled to reduce response sizes.
- **Security**: Basic security headers like `X-Frame-Options` and `X-Content-Type-Options` are included to protect against clickjacking and MIME sniffing.

## Rollback Procedure

In the event of a failed deployment, you can roll back to a previously working state. 

1. **Keep backups before deploy**: The `deploy.sh` script can be modified to compress the `/opt/books-app/backend/app` and `/opt/books-app/frontend/dist` directories into a timestamped `.tar.gz` archive before replacing them.
2. **Execute Rollback**:
   ```bash
   # Stop the service
   sudo systemctl stop books-app.service
   
   # Restore frontend
   sudo rm -rf /opt/books-app/frontend/dist
   sudo tar -xzf /path/to/backup/frontend_backup.tar.gz -C /opt/books-app/frontend
   
   # Restore backend
   sudo rm -rf /opt/books-app/backend/app
   sudo tar -xzf /path/to/backup/backend_backup.tar.gz -C /opt/books-app/backend
   
   # Restart the service
   sudo systemctl start books-app.service
   ```
