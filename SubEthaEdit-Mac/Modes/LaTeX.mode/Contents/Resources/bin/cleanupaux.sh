#!/bin/sh

#$Id: cleanupaux.sh,v 1.4 2008/02/17 11:30:24 mjb Exp $

# Copyright (c) 2008, Michael J. Barber
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject
# to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

PATH="$PATH:/usr/texbin:/usr/local/bin"
export PATH

CLEANUP=${SEE_LATEX_CLEANUP:-'rm -f $(basename "$FILE" .tex).{aux,bbl,blg,dvi,log,out,ps,pdf,pdfsync,toc}'}

FILE="$(basename "$1")"
DIRNAME="$(dirname "$1")"
PRODUCT="$(basename "$1" .tex).$PRODUCT_TYPE"

cd "$DIRNAME"
eval $CLEANUP
