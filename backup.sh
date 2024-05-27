#!/bin/bash

# Environment variables for MongoDB and S3
MONGO_URI=${MONGO_URI:-mongodb://localhost:27017}
S3_BUCKET=${S3_BUCKET}
S3_ACCESS_KEY=${S3_ACCESS_KEY}
S3_SECRET_KEY=${S3_SECRET_KEY}
S3_ENDPOINT=${S3_ENDPOINT}

# List of system databases to exclude
EXCLUDE_DBS=("admin" "local" "config")

# Get the current date and time for the dump directory
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
DUMP_DIR="/dump/mongodump-$TIMESTAMP"

# Create the dump directory
mkdir -p "$DUMP_DIR"

# Fetch the list of databases
DBS=$(mongo --quiet --eval "db.adminCommand('listDatabases').databases.map(db => db.name)" --uri "$MONGO_URI")

# Perform the MongoDB dump for each database, excluding system databases
for DB in $(echo "$DBS" | jq -r '.[]'); do
    if [[ ! " ${EXCLUDE_DBS[@]} " =~ " ${DB} " ]]; then
        echo "Dumping database: $DB"
        mongodump --uri "$MONGO_URI" --db "$DB" --out "$DUMP_DIR"
    fi
done

# Configure s3cmd with the provided credentials
echo "[default]
access_key = $S3_ACCESS_KEY
secret_key = $S3_SECRET_KEY
host_base = $S3_ENDPOINT
host_bucket = %(bucket)s.$S3_ENDPOINT
" > /root/.s3cfg

# Upload the dump to S3
s3cmd sync "$DUMP_DIR" s3://$S3_BUCKET/mongodump-$TIMESTAMP

# Clean up dump files
rm -rf "$DUMP_DIR"
