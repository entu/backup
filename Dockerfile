FROM python:3-slim

ADD ./ /usr/src/entu-backup

RUN apt-get -qq update && apt-get -qq install -y mysql-client
RUN pip3 install awscli

CMD ["/usr/src/entu-backup/backup.sh"]
