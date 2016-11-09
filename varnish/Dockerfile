FROM debian:jessie
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

COPY src/* /tmp/
RUN /tmp/docker-install.sh \
 && rm -rvf /tmp/*

EXPOSE 6081
ENTRYPOINT ["/usr/local/bin/chaperone"]
CMD ["--user", "varnish"]
