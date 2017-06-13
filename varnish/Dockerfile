FROM debian:jessie
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

COPY src/* /tmp/
RUN /tmp/docker-install.sh \
 && rm -rvf /tmp/*

EXPOSE 6081
CMD ["/usr/local/bin/chaperone", "--user", "varnish"]
