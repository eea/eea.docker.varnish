#!/bin/bash

set -e

# Priviledge separation user id
if [ ! -z "$PRIVILEDGED_USER" ]; then
    PARAMS="$PARAMS -u $PRIVILEDGED_USER"
fi

# Size of the cache storage
if [ ! -z "$CACHE_SIZE" ]; then
    PARAMS="$PARAMS -s malloc,$CACHE_SIZE"
else
    PARAMS="$PARAMS -s malloc,128M"
fi

# HTTP listen address and port
if [ ! -z "$ADDRESS_PORT" ]; then
    PARAMS="$PARAMS -a $ADDRESS_PORT"
fi

# 'param-value' parameters
if [ ! -z "$PARAM_VALUE" ]; then
    PARAMS="$PARAMS $PARAM_VALUE"
else
    PARAMS="$PARAMS -p default_ttl=3600 -p default_grace=3600"
fi

if [ ! -z "$BACKENDS" ]; then
    python add_backends.py env
else
    if ! test "$(ls -A /etc/varnish/conf.d/)"; then
        python add_backends.py hosts
        track_hosts &
    fi
fi

python /assemble_vcls.py

exec varnishd -F -f /etc/varnish/default.vcl $PARAMS
