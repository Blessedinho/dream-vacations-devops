#!/usr/bin/env bash
#
# setup-env.sh
# Idempotent environment setup script for the Dream Vacations app.
# Installs Docker, Docker Compose, and Node.js if not already present.
#
set -euo pipefail

log() {
  echo "[setup-env] $1"
}

# --- Docker ---
if command -v docker &> /dev/null; then
  log "Docker already installed ($(docker --version)). Skipping."
else
  log "Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  log "Docker installed. You may need to log out and back in for group changes to apply."
fi

# --- Docker Compose plugin check (installed alongside Docker above, but verify) ---
if docker compose version &> /dev/null; then
  log "Docker Compose already available ($(docker compose version))."
else
  log "WARNING: Docker Compose plugin not found after Docker install. Check installation manually."
fi

# --- Node.js (for local dev outside containers, e.g. running lint/tests) ---
if command -v node &> /dev/null; then
  log "Node.js already installed ($(node --version)). Skipping."
else
  log "Installing Node.js 18.x..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

log "Environment setup complete."
