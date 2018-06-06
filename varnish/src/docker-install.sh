#!/bin/bash
set -e

VARNISH_VERSION="4.1.10"
VARNISH_FILENAME="varnish-4.1.10.tgz"
VARNISH_SHA256="364833fbf6fb7540ddd54b62b5ac52b2fb00e915049c8446d71d334323e87c22"
VARNISH_AGENT_V="4.1.3"
VARNISH_DASHBOARD_COMMIT="e2cc1c854941c9fac18bdfedba2819fa766a5549"


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
    libmhash-dev
    libmicrohttpd-dev
    libcurl4-gnutls-dev
    git
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
    libmhash2
    libmicrohttpd-dev
    libcurl4-gnutls-dev
    rsyslog
    cron
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

curl -fSL "http://varnish-cache.org/_downloads/$VARNISH_FILENAME" -o "$VARNISH_FILENAME"
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
curl -o /tmp/varnish.tgz -SL https://download.varnish-software.com/varnish-modules/varnish-modules-0.12.1.tar.gz
tar -zxvf /tmp/varnish.tgz -C /tmp/
rm -rf /tmp/varnish.tgz
cd /tmp/varnish-modules-0.12.1
./configure
make
make install
ldconfig

curl -o /tmp/libvmod-digest.tar.gz -SL https://github.com/varnish/libvmod-digest/archive/libvmod-digest-1.0.1.tar.gz
tar -zxvf /tmp/libvmod-digest.tar.gz -C /tmp/
rm -rf /tmp/libvmod-digest.tar.gz
cd /tmp/libvmod-digest-libvmod-digest-1.0.1
./autogen.sh
./configure
make
make install
ldconfig



echo "========================================================================="
echo "Installing Varnish agent"
echo "========================================================================="

curl -o /tmp/vagent2.tar.gz -SL https://github.com/varnish/vagent2/archive/${VARNISH_AGENT_V}.tar.gz
tar -zxvf /tmp/vagent2.tar.gz  -C /tmp/
rm -rf  /tmp/vagent2.tar.gz
cd /tmp/vagent2-${VARNISH_AGENT_V}
./autogen.sh
./configure
make
make install
ldconfig

echo "========================================================================="
echo "Installing Varnish dashboard"
echo "========================================================================="

mkdir -p /var/www/html
cd /var/www/html
git clone https://github.com/brandonwamboldt/varnish-dashboard.git
cd varnish-dashboard
git checkout ${VARNISH_DASHBOARD_COMMIT}


echo "========================================================================="
echo "Unininstalling $buildDeps"
echo "========================================================================="

apt-get purge -y --auto-remove $buildDeps

echo "========================================================================="
echo "Installing $runDeps"
echo "========================================================================="

apt-get install -y --no-install-recommends $runDeps


echo "========================================================================="
echo "Configuring crontab logging"
echo "========================================================================="


sed -i '/#cron./c\cron.*                          \/proc\/1\/fd\/1'  /etc/rsyslog.conf
sed -i 's/-\/var\/log\/syslog/\/proc\/1\/fd\/1/g' /etc/rsyslog.conf


echo "========================================================================="
echo "Cleaning up cache..."
echo "========================================================================="

apt-get clean
rm -rf /var/lib/apt/lists/*
