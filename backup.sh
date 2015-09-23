#!/bin/sh

echo ""
echo ""
echo "`date +"%Y-%m-%d %H:%M:%S"` BACKUP STARTED"

data_dir=/usr/src/entu-backup

cd ${data_dir}

MYSQL_PWD=$MYSQL_PASSWORD mysql -h$MYSQL_HOST -u$MYSQL_USER -Bse "SELECT DISTINCT TABLE_SCHEMA FROM information_schema.TABLES WHERE TABLE_SCHEMA <> 'information_schema' ORDER BY TABLE_SCHEMA;" > databases.txt

while read database
do

    MYSQL_PWD=$MYSQL_PASSWORD mysql -h$MYSQL_HOST -u$MYSQL_USER -Bse "SELECT DISTINCT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '${database}' AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;" > ${database}.txt
    MYSQL_PWD=$MYSQL_PASSWORD mysqldump ${database} -h$MYSQL_HOST -u$MYSQL_USER --single-transaction `cat ${database}.txt` | gzip -9 > ${database}.sql.gz

    s3file=${database}/${database}_`date +"%Y-%m-%d_%H-%M-%S"`.sql.gz

    s3cmd put --quiet --config=${data_dir}/s3cfg --access_key=$S3_KEY --secret_key=$S3_SECRET --acl-private --no-progress --server-side-encryption --multipart-chunk-size-mb=640 ${database}.sql.gz $S3_BUCKET/daily/${s3file} 2>&1

    if [ `date +"%u"` -eq 1 ]
    then
        s3cmd sync --quiet --config=${data_dir}/s3cfg --access_key=$S3_KEY --secret_key=$S3_SECRET --acl-private --no-progress --server-side-encryption --multipart-chunk-size-mb=640 $S3_BUCKET/daily/${s3file} $S3_BUCKET/weekly/${database}/ 2>&1
    fi

    if [ `date +"%d"` -eq 1 ]
    then
        s3cmd sync --quiet --config=${data_dir}/s3cfg --access_key=$S3_KEY --secret_key=$S3_SECRET --acl-private --no-progress --server-side-encryption --multipart-chunk-size-mb=640 $S3_BUCKET/daily/${s3file} $S3_BUCKET/monthly/${database}/ 2>&1
    fi

    rm ${database}.txt
    rm ${database}.sql.gz

done < databases.txt

rm databases.txt

echo "`date +"%Y-%m-%d %H:%M:%S"` BACKUP DONE"
echo ""

exit 0
