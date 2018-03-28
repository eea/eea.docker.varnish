#!/bin/bash

source /etc/environment

# Make a copy of the existing configuration file
cp /etc/varnish/default.vcl /etc/varnish/old_default.vcl
python3 /assemble_vcls.py

# Generate a name for the new configuration
NEW_CONFIG_NAME="boot-$RANDOM"

# Attempt to load the new configuration
varnishadm "vcl.load $NEW_CONFIG_NAME /etc/varnish/default.vcl"
if [ $? -eq 0 ]; then
    # If the load succeeds, remove existing configurations and use the new one
    varnishadm "vcl.use $NEW_CONFIG_NAME"
    for CONFIG_NAME in $(varnishadm vcl.list | grep available | awk -F " " '{print $NF}'); do
        varnishadm "vcl.discard $CONFIG_NAME"
    done
    rm /etc/varnish/old_default.vcl
    echo "======           SUCCESSFULLY RELOADED VCL FILE               ======"
else
    # If the load fails, restore the old configuration file
    mv /etc/varnish/old_default.vcl /etc/varnish/default.vcl
    echo "======     FAILURE TO RELOAD. PLEASE CHECK CONFIGURATION      ======"
fi
