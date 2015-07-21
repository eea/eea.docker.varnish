import socket


try:
    hosts = open("/etc/hosts")
except:
    hosts = None

if hosts:
    index = 1
    localhost = socket.gethostbyname(socket.gethostname())
    existing_hosts = []
    backend_conf = ""
    init_conf = """import std;\nimport directors;\nsub vcl_init {
        new backends_director = directors.round_robin();\n"""

    for host in hosts:
        if "#" in host or "0.0.0.0" in host or "127.0.0.1" in host or localhost in host or "::" in host:
            continue
        host_ip = host.split()[0]
        host_name = host.split()[1]
        if host_ip in existing_hosts:
            continue
        existing_hosts.append(host_ip)
        backend_conf += """backend server%d {
            .host = \"%s\";
            .port = \"80\";
        }\n""" % (index, host_ip)
        init_conf += """backends_director.add_backend(server%d);\n""" % index
        index += 1

    init_conf += """}\n""";

    if existing_hosts:
        backends = open("/etc/varnish/conf.d/backends.vcl", "w")
        print >> backends, backend_conf
        print >> backends, init_conf
