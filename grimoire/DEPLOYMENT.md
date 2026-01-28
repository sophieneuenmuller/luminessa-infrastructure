# Grimoire Deployment Guide

Bookmark manager deployment for luminessa.net infrastructure.

## Overview

- **Service**: Grimoire (bookmark manager)
- **URL**: https://bookmarks.luminessa.net
- **Database**: SQLite (file-based, no additional containers)
- **Storage**: Bind mount `./data` (stored in `/opt/grimoire/data/` on the server)

## Prerequisites

- Existing Caddy reverse proxy with external `caddy` network
- DNS record for `bookmarks.luminessa.net` pointing to your server (via Cloudflare)

---

## Deployment Steps

### 1. Create DNS Record

In Cloudflare, add an A record:
- **Name**: `bookmarks`
- **Content**: `77.42.24.90`
- **Proxy status**: Proxied (orange cloud) or DNS only — your choice
- **TTL**: Auto

### 2. Create Directory Structure

Following the standard infrastructure layout:

```bash
# Create working directory and data directory
sudo mkdir -p /opt/grimoire/data

# Create symlink to docker-compose.yml from infrastructure repo
cd /opt/grimoire
ln -s /opt/infrastructure/grimoire/docker-compose.yml .

# Set appropriate permissions for data directory
sudo chown -R 1000:1000 /opt/grimoire/data
```

### 3. Configure Environment (if needed)

Grimoire doesn't require a `.env` file by default, but you can create one in `/opt/secrets/grimoire/` if you want to manage the `PUBLIC_SIGNUP_DISABLED` variable there.

### 4. Update Caddyfile

Add the Grimoire route to your existing Caddyfile:

```caddy
bookmarks.luminessa.net {
    reverse_proxy grimoire:5173
}
```

Then reload Caddy:
```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### 5. Start Grimoire

```bash
cd /opt/grimoire
docker compose up -d
```

### 6. Create Your Account

1. Navigate to https://bookmarks.luminessa.net
2. Click "Sign up" and create your account
3. The first account becomes the admin

### 7. Disable Public Registration

After creating your account, edit `docker-compose.yml`:

```yaml
- PUBLIC_SIGNUP_DISABLED=true
```

Then restart:
```bash
docker compose up -d
```

---

## Browser Extension Setup

### Install Grimoire Companion

1. **Chrome/Brave/Edge**: Install from [Chrome Web Store](https://chromewebstore.google.com/detail/grimoire-companion/mbciogjbnegofhhhlcbmlobjcgjdbgfh)
2. **Firefox**: Install from [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/grimoire-companion/)

### Configure Extension

1. Click the extension icon
2. Go to Settings
3. Enter your Grimoire URL: `https://bookmarks.luminessa.net`
4. Generate an API token in Grimoire (Settings → Integration API → Generate Token)
5. Paste the token in the extension settings

---

## Mobile Access

Grimoire doesn't have a native mobile app yet, but you can:

1. **Use the responsive web UI**: Navigate to https://bookmarks.luminessa.net on your mobile browser
2. **Add to Home Screen** (PWA-like experience):
   - iOS Safari: Share → Add to Home Screen
   - Android Chrome: Menu → Add to Home Screen

---

## Backup Strategy

### What to Backup

The SQLite database and all uploaded content are stored in `/opt/grimoire/data/`

### Backup Commands

```bash
# Create a backup (simple - just tar the data directory)
sudo tar -czvf grimoire-backup-$(date +%Y%m%d).tar.gz -C /opt/grimoire data/

# Restore a backup
sudo tar -xzvf grimoire-backup-20240128.tar.gz -C /opt/grimoire/
sudo chown -R 1000:1000 /opt/grimoire/data
```

### Automated Backup (Cron)

Add to your backup script or crontab:

```bash
#!/bin/bash
# grimoire-backup.sh
BACKUP_DIR="/path/to/your/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Stop container briefly for consistent backup (optional but recommended)
cd /opt/grimoire
docker compose stop

# Backup the data directory
sudo tar -czvf "${BACKUP_DIR}/grimoire-${DATE}.tar.gz" -C /opt/grimoire data/

# Restart container
docker compose start

# Keep only last 7 backups
find "${BACKUP_DIR}" -name "grimoire-*.tar.gz" -mtime +7 -delete
```

### Integration with Syncthing

Since data is now in a regular directory (`/opt/grimoire/data/`), integration is straightforward:

1. **Option 1**: Point backup script output to a Syncthing-watched directory
2. **Option 2**: Add `/opt/grimoire/data/` as a Syncthing shared folder (ensure proper permissions)

---

## AI Features (Optional)

Grimoire supports AI-powered summaries via Ollama. Since you want local models only:

### Option 1: Run Ollama on a Separate Machine

If you have a home server with more resources:

```yaml
# On your home server
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
```

Then configure Grimoire to point to it (check Grimoire's settings for AI configuration).

### Option 2: Skip AI Features

Grimoire works perfectly without AI. The fuzzy search is excellent, and manual tagging is straightforward.

---

## Maintenance

### View Logs

```bash
docker logs grimoire
docker logs -f grimoire  # Follow logs
```

### Update Grimoire

```bash
cd /opt/grimoire
docker compose pull
docker compose up -d
```

### Check Health

```bash
curl -s http://localhost:5173/api/health
# Or via Caddy
curl -s https://bookmarks.luminessa.net/api/health
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs grimoire

# Verify network exists
docker network ls | grep caddy

# Verify data directory exists and has correct permissions
ls -la /opt/grimoire/data
sudo chown -R 1000:1000 /opt/grimoire/data
```

### Can't Access via Domain

1. Check DNS propagation: `dig bookmarks.luminessa.net`
2. Check Caddy logs: `docker logs caddy`
3. Verify Caddyfile syntax: `docker exec caddy caddy validate --config /etc/caddy/Caddyfile`

### Extension Can't Connect

1. Verify API token is correct
2. Check that HTTPS is working (browser shouldn't show certificate errors)
3. Ensure `PUBLIC_HTTPS_ONLY=true` matches your Caddy setup

---

## File Structure

After deployment, your infrastructure should look like:

```
/opt/
├── infrastructure/          # Git repository
│   ├── grimoire/
│   │   └── docker-compose.yml
│   └── caddy/
│       └── Caddyfile (updated with grimoire route)
│
├── grimoire/               # Working directory
│   ├── docker-compose.yml  → symlink to /opt/infrastructure/grimoire/docker-compose.yml
│   └── data/              # SQLite database and uploads (NOT in git, in backups)
│       └── grimoire.db
│
└── caddy/
    └── Caddyfile          → symlink to /opt/infrastructure/caddy/Caddyfile
```

---

## Resource Usage

Expected resource consumption on your CX23:

| Metric | Idle | Active |
|--------|------|--------|
| RAM | ~100-150MB | ~200-300MB |
| CPU | Minimal | Low spikes during metadata fetch |
| Storage | Depends on bookmarks + screenshots | ~50MB base + your data |

This is very lightweight and will coexist happily with your existing services.
