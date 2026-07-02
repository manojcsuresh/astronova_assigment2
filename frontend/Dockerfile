# ════════════════════════════════════════════════════════════════
# AstroNova Frontend — Multi-stage Dockerfile (Vue.js + Nginx)
# ════════════════════════════════════════════════════════════════

# ── Stage 1: Build ────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /build

# Install dependencies first (layer caching)
COPY package.json package-lock.json* ./
RUN npm ci --silent

# Copy source and build
COPY . .

# Accept build-time API URL
ARG VITE_API_URL=""
ENV VITE_API_URL=${VITE_API_URL}

RUN npm run build

# ── Stage 2: Serve with Nginx ────────────────────────────────
FROM nginx:1.27-alpine AS production

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder stage
COPY --from=builder /build/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
