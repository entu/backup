#!/bin/bash

# Environment variables for MongoDB and S3
MONGODB_HOST=${MONGODB_HOST}
MONGODB_PORT=${MONGODB_PORT}
MONGODB_USERNAME=${MONGODB_USERNAME}
MONGODB_PASSWORD=${MONGODB_PASSWORD}

S3_REGION=${S3_REGION}
S3_ENDPOINT=${S3_ENDPOINT}
S3_BUCKET=${S3_BUCKET}
S3_KEY=${S3_KEY}
S3_SECRET=${S3_SECRET}

# List of system databases to exclude
EXCLUDE_DBS=("admin" "local" "config")

# Get the current date and time for the dump directory
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
DUMP_DIR="/dump/mongodump-$TIMESTAMP"

# Create the dump directory
mkdir -p "$DUMP_DIR"

# Fetch the list of databases
DBS=$(mongosh --host "$MONGODB_HOST" --port "$MONGODB_PORT" --username "$MONGODB_USERNAME" --password "$MONGODB_PASSWORD" --quiet --eval "db.adminCommand('listDatabases').databases.map(db => db.name).join('\n')" | sed "s/'//g")

# Perform the MongoDB dump for each database, excluding system databases
for DB in $DBS; do
    if [[ ! " ${EXCLUDE_DBS[@]} " =~ " ${DB} " ]]; then
        echo "Dumping database: $DB"
        mongodump --host "$MONGODB_HOST" --port "$MONGODB_PORT" --username "$MONGODB_USERNAME" --password "$MONGODB_PASSWORD" --db "$DB" --out "$DUMP_DIR"
    fi
done

# Configure s3cmd with the provided credentials
echo "[default]
access_key = $S3_KEY
secret_key = $S3_SECRET
host_base = $S3_ENDPOINT
host_bucket = %(bucket)s.$S3_ENDPOINT
region = $S3_REGION
" > /root/.s3cfg

# Upload the dump to S3
s3cmd sync "$DUMP_DIR" s3://$S3_BUCKET/mongodump-$TIMESTAMP

# Clean up dump files
rm -rf "$DUMP_DIR"
