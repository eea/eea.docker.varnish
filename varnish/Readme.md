# Varnish Docker image

Varnish docker image with support for dynamic backends, Rancher DNS, auto-configure
and reload.

This image is generic, thus you can obviously re-use it within
your non-related EEA projects.

 - Debian Jessie
 - Varnish **4.1**
 - EXPOSE **6081**

## Supported tags and respective Dockerfile links

  - `:latest` [*Dockerfile*](https://github.com/eea/eea.docker.varnish/blob/master/varnish/Dockerfile) (Debian Jessie, Varnish 4.1)

### Stable and immutable tags

  - `:4.1-1.0` [*Dockerfile*](https://github.com/eea/eea.docker.varnish/tree/4.1-1.0/varnish/Dockerfile) - Varnish: **4.1** Release: **1.0**

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
        - webapp
        environment:
          DNS_ENABLED: "true"
          BACKENDS: "webapp"

       webapp:
        image: eeacms/hello


The application can be scaled to use more server instances as backends, with `docker-compose scale`:

    $ docker-compose scale webapp=4 varnish=1

An example of a more complex application using the `eeacms/varnish` with `docker-compose`
image is [EEA WWW](https://github.com/eea/eea.docker.www).


### Run with backends specified as environment variable

Setting the `BACKENDS` variable overrides any other options and is a way
to quickstart the container. A configuration file will be created and
loaded automatically based on the contents of the variable.

    $ docker run -p 80:6081 -e BACKENDS="192.168.1.5 192.168.1.6" -e BACKENDS_PORT=8080 eeacms/varnish

The command above forwards `port 6081` in the container to `port 80` on your machine,
so you can view the results in your browser, and adds two backends with the `IP 192.168.1.5`
and `IP 192.168.1.6` providing services on `port 8080`.

You can also specify hosts by name, but they have to be included in `/etc/hosts`
in the container.  This could be done, for example, by extending the image
and adding a custom `/etc/hosts` file inside the container, overwriting the default one.

If there are multiple DNS records for one or more of your `BACKENDS` (e.g. when deployed using Rancher),
you can use `DNS_ENABLED` environment variable. This way, Varnish will load-balance
all of your backends instead of only the first entry found:

    $ docker run --link=webapp -e BACKENDS="webapp" -e DNS_ENABLED=true eeacms/varnish

It will also automatically add/remove backends when you scale them.

### Link this container to one or more application containers

    $ docker run --link app_instance_1 --link app_instance_2 eeacms/varnish

When linking containers with the `--link` flag, entries in `/etc/hosts`
are automatically added by `docker`. This image is configured so in absence of
a `conf.d` directory (or in case of an empty one) and when the `BACKENDS`
variable is not set it will automatically parse `/etc/hosts` and create and
load the configuration for `varnish`. In this scenario, the file `/etc/hosts`
will be monitored and every time it is modified (for example when restarting
a linked container) configuration for `varnish` will be automatically
recreated and reloaded.


### Mount a conf.d directory as a volume

To adapt this container specifically to your needs, you will need to provide
your custom `.vcl` files. The `default.vcl` file is static and serves as base
configuration that may not be changed once the container is running.
The configuration files found in the `conf.d` directory are automatically
included into the base `default.vcl` file in lexico-graphic order
(keep in mind that in VCL the order files are included matters, so name your
configuration files accordingly). The directory containing the configuration
files must be mounted as a volume, located at `/etc/varnish/conf.d/` inside the container.

    $ docker run -v $(pwd)/conf.d:/etc/varnish/conf.d eeacms/varnish


### Extend the image with a custom varnish.vcl file

The `default.vcl` file provided with this image is bare and only contains
the marker to specify the VCL version. If you plan on using a more
elaborate base configuration in your container and you want it shipped with
your image, you can extend the image in a Dockerfile, like this:

    FROM eeacms/varnish:4.1
    COPY backends.vcl /etc/varnish/conf.d/backends.vcl

and then run

    $ docker build -t varnish-custom /path/to/Dockerfile

As before, you are able to mount a `conf.d` directory in which to put your `.vcl`
files, in order to have modular configuration.


### Change and reload configuration without restarting the container

Since the configuration directory is mounted as a volume, you can modify
its content from outside the container. In order for the modifications
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
The varnish daemon can be configured by modifying the following env variables,
either when running the container or in a `docker-compose.yml` file,
using the `env_file` tag.

* `PRIVILEDGED_USER` Priviledge separation user id (e.g. `varnish`)
* `CACHE_SIZE` Size of the RAM cache storage (default `2G`)
* `CACHE_STORAGE` Override default RAM cache (e.g. `file,/var/lib/varnish/varnish_storage.bin,1G`)
* `ADDRESS_PORT` HTTP listen address and port (default `:6081`)
* `ADMIN_PORT` HTTP admin address and port (e.g. `:6082`)
* `PARAM_VALUE` A list of parameter-value pairs, each preceeded by the `-p` flag
* `BACKENDS` A list of `host[:port]` pairs separated by space
  (e.g. `BACKENDS="127.0.0.1 74.125.140.103:8080"`)
* `BACKENDS_PORT` Default port to be used for backends (defalut `80`)
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
