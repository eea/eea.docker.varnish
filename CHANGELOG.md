# Changelog

## 2018-04-26 (4.1-5.0)

- Add cookie configuration support via `COOKIES` and `COOKIES_WHITELIST` environment variables [twajr refs #19]

## 2018-03-28 (4.1-4.0)

- Remove chaperone, add cron and rsync for logging
- Add varnish agent 2  -  4.1.3  https://github.com/varnish/vagent2
- Add Varnish Dashboard https://github.com/brandonwamboldt/varnish-dashboard

## 2018-03-23 (4.1-3.2)

- Add Probe .request header support

- Upgrade Varnish modules: to 0.12.1

## 2017-09-07 (4.1-3.1)

- Release stable and immutable version: 4.1-3.1

- Upgrade Varnish version: 4.1.8

- Fix newlines on /etc/varnish/default.vcl on reload [chrodriguez - refs #11]

## 2017-03-27 (4.1-3.0)

- Release stable and immutable version: 4.1-3.0

- Upgrade Varnish version: 4.1.5

- Upgrade Varnish modules: 0.11.0

- Add `vmod_digest`

## 2017-03-27 (4.1-2.0)

- Release stable and immutable version: 4.1-2.0

- Possibility to disable backend probe via `BACKENDS_PROBE_ENABLED` env

## 2017-02-22 (4.1-1.0)

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
