#!/bin/bash
# Isaac Shell Script
# Inspired by the work of Ethan "flibitijibibo" Lee
 
# Move to script's directory
cd "`dirname "$0"`"
 
# Get the kernel/architecture information
UNAME=`uname`
ARCH=`uname -m`
 
# Set the libpath and pick the proper binary
if [ "$ARCH" == "x86_64" ]; then
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./libs/64
    ./binaries/isaac-linux64 $@
else
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./libs/32
    ./binaries/isaac-linux32 $@
fi
