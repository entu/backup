#!/bin/bash

# Environment variables for MongoDB and S3
MONGODB_URL="mongodb+srv://$MONGODB_USERNAME:$MONGODB_PASSWORD@$MONGODB_HOST/?tls=true&authSource=admin"

S3_REGION=${S3_REGION}
S3_ENDPOINT=${S3_ENDPOINT}
S3_BUCKET=${S3_BUCKET}
S3_KEY=${S3_KEY}
S3_SECRET=${S3_SECRET}

# List of system databases to exclude
EXCLUDE_DBS=("admin" "local" "config")

# Get the current date and time for the dump directory
TIMESTAMP=$(date +"%Y-%m-%d")
DUMP_DIR="/dump/$TIMESTAMP"

# Create the dump directory
mkdir -p "$DUMP_DIR"

# Fetch the list of databases
DBS=$(mongosh --quiet --eval "db.adminCommand('listDatabases').databases.map(db => db.name).join('\n')" "$MONGODB_URL" | sed "s/'//g")

# Perform the MongoDB dump for each database, excluding system databases
for DB in $DBS; do
    if [[ ! " ${EXCLUDE_DBS[@]} " =~ " ${DB} " ]]; then
        echo "Dumping database: $DB"
        mongodump --quiet --uri "$MONGODB_URL" --db "$DB" --out "$DUMP_DIR" --gzip
    fi
done

# Configure s3cmd with the provided credentials
echo "[default]
access_key = $S3_KEY
secret_key = $S3_SECRET
host_base = $S3_ENDPOINT
host_bucket = %(bucket)s.$S3_ENDPOINT
region = $S3_REGION
" > /data/db/.s3cfg

# Upload the dump to S3
s3cmd sync "$DUMP_DIR" s3://$S3_BUCKET/

# Clean up dump files
rm -rf "$DUMP_DIR"
