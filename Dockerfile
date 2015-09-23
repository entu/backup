FROM python:2.7-slim

ADD ./ /usr/src/entu-backup
ADD https://github.com/s3tools/s3cmd/releases/download/v1.6.0/s3cmd-1.6.0.tar.gz /usr/src/entu-backup/

RUN apt-get update && apt-get install -y mysql-client
RUN pip install python-dateutil python-magic
RUN cd /usr/src/entu-backup && tar -zxf s3cmd-1.6.0.tar.gz && mv s3cmd-1.6.0 s3cmd && rm s3cmd-1.6.0.tar.gz && mv s3cfg ~/.s3cfg

CMD ["/usr/src/entu-backup/backup.sh"]
