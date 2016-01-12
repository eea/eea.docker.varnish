#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# This file is static and it will not be possible to modify its contents once
# the container is started. Each file in the 'conf.d' volume extends this, but
# keep in mind that files are included in lexico-graphic order, based on their
# name (for example, file 'test1.vcl' will be included before file 'test2.vcl'
# and after file 'main.vcl').
