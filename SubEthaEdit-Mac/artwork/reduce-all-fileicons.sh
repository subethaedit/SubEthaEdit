#!/bin/sh
find . -name "file-*" -exec ./reduce.sh \{\} \;

