#!/bin/bash
export MACOSX_DEPLOYMENT_TARGET="10.7"
export CFLAGS="-mmacosx-version-min=10.7 -isysroot /Users/amos/Dev/MacOSX10.7.sdk"
export LDFLAGS="-Wl,-syslibroot,/Users/amos/Dev/MacOSX10.7.sdk"
rock -v -g -j3 +-headerpad_max_install_names
