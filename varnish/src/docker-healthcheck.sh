#!/bin/bash
set -eo pipefail


USER=${DASHBOARD_USER:-"admin"}
PASS=${DASHBOARD_PASSWORD:-"admin"}


health=$(curl -s -u$USER:$PASS "http://localhost:6085/status")

health=${health:-"Dashboard down"}

echo $health

if [[ $health == "Child in state running" ]]; then 
  exit 0
fi

exit 1
