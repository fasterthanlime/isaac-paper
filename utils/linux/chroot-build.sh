#!/bin/bash
CHROOT=$1

sudo chroot ${CHROOT} /bin/bash -c "cd /root/Dev/isaac-build && make clean -s"
sudo chroot ${CHROOT} /bin/bash -c "cd /root/Dev/isaac-build && ROCK_DIST=/root/prefix GC_PATH='-lgc -lz' CFLAGS='-w -DGLEW_NO_GLU -I/root/prefix/include -I/root/prefix/include/SDL2 -I/root/prefix/include/GL -I/root/prefix/include/freetype2 -L/root/prefix/lib' make clean all -s -j7"

