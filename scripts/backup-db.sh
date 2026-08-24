#!/usr/bin/env bash
#
# backup-db.sh
# Backs up the PostgreSQL database running in the "db" Docker Compose
# service, rotates old backups, and rotates the script's own log file.
#
# Usage: ./backup-db.sh
# Requires a .env file in the project root with POSTGRES_USER,
# POSTGRES_DB, and POSTGRES_PASSWORD set.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
BACKUP_DIR="$PROJECT_ROOT/backups"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/backup.log"
RETENTION_DAYS=7
CONTAINER_NAME="dreamvacation-db"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ ! -f "$ENV_FILE" ]; then
  log "ERROR: .env file not found at $ENV_FILE. Aborting."
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [ -z "${POSTGRES_USER:-}" ] || [ -z "${POSTGRES_DB:-}" ]; then
  log "ERROR: POSTGRES_USER or POSTGRES_DB not set in .env. Aborting."
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  log "ERROR: Database container '$CONTAINER_NAME' is not running. Aborting."
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${POSTGRES_DB}_${TIMESTAMP}.sql.gz"

log "Starting backup of database '$POSTGRES_DB'..."

if docker exec "$CONTAINER_NAME" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$BACKUP_FILE"; then
  log "Backup successful: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
else
  log "ERROR: Backup failed."
  rm -f "$BACKUP_FILE"
  exit 1
fi

# --- Rotate old backups: delete anything older than RETENTION_DAYS ---
log "Rotating backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +"$RETENTION_DAYS" -print -delete | while read -r old; do
  log "Deleted old backup: $old"
done

# --- Rotate the log file itself if it's grown past 1MB ---
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE")" -gt 1048576 ]; then
  mv "$LOG_FILE" "$LOG_FILE.$(date +%Y%m%d_%H%M%S).old"
  log "Log file rotated (exceeded 1MB)."
fi

log "Backup and rotation complete."
