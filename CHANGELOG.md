# Changelog


## 2017-03-27

- Release stable and immutable version: 4.1-1.0

- Possibility to disable backend probe via `BACKENDS_PROBE_ENABLED` env

## 2017-02-22

- Release stable and immutable version: 4.1-1.0

## 2016-04-20

- Added `centos` and `debian` tags. And when we will have an official `varnish`
  Docker Image (see this PR https://github.com/docker-library/official-images/pull/1294)
  we'll rebase to `debian`.

- Installed varnish-modules (Debian only)

- Support for named backends resolved by an internal/external DNS service (e.g. when deployed using rancher-compose)

- Auto-generate [saintmode backends](https://github.com/varnish/varnish-modules/blob/master/docs/saintmode.rst)
  if `BACKENDS_SAINT_MODE` env is provided. (Debian only)


## 2016-01-13

- Start Varnish on port *6081* instead of *80*

- Start all processes with *varnish* user instead of *root*

- Added chaperone process manager

- Improved varnish auto-reloading backends

- Fixed issue #2: Don't force malloc storage backend -
  Added possibility to override default cache settings via $CACHE_STORAGE

## 2015-07-16

- Initial public release
