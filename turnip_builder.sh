#!/bin/bash -e
green='\033[0;32m'
red='\033[0;31m'
nocolor='\033[0m'

deps="meson ninja patchelf unzip curl pip flex bison zip"
workdir="$(pwd)/turnip_workdir"
magiskdir="$workdir/turnip_module"
adrenotoolsdir="$workdir/turnip_adrenotools"
ndkver="android-ndk-r27-beta2"
sdkver="31"
mesasrc="https://gitlab.freedesktop.org/mesa/mesa/-/archive/main/mesa-main.zip"
clear

# there are 4 functions here, simply comment to disable.
# you can insert your own function and make a pull request.
run_all(){
	check_deps
	prepare_workdir
	build_lib_for_android
	port_lib_for_magisk
	generate_adrenotools
}


check_deps(){
	echo "Checking system for required Dependencies ..."
	for deps_chk in $deps;
		do
			sleep 0.25
			if command -v "$deps_chk" >/dev/null 2>&1 ; then
				echo -e "$green - $deps_chk found $nocolor"
			else
				echo -e "$red - $deps_chk not found, can't countinue. $nocolor"
				deps_missing=1
			fi;
		done

		if [ "$deps_missing" == "1" ]
			then echo "Please install missing dependencies" && exit 1
		fi

	echo "Installing python Mako dependency (if missing) ..." $'\n'
	pip install mako &> /dev/null
}



prepare_workdir(){
	echo "Creating and entering to work directory ..." $'\n'
	mkdir -p "$workdir" && cd "$_"

	echo "Downloading android-ndk from google server (~640 MB) ..." $'\n'
	curl https://dl.google.com/android/repository/"$ndkver"-linux.zip --output "$ndkver"-linux.zip &> /dev/null
	###
	echo "Exracting android-ndk to a folder ..." $'\n'
	unzip "$ndkver"-linux.zip  &> /dev/null

	echo "Downloading mesa source (~50 MB) ..." $'\n'
	curl "$mesasrc" --output mesa-main.zip &> /dev/null
	###
	echo "Exracting mesa source to a folder ..." $'\n'
	unzip mesa-main.zip &> /dev/null
	cd mesa-main
}



build_lib_for_android(){
	echo "Creating meson cross file ..." $'\n'
	ndk="$workdir/$ndkver/toolchains/llvm/prebuilt/linux-x86_64/bin"

	cat <<EOF >"android-aarch64"
[binaries]
ar = '$ndk/llvm-ar'
c = ['ccache', '$ndk/aarch64-linux-android$sdkver-clang']
cpp = ['ccache', '$ndk/aarch64-linux-android$sdkver-clang++', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-static-libstdc++']
c_ld = 'lld'
cpp_ld = 'lld'
strip = '$ndk/aarch64-linux-android-strip'
pkgconfig = ['env', 'PKG_CONFIG_LIBDIR=NDKDIR/pkgconfig', '/usr/bin/pkg-config']
[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF

	echo "Generating build files ..." $'\n'
	meson build-android-aarch64 --cross-file "$workdir"/mesa-main/android-aarch64 -Dbuildtype=release -Dplatforms=android -Dplatform-sdk-version=$sdkver -Dandroid-stub=true -Dandroid-strict=false -Dgallium-drivers= -Dvulkan-drivers=freedreno -Dvulkan-beta=true -Dfreedreno-kmds=kgsl -Db_lto=true | tee "$workdir"/meson_log

	echo "Compiling build files ..." $'\n'
	ninja -C build-android-aarch64 | tee "$workdir"/ninja_log
}



port_lib_for_magisk(){
	echo "Using patchelf to match soname ..."  $'\n'
	cp "$workdir"/mesa-main/build-android-aarch64/src/freedreno/vulkan/libvulkan_freedreno.so "$workdir"
	cd "$workdir"
	patchelf --set-soname vulkan.adreno.so libvulkan_freedreno.so
	mv libvulkan_freedreno.so vulkan.adreno.so

	if ! [ -a vulkan.adreno.so ]; then
		echo -e "$red Build failed! $nocolor" && exit 1
	fi

	echo "Prepare magisk module structure ..." $'\n'
	p1="system/vendor/lib64/hw"
	mkdir -p "$magiskdir" && cd "$_"
	mkdir -p "$p1"

	meta="META-INF/com/google/android"
	mkdir -p "$meta"

	cat <<EOF >"$meta/update-binary"
#################
# Initialization
#################
umask 022
ui_print() { echo "\$1"; }
OUTFD=\$2
ZIPFILE=\$3
. /data/adb/magisk/util_functions.sh
install_module
exit 0
EOF

	cat <<EOF >"$meta/updater-script"
#MAGISK
EOF

	cat <<EOF >"module.prop"
id=turnip
name=turnip
version=v2.0
versionCode=1
author=MasterOfMistakes
description=Turnip is an open-source vulkan driver for adreno GPUs.
EOF

	cat <<EOF >"customize.sh"
set_perm_recursive \$MODPATH/system 0 0 755 u:object_r:system_file:s0
set_perm_recursive \$MODPATH/system/vendor 0 2000 755 u:object_r:vendor_file:s0
set_perm \$MODPATH/$p1/vulkan.adreno.so 0 0 0644 u:object_r:same_process_hal_file:s0
EOF

	echo "Copy necessary files from work directory ..." $'\n'
	cp "$workdir"/vulkan.adreno.so "$magiskdir"/"$p1"

	echo "Packing files in to magisk module ..." $'\n'
	zip -r "$workdir"/turnip.zip ./* &> /dev/null
	if ! [ -a "$workdir"/turnip.zip ];
		then echo -e "$red-Packing failed!$nocolor" && exit 1
		else echo -e "$green-All done, you can take your module from here;$nocolor" && echo "$workdir"/turnip.zip
	fi
}

generate_adrenotools(){
    cd $workdir
    echo "Creating AdrenoTools Zip release now..."
    echo "Generate ZIP hierarchy files"
    mkdir $adrenotoolsdir
    cd $adrenotoolsdir

    echo "Generating XML files ..."

    cat <<EOF > "meta.json"
    {
      "schemaVersion": 1,
      "name": "Mesa Turnip Driver v24.3.0",
      "description": "Builded by CI based on KIMCHI releases .",
      "author": "MasterOfMistakes",
      "packageVersion": "2",
      "vendor": "Mesa",
      "driverVersion": "Vulkan 1.3.292",
      "minApi": 29,
      "libraryName": "vulkan.ad07xx.so"
    }
EOF

    cp "$workdir"/vulkan.adreno.so "$adrenotoolsdir"/
    patchelf --set-soname vulkan.ad07xx.so vulkan.adreno.so
    cd $workdir
   	zip -r "$workdir"/turnip_adrenotools.zip "$adrenotoolsdir"/meta.json "$adrenotoolsdir"/vulkan.ad07xx.so &> /dev/null
    if ! [ -a "$workdir"/turnip_adrenotools.zip ];
		then echo -e "$red-Packing failed!$nocolor" && exit 1
		else echo -e "$green-All done, you can take your module from here;$nocolor" && echo "$workdir"/turnip_adrenotools.zip
	fi
}

run_all
