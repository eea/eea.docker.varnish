FROM debian:jessie
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

COPY src/docker-install.sh /tmp/docker-install.sh
RUN /tmp/docker-install.sh \
 && rm -rvf /tmp/*

COPY src/add_backends.py         /add_backends.py
COPY src/assemble_vcls.py        /assemble_vcls.py
COPY src/docker-entrypoint.sh    /docker-entrypoint.sh
COPY src/track_hosts.sh          /track_hosts
COPY src/track_dns.sh            /track_dns
COPY src/reload.sh               /usr/bin/reload
COPY src/default.vcl             /etc/varnish/default.vcl
COPY src/docker-healthcheck.sh   /docker-healthcheck.sh
COPY src/cookie_config.py        /cookie_config.py


EXPOSE 6081 6085


HEALTHCHECK --interval=1m --timeout=3s \
  CMD ["/docker-healthcheck.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["varnish"]
