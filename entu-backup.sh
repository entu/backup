#!/bin/bash

mkdir -p /data/backup/code /data/backup/ssl /data/backup/dump
cd /data/backup/code

git clone -q https://github.com/entu/entu-backup.git ./
git checkout -q master
git pull

printf "\n\n"
docker build --quiet --pull --tag=backup ./

printf "\n\n"
docker stop backup
docker rm backup
docker run -d \
    --net="entu" \
    --name="backup" \
    --env="MYSQL_HOST=" \
    --env="MYSQL_PORT=" \
    --env="MYSQL_USER=" \
    --env="MYSQL_PASSWORD=" \
    --env="MYSQL_SSL_CA=" \
    --env="S3_BUCKET=s3://" \
    --env="S3_KEY=" \
    --env="S3_SECRET=" \
    --volume="/data/backup/dump:/usr/src/entu-backup/dump" \
    backup
