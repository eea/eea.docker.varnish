#!/bin/sh
# Healthy when the varnishd management process reports a running child.
# Uses the local admin socket (secret is read from the varnish work dir),
# so it does not depend on the backend being up.

status=$(varnishadm status 2>&1)

echo "$status"

case "$status" in
  *"Child in state running"*) exit 0 ;;
esac

exit 1
