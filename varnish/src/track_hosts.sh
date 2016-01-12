#!/bin/bash

while inotifywait -e close_write /etc/hosts 1>/dev/null 2>/dev/null; do
  python add_backends.py hosts
  reload
done
