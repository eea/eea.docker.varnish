## Varnish Docker image

 > Centos 6
 > Varnish 3

### Supported tags and respective Dockerfile links

  - `:3` (default)

### Base docker image

 - [hub.docker.com](https://registry.hub.docker.com/u/eeacms/varnish)


### Source code

  - [github.com](http://github.com/eea/eea.docker.varnish)


### Installation

1. Install [Docker](https://www.docker.com/).

### Usage

To use this container, you will need to provide your custom `.vcl` files. The `default.vcl` file is static and serves as base configuration that may not be changed once the container is running. The configuration files found in the `conf.d` directory are automatically included into the base `default.vcl` file in lexico-graphic order (keep in mind that in VCL the order files are included matters, so name your configuration files accordingly). The directory containing the configuration files must be mounted as a volume, located at `/etc/varnish/conf.d/` inside the container.

    $ # The container is ran in the background with the directory
    $ # '/absolute/path/to/configuration/directory' mounted in
    $ # '/etc/varnish/conf.d'
    $ docker run -d \
    $   -v /absolute/path/to/configuration/directory:/etc/varnish/conf.d \
    $   eeacms/varnish:3


### Upgrade

    $ docker pull eeacms/varnish:3

## Supported environment variables ##


### varnish.env ###

  As varnish has close to no purpose by itself, this image should be used in combination with others with [Docker Compose](https://docs.docker.com/compose/). The varnish daemon can be configured by modifying the following env variables, either when running the container or in a `docker-compose.yml` file, using the `env_file` tag.

  * `PRIVILEDGED_USER` Priviledge separation user id
  * `CACHE_SIZE` Size of the cache storage
  * `ADDRESS_PORT` HTTP listen address and port
  * `PARAM_VALUE` A list of parameter-value pairs, each preceeded by the `-p` flag

### Docker Compose example
Here is a basic example of a `docker-compose.yml` file using the `eeacms/varnish` docker image:

    database:
      image: eeacms/postgres

    app:
      image: eeacms/plone-instance
      links:
       - database

    varnish:
      image: eeacms/varnish:3
      links:
       - app
      volumes:
       - /absolute/path/to/varnish/conf.d/directory/:/etc/varnish/conf.d/
      # env_file:
       # - /path/to/varnish.env

The application can be scaled to use more application instances, with `docker-compose scale`:

    $ docker-compose scale database=1 app=<number of instances> varnish=1

An example of such an application is [EEAGlossary](https://github.com/eea/eea.docker.glossary).

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
