#!/bin/bash -e

clone_ios_angle() {
	datadir=$1

	depot_hash="6d817fd7f4c19cde114d7cfb62fc5b313521776b"
	#angle_hash="6b10ae3386b706624893d6f654f3af953840b3a2"
	angle_hash="d81d29e166b6af1181f06e56c916c06676dd6ad1"

	git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git depot_tools
	git -C depot_tools fetch --depth 1 origin $depot_hash
	git -C depot_tools checkout $depot_hash
	git clone --depth 1 https://chromium.googlesource.com/angle/angle angle
	git -C angle fetch --depth 1 origin $angle_hash
	git -C angle checkout $angle_hash

	export PATH=$PWD/depot_tools:$PATH

	# angle
	cd angle
	python3 scripts/bootstrap.py
	gclient sync
	# for usable static libraries output
	if ! grep -q "libANGLE_static" BUILD.gn; then
		cat $datadir/BUILD.gn >> BUILD.gn
	fi
	sed -i '' '/compiler:thin_archive/d' build/config/BUILDCONFIG.gn

	cd ..
}

build_ios_angle() {
	arch=$1
	osver=$2
	xcodever=$3
	installdir=$4
	datadir=$5

	export PATH=$PWD/depot_tools:$PATH

	xcodeapp="Xcode.app"
	if [[ -n $xcodever ]]; then
		xcodeapp="Xcode_$xcodever.app"
		sudo xcode-select -s /Applications/$xcodeapp/Contents/Developer
	fi

	# angle
	cd angle
	echo "Configuring angle..."
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
	mkdir -p $installdir/lib
	mkdir -p $installdir/include
	cp out/obj/libANGLE_static.a $installdir/lib
	cp out/obj/libEGL_static.a $installdir/lib
	cp out/obj/libGLESv2_static.a $installdir/lib
	cp -r include $installdir/include/ANGLE
	filecheck="$installdir/lib/libANGLE_static.a"
	if [ ! -f $filecheck ]; then
		echo "File $filecheck not found"
		exit 1
	fi
	cd $dir
}

