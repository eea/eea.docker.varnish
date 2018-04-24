import socket
import sys
import os
import subprocess

################################################################################
# INIT
################################################################################
COOKIES = os.environ.get('COOKIES', '').split(' ')