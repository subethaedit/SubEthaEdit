
#!/bin/sh

if [ "a" != "b" ]; then
	foo
	echo "true"
else 
	echo "false"
fi

if [ "a" != "b" ]; then
	echo "true"
elif [ "1" -ge "2" ] 
	echo "false"
fi


elif
		
fi


"let me test this"

`this` still work\`s

echo "The # here does not begin a comment."
echo 'The # here does not begin a comment.'
echo The \# here does not begin a comment.
echo The # here begins a comment.

echo ${PATH#*:}       # Parameter substitution, not a comment.
echo $(( 2#101011 ))  # Base conversion, not a comment.


cd 265_Videos
for f in ../*.mov; do o=${f##*/}; ffmpeg -i $f -c:v libx265 -crf 25 -tag:v hvc1 ${o%.*}.h265.mp4; done

