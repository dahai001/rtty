#!/bin/bash

get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist"
}

# perform some very rudimentary platform detection
lsb_dist=$( get_distribution )
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

case "$lsb_dist" in
	ubuntu)
		which pkg-config > /dev/null || apt-get -y install pkg-config
		which gcc > /dev/null || apt-get -y install gcc
		which make > /dev/null || apt-get -y install make
		which cmake > /dev/null || apt-get -y install cmake
		which git > /dev/null || apt-get -y install git
		which quilt > /dev/null || apt-get -y install quilt

		dpkg -L libjson-c-dev > /dev/null 2>&1 || apt-get -y install libjson-c-dev
		dpkg -L libssl-dev > /dev/null 2>&1 || apt-get -y install libssl-dev
	;;
	*)
		echo "Your platform is not supported by this installer script."
		exit 1
	;;
esac

rm -rf /tmp/rtty-build
mkdir /tmp/rtty-build
pushd /tmp/rtty-build

git clone https://git.openwrt.org/project/libubox.git
git clone https://git.openwrt.org/project/ustream-ssl.git
git clone https://github.com/zhaojh329/libuwsc.git
git clone https://github.com/zhaojh329/rtty.git

# libubox
cd libubox && cmake -DBUILD_LUA=OFF . && make install && cd -


# ustream-ssl
cd ustream-ssl
git checkout 189cd38b4188bfcb4c8cf67d8ae71741ffc2b906

LIBSSL_VER=$(cat /usr/include/openssl/opensslv.h | grep OPENSSL_VERSION_NUMBER | grep -o '[0-9x]\+')
LIBSSL_VER=$(echo ${LIBSSL_VER:2:6})

# > 1.1
if [ $LIBSSL_VER -ge 1010000 ];
then 
	quilt import ../rtty/tools/us-openssl_v1_1.patch
	quilt push -a
elif [ $LIBSSL_VER -le 100020 ];
then
    # < 1.1.2
    quilt import ../rtty/tools/us-openssl_v1_0_1.patch
    quilt push -a
fi

cmake . && make install && cd -


# libuwsc
cd libuwsc && cmake . && make install && cd -


# rtty
cd rtty && cmake . && make install

popd
rm -rf /tmp/rtty-build

ldconfig

rtty -V
