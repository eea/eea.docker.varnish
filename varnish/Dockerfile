FROM debian:jessie
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

COPY src/* /tmp/
RUN /tmp/docker-install.sh \
 && rm -rvf /tmp/*

EXPOSE 6081 6085


HEALTHCHECK --interval=1m --timeout=3s \
  CMD ["/docker-healthcheck.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["varnish"]
