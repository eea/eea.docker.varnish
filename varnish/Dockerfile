FROM centos:7
MAINTAINER "Alin Voinea" <alin.voinea@eaudeweb.ro>

RUN yum -y updateinfo \
 && yum -y install epel-release \
 && yum -y install  varnish inotify-tools python34-devel \
 && yum clean all \
 && curl https://bootstrap.pypa.io/get-pip.py | python3.4 \
 && pip3 install chaperone dnspython3 \
 && mkdir -p /etc/varnish/conf.d/ /var/lib/varnish/ \
 && chown -R varnish:varnish /etc/varnish/ /var/lib/varnish/

COPY src/chaperone.conf     /etc/chaperone.d/chaperone.conf
COPY src/assemble_vcls.py   /assemble_vcls.py
COPY src/add_backends.py    /add_backends.py
COPY src/docker-setup.sh    /docker-setup.sh
COPY src/track_hosts.sh     /track_hosts
COPY src/track_dns.sh       /track_dns
COPY src/reload.sh          /usr/bin/reload
COPY src/default.vcl        /etc/varnish/default.vcl

USER varnish

ENTRYPOINT ["/usr/bin/chaperone"]
CMD ["--user", "varnish"]
