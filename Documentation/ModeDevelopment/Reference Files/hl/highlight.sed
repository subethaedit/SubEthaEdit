# addresses
123d
/rege[xX] ad\/dress/p
\dother \delimitersdn
$D

# ranges
/12/,452n
23~4P
2,$H
78,109F

# negations
/not this line/!h
123,456!g
$!=

# negation of addresses and ranges
/do not replace this line/!G
/blah/,123!x
/begin/,/end/!v
674~12z

# the s command
s/hello/world/6gw/output/file
saw\(it\)h \anotheradelim\1era

# the y command
y/a\nbc/wxyz/
yxabcx\xyzx

# the a, i and c commands
a\
This is literal text\
That is spread over multiple lines\
and even contains \\ escaped backslashes

i\
The i...

c\
... and c commands work similarly

# labels
:label
blabel
tlabel
Tlabel

# the w and r commands
w/output/file
W/another/output/file
r/input/file
R/another/output/file

/the end/q 2

# compound commands
/begin/,/end/{
        l 67
        /test/x
        y/abc/xyz/
}

# semicolons
L 23;x
x;/[Aa]bc/H;$g

# invalid command
/123/k

# excess characters
hblah

# missing line continuation
a
hello world

# invalid flags
s/hello/world/o
