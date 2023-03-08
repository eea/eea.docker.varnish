import socket
import sys
import os
import subprocess

################################################################################
# INIT
################################################################################
BACKENDS = os.environ.get('BACKENDS', '').split(' ')
BACKENDS_PORT = os.environ.get('BACKENDS_PORT', "80").strip()
BACKENDS_PROBE_ENABLED = os.environ.get('BACKENDS_PROBE_ENABLED', "True").strip().lower() in ("true", "yes", "1")
BACKENDS_PROBE_URL = os.environ.get('BACKENDS_PROBE_URL', "/").strip()
BACKENDS_PROBE_TIMEOUT = os.environ.get('BACKENDS_PROBE_TIMEOUT', "1s").strip()
BACKENDS_PROBE_INTERVAL = os.environ.get('BACKENDS_PROBE_INTERVAL', "1s").strip()
BACKENDS_PROBE_WINDOW = os.environ.get('BACKENDS_PROBE_WINDOW', "3").strip()
BACKENDS_PROBE_THRESHOLD = os.environ.get('BACKENDS_PROBE_THRESHOLD', "2").strip()
BACKENDS_SAINT_MODE = os.environ.get("BACKENDS_SAINT_MODE", "").strip()
BACKENDS_PROBE_REQUEST = os.environ.get('BACKENDS_PROBE_REQUEST', "").strip()
BACKENDS_PROBE_REQUEST_DELIMITER = os.environ.get('BACKENDS_PROBE_DELIMITER', "|").strip()
BACKENDS_PURGE_LIST = os.environ.get('BACKENDS_PURGE_LIST',"localhost;172.17.0.0/16;10.42.0.0/16").strip()

VARNISH_SINGLE_CLUSTER = os.environ.get('VARNISH_SINGLE_CLUSTER', "True").strip().lower() in ("true", "yes", "1")
VARNISH_CLUSTER = os.environ.get('VARNISH_CLUSTER', "loadbalancer").strip()



init_conf = """
import std;
import directors;
import saintmode;
sub vcl_init {
"""

init_conf_director = """
  new cluster_%(director)s = directors.round_robin();
"""

init_conf_backend = """
  cluster_%(director)s.add_backend(server_%(name)s_%(index)s);
"""

init_conf_saint_backend = """
  new sm_%(name)s_%(index)s = saintmode.saintmode(server_%(name)s_%(index)s, 10);
  cluster_%(director)s.add_backend(sm_%(name)s_%(index)s.backend());
"""

backend_conf = ""
backend_probe = """
backend server_%(name)s_%(index)s {
    .host = "%(host)s";
    .port = "%(port)s";
    .probe = {
        .url = "%(probe_url)s";
        .timeout = %(probe_timeout)s;
        .interval = %(probe_interval)s;
        .window = %(probe_window)s;
        .threshold = %(probe_threshold)s;
    }
}
"""
backend_no_probe = """
backend server_%(name)s_%(index)s {
    .host = "%(host)s";
    .port = "%(port)s";
}
"""

backend_conf_add = backend_probe if BACKENDS_PROBE_ENABLED else backend_no_probe

backend_purge_ips = ''.join([ '    "'+item.strip('"').strip("'")+'";\r\n' for item in BACKENDS_PURGE_LIST.strip(';').split(';')])

recv_conf = """
acl purge {
""" + backend_purge_ips + """}

sub vcl_recv {
  if (req.method == "PURGE") {
    if (!client.ip ~ purge) {
        return(synth(405, "Not allowed."));
    }
    return (purge);
  }

  set req.backend_hint = cluster_%(director)s.backend();
}
"""

def toName(text):
    return text.replace('.', '_').replace('-', '_').replace(':', '_')


FOUND_BACKENDS = False



################################################################################
# Backends provided via BACKENDS environment variable
################################################################################

if sys.argv[1] == "env":
    name = "backends"
    directors = set()
    for index, host in enumerate(BACKENDS):
        host_split = host.split(":")
        host_name_or_ip = host_split[0]
        host_port = host_split[1] if len(host_split) > 1 else BACKENDS_PORT
        name = toName(host_name_or_ip)[-40:]
        # replace probe .url with .request headers
        if BACKENDS_PROBE_REQUEST:
            hdrs = BACKENDS_PROBE_REQUEST.split(BACKENDS_PROBE_REQUEST_DELIMITER)
            request = '.request = \r\n' + ''.join([ '\t\t"'+item+'"\r\n' for item in hdrs])
            request = request[:-2] + ";"
            backend_conf_add = backend_conf_add .replace(r'.url = "%(probe_url)s";', request)

        backend_conf += backend_conf_add % dict(
                name=name,
                index=index,
                host=host_name_or_ip,
                hostname=host_name_or_ip,
                port=host_port,
                probe_url=BACKENDS_PROBE_URL,
                probe_timeout=BACKENDS_PROBE_TIMEOUT,
                probe_interval=BACKENDS_PROBE_INTERVAL,
                probe_window=BACKENDS_PROBE_WINDOW,
                probe_threshold=BACKENDS_PROBE_THRESHOLD
        )
        if VARNISH_SINGLE_CLUSTER:
            director_name = VARNISH_CLUSTER
        else:
            director_name = name

        if director_name not in directors:
            directors.add(director_name)
            init_conf += init_conf_director % dict(director=director_name)

        if BACKENDS_SAINT_MODE:
            init_conf += init_conf_saint_backend % dict(
                director=director_name,
                name=name,
                index=index
            )
        else:
            init_conf += init_conf_backend % dict(
                director=director_name,
                name=name,
                index=index
            )
        FOUND_BACKENDS = True

    init_conf += "}"
    recv_conf = recv_conf % dict(director=director_name)


if FOUND_BACKENDS:
    with open("/etc/varnish/conf.d/backends.vcl", "w") as configuration:
        configuration.write(backend_conf)
        configuration.write(init_conf)

        # Allow adding custom vcl_recv to /etc/varnish/conf.d/varnish.vcl
        if not os.path.exists("/etc/varnish/conf.d/varnish.vcl"):
            configuration.write(recv_conf)
