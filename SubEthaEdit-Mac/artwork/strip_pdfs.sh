#!/bin/sh

find . -name "*.pdf" -exec ./remove-metadata.sh \{\} \;