# Use an official MongoDB image as the base
FROM mongo:latest

# Install s3cmd, cron, and jq
RUN apt-get update && \
    apt-get install -y python3-pip cron jq && \
    pip3 install s3cmd

# Create a directory for the dump files
RUN mkdir -p /dump

# Copy the script to the container
COPY backup.sh /backup.sh

# Make the script executable
RUN chmod +x /backup.sh

# Add the crontab file
COPY crontab /etc/cron.d/mongo-backup-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/mongo-backup-cron

# Apply the cron job
RUN crontab /etc/cron.d/mongo-backup-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Set the working directory
WORKDIR /dump

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log
