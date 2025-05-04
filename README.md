# docker-volume-s3-backup

## Introduction

This project provides a Docker image that periodically backs up a Docker volume to AWS S3, and can restore a backup as needed.

## Usage

### Backup

Example `docker-compose.yml`:

```yaml
services:
  my_service:
    image: ...
    volumes:
      data:/app/some-data-dir

  volume_backup:
    image: smartyellow/docker-volume-s3-backup
    environment:
      SCHEDULE: '@weekly'     # optional
      BACKUP_KEEP_DAYS: 7     # optional
      PASSPHRASE: passphrase  # optional
      S3_REGION: region
      S3_ACCESS_KEY_ID: key
      S3_SECRET_ACCESS_KEY: secret
      S3_BUCKET: my-bucket
      S3_PREFIX: backup
```

- The `SCHEDULE` variable determines backup frequency. See go-cron schedules documentation [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules). Omit to run the backup immediately and then exit.
- If `PASSPHRASE` is provided, the backup will be encrypted using GPG.
- Run `docker exec <container_name> sh backup.sh` to trigger a backup ad-hoc.
- If `BACKUP_KEEP_DAYS` is set, backups older than this many days will be deleted from S3.
- Set `S3_ENDPOINT` if you're using a non-AWS S3-compatible storage provider.

### Restore

> [!CAUTION]
> DATA LOSS! All database objects will be dropped and re-created.

#### ... from latest backup

```sh
docker exec <container_name> sh restore.sh
```

> [!NOTE]
> If your bucket has more than a 1000 files, the latest may not be restored -- only one S3 `ls` command is used

#### ... from specific backup

```sh
docker exec <container_name> sh restore.sh <timestamp>
```

## Development

### Run a simple test environment with Docker Compose
```sh
cp template.env .env
# fill out your secrets/params in .env
docker compose up -d
```

## Acknowledgements

This project is a modification of the excellent [`eeshugerman/postgres-backup-s3`](https://github.com/eeshugerman/postgres-backup-s3), which in turn is a fork and re-structuring of [`schickling/postgres-backup-s3`](https://github.com/schickling/dockerfiles/tree/master/postgres-backup-s3) and [`schickling/postgres-restore-s3`](https://github.com/schickling/dockerfiles/tree/master/postgres-restore-s3).

## Copyright

Copyright (c) 2017 Johannes Schickling

Copyright (c) 2022 Elliott Shugerman

Copyright (c) 2025 [Romein van Buren](mailto:romein@smartyellow.nl)

Licensed under the MIT license.
