#!/bin/bash

if [ ! -z "$DNS_ENABLED" ]; then
  # Backends are resolved using internal or external DNS service
  python3 /add_backends.py dns
  touch /etc/varnish/dns.backends
  exit $?
fi

if [ ! -z "$BACKENDS" ]; then
  # Backend provided via $BACKENDS env
  python3 /add_backends.py env
  exit $?
fi

# Backend vcl files directly added to /etc/varnish/conf.d/
if test "$(ls -A /etc/varnish/conf.d/)"; then
    exit 0
fi

# Find backend within /etc/hosts
python3 /add_backends.py hosts
touch /etc/varnish/hosts.backends
