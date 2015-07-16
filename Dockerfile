FROM centos:centos7

MAINTAINER "Razvan Chitu" <razvan.chitu@eaudeweb.ro>

RUN yum updateinfo -y && \
    yum install -y epel-release && \
    yum install -y varnish && \
    yum install -y libmhash-devel && \
    yum clean all

COPY assemble_vcls.py   /assemble_vcls.py
COPY start.sh           /usr/bin/start
COPY reload.sh          /usr/bin/reload
COPY default.vcl        /etc/varnish/default.vcl

CMD ["start"]
