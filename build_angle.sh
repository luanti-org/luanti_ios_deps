#!/bin/bash

echo "This is script automate Google ANGLE build for iOS."

if [[ $# -ne 4 ]] ; then
	echo "Usage: build_angle.sh where_angle arch osver xcodever"
	echo "  arch - iPhoneOS, iPhoneSimulator"
	echo "  osver  - 18.2 etc."
	echo "	xcodever - 16.2 etc"
	exit 1
fi

RUN_DIR=$(pwd)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

where_angle=$1
arch=$2
osver=$3
xcodever=$4

install_angle=$where_angle/install

depot_hash="6d817fd7f4c19cde114d7cfb62fc5b313521776b"
#angle_hash="6b10ae3386b706624893d6f654f3af953840b3a2"
angle_hash="d81d29e166b6af1181f06e56c916c06676dd6ad1"

datadir=$SCRIPT_DIR/data

mkdir -p $where_angle
cd $where_angle

git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git depot_tools
git -C depot_tools fetch --depth 1 origin $depot_hash
git -C depot_tools checkout $depot_hash
git clone --depth 1 https://chromium.googlesource.com/angle/angle angle
git -C angle fetch --depth 1 origin $angle_hash
git -C angle checkout $angle_hash

export PATH=$PWD/depot_tools:$PATH

# angle
cd angle
echo "Configuring angle..."
echo "PWD=$PWD"
echo "PATH=$PATH"
python3 scripts/bootstrap.py
gclient sync
cat $datadir/BUILD.gn >> BUILD.gn
gn gen out
cp $datadir/args.gn out
# Update ios_sdk_version in the file
sed -i.bak "s/^ios_sdk_version = .*/ios_sdk_version = \"$osver\"/" "out/args.gn"
# Update target_os in the file
if [[ $arch == "iPhoneSimulator" ]]; then
	sed -i.bak "s/^target_environment = .*/target_environment = \"simulator\"/" "out/args.gn"
else
	sed -i.bak "s/^target_environment = .*/target_environment = \"device\"/" "out/args.gn"
fi
gn gen out
echo "Building angle..."
ninja -j 6 -C out
mkdir -p $install_angle/lib
mkdir -p $install_angle/include
cp out/obj/libANGLE_static.a $install_angle/lib
cp out/obj/libEGL_static.a $install_angle/lib
cp out/obj/libGLESv2_static.a $install_angle/lib
cp -r include $install_angle/include/ANGLE
filecheck="$install_angle/lib/libANGLE_static.a"
if [ ! -f $filecheck ]; then
	echo "File $filecheck not found"
	exit 1
fi
cd $dir

