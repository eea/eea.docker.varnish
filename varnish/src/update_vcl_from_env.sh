#!/bin/bash


for x in $(env | grep -v ^VARNISH_HTTP_PORT | grep -v ^VARNISH_SIZE | grep ^VARNISH_ | awk -F"=" '{print $1}'); do
	find /etc/varnish -type f -name "*.vcl" -exec sed -i "s/<${x}>/${!x}/g" {} +
done






