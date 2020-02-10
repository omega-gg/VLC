#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

external="../3rdparty"

#--------------------------------------------------------------------------------------------------

VLC_version="3.0.6"

#--------------------------------------------------------------------------------------------------
# Android

NDK_version="21"

VLC_version_android="3.2.7-1"

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 ] \
   || \
   [ $1 != "win32" -a $1 != "win64" -a $1 != "macOS" -a $1 != "linux" -a $1 != "android32" -a \
                                                                         $1 != "android64" ]; then

    echo "Usage: build <win32 | win64 | macOS | linux | android32 | android64>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

external="$external/$1"

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

elif [ $1 = "android32" -o $1 = "android64" ]; then

    os="android"

    $VLC_version=$VLC_version_android
else
    os="default"
fi

#--------------------------------------------------------------------------------------------------

NDK="$external/NDK/$NDK_version"

#--------------------------------------------------------------------------------------------------

if [ $os = "android" ]; then

    VLC_url="https://code.videolan.org/videolan/vlc-android/tree/$VLC_version"
else
    VLC_url="https://download.videolan.org/pub/videolan/vlc/$VLC_version/vlc-$VLC_version.tar.xz"
fi

#--------------------------------------------------------------------------------------------------
# Clean
#--------------------------------------------------------------------------------------------------

echo "CLEANING"

rm -rf deploy
mkdir  deploy
touch  deploy/.gitignore

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------

if [ $1 = "linux" ]; then

    sudo apt-get -y install build-essential pkg-config libtool automake autopoint gettext

elif [ $os = "android" ]; then

    sudo apt-get -y install automake ant autopoint cmake build-essential libtool-bin patch \
                            pkg-config protobuf-compiler ragel subversion unzip git \
                            openjdk-8-jre openjdk-8-jdk flex python wget
fi

#--------------------------------------------------------------------------------------------------
# Download
#--------------------------------------------------------------------------------------------------

echo ""
echo "DOWNLOADING VLC"
echo $VLC_url

if [ $os = "android" ]; then

    git clone $VLC_url vlc-$VLC_version
else
    curl -L -o VLC.tar.xz $VLC_url
fi

#--------------------------------------------------------------------------------------------------
# Extract
#--------------------------------------------------------------------------------------------------

# NOTE Windows: We need to use 7z otherwise it seems to freeze Azure.
if [ $os = "windows" ]; then

    echo ""
    echo "EXTRACTING VLC"

    7z x VLC.tar.xz
    7z x VLC.tar

elif [ $os != "android" ]; then

    echo ""
    echo "EXTRACTING VLC"

    tar -xf VLC.tar.xz
fi

#--------------------------------------------------------------------------------------------------
# Dependencies
#--------------------------------------------------------------------------------------------------

if [ $1 = "linux" ]; then

    echo ""
    echo "GET DEPENDENCIES"

    sudo apt-get -y build-dep vlc
fi

#--------------------------------------------------------------------------------------------------
# Configure
#--------------------------------------------------------------------------------------------------

echo ""
echo "CONFIGURING VLC"

cd vlc-$VLC_version

if [ $1 = "linux" ]; then

    ./configure --prefix=$PWD/../deploy

elif [ $os = "android" ]; then

    export ANDROID_NDK="$NDK"
fi

#--------------------------------------------------------------------------------------------------
# Build
#--------------------------------------------------------------------------------------------------

echo ""
echo "BUILDING VLC"

if [ $os = "windows" ]; then

    mingw32-make
    mingw32-make install

elif [ $1 = "android32" ]; then

    sh compile.sh -r -l -a armeabi-v7a
else
    make
    make install
fi
