import socket
import sys
import os

BACKENDS_PORT = os.environ.get('BACKENDS_PORT', "80").strip()
BACKENDS_PROBE_URL = os.environ.get('BACKENDS_PROBE_URL', "/").strip()
BACKENDS_PROBE_TIMEOUT = os.environ.get('BACKENDS_PROBE_TIMEOUT', "1s").strip()
BACKENDS_PROBE_INTERVAL = os.environ.get('BACKENDS_PROBE_INTERVAL', "1s").strip()
BACKENDS_PROBE_WINDOW = os.environ.get('BACKENDS_PROBE_WINDOW', "3").strip()
BACKENDS_PROBE_THRESHOLD = os.environ.get('BACKENDS_PROBE_THRESHOLD', "2").strip()

init_conf = """
import std;
import directors;
sub vcl_init {
  new backends_director = directors.round_robin();
"""

init_conf_backend = """
  backends_director.add_backend(server%d);
"""

backend_conf = ""
backend_conf_add = """
backend server%(index)d {
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

recv_conf = """
sub vcl_recv {
  set req.backend_hint = backends_director.backend();
}
"""

backends = open("/etc/varnish/conf.d/backends.vcl", "w")

index = 1
if sys.argv[1] == "hosts":
    try:
        hosts = open("/etc/hosts")
    except:
        exit

    localhost = socket.gethostbyname(socket.gethostname())
    existing_hosts = set()

    for host in hosts:
        if "#" in host:
            continue
        if "0.0.0.0" in host:
            continue
        if "127.0.0.1" in host:
            continue
        if localhost in host:
            continue
        if "::" in host:
            continue

        host_ip = host.split()[0]
        if host_ip in existing_hosts:
            continue

        existing_hosts.add(host_ip)
        backend_conf += backend_conf_add % dict(
            index=index,
            host=host_ip,
            port=BACKENDS_PORT,
            probe_url=BACKENDS_PROBE_URL,
            probe_timeout=BACKENDS_PROBE_TIMEOUT,
            probe_interval=BACKENDS_PROBE_INTERVAL,
            probe_window=BACKENDS_PROBE_WINDOW,
            probe_threshold=BACKENDS_PROBE_THRESHOLD
        )

        init_conf += init_conf_backend % index
        index += 1

    init_conf += "}"

    if existing_hosts:
        print >> backends, backend_conf
        print >> backends, init_conf
        print >> backends, recv_conf

else:
    hosts = os.environ['BACKENDS'].strip('"').split()
    for host in hosts:
        host_split = host.split(":")
        host_name_or_ip = host_split[0]
        host_port = host_split[1] if len(host_split) > 1 else BACKENDS_PORT
        backend_conf += backend_conf_add % dict(
                index=index,
                host=host_name_or_ip,
                port=host_port,
                probe_url=BACKENDS_PROBE_URL,
                probe_timeout=BACKENDS_PROBE_TIMEOUT,
                probe_interval=BACKENDS_PROBE_INTERVAL,
                probe_window=BACKENDS_PROBE_WINDOW,
                probe_threshold=BACKENDS_PROBE_THRESHOLD
        )

        init_conf += init_conf_backend % index
        index += 1

    init_conf += "}"
    print >> backends, backend_conf
    print >> backends, init_conf
    print >> backends, recv_conf
