# AstroNova Books App — Traditional Linux Deployment

A production-style deployment of the AstroNova Books application on Ubuntu 22.04 using systemd, Nginx, and shell-based automation — without containers.

---

## Deployment Architecture

```
                    ┌──────────────────────────┐
                    │     User's Browser       │
                    └────────────┬─────────────┘
                                 │
                            HTTP (80)
                                 │
                    ┌────────────▼─────────────┐
                    │     Nginx (Port 80)       │
                    │  Reverse Proxy + Static   │
                    │                           │
                    │  /           → Vue SPA    │
                    │  /api/*      → FastAPI    │
                    │  /health     → FastAPI    │
                    └──────┬───────────┬────────┘
                           │           │
                     Static Files   Proxy Pass
                           │           │
              ┌────────────▼──┐  ┌─────▼──────────┐
              │  /opt/books-  │  │  Uvicorn        │
              │  app/frontend │  │  127.0.0.1:8080 │
              │  /dist/       │  │  (systemd)      │
              └───────────────┘  └─────────────────┘
```

---

## Deployment Directory Structure

The application is deployed to `/opt/books-app/` with the following layout:

```
/opt/books-app/
├── backend/
│   ├── app/                    # FastAPI application source code
│   │   ├── main.py             # Application entry point
│   │   ├── models.py           # Pydantic data models
│   │   ├── store.py            # In-memory book data store
│   │   └── routes/
│   │       ├── books.py        # CRUD API endpoints
│   │       └── health.py       # Health check endpoint
│   ├── requirements.txt        # Python dependencies
│   └── venv/                   # Python virtual environment (created by deploy.sh)
├── frontend/
│   └── dist/                   # Built Vue.js SPA (static files served by Nginx)
│       ├── index.html
│       ├── assets/
│       │   ├── index-*.js
│       │   └── index-*.css
│       └── favicon.ico
└── backend.env                 # Environment variables for the backend service
```

### Configuration Files (System-Level)

| File                | Installed To                            | Purpose                                 |
| ------------------- | --------------------------------------- | --------------------------------------- |
| `nginx.conf`        | `/etc/nginx/sites-available/books-app`  | Nginx virtual host configuration        |
| `books-app.service` | `/etc/systemd/system/books-app.service` | systemd service unit for the backend    |
| `backend.env`       | `/opt/books-app/backend.env`            | Environment variables loaded by systemd |

---

## Repository Structure

```
assignment_2/
├── backend/                    # FastAPI REST API source code
│   ├── app/
│   │   ├── main.py
│   │   ├── models.py
│   │   ├── store.py
│   │   └── routes/
│   │       ├── books.py
│   │       └── health.py
│   └── requirements.txt
├── frontend/                   # Vue.js SPA source code
│   ├── src/
│   │   ├── App.vue
│   │   ├── main.js
│   │   └── components/
│   ├── index.html
│   ├── package.json
│   └── vite.config.js
├── scripts/
│   ├── install.sh              # One-time server setup (dependencies, Nginx, systemd)
│   └── deploy.sh               # Build and deploy with automatic rollback
├── nginx.conf                  # Nginx reverse proxy configuration
├── books-app.service           # systemd service unit
├── backend.env                 # Backend environment variables
├── screenshots/                # Deployment evidence screenshots
├── SECURITY_INCIDENT.md        # Private key incident report and prevention
├── .gitignore
└── README.md
```

---

## How to Deploy

### Prerequisites

- Ubuntu 22.04 LTS server
- SSH access with sudo privileges
- Git installed on the server

### Step 1: Clone to Server

```bash
git clone https://github.com/manojcsuresh/astronova_assigment2.git assignment_2
cd assignment_2
```

### Step 2: Run Install Script (One-Time Setup)

```bash
sudo ./scripts/install.sh
```

This script:

- Installs system dependencies (Python 3, Node.js 18.x, Nginx, pip, venv)
- Creates a dedicated `booksapp` system user
- Creates the `/opt/books-app/` directory structure
- Copies `nginx.conf` → `/etc/nginx/sites-available/books-app` and symlinks to `sites-enabled`
- Removes the default Nginx site
- Copies `books-app.service` → `/etc/systemd/system/`
- Copies `backend.env` → `/opt/books-app/`
- Enables the service and restarts Nginx

### Step 3: Deploy the Application

```bash
sudo ./scripts/deploy.sh
```

This script:

1. Builds the Vue.js frontend (`npm install && npm run build`)
2. Creates a backup of the current deployment in `/tmp/astronova_backup`
3. Copies the built frontend to `/opt/books-app/frontend/dist/`
4. Copies backend source code to `/opt/books-app/backend/`
5. Creates/updates the Python virtual environment and installs dependencies
6. Restarts the `books-app.service` via systemd
7. Runs a health check (`curl http://localhost/health`)
8. **On failure:** Automatically rolls back to the backup and restarts the service

---

## Nginx Configuration Explained

The `nginx.conf` file defines the Nginx virtual host for the application:

```nginx
server {
    listen 80;                          # Listen on port 80 (HTTP)
    server_name _;                      # Accept requests for any hostname

    root /opt/books-app/frontend/dist;  # Serve Vue.js static files from here
    index index.html;                   # Default file to serve

    # ── Compression ─────────────────────────────────────────────
    gzip on;                            # Enable gzip compression
    gzip_vary on;                       # Add Vary: Accept-Encoding header
    gzip_proxied any;                   # Compress responses from proxied requests
    gzip_comp_level 6;                  # Compression level (1-9, 6 is balanced)
    gzip_types text/plain text/css      # MIME types to compress
               application/json application/javascript
               text/xml application/xml text/javascript
               image/svg+xml;

    # ── Security Headers ────────────────────────────────────────
    add_header X-Frame-Options "SAMEORIGIN" always;           # Prevent clickjacking
    add_header X-Content-Type-Options "nosniff" always;       # Prevent MIME sniffing
    add_header X-XSS-Protection "1; mode=block" always;       # XSS filter
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # ── Static Asset Caching ────────────────────────────────────
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;                     # Cache static assets for 1 year
        add_header Cache-Control "public, immutable";
    }

    # ── Vue.js SPA Routing ──────────────────────────────────────
    location / {
        try_files $uri $uri/ /index.html;   # Fallback to index.html for SPA routes
    }

    # ── API Reverse Proxy ───────────────────────────────────────
    location /api/ {
        proxy_pass http://127.0.0.1:8080;   # Forward to Uvicorn backend
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ── Health Check Proxy ──────────────────────────────────────
    location /health {
        proxy_pass http://127.0.0.1:8080;   # Forward health check to backend
        proxy_set_header Host $host;
    }
}
```

**Key Design Decisions:**

- Nginx serves static files directly (no Node.js server in production)
- API requests are reverse-proxied to Uvicorn on `127.0.0.1:8080` (loopback only, not exposed externally)
- `try_files` ensures Vue Router's client-side routing works (refreshing `/books/123` doesn't return 404)
- Security headers protect against common web vulnerabilities
- Gzip compression reduces bandwidth for text-based assets
- Long-lived cache headers for hashed Vite build assets (immutable filenames)

---

## systemctl and journalctl Commands Reference

### Service Management (systemctl)

```bash
# Check if the backend service is running
sudo systemctl status books-app.service

# Start the service
sudo systemctl start books-app.service

# Stop the service
sudo systemctl stop books-app.service

# Restart the service (stop + start)
sudo systemctl restart books-app.service

# Reload the service without full restart (graceful)
sudo systemctl reload-or-restart books-app.service

# Enable service to start on boot
sudo systemctl enable books-app.service

# Disable service from starting on boot
sudo systemctl disable books-app.service

# Check if the service is enabled
sudo systemctl is-enabled books-app.service
```

### Nginx Management

```bash
# Check Nginx status
sudo systemctl status nginx

# Test Nginx configuration for syntax errors
sudo nginx -t

# Reload Nginx configuration (no downtime)
sudo systemctl reload nginx

# Restart Nginx
sudo systemctl restart nginx

# View Nginx error logs
sudo tail -f /var/log/nginx/error.log

# View Nginx access logs
sudo tail -f /var/log/nginx/access.log
```

### Log Viewing (journalctl)

```bash
# View all logs for the books-app service
sudo journalctl -u books-app.service

# Follow logs in real-time (like tail -f)
sudo journalctl -u books-app.service -f

# View last 50 lines
sudo journalctl -u books-app.service -n 50

# View logs since the last boot
sudo journalctl -u books-app.service -b

# View logs from the last hour
sudo journalctl -u books-app.service --since "1 hour ago"

# View logs from a specific date range
sudo journalctl -u books-app.service --since "2026-07-01" --until "2026-07-02"

# View logs in JSON format (for parsing)
sudo journalctl -u books-app.service -o json-pretty

# View logs with priority (error and above)
sudo journalctl -u books-app.service -p err

# Check disk usage of journal logs
sudo journalctl --disk-usage

# Clean logs older than 7 days
sudo journalctl --vacuum-time=7d
```

---

## Screenshots

Screenshots demonstrating the live deployment are located in the [`screenshots/`](./screenshots/) directory:

| Screenshot             | Description                                                                |
| ---------------------- | -------------------------------------------------------------------------- |
| `systemctl-status.png` | Output of `systemctl status books-app.service` showing the service running |
| `journalctl-logs.png`  | Output of `journalctl -u books-app.service -n 30` showing application logs |
| `nginx-status.png`     | Output of `systemctl status nginx` showing Nginx running                   |
| `frontend-ui.png`      | Browser screenshot of the AstroNova frontend application                   |
| `api-call.png`         | Terminal output of a `curl` API call to `/api/books`                       |

---

## Rollback

The `deploy.sh` script automatically creates a backup of the current deployment in `/tmp/astronova_backup` before deploying. If the health check fails after deployment:

1. The script prints the last 20 lines from `journalctl` for debugging
2. Restores the frontend and backend from the backup
3. Reinstalls Python dependencies from the backed-up `requirements.txt`
4. Restarts the service with the previous working version
5. Exits with a non-zero status code

---

## API Documentation

**Base URL:** `http://<server-ip>`

| Method   | Endpoint          | Description             | Status Codes  |
| -------- | ----------------- | ----------------------- | ------------- |
| `GET`    | `/api/books`      | List all books          | 200           |
| `GET`    | `/api/books/{id}` | Get a book by ID        | 200, 404      |
| `POST`   | `/api/books`      | Create a new book       | 201, 422      |
| `PATCH`  | `/api/books/{id}` | Update a book partially | 200, 400, 404 |
| `DELETE` | `/api/books/{id}` | Delete a book           | 204, 404      |
| `GET`    | `/health`         | Health check            | 200           |

### Example API Calls

```bash
# List all books
curl http://<server-ip>/api/books | python3 -m json.tool

# Create a new book
curl -X POST http://<server-ip>/api/books \
  -H "Content-Type: application/json" \
  -d '{"title": "Kubernetes in Action", "author": "Marko Luksa", "publishedYear": 2018}'

# Get a specific book
curl http://<server-ip>/api/books/<book-id> | python3 -m json.tool

# Update a book
curl -X PATCH http://<server-ip>/api/books/<book-id> \
  -H "Content-Type: application/json" \
  -d '{"title": "Kubernetes in Action, 2nd Edition"}'

# Delete a book
curl -X DELETE http://<server-ip>/api/books/<book-id>

# Health check
curl http://<server-ip>/health
```

---

