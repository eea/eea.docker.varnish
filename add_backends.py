import socket
import sys
import os


init_conf = """import std;\nimport directors;\nsub vcl_init {
    new backends_director = directors.round_robin();\n"""
backend_conf = ""
recv_conf = """sub vcl_recv {
    set req.backend_hint = backends_director.backend();
    }"""

backends = open("/etc/varnish/conf.d/backends.vcl", "w")
index = 1
if sys.argv[1] == "hosts":
    try:
        hosts = open("/etc/hosts")
    except:
        exit

    localhost = socket.gethostbyname(socket.gethostname())
    existing_hosts = []

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
            .probe = {
                .url = "/";
                .timeout = 1s;
                .interval = 1s;
                .window = 3;
                .threshold = 2;
            }
        }\n""" % (index, host_ip)
        init_conf += """backends_director.add_backend(server%d);\n""" % index
        index += 1

    init_conf += """}\n"""
    if existing_hosts:
        print >> backends, backend_conf
        print >> backends, init_conf
        print >> backends, recv_conf

else:
    hosts = os.environ['BACKENDS'].strip('"').split()
    for host in hosts:
        host_name_or_ip = host.split(':')[0]
        host_port = host.split(':')[1]
        backend_conf += """backend server%d {
            .host = \"%s\";
            .port = \"%s\";
            .probe = {
                .url = "/";
                .timeout = 1s;
                .interval = 1s;
                .window = 3;
                .threshold = 2;
            }
        }\n""" % (index, host_name_or_ip, host_port)
        init_conf += """backends_director.add_backend(server%d);\n""" % index
        index += 1

    init_conf += """}\n"""
    print >> backends, backend_conf
    print >> backends, init_conf
    print >> backends, recv_conf
