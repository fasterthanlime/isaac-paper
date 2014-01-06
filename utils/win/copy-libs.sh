#!/bin/bash
DEST=$1
TOOLCHAIN=$2
LIBS=$3

PREFIX=/usr/${TOOLCHAIN}
GCCVER=4.8
LIBGCC=/usr/lib/gcc/${TOOLCHAIN}/${GCCVER}

for LIB in $LIBS; do
  if [[ -e ${PREFIX}/bin/${LIB}.dll ]]; then
    cp ${PREFIX}/bin/${LIB}.dll $DEST
  elif [[ -e ${PREFIX}/lib/${LIB}.dll ]]; then
    cp ${PREFIX}/lib/${LIB}.dll $DEST
  elif [[ -e ${LIBGCC}/${LIB}.dll ]]; then
    cp ${LIBGCC}/${LIB}.dll $DEST
  else
    echo "Couldn't find lib ${LIB}"
    exit 1
  fi
done

