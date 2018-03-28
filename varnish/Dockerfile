FROM debian:jessie
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

COPY src/* /tmp/
RUN /tmp/docker-install.sh \
 && rm -rvf /tmp/*

EXPOSE 6081 6085


HEALTHCHECK --interval=1m --timeout=3s \
  CMD ( curl -sI http://localhost:6085 | grep -i "HTTP/1.1 401 Unauthorized" ) || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]

