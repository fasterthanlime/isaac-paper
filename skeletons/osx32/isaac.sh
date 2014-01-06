#!/bin/bash
cd "${0%/*}"
export DYLD_LIBRARY_PATH=$PWD/libs
./isaac-osx32 $@
