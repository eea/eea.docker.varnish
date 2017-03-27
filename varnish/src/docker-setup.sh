#!/bin/bash

if [ ! -z "$DNS_ENABLED" ]; then
  # Backends are resolved using internal or external DNS service
  touch /etc/varnish/dns.backends
  python3 /add_backends.py dns
  python3 /assemble_vcls.py
  exit $?
fi

if [ ! -z "$BACKENDS" ]; then
  # Backend provided via $BACKENDS env
  python3 /add_backends.py env
  python3 /assemble_vcls.py
  exit $?
fi

if test "$(ls -A /etc/varnish/conf.d/)"; then
    # Backend vcl files directly added to /etc/varnish/conf.d/
    python3 /assemble_vcls.py
else
    # Find backend within /etc/hosts
    touch /etc/varnish/hosts.backends
    python3 /add_backends.py hosts
    python3 /assemble_vcls.py
fi
