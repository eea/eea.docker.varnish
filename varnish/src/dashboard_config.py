import os
import subprocess

CONFIG_JS = """
var config = {
  servers: [%(SERVERS)s],
  groups: [],
  update_freq: 2000,
  max_points: 100,
  default_log_fetch: 10000,
  default_log_display: 100,
  show_bans_page: true,
  show_manage_server_page: true,
  show_vcl_page: true,
  show_stats_page: true,
  show_params_page: true,
  show_logs_page: true,
  show_restart_varnish_btn: true
};
"""

SERVER = """{
    name: "%(DASHBOARD_SERVER)s",
    host: "%(DASHBOARD_SERVER)s",
    port: %(DASHBOARD_PORT)s,
    user: "%(DASHBOARD_USER)s",
    pass: "%(DASHBOARD_PASSWORD)s"
  }"""

DASHBOARD_USER = os.environ.get("DASHBOARD_USER", "admin")
DASHBOARD_PASSWORD = os.environ.get("DASHBOARD_PASSWORD", "admin")
DASHBOARD_SERVERS = os.environ.get("DASHBOARD_SERVERS", "")
DASHBOARD_PORT = os.environ.get("DASHBOARD_PORT", "6085")
DASHBOARD_DNS_ENABLED = os.environ.get("DASHBOARD_DNS_ENABLED", "").lower() in ("true", "yes", "on")

ips = {}
for server in DASHBOARD_SERVERS.split():
    if ":" in server:
        server, port = server.split(":")
    else:
        port = DASHBOARD_PORT

    if not DASHBOARD_DNS_ENABLED:
        ips[server] = port
        continue

    try:
        records = subprocess.check_output(["getent", "hosts", server])
    except Exception as err:
        print(err)
        continue
    else:
        for record in records.splitlines():
            ip = record.split()[0].decode()
            ips[ip] = port

if ips:
    SERVERS = set()
    for ip, port in ips.items():
        SERVERS.add(SERVER % dict(
            DASHBOARD_SERVER=ip,
            DASHBOARD_PORT=port,
            DASHBOARD_USER=DASHBOARD_USER,
            DASHBOARD_PASSWORD=DASHBOARD_PASSWORD
        ))

    with open("/var/www/html/varnish-dashboard/config.js", "w") as cfile:
        cfile.write(CONFIG_JS % dict(
            SERVERS=", ".join(SERVERS)
        ))
