# Changelog

## 2016-01-13

- Start Zope on port *6081* instead of *80*

- Start all processes with *varnish* user instead of *root*

- Added chaperone process manager

- Improved varnish auto-reloading backends

- Fixed issue #2: Don't force malloc storage backend -
  Added possibility to override default cache settings via $CACHE_STORAGE

## 2015-07-16

- Initial public release
