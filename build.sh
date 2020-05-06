#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

external="$PWD/../3rdparty"

#--------------------------------------------------------------------------------------------------

VLC_version="3.0.10"

#--------------------------------------------------------------------------------------------------
# Android

VLC_version_android="3.2.12"

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 ] \
   || \
   [ $1 != "win32" -a $1 != "win64" -a $1 != "macOS" -a $1 != "linux" -a $1 != "android" ]; then

    echo "Usage: build <win32 | win64 | macOS | linux | android>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

external="$external/$1"

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

elif [ $1 = "android" ]; then

    os="default"

    VLC_version=$VLC_version_android
else
    os="default"
fi

#--------------------------------------------------------------------------------------------------

if [ $1 = "android" ]; then

    VLC_url="https://code.videolan.org/videolan/vlc-android"
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

rm -rf vlc-$VLC_version

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------

if [ $1 = "linux" ]; then

    sudo apt-get -y install build-essential pkg-config libtool automake autopoint gettext

#elif [ $1 = "android" ]; then
#
#    sudo apt-get -y install automake ant autopoint cmake build-essential libtool-bin patch \
#                            pkg-config protobuf-compiler ragel subversion unzip git \
#                            openjdk-8-jre openjdk-8-jdk flex python wget
fi

#--------------------------------------------------------------------------------------------------
# Download
#--------------------------------------------------------------------------------------------------

if [ $1 != "android" ]; then

    echo ""
    echo "DOWNLOADING VLC"
    echo $VLC_url

    curl -L -o VLC.tar.xz $VLC_url
fi

#--------------------------------------------------------------------------------------------------
# Extract
#--------------------------------------------------------------------------------------------------

# NOTE Windows: We need to use 7z otherwise it seems to freeze Azure.
if [ $os = "windows" ]; then

    echo ""
    echo "EXTRACTING VLC"

    7z x VLC.tar.xz > null
    7z x VLC.tar    > null

elif [ $1 != "android" ]; then

    echo ""
    echo "EXTRACTING VLC"

    tar -xf VLC.tar.xz
fi

#--------------------------------------------------------------------------------------------------
# Clone
#--------------------------------------------------------------------------------------------------

if [ $1 = "android" ]; then

    echo ""
    echo "CLONING VLC"
    echo $VLC_url

    git clone $VLC_url vlc-$VLC_version
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

#elif [ $1 = "android" ]; then

    #export ANDROID_NDK="$NDK"

    #git checkout tags/$VLC_version
fi

#--------------------------------------------------------------------------------------------------
# Build
#--------------------------------------------------------------------------------------------------

echo ""
echo "BUILDING VLC"

if [ $os = "windows" ]; then

    mingw32-make
    mingw32-make install

elif [ $1 = "android" ]; then

    ./buildsystem/compile.sh -r
else
    make
    make install
fi

#--------------------------------------------------------------------------------------------------
# Deploy
#--------------------------------------------------------------------------------------------------

if [ $1 = "android" ]; then

    echo ""
    echo "DEPLOYING VLC"

    mv vlc/include ../deploy

    mv libvlc      ../deploy
    mv vlc-android ../deploy
fi
