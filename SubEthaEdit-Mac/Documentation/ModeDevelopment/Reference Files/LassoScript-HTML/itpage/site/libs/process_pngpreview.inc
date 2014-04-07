<?Lassoscript
// Last modified 6/12/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file creates .png previews from video files.
// it is called from process_video.inc and process_swf.inc

// CHANGE NOTES
// 6/12/09
// Moved this code into separate include as it is used in more than one place

// -----------------------------------------------//
// Create the SOURCE PNG image
// -----------------------------------------------//
// Construct the FFMpeg command to create the SOURCE PNG
// This is different than images because we are coming from video
// SAMPLE COMMAND
// /usr/Local/bin/ffmpeg -y -i "/Library/Webserver/Documents/landmanninteractive.com/media/FeingoldMilitaryCommActStmt_2EQ.flv" -vframes 1 -ss 3  -an -vcodec png -f rawvideo  -s 320x240 "/Library/Webserver/Documents/landmanninteractive.com/media/FeingoldMilitaryCommActStmt_2EQ.png
#PassThruCommand2 = ($svPathToffmpeg' -y -i "'($svWebserverRoot)(#ThisFilePathSource)'" ');
// This next command grabs a frame from the #halftime variable
// NOT using this now, instead we are doing in three seconds
// #PassThruCommand2 += ('-vframes 1 -ss '+(duration(#halftime)));
#PassThruCommand2 += ('-vframes 1 -ss 3 ');
#PassThruCommand2 += (' -an -vcodec png -f rawvideo ');
#PassThruCommand2 += ('"'($svWebserverRoot)(#DestPath)(#NewFileNamePoster)'"');
// Run it
#create_placeholder = (PassThru(#PassThruCommand2));
Debug;
	'566: <strong>passthrucommand2</strong> = ' #passthrucommand2 '<br>\n';
	'566: <strong>create_placeholder</strong> = ' #create_placeholder '<br>\n';
/Debug;

// Log the PassThru command
Log: ($svLogFile);
	'passthrucommand2 = ' (#passthrucommand2) '\n';
	'create_flv_outputfile = ' (#create_flv_outputfile) '\n';
	'\n';
/Log;

?>