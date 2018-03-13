#!/bin/sh

echo ""
echo ""
echo "`date +"%Y-%m-%d %H:%M:%S"` BACKUP STARTED"

aws configure set aws_access_key_id $S3_KEY
aws configure set aws_secret_access_key $S3_SECRET

data_dir=/usr/src/entu-backup

cd ${data_dir}

MYSQL_PWD=$MYSQL_PASSWORD mysql -h$MYSQL_HOST -u$MYSQL_USER --ssl-ca=$MYSQL_SSL_CA --ssl-verify-server-cert -Bse "SELECT DISTINCT TABLE_SCHEMA FROM information_schema.TABLES WHERE TABLE_SCHEMA <> 'information_schema' ORDER BY TABLE_SCHEMA;" > databases.txt

while read database
do

    MYSQL_PWD=$MYSQL_PASSWORD mysql -h$MYSQL_HOST -u$MYSQL_USER --ssl-ca=$MYSQL_SSL_CA --ssl-verify-server-cert -Bse "SELECT DISTINCT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '${database}' AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;" > ${database}.txt
    MYSQL_PWD=$MYSQL_PASSWORD mysqldump ${database} -h$MYSQL_HOST -u$MYSQL_USER --ssl-ca=$MYSQL_SSL_CA --ssl-verify-server-cert --single-transaction `cat ${database}.txt` | gzip -9 > ${database}.sql.gz

    s3file=${database}/${database}_`date +"%Y-%m-%d_%H-%M-%S"`.sql.gz

    aws s3 cp ${database}.sql.gz $S3_BUCKET/daily/${s3file} --quiet --sse --acl private

    if [ `date +"%u"` -eq 1 ]
    then
        aws s3 cp $S3_BUCKET/daily/${s3file} $S3_BUCKET/weekly/${database}/ --quiet --sse --acl private
    fi

    if [ `date +"%d"` -eq 1 ]
    then
        aws s3 cp $S3_BUCKET/daily/${s3file} $S3_BUCKET/monthly/${database}/ --quiet --sse --acl private
    fi

    rm ${database}.txt
    rm ${database}.sql.gz

done < databases.txt

rm databases.txt

echo "`date +"%Y-%m-%d %H:%M:%S"` BACKUP DONE"
echo ""

exit 0
