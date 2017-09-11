FROM debian:jessie

RUN apt-get update && apt-get install -y build-essential python-dev python-pip python-setuptools memcached \
  libffi-dev libjpeg-dev libssl-dev patch git-core python-mysqldb apache2 memcached netcat mysql-client \
  apache2-utils libexpat1 ssl-cert python libapache2-mod-wsgi

RUN pip install -U pip
RUN pip install python-memcached==1.58 ReviewBoard==2.5.15
RUN pip install rb_oauth==0.3

COPY conf.txt /conf.txt
COPY entrypoint.sh /entrypoint.sh

CMD ./entrypoint.sh

