#!/bin/sh


VARNISH_TTL=${VARNISH_TTL:-60s}
VARNISH_GRACE=${VARNISH_GRACE:-120s}
VARNISH_KEEP=${VARNISH_KEEP:-120s}

if [ -f /etc/varnish/conf.d/varnish.vcl ]; then

  sed -i "s/set beresp.ttl = [1-9][0-9]*s/set beresp.ttl = $VARNISH_TTL/g"   /etc/varnish/conf.d/varnish.vcl

  sed -i "s/set beresp.grace = .*/set beresp.grace = $VARNISH_GRACE;/g" /etc/varnish/conf.d/varnish.vcl

  sed -i "s/set beresp.keep = .*/set beresp.keep = $VARNISH_GRACE;/g"  /etc/varnish/conf.d/varnish.vcl

fi


