FROM python:2.7-slim

ADD ./ /usr/src/entu-backup

RUN apt-get update && apt-get install -y mysql-client
RUN pip install awscli

CMD ["/usr/src/entu-backup/backup.sh"]
