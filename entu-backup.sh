#!/bin/bash

mkdir -p /data/entu_backup/code /data/entu_backup/dump
cd /data/entu_backup/code

git clone -q https://github.com/argoroots/entu-backup.git ./
git checkout -q master
git pull

printf "\n\n"
version=`date +"%y%m%d.%H%M%S"`
docker build --quiet --pull --tag=entu_backup:$version ./ && docker tag entu_backup:$version entu_backup:latest

printf "\n\n"
docker stop entu_backup
docker rm entu_backup
docker run -d \
    --name="entu_backup" \
    --cpu-shares=512 \
    --env="VERSION=$version" \
    --env="MYSQL_HOST=" \
    --env="MYSQL_USER=" \
    --env="MYSQL_PASSWORD=" \
    --env="S3_BUCKET=" \
    --env="S3_KEY=" \
    --env="S3_SECRET=" \
    --volume="/data/entu_backup/dump:/usr/src/entu-backup/dump" \
    entu_backup
