#!/bin/sh


VARNISH_HTTP_PORT=${VARNISH_HTTP_PORT:-6081}
VARNISH_SIZE="${VARNISH_SIZE:-$CACHE_SIZE}"

VARNISH_SINGLE_CLUSTER="${VARNISH_SINGLE_CLUSTER:-'True'}"

mkdir -p /etc/varnish/conf.d

if [ -n "$COOKIES" ]; then
  python3 /cookie_config.py
fi

if [ -n "$BACKENDS" ]; then
     # Backend provided via $BACKENDS env
     python3 /add_backends.py env
     python3 /assemble_vcls.py

else

      if test "$(ls -A /etc/varnish/conf.d/)"; then
          # Backend vcl files directly added to /etc/varnish/conf.d/
          python3 /assemble_vcls.py
      fi
fi

if [ -n "$AUTOKILL_CRON" ]; then
    
     echo "$AUTOKILL_CRON /stop_varnish_cache.sh  | logger " >> /var/crontab.txt	
    #add crontab
     crontab /var/crontab.txt
     chmod 600 /etc/crontab

fi

if [ -n "$VARNISH_TTL" ] || [ -n "$VARNISH_GRACE" ] || [ -n "${VARNISH_KEEP}" ]; then
    /update_timetokeep.sh
fi

exec /usr/local/bin/docker-varnish-entrypoint "$@"


