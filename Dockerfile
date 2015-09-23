FROM mysql:5.6

ADD ./ /usr/src/entu-backup
ADD https://github.com/s3tools/s3cmd/releases/download/v1.6.0/s3cmd-1.6.0.tar.gz /usr/src/entu-backup/

RUN cd /usr/src/entu-backup && tar -zxf s3cmd-1.6.0.tar.gz && mv s3cmd-1.6.0 s3cmd && rm s3cmd-1.6.0.tar.gz && mv s3cfg ~/.s3cfg
RUN apt-get update && apt-get install -y python python-dateutil python-pip && pip install python-magic

CMD ["/usr/src/entu-backup/backup.sh"]
