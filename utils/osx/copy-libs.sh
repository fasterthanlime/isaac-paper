#!/bin/bash
DEST=$1
PREFIX=$2
LIBS=$3

for LIB in $LIBS; do
  cp ${PREFIX}/lib/${LIB}.*dylib $DEST
done


