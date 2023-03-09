#!/bin/sh


VARNISH_HTTP_PORT=${VARNISH_HTTP_PORT:-6081}
VARNISH_SIZE="${VARNISH_SIZE:-$CACHE_SIZE}"


if [ -n "$AUTOKILL_CRON" ]; then
    
     echo "$AUTOKILL_CRON /stop_varnish_cache.sh  | logger " >> /var/crontab.txt	
    #add crontab
     crontab /var/crontab.txt
     chmod 600 /etc/crontab

fi

if [ -n "$VARNISH_CFG_CONTENT" ]; then
    echo -e "$VARNISH_CFG_CONTENT" > /etc/varnish/default.vcl
    unset VARNISH_CFG_CONTENT
fi


if [ $(env | grep -v ^VARNISH_HTTP_PORT | grep -v ^VARNISH_SIZE | grep ^VARNISH_ | wc -l ) -gt 0 ]; then
    /update_vcl_from_env.sh
fi

exec /usr/local/bin/docker-varnish-entrypoint "$@"


