#!/bin/bash
set -e

VARNISH_VERSION="4.1.3"
VARNISH_FILENAME="varnish-4.1.3.tar.gz"
VARNISH_SHA256="9f9469b9fda2a578da2a9d282c71c34eeb5c42eda7f8d8728284d92282108429"

buildDeps="
    automake
    build-essential
    libedit-dev
    libjemalloc-dev
    libncurses-dev
    libpcre3-dev
    libtool
    pkg-config
    python-docutils
    curl
    ca-certificates
    libvarnishapi-dev
    python3-dev
    python3-pip
"

runDeps="
    curl
    ca-certificates
    libedit2
    libjemalloc1
    libncurses5
    libpcre3
    libtool
    libvarnishapi1
    python3-dev
    python3-pip
    inotify-tools
"

echo "========================================================================="
echo "Installing $buildDeps"
echo "========================================================================="

apt-get update
apt-get install -y --no-install-recommends $buildDeps


echo "========================================================================="
echo "Adding varnish user"
echo "========================================================================="

adduser --quiet --system --no-create-home --group varnish


echo "========================================================================="
echo "Installing varnish"
echo "========================================================================="

curl -fSL "https://repo.varnish-cache.org/source/$VARNISH_FILENAME" -o "$VARNISH_FILENAME"
echo "$VARNISH_SHA256 *$VARNISH_FILENAME" | sha256sum -c -
mkdir -p /usr/local/src
tar -xzf "$VARNISH_FILENAME" -C /usr/local/src
rm "$VARNISH_FILENAME"
mv "/usr/local/src/varnish-$VARNISH_VERSION" /usr/local/src/varnish
cd /usr/local/src/varnish
./autogen.sh
./configure
make install
ldconfig

echo "========================================================================="
echo "Installing varnish modules"
echo "========================================================================="

mkdir -p /etc/varnish/conf.d/ /usr/local/var/varnish /etc/chaperone.d
chown -R varnish /etc/varnish /usr/local/var/varnish /etc/chaperone.d
curl -o /tmp/varnish.tgz -SL https://download.varnish-software.com/varnish-modules/varnish-modules-0.9.0.tar.gz
tar -zxvf /tmp/varnish.tgz -C /tmp/
rm -rf /tmp/varnish.tgz
cd /tmp/varnish-modules-0.9.0
./configure
make
make install
ldconfig

echo "========================================================================="
echo "Installing chaperone"
echo "========================================================================="

pip3 install chaperone dnspython3


echo "========================================================================="
echo "Unininstalling $buildDeps"
echo "========================================================================="

apt-get purge -y --auto-remove $buildDeps

echo "========================================================================="
echo "Installing $runDeps"
echo "========================================================================="

apt-get install -y --no-install-recommends $runDeps


echo "========================================================================="
echo "Cleaning up cache..."
echo "========================================================================="

apt-get clean
rm -rf /var/lib/apt/lists/*


echo "========================================================================="
echo "Configuration scripts"
echo "========================================================================="

mv -v /tmp/chaperone.conf     /etc/chaperone.d/chaperone.conf
mv -v /tmp/assemble_vcls.py   /assemble_vcls.py
mv -v /tmp/add_backends.py    /add_backends.py
mv -v /tmp/docker-setup.sh    /docker-setup.sh
mv -v /tmp/track_hosts.sh     /track_hosts
mv -v /tmp/track_dns.sh       /track_dns
mv -v /tmp/reload.sh          /usr/bin/reload
mv -v /tmp/default.vcl        /etc/varnish/default.vcl
