#!/bin/sh


for x in $(env | grep ^VARNISH_ | awk -F"=" '{print $1}'); do
	find /etc/varnish -type f -name "*.vcl" -exec sed -i "s/${x}/${!x}/g" {} +
done






