#! /bin/sh

set -e
set -o pipefail



# Environment checks
if [ "${POSTGRES_DATABASE}" = "**None**" ]; then
  echo -n "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo -n "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo -n "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo -n "You need to set the POSTGRES_PASSWORD environment variable."
  exit 1
fi

if [ "${GCLOUD_KEYFILE_BASE64}" = "**None**" ]; then
  echo -n "You need to set the GCLOUD_KEYFILE_BASE64 environment variable."
  exit 1
fi

if [ "${GCLOUD_PROJECT_ID}" = "**None**" ]; then
  echo -n "You need to set the GCLOUD_PROJECT_ID environment variable."
  exit 1
fi

if [ "${GCS_BACKUP_BUCKET}" = "**None**" ]; then
  echo -n "You need to set the GCS_BACKUP_BUCKET environment variable."
  exit 1
fi

if [ "${BACKUPNAME}" = "**None**" ]; then
  echo -n "You need to set the BACKUPNAME environment variable."
  exit 1
fi

# Google Cloud Auth
echo -n "Authenticating to Google Cloud"
echo -n $GCLOUD_KEYFILE_BASE64 | base64 -d > /key.json
gcloud auth activate-service-account --key-file /key.json --project "$GCLOUD_PROJECT_ID" -q


# Postgres dumping
DATE=`date +"%Y-%m-%d_%H-%M-%S"`
FILENAME="${BACKUPNAME}_${DATE}.dump"
export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

echo -n "Uploading pg_dump to $GCS_BACKUP_BUCKET"
pg_dump $POSTGRES_HOST_OPTS -Fc $POSTGRES_DATABASE | gsutil cp - $GCS_BACKUP_BUCKET/$FILENAME
echo -n "SQL backup uploaded successfully"
