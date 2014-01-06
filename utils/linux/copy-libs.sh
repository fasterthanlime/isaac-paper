#!/bin/bash
CHROOT=$1
BINARY_PATH=$2
DEST=$3

mkdir -p ${DEST}

BINARY_DIR=$(dirname ${BINARY_PATH})
BINARY_BASE=$(basename ${BINARY_PATH})

IFS=$'\n'
LIBS=$(sudo chroot ${CHROOT} /bin/bash -c "cd ${BINARY_DIR} && LD_LIBRARY_PATH=/root/prefix/lib ldd ${BINARY_BASE} | grep prefix | cut -d ' ' -f 3")

for LIB in $LIBS; do
  cp -vfH ${CHROOT}${LIB} ${DEST}/
done
