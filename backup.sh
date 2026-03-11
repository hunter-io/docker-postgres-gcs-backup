#! /bin/sh

set -e
set -o pipefail

# Logging helper — timestamps every message for Kubernetes log aggregators
log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }

# Log on non-zero exit (EXIT trap is POSIX, unlike ERR which requires bash)
# shellcheck disable=SC2154 # exit_code is assigned via $? in the trap body
trap 'exit_code=$?; if [ $exit_code -ne 0 ]; then log "ERROR: Backup failed (exit code $exit_code)"; fi' EXIT

# Helper to format seconds into human-readable duration
format_duration() {
  total=$1
  mins=$((total / 60))
  secs=$((total % 60))
  if [ "$mins" -gt 0 ]; then
    echo "${mins}m ${secs}s"
  else
    echo "${secs}s"
  fi
}

# Environment checks
if [ "${POSTGRES_DATABASE}" = "**None**" ]; then
  log "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    log "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  log "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  log "You need to set the POSTGRES_PASSWORD environment variable."
  exit 1
fi

if [ "${GCLOUD_KEYFILE_BASE64}" = "**None**" ]; then
  log "You need to set the GCLOUD_KEYFILE_BASE64 environment variable."
  exit 1
fi

if [ "${GCLOUD_PROJECT_ID}" = "**None**" ]; then
  log "You need to set the GCLOUD_PROJECT_ID environment variable."
  exit 1
fi

if [ "${GCS_BACKUP_BUCKET}" = "**None**" ]; then
  log "You need to set the GCS_BACKUP_BUCKET environment variable."
  exit 1
fi

if [ "${BACKUPNAME}" = "**None**" ]; then
  log "You need to set the BACKUPNAME environment variable."
  exit 1
fi

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="${BACKUPNAME}_${DATE}.tar.gz.dump"
export PGPASSWORD="$POSTGRES_PASSWORD"
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER"

# Export SSL settings for libpq (used by pg_dump)
if [ -n "$POSTGRES_SSLMODE" ]; then
  export PGSSLMODE="$POSTGRES_SSLMODE"
fi

if [ -n "$POSTGRES_SSLROOTCERT" ]; then
  export PGSSLROOTCERT="$POSTGRES_SSLROOTCERT"
fi

if [ -n "$POSTGRES_SSLCERT" ]; then
  export PGSSLCERT="$POSTGRES_SSLCERT"
fi

if [ -n "$POSTGRES_SSLKEY" ]; then
  export PGSSLKEY="$POSTGRES_SSLKEY"
fi

BACKUP_START=$(date +%s)

log "=== Starting backup ==="
log "Database: $POSTGRES_DATABASE"
log "Host: $POSTGRES_HOST:$POSTGRES_PORT"
log "Backup name: $BACKUPNAME"
log "Target bucket: $GCS_BACKUP_BUCKET"

log "Clearing backups directory"
rm -rf /backups/*

log "Starting pg_dump (format=directory, jobs=4)..."
STEP_START=$(date +%s)
# shellcheck disable=SC2086 # HOST_OPTS and EXTRA_OPTS need word splitting into separate arguments
pg_dump $POSTGRES_HOST_OPTS $POSTGRES_EXTRA_OPTS -Fd -j4 -f "/backups/${BACKUPNAME}_${DATE}" "$POSTGRES_DATABASE"
STEP_END=$(date +%s)
DUMP_SIZE=$(du -sh "/backups/${BACKUPNAME}_${DATE}" | cut -f1)
log "pg_dump completed in $(format_duration $((STEP_END - STEP_START))) — dump size: $DUMP_SIZE"

log "Compressing dump with pigz (level 9)..."
STEP_START=$(date +%s)
tar -cf - "/backups/${BACKUPNAME}_${DATE}"/ | pigz -9 > "/backups/${FILENAME}"
STEP_END=$(date +%s)
ARCHIVE_SIZE=$(du -sh "/backups/${FILENAME}" | cut -f1)
log "Compression completed in $(format_duration $((STEP_END - STEP_START))) — archive size: $ARCHIVE_SIZE ($FILENAME)"

log "Authenticating to Google Cloud..."
printf '%s' "$GCLOUD_KEYFILE_BASE64" | base64 -d > /key.json
gcloud auth activate-service-account --key-file /key.json --project "$GCLOUD_PROJECT_ID" -q

log "Uploading $ARCHIVE_SIZE to $GCS_BACKUP_BUCKET/$FILENAME..."
STEP_START=$(date +%s)
gcloud storage cp "/backups/${FILENAME}" "$GCS_BACKUP_BUCKET/$FILENAME"
STEP_END=$(date +%s)
log "Upload completed in $(format_duration $((STEP_END - STEP_START)))"

log "Clearing backups directory"
rm -rf /backups/*

BACKUP_END=$(date +%s)
log "=== Backup completed successfully in $(format_duration $((BACKUP_END - BACKUP_START))) ==="
