FROM varnish:7.4.2-alpine

MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>


COPY src/*.sh  /

USER root

RUN chown -R varnish:varnish /etc/varnish \
 && apk add --no-cache bash \
 && touch /var/crontab.txt

HEALTHCHECK --interval=1m --timeout=3s \
  CMD ["/docker-healthcheck.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["-p", "default_ttl=3600", "-p", "default_grace=3600"]
