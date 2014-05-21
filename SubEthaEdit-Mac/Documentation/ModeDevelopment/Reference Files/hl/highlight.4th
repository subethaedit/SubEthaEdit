(

  Example File for ANS Forth Syntax Highlighting

  6th December 2011 Mark Corbin <mark@dibsco.co.uk>

  Version 1.0 06-12-11
    - Initial release.

)

\ This is a single line comment.

( This
is
a 
multi-line
comment )

\ Single Characters
char A
[char] B

\ Strings
." Display this string."
s" Compile this string."
abort" This is an error message."
word parsethisstring
c" Compile another string."
parse parsethisstringtoo  
.( Display this string too.)

\ Constants and Variables
variable myvar
2variable mydoublevar
constant myconst
2constant mydoubleconst
value myval
20 to myval
fvariable myfloatvar
fconstant myfloatconst
locals| a b c d|

\ Single Numbers
123
-123

\ Double Numbers
123.
12.3
-123.
-12.3


\ Floating Point Numbers
1.2e3
-1.2e3
12e-3
+12e-3
-12e-3
+12e+3

\ Keywords (one from each list)
dup
roll
flush
scr
dnegate
2rot
catch
abort
at-xy
time&date
file-size
rename-file
fround
fsincos
(local)
locals| |
allocate
words
assembler
search-wordlist
order
/string


\ Obsolete Keywords (one from each list)
tib
forget

\ Simple Word Definition

: square ( n1 -- n2 )
  dup         \ Duplicate n1 on top of stack.
  *           \ Multiply values together leaving result n2.
;

\ Words that Define New Words or Reference Existing Words

create newword
marker newmarker
[compile] existingword
see existingword
code newcodeword
forget existingword

\ Loop Constructs

: squares ( -- )
  10 0 do
    i
    dup 
    * 
    .
  loop
;

: forever ( -- )
  begin
    ." This is an infinite loop."
  again
;


variable counter
0 counter !

: countdown ( -- )
  begin
    counter @           \ Fetch counter
    dup .               \ Display count value
    1- dup counter !    \ Decrement counter
    0=                  \ Loop until counter = 0
  until
;

: countup ( -- )
  begin
    counter @           \ Fetch counter
    dup .               \ Display count value
    10                  
    <
  while
    1 counter +!        \ Increment counter if < 10
  repeat
;

\ Conditional Constructs

: testnegative ( n -- )
  0< if
    ." Number is negative"
  then
;


variable flag
0 flag !

: toggleflag ( -- )
  flag @ if               \ Fetch flag and test
    ." Flag is true."
    0 flag !              \ Set flag to false
  else
    ." Flag is false."
    1 flag !              \ Set flag to true
  then
;


: translatenumber ( n -- )
  case
    1 of
      ." Eins"
    endof
    2 of
      ." Zwei"
    endof
    3 of
      ." Drei"
    endof
    ." Please choose a number between 1 and 3."
  endcase
;

\ END OF FILE
