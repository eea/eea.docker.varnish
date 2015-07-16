FROM centos:centos6

MAINTAINER "Razvan Chitu" <razvan.chitu@eaudeweb.ro>

RUN yum -y update && \
	rpm --nosignature -i https://repo.varnish-cache.org/redhat/varnish-3.0.el6.rpm && \
	yum install -y varnish && \
	yum clean all

COPY assemble_vcls.py   /assemble_vcls.py
COPY start.sh           /usr/bin/start
COPY default.vcl        /etc/varnish/default.vcl

CMD ["/start.sh"]
