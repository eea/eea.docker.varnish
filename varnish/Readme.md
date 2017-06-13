# Varnish Docker image

Varnish docker image with support for dynamic backends, Rancher DNS, auto-configure
and reload.

This image is generic, thus you can obviously re-use it within
your non-related EEA projects.

 - Debian Jessie
 - Varnish **4.1.5**
 - EXPOSE **6081**

## Supported tags and respective Dockerfile links

  - `:latest` [*Dockerfile*](https://github.com/eea/eea.docker.varnish/blob/master/varnish/Dockerfile) (Debian Jessie, Varnish 4.1)

### Stable and immutable tags

  - `:4.1-3.0` [*Dockerfile*](https://github.com/eea/eea.docker.varnish/tree/4.1-3.0/varnish/Dockerfile) - Varnish: **4.1** Release: **3.0**

See [older versions](https://github.com/eea/eea.docker.varnish/releases)

### Changes

 - [CHANGELOG.md](https://github.com/eea/eea.docker.varnish/blob/master/CHANGELOG.md)

## Base docker image

 - [hub.docker.com](https://registry.hub.docker.com/u/eeacms/varnish)

## Source code

  - [github.com](http://github.com/eea/eea.docker.varnish)


## Installation

1. Install [Docker](https://www.docker.com/).


## Usage

### Run with Docker Compose

Here is a basic example of a `docker-compose.yml` file using the `eeacms/varnish` docker image:

    version: "2"
    services:
      varnish:
        image: eeacms/varnish
        ports:
        - "80:6081"
        depends_on:
        - anon
        - auth
        - download
        environment:
          BACKENDS: "anon auth download"
          BACKENDS_PORT: "8080"
          DNS_ENABLED: "true"
          BACKENDS_PROBE_INTERVAL: "3s"
          BACKENDS_PROBE_TIMEOUT: "1s"
          BACKENDS_PROBE_WINDOW: "3"
          BACKENDS_PROBE_THRESHOLD: "2"
      anon:
        image: eeacms/hello
        environment:
          PORT: "8080"
      auth:
        image: eeacms/hello
        environment:
          PORT: "8080"
      download:
        image: eeacms/hello
        environment:
          PORT: "8080"


The application can be scaled to use more server instances as backends, with `docker-compose scale`:

    $ docker-compose up -d
    $ docker-compose scale anon=4 auth=2

An example of a more complex application using the `eeacms/varnish` with `docker-compose`
image is [EEA WWW](https://github.com/eea/eea.docker.www).


### Extend the image with a custom varnish.vcl file

The `default.vcl` file provided with this image is bare and only contains
the marker to specify the VCL version. If you plan on using a more
elaborate base configuration in your container and you want it shipped with
your image, you can extend the image in a Dockerfile, like this:

    FROM eeacms/varnish
    COPY varnish.vcl backends.vcl /etc/varnish/conf.d/

and then run

    $ docker build -t varnish-custom /path/to/Dockerfile


### Change and reload configuration without restarting the container

If the configuration directory is mounted as a volume, you can modify
it from outside the container. In order for the modifications
to be loaded by the varnish daemon, you have to run the `reload` command,
as following:

    $ docker exec <container-name-or-id> reload

The command will load the new configuration, compile it, and if compilation
succeeds replace the old one with it. If compilation of the new configuration
fails, the varnish daemon will continue to use the old configuration.
Keep in mind that the only way to restore a previous configuration is to
restore the configuration files and then reload them.


### Upgrade

    $ docker pull eeacms/varnish

## Supported environment variables ##


As varnish has close to no purpose by itself, this image should be used
in combination with others with [Docker Compose](https://docs.docker.com/compose/).
The varnish daemon can be configured by modifying the following environment variables:

* `PRIVILEDGED_USER` Priviledge separation user id (e.g. `varnish`)
* `CACHE_SIZE` Size of the RAM cache storage (default `2G`)
* `CACHE_STORAGE` Override default RAM cache (e.g. `file,/var/lib/varnish/varnish_storage.bin,1G`)
* `ADDRESS_PORT` HTTP listen address and port (default `:6081`)
* `ADMIN_PORT` HTTP admin address and port (e.g. `:6082`)
* `PARAM_VALUE` A list of parameter-value pairs, each preceeded by the `-p` flag
* `BACKENDS` A list of `host[:port]` pairs separated by space
  (e.g. `BACKENDS="127.0.0.1 74.125.140.103:8080"`)
* `BACKENDS_PORT` Default port to be used for backends (defalut `80`)
* `BACKENDS_PROBE_ENABLED` Enable backend probe (default `True`)
* `BACKENDS_PROBE_URL` Backend probe URL (default `/`)
* `BACKENDS_PROBE_TIMEOUT` Backend probe timeout (defalut `1s`)
* `BACKENDS_PROBE_INTERVAL` Backend probe interval (defalut `1s`)
* `BACKENDS_PROBE_WINDOW` Backend probe window (defalut `3`)
* `BACKENDS_PROBE_THRESHOLD` Backend probe threshold (defalut `2`)
* `DNS_ENABLED` DNS lookup provided `BACKENDS`. Use this option when your backends are resolved by an internal/external DNS service (e.g. Rancher)
* `DNS_TTL` DNS lookup backends every $DNS_TTL minutes. Default 1 minute.
* `BACKENDS_SAINT_MODE` Register backends using [saintmode module](https://github.com/varnish/varnish-modules/blob/master/docs/saintmode.rst)

## Copyright and license

The Initial Owner of the Original Code is European Environment Agency (EEA).
All Rights Reserved.

The Original Code is free software;
you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later
version.


## Funding

[European Environment Agency (EU)](http://eea.europa.eu)
