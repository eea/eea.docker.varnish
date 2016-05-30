import socket
import sys
import os
import dns.resolver

################################################################################
# INIT
################################################################################
BACKENDS = os.environ.get('BACKENDS', '').split(' ')
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
"""

init_conf_director = """
  new cluster_%(director)s = directors.round_robin();
"""

init_conf_backend = """
  cluster_%(director)s.add_backend(server_%(name)s_%(index)s);
"""

backend_conf = ""
backend_conf_add = """
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

recv_conf = """
acl purge {
    "localhost";
    "172.17.0.0/16";
    "10.42.0.0/16";
}

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
# Backends are resolved using internal or external DNS service
################################################################################

if sys.argv[1] == "dns":
    ips = {}
    name = "backends"
    for index, backend_server in enumerate(BACKENDS):
        server_port = backend_server.split(':')
        host = server_port[0]
        port = server_port[1] if len(server_port) > 1 else BACKENDS_PORT
        try:
            records = dns.resolver.query(host)
        except Exception as err:
            print(err)
            continue
        else:
            init_conf += init_conf_director % dict(director=toName(host))
            for ip in records:
                ips[str(ip)] = host

    with open('/etc/varnish/dns.backends', 'w') as bfile:
        bfile.write(
            ' '.join(sorted(ips))
        )

    for ip, host in ips.items():
        name = toName(host)
        index = ip.replace('.', '_')
        backend_conf += backend_conf_add % dict(
                name=name,
                index=index,
                host=ip,
                port=port,
                probe_url=BACKENDS_PROBE_URL,
                probe_timeout=BACKENDS_PROBE_TIMEOUT,
                probe_interval=BACKENDS_PROBE_INTERVAL,
                probe_window=BACKENDS_PROBE_WINDOW,
                probe_threshold=BACKENDS_PROBE_THRESHOLD
            )

        init_conf += init_conf_backend % dict(
            director=name,
            name=name,
            index=index
        )
        FOUND_BACKENDS = True

    init_conf += "}"
    recv_conf = recv_conf % dict(director=name)


################################################################################
# Backends provided via BACKENDS environment variable
################################################################################

elif sys.argv[1] == "env":
    name = "backends"
    directors = set()
    for index, host in enumerate(BACKENDS):
        host_split = host.split(":")
        host_name_or_ip = host_split[0]
        host_port = host_split[1] if len(host_split) > 1 else BACKENDS_PORT
        name = toName(host_name_or_ip)
        backend_conf += backend_conf_add % dict(
                name=name,
                index=index,
                host=host_name_or_ip,
                port=host_port,
                probe_url=BACKENDS_PROBE_URL,
                probe_timeout=BACKENDS_PROBE_TIMEOUT,
                probe_interval=BACKENDS_PROBE_INTERVAL,
                probe_window=BACKENDS_PROBE_WINDOW,
                probe_threshold=BACKENDS_PROBE_THRESHOLD
        )

        if name not in directors:
            directors.add(name)
            init_conf += init_conf_director % dict(director=name)

        init_conf += init_conf_backend % dict(
            director=name,
            name=name,
            index=index
        )
        FOUND_BACKENDS = True

    init_conf += "}"
    recv_conf = recv_conf % dict(director=name)

################################################################################
# Look for backend within /etc/hosts
################################################################################


elif sys.argv[1] == "hosts":
    director = "backends"
    try:
        hosts = open("/etc/hosts")
    except:
        exit

    localhost = socket.gethostbyname(socket.gethostname())
    existing_hosts = set()

    init_conf += init_conf_director % dict(director=director)
    index = 1
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
        name = 'server'
        backend_conf += backend_conf_add % dict(
            name=name,
            index=index,
            host=host_ip,
            port=BACKENDS_PORT,
            probe_url=BACKENDS_PROBE_URL,
            probe_timeout=BACKENDS_PROBE_TIMEOUT,
            probe_interval=BACKENDS_PROBE_INTERVAL,
            probe_window=BACKENDS_PROBE_WINDOW,
            probe_threshold=BACKENDS_PROBE_THRESHOLD
        )

        init_conf += init_conf_backend % dict(
            director=director,
            name=name,
            index=index
        )

        index += 1

    init_conf += "}"
    recv_conf = recv_conf % dict(director=director)

    if existing_hosts:
        FOUND_BACKENDS = True


if FOUND_BACKENDS:
    with open("/etc/varnish/conf.d/backends.vcl", "w") as configuration:
        configuration.write(backend_conf)
        configuration.write(init_conf)

        # Allow adding custom vcl_recv to /etc/varnish/conf.d/varnish.vcl
        if not os.path.exists("/etc/varnish/conf.d/varnish.vcl"):
            configuration.write(recv_conf)
