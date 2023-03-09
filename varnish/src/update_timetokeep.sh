#!/bin/sh


# VARNISH_TTL=${VARNISH_TTL:-60s}
# VARNISH_GRACE=${VARNISH_GRACE:-120s}
# VARNISH_KEEP=${VARNISH_KEEP:-120s}

  if [ -n "$VARNISH_TTL" ]; then
    find /etc/varnish -type f -name "*.vcl" -exec sed -i "s/set beresp.ttl = [1-9][0-9]*s/set beresp.ttl = $VARNISH_TTL/g" {} +
  fi

  if [ -n "$VARNISH_GRACE" ]; then
    find /etc/varnish -type f -name "*.vcl" -exec sed -i "s/set beresp.grace = .*/set beresp.grace = $VARNISH_GRACE;/g" {} +
  fi

  if [ -n "$VARNISH_KEEP" ]; then
    find /etc/varnish -type f -name "*.vcl" -exec sed -i "s/set beresp.keep = .*/set beresp.keep = $VARNISH_KEEP;/g" {} +
  fi



