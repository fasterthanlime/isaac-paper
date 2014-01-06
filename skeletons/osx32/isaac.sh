#!/bin/bash
cd "${0%/*}"
export DYLD_LIBRARY_PATH=$PWD
./isaac-osx32 $@
