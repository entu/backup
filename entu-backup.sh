#!/bin/bash

mkdir -p /data/entu-backup/code
cd /data/entu-backup/code

git clone -q https://github.com/argoroots/entu-backup.git ./
git checkout -q master
git pull
printf "\n\n"

version=`date +"%y%m%d.%H%M%S"`
docker build -q -t entu-backup:$version ./ && docker tag -f entu-backup:$version entu-backup:latest
printf "\n\n"

docker stop entu-backup
docker rm entu-backup
docker run \
    --name="entu-backup" \
    --env="MYSQL_HOST=" \
    --env="MYSQL_USER=" \
    --env="MYSQL_PASSWORD=" \
    --env="S3_BUCKET=" \
    --env="S3_KEY=" \
    --env="S3_SECRET=" \
    --link="entu-mysql:entumysql" \
    entu-backup
