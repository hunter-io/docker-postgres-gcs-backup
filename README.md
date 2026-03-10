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
| `POSTGRES_SSLMODE`      | SSL connection mode for `pg_dump`. Options: `disable`, `allow`, `prefer`, `require`, `verify-ca`, `verify-full`. **Default:** `''` (libpq default is `prefer`) |
| `POSTGRES_SSLROOTCERT`  | Path to the root CA certificate file inside the container, used to verify the server certificate. Required for `verify-ca` and `verify-full` modes. |
| `POSTGRES_SSLCERT`      | Path to the client SSL certificate file inside the container, for mutual TLS / client certificate authentication. |
| `POSTGRES_SSLKEY`       | Path to the client SSL private key file inside the container. Must have restrictive permissions (`chmod 0600`). |
| `GCLOUD_KEYFILE_BASE64` | The GCP service account's credential file, in base64. See below for recommendations regarding this.            |
| `GCLOUD_PROJECT_ID`     | The Project ID which the bucket you wish to backup to is in.                                                   |
| `BACKUPNAME`            | The prefix for the backup file name.

### SSL Configuration

By default, `pg_dump` uses `sslmode=prefer`, which attempts SSL but falls back to an unencrypted connection silently. For production use, you should enforce SSL explicitly.

**Require SSL (no certificate verification):**
```
-e POSTGRES_SSLMODE=require
```

**Verify the server certificate (recommended for production):**
```
-e POSTGRES_SSLMODE=verify-full \
-e POSTGRES_SSLROOTCERT=/certs/root.crt \
-v /path/to/root.crt:/certs/root.crt:ro
```

**Mutual TLS (client certificate authentication):**
```
-e POSTGRES_SSLMODE=verify-full \
-e POSTGRES_SSLROOTCERT=/certs/root.crt \
-e POSTGRES_SSLCERT=/certs/client.crt \
-e POSTGRES_SSLKEY=/certs/client.key \
-v /path/to/certs:/certs:ro
```

Note: The client key file must have restrictive permissions (`chmod 0600`), or libpq will refuse to use it.
