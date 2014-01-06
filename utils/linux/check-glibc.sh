#!/bin/bash

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )
source $SCRIPTPATH/vercomp.sh

BINARY=$1
MAX_VER=2.13

IFS="
"
VERS=$(objdump -T $BINARY | grep GLIBC | sed 's/.*GLIBC_\([.0-9]*\).*/\1/g' | sort -u)

for VER in $VERS; do
  vercomp $VER $MAX_VER
  COMP=$?
  if [[ $COMP -eq 1 ]]; then
    echo "Error! ${BINARY} requests GLIBC ${VER}, which is higher than target ${MAX_VER}"
    echo "Affected symbols:"
    objdump -T $BINARY | grep GLIBC_${VER}
    echo "Looking for symbols in libraries..."
    for LIBRARY in $(ldd $BINARY | cut -d ' ' -f 3); do
      echo $LIBRARY
      objdump -T $LIBRARY | fgrep GLIBC_${VER}
    done
    exit 27
  else
    echo "Found version ${VER}"
  fi
done
