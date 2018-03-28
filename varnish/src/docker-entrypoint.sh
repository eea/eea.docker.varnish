#!/bin/bash



# Priviledge separation user id
_USER="${PRIVILEDGED_USER:+-u ${PRIVILEDGED_USER}}"

# Size of the cache storage
CACHE_SIZE="${CACHE_SIZE:-2G}"
CACHE_STORAGE="${CACHE_STORAGE:-malloc,${CACHE_SIZE}}"

# Cache storage
_STORAGE="${CACHE_STORAGE:+-s ${CACHE_STORAGE}}"

# Address:Port
ADDRESS_PORT="${ADDRESS_PORT:-:6081}"
_ADDRESS="${ADDRESS_PORT:+-a ${ADDRESS_PORT}}"

# Admin:Port
 _ADMIN="${ADMIN_PORT:+-T ${ADMIN_PORT}}"

 # Custom params
PARAM_VALUE="${PARAM_VALUE:--p default_ttl=3600 -p default_grace=3600}"
_VALUE="${PARAM_VALUE}"

PARAMS="${_USER} ${_STORAGE} ${_ADDRESS} ${_ADMIN} ${_VALUE}"



if [ ! -z "$DNS_ENABLED" ]; then

  # Backends are resolved using internal or external DNS service
  touch /etc/varnish/dns.backends
  python3 /add_backends.py dns
  python3 /assemble_vcls.py
  echo "*/${DNS_TTL:-1} * * * * /track_dns  | logger " > /var/crontab.txt

else

  echo "*/${DNS_TTL:-1} * * * * /track_hosts  | logger " > /var/crontab.txt
  if [ ! -z "$BACKENDS" ]; then
     # Backend provided via $BACKENDS env
     python3 /add_backends.py env
     python3 /assemble_vcls.py
 
  else 

      if test "$(ls -A /etc/varnish/conf.d/)"; then
          # Backend vcl files directly added to /etc/varnish/conf.d/
          python3 /assemble_vcls.py
      else
         # Find backend within /etc/hosts
         touch /etc/varnish/hosts.backends
         python3 /add_backends.py hosts
         python3 /assemble_vcls.py
      fi
   fi
fi



#enable cron logging
service rsyslog restart

#add crontab
crontab /var/crontab.txt
chmod 600 /etc/crontab
service cron restart



#Add env variables for varnish
echo "export PATH=$PATH" >> /etc/environment
if [ ! -z "$ADDRESS_PORT" ]; then echo "export ADDRESS_PORT=$ADDRESS_PORT" >> /etc/environment; fi
if [ ! -z "$ADMIN_PORT" ]; then echo "export ADMIN_PORT=$ADMIN_PORT" >> /etc/environment; fi
if [ ! -z "$BACKENDS" ]; then echo "export BACKENDS=\"$BACKENDS\"" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PORT" ]; then echo "export BACKENDS_PORT=$BACKENDS_PORT" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PROBE_ENABLED" ]; then echo "export BACKENDS_PROBE_ENABLED=$BACKENDS_PROBE_ENABLED" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PROBE_INTERVAL" ]; then echo "export BACKENDS_PROBE_INTERVAL=$BACKENDS_PROBE_INTERVAL" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PROBE_REQUEST" ]; then echo "export BACKENDS_PROBE_REQUEST=$BACKENDS_PROBE_REQUEST" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PROBE_REQUEST_DELIMITER" ]; then echo "export BACKENDS_PROBE_REQUEST_DELIMITER=$BACKENDS_PROBE_REQUEST_DELIMITER" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PROBE_THRESHOLD" ]; then echo "export BACKENDS_PROBE_THRESHOLD=$BACKENDS_PROBE_THRESHOLD" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PROBE_TIMEOUT" ]; then echo "export BACKENDS_PROBE_TIMEOUT=$BACKENDS_PROBE_TIMEOUT" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PROBE_URL" ]; then echo "export BACKENDS_PROBE_URL=$BACKENDS_PROBE_URL" >> /etc/environment; fi
if [ ! -z "$BACKENDS_PROBE_WINDOW" ]; then echo "export BACKENDS_PROBE_WINDOW=$BACKENDS_PROBE_WINDOW" >> /etc/environment; fi
if [ ! -z "$BACKENDS_SAINT_MODE" ]; then echo "export BACKENDS_SAINT_MODE=$BACKENDS_SAINT_MODE" >> /etc/environment; fi
if [ ! -z "$CACHE_SIZE" ]; then echo "export CACHE_SIZE=$CACHE_SIZE" >> /etc/environment; fi
if [ ! -z "$CACHE_STORAGE" ]; then echo "export CACHE_STORAGE=$CACHE_STORAGE" >> /etc/environment; fi
if [ ! -z "$DNS_ENABLED" ]; then echo "export DNS_ENABLED=$DNS_ENABLED" >> /etc/environment; fi
if [ ! -z "$DNS_TTL" ]; then echo "export DNS_TTL=$DNS_TTL" >> /etc/environment; fi
if [ ! -z "$PARAM_VALUE" ]; then echo "export PARAM_VALUE=$PARAM_VALUE" >> /etc/environment; fi
if [ ! -z "$PRIVILEDGED_USER" ]; then echo "export PRIVILEDGED_USER=$PRIVILEDGED_USER" >> /etc/environment; fi


mkdir -p /usr/local/etc/varnish
echo "${DASHBOARD_USER:-admin}:${DASHBOARD_PASSWORD:-admin}" > /usr/local/etc/varnish/agent_secret
chown -R varnish:varnish /usr/local/etc/varnish
chown -R varnish:varnish /usr/local/var/varnish


varnish-agent -H /var/www/html/varnish-dashboard


if [[ $1 == "varnish" ]]; then
   exec varnishd  -j unix,user=varnish  -F -f /etc/varnish/default.vcl ${PARAMS}
else
   exec "$@"
fi
