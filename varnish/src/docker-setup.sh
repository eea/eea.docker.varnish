#!/bin/bash

# Backend vcl files directly added to /etc/varnish/conf.d/
if test "$(ls -A /etc/varnish/conf.d/)"; then
    exit 0
fi

if [ ! -z "$BACKENDS" ]; then
  # Backend provided via $BACKENDS env
  python /add_backends.py env
else
  # Find backend within /etc/hosts
  python /add_backends.py hosts
  touch /etc/varnish/hosts.backends
fi
