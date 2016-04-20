FROM newsdev/varnish
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libvarnishapi-dev \
    inotify-tools \
    python3-dev \
    python3-pip \
 && pip3 install chaperone dnspython3 \
 && mkdir -p /etc/varnish/conf.d/ /usr/local/var/varnish \
 && chown -R varnishd /etc/varnish /usr/local/var/varnish \
 && curl -o /tmp/varnish.tgz -SL https://download.varnish-software.com/varnish-modules/varnish-modules-0.9.0.tar.gz \
 && tar -zxvf /tmp/varnish.tgz -C /tmp/ \
 && cd /tmp/varnish-modules-0.9.0 \
 && ./configure \
 && make \
 && make install \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/varnish.tgz

COPY src/chaperone.conf     /etc/chaperone.d/chaperone.conf
COPY src/assemble_vcls.py   /assemble_vcls.py
COPY src/add_backends.py    /add_backends.py
COPY src/docker-setup.sh    /docker-setup.sh
COPY src/track_hosts.sh     /track_hosts
COPY src/track_dns.sh       /track_dns
COPY src/reload.sh          /usr/bin/reload

USER varnishd

ENTRYPOINT ["/usr/local/bin/chaperone"]
CMD ["--user", "varnishd"]
