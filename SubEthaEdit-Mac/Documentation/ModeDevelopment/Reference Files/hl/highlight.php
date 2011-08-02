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