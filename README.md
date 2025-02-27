# Backup Postgresql databases to Google Cloud Storage

This docker image uploads a pg_dump backup of a database to GCS. It's based almost entirely on the work of [Nullpixel](https://github.com/nullpixel/postgres-docker-gcs-backup).

## Usage

### Environment variables
| Variable                | Description                                                                                                    |
|-------------------------|----------------------------------------------------------------------------------------------------------------|
| `POSTGRES_DATABASE`     | The name of the database to backup.                                                                            |
| `POSTGRES_HOST`         | The host of the database to backup.                                                                            |
| `POSTGRES_PORT`         | The port of the database to backup.  **Default:** 5432                                                         |
| `POSTGRES_USER`         | The username of the backup user.                                                                               |
| `POSTGRES_PASSWORD`     | The password of the backup user.                                                                               |
| `POSTGRES_EXTRA_OPTS`   | Any additional options you wish to pass to `pg_dump`. **Default:** `''`                                        |
| `GCLOUD_KEYFILE_BASE64` | The GCP service account's credential file, in base64. See below for recommendations regarding this.            |
| `GCLOUD_PROJECT_ID`     | The Project ID which the bucket you wish to backup to is in.                                                   |
| `BACKUPNAME`            | The prefix for the backup file name.
