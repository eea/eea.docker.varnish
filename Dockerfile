FROM centos:centos7

MAINTAINER "Razvan Chitu" <razvan.chitu@eaudeweb.ro>

RUN yum updateinfo -y && \
    yum install -y epel-release && \
    yum install -y varnish && \
    yum install -y libmhash-devel && \
    yum install -y inotify-tools && \
    yum clean all && \
    mkdir -p /etc/varnish/conf.d/

COPY assemble_vcls.py   /assemble_vcls.py
COPY add_backends.py    /add_backends.py
COPY start.sh           /usr/bin/start
COPY track_hosts.sh     /usr/bin/track_hosts
COPY reload.sh          /usr/bin/reload
COPY default.vcl        /etc/varnish/default.vcl

CMD ["start"]
