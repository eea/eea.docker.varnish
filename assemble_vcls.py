import os
import subprocess


def add_includes(g):
    print >> g
    includes = os.listdir("/etc/varnish/conf.d")
    includes.sort()
    for include in includes:
        if ".vcl" not in include:
            continue
        print >> g, 'include "/etc/varnish/conf.d/' + include + '";'


g = open("/etc/varnish/temp_default.vcl", "w")
with open("/etc/varnish/default.vcl", "r") as f, open("/etc/varnish/temp_default.vcl", "w") as g:
    for line in f:
        if line[0] is not "#" and "include" in line:
            continue
        print >> g, line,

    add_includes(g)

subprocess.call(["mv", "/etc/varnish/temp_default.vcl", "/etc/varnish/default.vcl"])
