#!/bin/sh
grep VERSION source/isaac/VERSION.ooc | cut -d '"' -f 2
