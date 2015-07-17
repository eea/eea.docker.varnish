## Varnish Docker image

 > Centos 7
 > Varnish 4.x

### Supported tags and respective Dockerfile links

  - `:4` (default)

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
    $   eeacms/varnish:4

### Change and reload configuration without restarting the container

Since the configuration directory is mounted as a volume, you can modify its content from outside the container. In order for the modifications to be loaded by the varnish daemon, you have to run the `reload` command, as following:

    $ docker exec <container-name-or-id> reload

The command will load the new configuration, compile it, and if compilation succeeds replace the old one with it. If compilation of the new configuration fails, the varnish daemon will continue to use the old configuration. Keep in mind that the only way to restore a previous configuration is to restore the configuration files and then reload them.

### Upgrade

    $ docker pull eeacms/varnish:4

## Supported environment variables ##


### varnish.env ###

  As varnish has close to no purpose by itself, this image should be used in combination with others with [Docker Compose](https://docs.docker.com/compose/). The varnish daemon can be configured by modifying the following env variables, either when running the container or in a `docker-compose.yml` file, using the `env_file` tag.

  * `PRIVILEDGED_USER` Priviledge separation user id
  * `CACHE_SIZE` Size of the cache storage
  * `ADDRESS_PORT` HTTP listen address and port
  * `PARAM_VALUE` A list of parameter-value pairs, each preceeded by the `-p` flag
