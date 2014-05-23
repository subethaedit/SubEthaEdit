<?Lassoscript
// Last modified 6/12/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Process video file uploads

// TO DO
// More research on output from $i to trap various phrases (line 38)

// CHANGE NOTES
// 6/12/09
// Split off this routine into this file from process_imageupload.inc

// Debugging
// Var:'svDebug' = 'Y';

// Define vars for movie info and PassThru commands
Local('movie_info' = string);
Local('passthrucommand1' = string);
Local('passthrucommand2' = string);
Local('create_flv_outputfile' = string);
Local('create_placeholder' = string);

// -----------------------------------------------//
// Get info on the Movie
// -----------------------------------------------//
// SAMPLE COMMAND
// #movie_info = (PassThru:('/usr/local/bin/ffmpeg -i "' '///Library/Webserver/Documents/landmanninteractive.com' (#ThisFilePath) '"'));
#movie_info = (PassThru:($svPathToffmpeg' -i "'($svWebserverRoot)(#ThisFilePathSource)'"'));
Debug;
	'316: movie_info = ' #movie_info '<br>\n';
/Debug;

// Log the PassThru command
Log: ($svLogFile);
	'\n';
	'movie_info = ' (#movie_info) '\n';
/Log;

// Check for several error strings. If they exist, kill the process and return error 7023 "Media Error"
Iterate: $MediaConvertErrorsArray, (Var:'i'); 
	If: (#movie_info->contains(#i));

		// Set KeepGoing to false which we will use to kill the processing
		#KeepGoing = false;
		$vError = '7023';
		$vOption = 'The input video file\'s data cannot be converted.';
		Debug;
			'323: i = ' #i '<br>\n';
			'323: KeepGoing = ' #KeepGoing '<br>\n';
		/Debug;
	/If;
 /Iterate; 

Debug;
	'346: FileExt = ' #FileExt '<br>\n';
	'346: KeepGoing = ' #KeepGoing '<br>\n';
	'346: NewFileNameFinal = ' (#NewFileNameFinal) '<br>\n';
	'346: ThisFilePathSource = ' (#ThisFilePathSource) '<br>\n';
	'346: ThisFilePath = ' (#ThisFilePath) '<br>\n';
/Debug;

// -----------------------------------------------//
// CHECK TO ABORT
// -----------------------------------------------//
// If KeepGoing is false, redirect with error
If: #KeepGoing == false;

	// -----------------------------------------------//
	// DELETE FILES
	// -----------------------------------------------//
	// Delete original file
	File_Delete(#ThisFilePathSource);
		If: $svDebug == 'Y';
			'367: <strong>Deleting #ThisFilePathSource</strong><br>\n';
			'367: Deleting ' (#ThisFilePathSource) '<br>\n';
			'367: File_CurrentError = '(File_CurrentError)'<br>\n';
		/If;
	// THIS COMMENT IS WRONG
	// Delete .flv or .swf file
	File_Delete(#ThisFilePath);
		If: $svDebug == 'Y';
			'375: <strong>Deleting #ThisFilePath</strong><br>\n';
			'375: Deleting ' (#ThisFilePath) '<br>\n';
			'375: File_CurrentError = '(File_CurrentError)'<br>\n';
		/If;

	Log: ($svLogFile);
		'================================\n';
		'UPLOAD FAILED!';
		'Filename: ' (#ThisFilePathSource) '\n';
		'========== END UPLOAD ==========\n';
	/Log;

	Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error='($vError)'&Option='($vOption));
	If: $svDebug == 'Y';
		'389: URL = <a href="' $URL '">' $URL '</a><br>';
		Abort;
	Else;
		Redirect_URL: $URL;
	/If;
/If;

// Establish if the file is Video, Audio, or Unsupported: 
If((string_findregexp:#movie_info, -find='Video') -> size > 0); 
	Local('filetype' = 'Video'); 
Else((string_findregexp:#movie_info, -find='Audio') -> size > 0); 
	Local('filetype' = 'Audio'); 
Else; 
	Local('filetype' = 'Unknown');
/If; 
 
// Declare variables for Video-Specific details 
Local('dimensions' = string); 
Local('width' = string); 
Local('height' = string); 
Local('fps' = string); 


// -----------------------------------------------//
// Proceed if filetype is Video
// -----------------------------------------------//
If:(#filetype == 'Video'); 

	// -----------------------------------------------//
	// TO DO - More research on output from -i to trap various phrases
	// -----------------------------------------------//
	Protect;

		Local:'dimensions_temp' = (string_findregexp: #movie_info, -find='Video: [^x]*x[^,]*'); 
		Local:'fps_temp' = (string_findregexp: #movie_info, -find='Video:[^f]* fps'); 
	
		#fps = (#fps_temp -> get:1 -> split:' '); 
	
		Local:'fps_x'=(#fps -> size); 
		#fps = (#fps -> get:(#fps_x - 1)); 
	
		Local:'dimensions_array' = (array); 
	
		If:(#dimensions_temp -> size > 0); 
			#dimensions_array = (string_findregexp:(#dimensions_temp -> get:1), -find='(\\d+)x(\\d+)'); 
	
		/If; 
	   
		If:(#dimensions_array -> size == 3); 
			#dimensions = (#dimensions_array -> get: 1); 
			#width = (#dimensions_array -> get: 2); 
			#height = (#dimensions_array -> get: 3); 
		/If;

	/Protect;
					 
	// Declare variables for general audio/video details 
	Local('duration_temp' = (string_findregexp: #movie_info, -find='Duration: [^ ,]*'));
	Local('duration_display' = string);
	Local('duration' = decimal);
	Local('seconds' = decimal);
	Local('halftime' = duration);
	
	If:(#duration_temp -> size > 0); 
	 
		#duration_display = (string_removeleading:(#duration_temp -> get:1), -pattern='Duration: '); 
		#seconds = #duration_display -> split:':' -> last; 
		#duration_display=(duration:#duration_display); 
	 
		// calculate duration in seconds with decimal value to accurately grab frame interval rate 
		#duration = (#duration_display->second); 
		#duration = (#duration - (integer:#seconds)); 
		#duration = (decimal:#duration) + (decimal:#seconds); 
		// Changing definition of halftime to actually 1/4 of the way through the video
		#halftime = (duration(integer(#duration / 4))); 
	 
	 /If;
	
	// -----------------------------------------------//
	// Create the Flash Video output file
	// -----------------------------------------------//
	// Construct the FFMpeg command
	// SAMPLE COMMAND
	// /usr/Local/bin/ffmpeg -i "/Library/Webserver/Documents/landmanninteractive.com/media/FeingoldMilitaryCommActStmt_2EQ.flv" -acodec mp3 -ar 22050 -ab 32 -f flv -s 320x240 "/Library/Webserver/Documents/landmanninteractive.com/media/FeingoldMilitaryCommActStmt_2EQ.flv"
	// THIS WORKS 11/30/08
	// ffmpeg -y -i "Jadin Turns 7.mov" -ar 22050 -f flv "Jadin Turns 7.flv"
	// #passthrucommand1 = ($svPathToffmpeg' -i "'($svWebserverRoot)(#ThisFilePath)'" -acodec mp3');
	// #passthrucommand1 += (' -ar 22050 -ab 32 -f flv -s '+#width+'x'+#height) ' "'; 
	#passthrucommand1 = ($svPathToffmpeg' -y -i "'($svWebserverRoot)(#ThisFilePathSource)'" ');
	#passthrucommand1 += ('-ar 22050 -f flv ');
	// #passthrucommand1 += ('-ab copy ');
	#passthrucommand1 += ('-b 2048k ');
	#passthrucommand1 += ('"'($svWebserverRoot)(#DestPath)(#NewFileNameFinal) '"');
	// Run it
	#create_flv_outputfile = (passthru(#passthrucommand1));
	Debug;
		'491: <strong>passthrucommand1</strong> = ' #passthrucommand1 '<br>\n';
		'491: <strong>create_flv_outputfile</strong> = ' #create_flv_outputfile '<br>\n';
	/Debug;

	// Log the PassThru command
	Log: ($svLogFile);
		'passthrucommand1 = ' (#passthrucommand1) '\n';
		'create_flv_outputfile = ' (#create_flv_outputfile) '\n';
		'\n';
	/Log;


	// START REDUNDANT CODE
	// This is the same code as above, except for the variable being examined #create_flv_outputfile
	// Check for several error strings. If they exist, kill the process and return error 7023 "Media Error"
	Iterate: $MediaConvertErrorsArray, (Var:'i'); 
		If: (#create_flv_outputfile->contains(#i));

			// Set KeepGoing to false which we will use to kill the processing
			#KeepGoing = false;
			$vError = '7023';
			$vOption = 'The input video file\'s data cannot be converted.';
			Debug;
				'323: i = ' #i '<br>\n';
				'323: KeepGoing = ' #KeepGoing '<br>\n';
			/Debug;
		/If;
	 /Iterate;

	// -----------------------------------------------//
	// CHECK TO ABORT
	// -----------------------------------------------//
	// If KeepGoing is false, redirect with error
	If: #KeepGoing == false;

		// -----------------------------------------------//
		// DELETE FILES
		// -----------------------------------------------//
		// Delete original file
		File_Delete(#ThisFilePathSource);
			If: $svDebug == 'Y';
				'493: Deleting #ThisFilePathSource<br>\n';
				'493: File_CurrentError = '(File_CurrentError)'<br>\n';
			/If;
		// Delete .flv file
		File_Delete(#ThisFilePath);
			If: $svDebug == 'Y';
				'500: Deleting #ThisFilePath<br>\n';
				'500: File_CurrentError = '(File_CurrentError)'<br>\n';
			/If;

		Log: ($svLogFile);
			'================================\n';
			'UPLOAD FAILED!';
			'Filename: ' (#ThisFilePathSource) '\n';
			'========== END UPLOAD ==========\n';
		/Log;

		Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error='($vError)'&Option='($vOption));
		If: $svDebug == 'Y';
			'505: URL = <a href="' $URL '">' $URL '</a><br>';
			Abort;
		Else;
			Redirect_URL: $URL;
		/If;
	/If;
	// END REDUNDANT CODE

	// Make the .png preview
	Include:($svLibsPath)'process_pngpreview.inc';

	// -----------------------------------------------//
	// DELETE FILES
	// -----------------------------------------------//
	// Delete Source file
	File_Delete(#ThisFilePathSource);
		Debug;
			'573: Deleting ' (#ThisFilePathSource )'<br>\n';
			'573: File_CurrentError = '(File_CurrentError)'<br>\n';
		/Debug;

	// OVERRIDE #ThisFilePath and #NewFileName (VIDEO ONLY)
	#ThisFilePath = (($svMediaPath)(#NewFileNamePoster));
	#NewFileName = ((#NewFileNamePrefix)'.jpg');
	
	// Create thumb, medium, and large image preview for Images and Media filetypes
	Include:($svLibsPath)'process_imagepreviews.inc';


// Filetype NOT video, so now what?
Else;
	// FINISH THIS
	// Do something with Audio or "Other" filetypes
	// Probably want to create a source PNG like we do in process_swf.inc

/If;

?>