#!/bin/bash
set -eo pipefail


USER=${DASHBOARD_USER:-"admin"}
PASS=${DASHBOARD_PASSWORD:-"admin"}
PORT=${DASHBOARD_PORT:-"6085"}


health=$(curl -s -u$USER:$PASS "http://localhost:$PORT/status")

health=${health:-"Dashboard down"}

echo $health

if [[ $health == "Child in state running" ]]; then
  exit 0
fi

exit 1
