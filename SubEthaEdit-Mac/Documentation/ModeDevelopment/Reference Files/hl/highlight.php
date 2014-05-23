<?
/* This is a pseudo PHP file to test Kate's PHP syntax highlighting. */
# TODO: this is incomplete, add more syntax examples!
# this is also a comment.
// Even this is a comment
function test($varname) {
	return "bla";	# this is also a comment
}

?>

<?php echo("hello test"); ?>

<html>
	<? print "<title>test</title>"; ?>
</html>

<?php
$var = <<<DOOH
This is the $string inside the variable (which seems to be rendered as a string)
It works well, I think.
DOOH
?>

<?php

$test = <<<EOT

$foo bar

EOT

$test = <<<"EOT"

$foo bar

EOT

$test = <<<'EOT'

$foo bar

EOT

//html
$test = <<<EOHTML

<tag>$tag</tag>
<$tag>$foo</$tag>

EOHTML

$test = <<<"EOHTML"

<tag>$tag</tag>
<$tag>$foo</$tag>

EOHTML

$test = <<<'EOHTML'

<tag>$tag</tag>

EOHTML

//css
$test = <<<EOCSS

$class {
        $foo: $bar
}
.class {
        color: $color
}

EOCSS

$test = <<<"EOCSS"

$class {
        $foo: $bar
}
.class {
        color: $color
}

EOCSS

$test = <<<'EOCSS'

.class {
        color: $color
}

EOCSS

//javascript
$test = <<<EOJAVASCRIPT

var foo = "$foo";
function $bar() {
        $baz;
}

EOJAVASCRIPT

$test = <<<"EOJAVASCRIPT"

var foo = "$foo";
function $bar() {
        $baz;
}

EOJAVASCRIPT

$test = <<<'EOJAVASCRIPT'

var foo = "$foo";
function $bar() {
        $baz;
}

EOJAVASCRIPT

//mysql
$test = <<<EOMYSQL

SELECT $foo FROM $bar WHERE id = $baz;

EOMYSQL

$test = <<<"EOMYSQL"

SELECT $foo FROM $bar WHERE id = $baz;

EOMYSQL

$test = <<<'EOMYSQL'

SELECT $foo FROM $bar WHERE id = $baz;

EOMYSQL

//no EO

//html
$test = <<<HTML

<tag>$tag</tag>

HTML

$test = <<<"HTML"

<tag>$tag</tag>

HTML

$test = <<<'HTML'

<tag>$tag</tag>

HTML

//css
$test = <<<CSS

.class {
        color: $color
}

CSS

$test = <<<"CSS"

.class {
        color: $color
}

CSS

$test = <<<'CSS'

.class {
        color: $color
}

CSS

//javascript
$test = <<<JAVASCRIPT

var foo = "$foo";
function $bar() {
        $baz;
}

JAVASCRIPT

$test = <<<"JAVASCRIPT"

var foo = "$foo";
function $bar() {
        $baz;
}

JAVASCRIPT

$test = <<<'JAVASCRIPT'

var foo = "$foo";
function $bar() {
        $baz;
}

JAVASCRIPT

//mysql
$test = <<<MYSQL

SELECT $foo FROM $bar WHERE id = $baz;

MYSQL

$test = <<<"MYSQL"

SELECT $foo FROM $bar WHERE id = $baz;

MYSQL

$test = <<<'MYSQL'

SELECT $foo FROM $bar WHERE id = $baz;

MYSQL

?>