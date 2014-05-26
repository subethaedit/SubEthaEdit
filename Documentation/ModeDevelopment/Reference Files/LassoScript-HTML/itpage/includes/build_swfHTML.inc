<?Lassoscript
// Last modified 6/6/09 by ECL

// FUNCTIONALITY
// This file builds the object/embed HTML code for a .swf file

// DEPENDENCIES
// It is expected that the video vars exist.
// These are fetched with LI_MediaGetInfo.
// See /admin/media.lasso for an example

// CHANGE NOTES
// 6/6/09
// First implementation

Var('swfHTML' = string);

$swfHTML += '<OBJECT CLASSID="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
	WIDTH="'($VideoWidth)'"
	HEIGHT="'($VideoHeight)'"
	CODEBASE="http://active.macromedia.com/flash5/cabs/swflash.cab#version=9,0,0,0">
	<PARAM NAME="MOVIE" VALUE="'($svMediaPath)($ThisMediaFile)'">
	<PARAM NAME="PLAY" VALUE="true">
	<PARAM NAME="LOOP" VALUE="true">
	<PARAM NAME="QUALITY" VALUE="high">
	<EMBED SRC="'($svMediaPath)($ThisMediaFile)'" WIDTH="'($VideoWidth)'" HEIGHT="'($VideoHeight)'"
		PLAY="true" ALIGN="" LOOP="true" QUALITY="high"
		TYPE="application/x-shockwave-flash"
		PLUGINSPAGE="http://www.macromedia.com/go/getflashplayer">
	</EMBED>
</OBJECT>
';
?>