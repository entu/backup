FROM python:3-slim

ADD ./ /usr/src/entu-backup

RUN apt-get update && apt-get install -y mysql-client
RUN pip3 install awscli

CMD ["/usr/src/entu-backup/backup.sh"]
