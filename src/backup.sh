#!/bin/sh

set -eu
set -o pipefail

source ./env.sh

echo "Creating backup..."
tar -czf dump.tar.gz /data

timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}/${BACKUP_NAME}_${timestamp}.tar.gz"

if [ -n "$PASSPHRASE" ]; then
  echo "Encrypting backup..."
  rm -f dump.tar.gz.gpg
  gpg --symmetric --batch --passphrase "$PASSPHRASE" dump.tar.gz
  rm dump.tar.gz
  local_file="dump.tar.gz.gpg"
  s3_uri="${s3_uri_base}.gpg"
else
  local_file="dump.tar.gz"
  s3_uri="$s3_uri_base"
fi

echo "Uploading backup to $S3_BUCKET..."
aws $aws_args s3 cp "$local_file" "$s3_uri"
rm "$local_file"

echo "Backup complete."

if [ -n "$BACKUP_KEEP_DAYS" ]; then
  sec=$((86400*BACKUP_KEEP_DAYS))
  date_from_remove=$(date -d "@$(($(date +%s) - sec))" +%Y-%m-%d)
  backups_query="Contents[?LastModified<='${date_from_remove} 00:00:00'].{Key: Key}"

  echo "Removing old backups from $S3_BUCKET..."
  aws $aws_args s3api list-objects \
    --bucket "${S3_BUCKET}" \
    --prefix "${S3_PREFIX}" \
    --query "${backups_query}" \
    --output text \
    | xargs -n1 -t -I 'KEY' aws $aws_args s3 rm s3://"${S3_BUCKET}"/'KEY'
  echo "Removal complete."
fi
