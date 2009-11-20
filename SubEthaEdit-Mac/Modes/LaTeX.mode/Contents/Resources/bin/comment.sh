#!/bin/sh

# Toggle comment status for text lines. Text lines are read from 
# stdin and un/commented text lines are written to stdout.
#
# Comments are defined by the line starting with a text string given
# by the first argument. The lines will be uncommented if all lines
# are commented, and commented if any or all of the the lines are
# uncommented. The script is its own inverse, i.e., piping the text 
# through the script twice writes the original text to stdout. 

#$Id: comment.sh,v 1.4 2008/02/17 11:30:24 mjb Exp $

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

tmp=$(mktemp /tmp/comments.XXXXXXXXXXXXXXXXXXXX)

clen=$(printf "%s" "$1" | wc -c)

tee "$tmp" | 
    awk -v clen="$clen" '{ print substr($0, 1, clen) }' | 
        grep -F -q -v "$1"

if (($?)) 
then
    # uncomment
    cat "$tmp" | awk -v lnbeg=$((clen+1)) '{ print substr($0, lnbeg) }'
else
    # comment
    cat "$tmp" | awk -v comment="$1" '{ print comment $0 }'
fi

trap "rm -f $tmp; exit" EXIT HUP INT TERM
