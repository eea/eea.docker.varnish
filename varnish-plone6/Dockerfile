FROM eeacms/varnish:7
LABEL maintainer="IDM2 A-Team <eea-edw-a-team-alerts@googlegroups.com>"

ENV VARNISH_SIZE="2G" 
ENV VARNISH_CLUSTER="loadbalancer"

CMD ["-p", "thread_pools=8", "-p", "thread_pool_timeout=120", "-p", "thread_pool_add_delay=0.002", "-p", "ban_lurker_sleep=0.1", "-p", "send_timeout=3600", "-p", "connect_timeout=2s", "-p", "first_byte_timeout=300s", "-p", "between_bytes_timeout=60s"]

COPY varnish.vcl /etc/varnish/conf.d/
