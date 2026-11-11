ARG VARNISH_IMAGE=varnish:9.1.0

# vmod_dynamic (DNS-based backends, used by plone-varnish & co.) is no longer
# shipped in the official varnish 9 image, so build it against the same version.
FROM ${VARNISH_IMAGE} AS vmod-dynamic

# 9.1 branch of https://github.com/nigoroll/libvmod-dynamic
ARG VMOD_DYNAMIC_COMMIT=4eba23942b618826109db7e5cb880d950f8d6e39

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      "varnish-dev=$(dpkg-query -W -f='${Version}' varnish)" \
      autoconf automake ca-certificates curl gcc libtool make pkg-config python3-docutils \
 && SKIP_CHECK=1 install-vmod "https://github.com/nigoroll/libvmod-dynamic/archive/${VMOD_DYNAMIC_COMMIT}.tar.gz"


FROM ${VARNISH_IMAGE}

LABEL maintainer="EEA: IDM2 A-Team <eea-edw-a-team-alerts@googlegroups.com>"

COPY --from=vmod-dynamic /usr/lib/varnish/vmods/libvmod_dynamic.so /usr/lib/varnish/vmods/

COPY src/*.sh  /

USER root

# cron is needed by AUTOKILL_CRON (the debian based varnish 9 image does not ship it)
RUN apt-get update \
 && apt-get install -y --no-install-recommends cron \
 && rm -rf /var/lib/apt/lists/* \
 && chown -R varnish:varnish /etc/varnish \
 && touch /var/crontab.txt

HEALTHCHECK --interval=1m --timeout=3s \
  CMD ["/docker-healthcheck.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["-p", "default_ttl=3600", "-p", "default_grace=3600"]
