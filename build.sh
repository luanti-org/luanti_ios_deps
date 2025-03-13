#!/bin/bash

echo "This is script automate Luanti deps build process for iOS."

if [[ $# -ne 3 ]] ; then
	echo "Usage: ios_build_with_deps.sh where_deps arch osver"
	echo "  arch - iPhoneOS, iPhoneSimulator"
	echo "  osver  - 18.2 etc."
	exit 1
fi

RUN_DIR=$(pwd)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

where_deps=$1
arch=$2
osver=$3

if [[ "$arch" != "iPhoneOS" ]] && [[ "$arch" != "iPhoneSimulator" ]]; then
	echo "Unsuported value of arch argument: $arch"
	exit 1
fi

source $SCRIPT_DIR/build_deps.sh

mkdir -p $where_deps

cd $where_deps
if [ $? -ne 0 ]; then
	echo "Bad target directory $where_deps."
	exit 1
fi
DEPS_DIR=$(pwd)

download_ios_deps $arch $osver

untar_ios_deps $arch $osver

compile_ios_deps $arch $osver "$SCRIPT_DIR/data"

cd $RUN_DIR
