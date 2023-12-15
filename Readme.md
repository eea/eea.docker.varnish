# Varnish Docker image

Varnish docker image with support for dynamic backends, Rancher DNS, auto-configure
and reload.

This image is generic, thus you can obviously re-use it within
your non-related EEA projects.

 - Alpine **3.19**
 - Varnish **7.4.2**
 - Expose **80**, **8443**

## Supported tags and respective Dockerfile links

  - `:7` [*Dockerfile*](https://github.com/eea/eea.docker.varnish/blob/7.x/Dockerfile) (Alpine 3.15, Varnish 7.4.2)

### Stable and immutable tags

  - `:4.1-6.5` [*Dockerfile*](https://github.com/eea/eea.docker.varnish/tree/4.1-6.5/varnish/Dockerfile) - Varnish: **4.1.11** Release: **6.5**
  - `:7.2-1.0` [*Dockerfile*](https://github.com/eea/eea.docker.varnish/tree/7.2-1.0/Dockerfile) - Varnish: **7.2** Release: **1.0**
  - `:7.4-1.1` [*Dockerfile*](https://github.com/eea/eea.docker.varnish/tree/7.4-1.1/Dockerfile) - Varnish: **7.4.2** Release: **1.1**

See [older versions](https://github.com/eea/eea.docker.varnish/releases)

### Changes

 - [CHANGELOG.md](https://github.com/eea/eea.docker.varnish/blob/master/CHANGELOG.md)

## Base docker image

 - [hub.docker.com](https://registry.hub.docker.com/u/eeacms/varnish)

## Source code

  - [github.com](http://github.com/eea/eea.docker.varnish)


## Installation

1. Install [Docker](https://www.docker.com/).

## Variables

* `VARNISH_HTTP_PORT` - varnish port
* `VARNISH_HTTPS_PORT` - varnish ssl port
* `VARNISH_SIZE` - varnish cache size
* `AUTOKILL_CRON` - Varnish re-create crontab, will force a recreation of the container. Uses UTC time, format is linux crontab - for example -  `0 2 * * *` is 02:00 UTC each day" 
* `VARNISH_CFG_CONTENT` - Multiline variable that will be written in the `default.vcl` file

## Usage

### Using `VARNISH_CFG_CONTENT`

See [docker-compose.yml](https://github.com/eea/eea.docker.varnish/blob/7.x/docker-compose.yml).

### Extend the image with a custom varnish.vcl file

The `default.vcl` file provided with this image is bare and only contains
the marker to specify the VCL version. If you plan on using a more
elaborate base configuration in your container and you want it shipped with
your image, you can extend the image in a Dockerfile, like this:

    FROM eeacms/varnish
    COPY varnish.vcl /etc/varnish/conf.d/

and then run

    $ docker build -t varnish-custom /path/to/Dockerfile

## How to add docker environment variables in varnish.vcl

1. Choose relevant variable name, starting with `VARNISH_` - eg. `VARNISH_EXAMPLE`

2. Add default value in Dockerfile 

      ENV VARNISH_EXAMPLE="GET"

3. Add variable in `<>` in varnish.vcl

      set req.http.X-Varnish-Routed = "<VARNISH_EXAMPLE>";

4. Add description in `Readme.md`

### Rancher integration

Use `dynamic.director` to integrate varnish in rancher DNS - if a backend containers are changed, it knows to get the latest list of IPs automatically.

      new cluster = dynamic.director(port = "<VARNISH_BACKEND_PORT>", ttl = <VARNISH_DNS_TTL>);


### Example:

You can use [plone-varnish](https://github.com/eea/plone-varnish) as an example of usage. 

### Upgrade

    $ docker pull eeacms/varnish


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
