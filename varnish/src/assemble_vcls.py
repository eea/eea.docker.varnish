import os

def add_includes(g):
    g.write("\n")
    includes = os.listdir("/etc/varnish/conf.d")
    includes.sort()
    for include in includes:
        if ".vcl" not in include:
            continue
        g.write('include "/etc/varnish/conf.d/' + include + '";\n')

with open("/etc/varnish/default.vcl", "r") as f, open("/etc/varnish/temp_default.vcl", "w") as g:
    for line in f:
        if line[0] is not "#" and "include" in line:
            continue
        g.write(line)
    add_includes(g)

os.rename("/etc/varnish/temp_default.vcl", "/etc/varnish/default.vcl")
