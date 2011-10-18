<?Lassoscript
// Last modified 6/4/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_MediaGetInfo }
	{Description=		Gets information about a video file }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				12/4/08 }
	{Usage=				LI_MediaGetInfo: -Filepath=$ThisFile
						LI_MediaGetInfo: -Filepath=($svMediaPath)'networking_480x376_6NU.flv')
						Important: -Filepath is webserver root relative }
	{ExpectedResults=	If a .flv, builds a map ($VideoInfoMap) containing information about the video
						If a .swf, builds a map ($SWFInfo) of all the information relating the SWF file }
	{Dependencies=		Uses PassThru and ffmpeg
						Uses FlowPlayerLight.swf, which must be in the /site/libs folder and /site/js/flashembed.min.js }
	{DevelNotes=		See proof of concept "media.lasso"
						See below for sample output of #movie_info which contains the movie metadata }
	{ChangeNotes=		6/4/09
						Added processing of .swf files. New variable $SWFInfo has various bits of information about the .swf file. }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI_';

If:!(Lasso_TagExists:'LI_MediaGetInfo');
	Define_Tag: 'MediaGetInfo',
		-Description='Gets information about a video file',
		-Required='Filepath',
		-namespace=$svCTNamespace,
		-Priority='Replace';

		Inline: -Username=$svSiteUsername, -Password=$svSitePassword;

		Local:'MediaFilepathCheck' = (($svMediaPath)(#Filepath));
		Local:'MediaFilepathRoot' = (($svWebserverRoot)(#MediaFilepathCheck));
		Local:'MediaFileExists' = File_Exists:(#MediaFilepathCheck);
		Local('PassThruGetMediaInfo' = string);
		Local('Result' = string);
		Var:'VideoInfoMap' = map;
	
		If: $svDebug == 'Y';
			#Result += (
					'<p class="debugCT">\n'
					'<strong>LI_MediaGetInfo</strong><br>\n'
					);
			#Result += ('<strong>45: MediaFilepathCheck</strong> = ' #MediaFilepathCheck '<br>\n');
			#Result += ('<strong>45: MediaFilepathRoot</strong> = ' #MediaFilepathRoot '<br>\n');
		/If;
	
		// If media exists, get the dimensions
		If: #MediaFileExists == true;
		
			// Check for .swf file, which requires using swfdump instead of ffmpeg
			If: #Filepath->EndsWith('swf');

				// Build the filename
				
				// Used to build a map of all the information relating to a SWF file
				Var('SWFInfo' = map);
				// Used to capture information from the SWF file (names self-explanatory)
				Local('SWFWidth' = string);
				Local('SWFHeight' = string);
				Local('SWFRate' = string);
				Local('SWFFrames' = string);
				Local('SWFHTML' = string);			
				
				// Get the width
				#SWFWidth = (Passthru(($svPathToswftools)' --width "'(#MediaFilepathRoot)'"'));
			
				// Check if swfdump failed
				If: #SWFWidth >> 'command not found';
					Var:'vError' = '9001';
					Var:'vOption' = 'Swfdump not installed, aborting.';
					LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
			
//					'Error_CurrentError = ' (Error_CurrentError) '<br>\n';
//					'File_CurrentError = ' (File_CurrentError) '<br>\n';
			
					Abort;
			
				Else;
			
					#SWFHeight = (Passthru(($svPathToswftools)' --height "'(#MediaFilepathRoot)'"'));
					#SWFRate = (Passthru(($svPathToswftools)' --rate "'(#MediaFilepathRoot)'"'));
					#SWFFrames = (Passthru(($svPathToswftools)' --frames "'(#MediaFilepathRoot)'"'));
					#SWFHTML = (Passthru(($svPathToswftools)' --html "'(#MediaFilepathRoot)'"'));
				
					// Clean the data - no need to clean #SWFHtml
					#SWFwidth = (String_Replace: -Find='-X ', -Replace='', #SWFWidth);
					#SWFHeight =  (String_Replace: -Find='-Y ', -Replace='', #SWFHeight);
					#SWFRate =  (String_Replace: -Find='-r ', -Replace='', #SWFRate);
					#SWFFrames =  (String_Replace: -Find='-f ', -Replace='', #SWFFrames);
			
					// Trim excess white space
					#SWFwidth->trim;
					#SWFHeight->trim;
					#SWFRate->trim;
					#SWFFrames->trim;
			
					// Insert into the map
					$SwfInfo->Insert('SWFWidth' = #SWFWidth);
					$SwfInfo->Insert('SWFHeight' = #SWFHeight);
					$SwfInfo->Insert('SWFRate' = #SWFRate);
					$SwfInfo->Insert('SWFFrames' = #SWFFrames);
					$SwfInfo->Insert('SWFHTML' = #SWFHTML);
					
					Debug;
						#Result += ('SWFWidth = ' (#SWFWidth) '<br>\n');
						#Result += ('SWFHeight = ' (#SWFHeight) '<br>\n');
						#Result += ('SWFRate = ' (#SWFRate) '<br>\n');
						#Result += ('SWFFrames = ' (#SWFFrames) '<br>\n');
						#Result += ('SWFHTML = ' (Output:#SWFHTML, -EncodeHTML) '<br>\n');
						#Result += ('SWFInfo = ' ($SWFInfo) '<br>\n');
						#Result += ('Error_CurrentError = ' (Error_CurrentError) '<br>\n');
						#Result += ('File_CurrentError = ' (File_CurrentError) '<br>\n');
					/Debug;
			
				/If;

			// File is not .swf, so use ffmpeg
			Else;


				//	Local('MediaWidth' = '320');
				//	Local('MediaHeight' = '240');
			
				// Copied from process_imageupload.inc - Around lines 246-298
				// -------------------------------------------------------------//
				// Define vars for movie info and PassThru commands
				Local('movie_info') = string;
				
				// WORKS #movie_info = (PassThru:('/usr/local/bin/ffmpeg -i "' '///Library/Webserver/Documents/landmanninteractive.com' (#ThisFile) '"'));
				/* TYPICAL OUTPUT BELOW
				316: movie_info = FFmpeg version SVN-r7433, Copyright (c) 2000-2006 Fabrice Bellard, et al.
				configuration: libavutil version: 49.1.0 libavcodec version: 51.28.0 libavformat version: 51.7.0
				built on Jan 10 2007 11:48:03, gcc: 3.3 20030304 (Apple Computer, Inc. build 1666) [mov,mp4,m4a,3gp,3g2,mj2 @ 0x3193a4]
				negative ctts, ignoring Input #0, mov,mp4,m4a,3gp,3g2,mj2, from '/Library/Webserver/Documents/landmanninteractive.com/media/networking_480x376_6NU.flv':
				Duration: 00:00:31.0, start: 0.000000, bitrate: 659 kb/s
				Stream #0.0(eng): Video: h264, yuv420p, 480x360, 23.98 fps(r)
				Stream #0.1(eng): Audio: mp4a / 0x6134706D, 44100 Hz, stereo
				Stream #0.2(eng): Data: tmcd / 0x64636D74
				Must supply at least one output file  */
	
/*
movie_info = FFmpeg version UNKNOWN, Copyright (c) 2000-2008 Fabrice Bellard, et al.
  configuration: --disable-altivec --enable-libmp3lame --disable-vhook --enable-shared --disable-mmx --enable-libfaac --enable-libfaad --enable-gpl
  libavutil     49.12. 0 / 49.12. 0
  libavcodec    52. 3. 0 / 52. 3. 0
  libavformat   52.23. 1 / 52.23. 1
  libavdevice   52. 1. 0 / 52. 1. 0
  built on Dec  1 2008 13:41:46, gcc: 4.0.1 (Apple Computer, Inc. build 5370)

Seems stream 0 codec frame rate differs from container frame rate: 1000.00 (1000/1) -> 25.00 (25/1)
Input #0, flv, from '/Library/Webserver/Documents/landmanninteractive.com/media/bear3.flv':
Duration: 00:00:30.17, start: 0.000000, bitrate: 64 kb/s
Stream #0.0: Video: flv, yuv420p, 352x288, 25.00 tb(r)
Stream #0.1: Audio: mp3, 22050 Hz, mono, s16, 64 kb/s
At least one output file must be specified
*/
				Protect;
					#PassThruGetMediaInfo = ($svPathToffmpeg' -i "'($svWebserverRoot)($svMediaPath)(#Filepath)'"');
					#movie_info = (PassThru:(#PassThruGetMediaInfo));
					If: $svDebug == 'Y';
						#Result += '<strong>103: PassThruGetMediaInfo</strong> = ' #PassThruGetMediaInfo '<br>\n';
						#Result += '<strong>103: movie_info</strong> = ' #movie_info '<br>\n';
					/If;
					
					// Establish if the file is Video, Audio, or Unsupported
					// Look for Video first, if no video then check for audio
					If((string_findregexp:#movie_info, -find='Video') -> size > 0); 
						Local('filetype' = 'Video'); 
					Else((string_findregexp:#movie_info, -find='Audio') -> size > 0); 
						Local('filetype' = 'Audio'); 
					// OVERRIDE - If file ends with .flv, tag it as a Flash Video file
					Else: (#FilePath->EndsWith('.flv'));
						Local('filetype' = 'FlashVideo'); 
					Else; 
						Local('filetype' = 'Unknown');
					/If; 
					If: $svDebug == 'Y';
						#Result += ('117: filetype = ' #filetype '<br>\n');
					/If;
			
					// Declare variables for Video-Specific details 
					Local('dimensions' = string); 
					Local('width' = string); 
					Local('height' = string); 
	//				Local('fps' = string); 
					Local('duration' = string);
			  
					If: (#filetype == 'Video') || (#filetype == 'FlashVideo'); 
					
					// NOT USING THIS METHOD, but code might be useful in future
	/*					Local:'dimensions_temp' = (string_findregexp: #movie_info, -find='Video: [^x]*x[^,]*'); 
						Local:'fps_temp' = (string_findregexp: #movie_info, -find='Video:[^f]* fps'); 
						#fps = (#fps_temp -> get:1 -> split:' '); 
						Local:'fps_x'=(#fps -> size); 
						#fps = (#fps -> get:(#fps_x - 1)); 
	*/
						// Get the dimensions straight from #movie_info
						Local:'dimensions_array' = (array); 
						#dimensions_array = (string_findregexp:#movie_info, -find=' (\\d+)x(\\d+),');
						If: $svDebug == 'Y';
							#Result += ('114: dimensions_array = ' #dimensions_array '<br>\n');
						/If;
						If:(#dimensions_array -> size == 3); 
							#dimensions = (#dimensions_array -> get: 1); 
							// Trim extra spaces and trailing comma
							#dimensions->trim; 
							#dimensions->RemoveTrailing(',');
							#width = (#dimensions_array -> get: 2); 
							#height = (#dimensions_array -> get: 3); 
						/If;
			
						// Declare variables for general audio/video details 
						Local:'duration_temp' = (string_findregexp: #movie_info, -find='Duration: [^ ,]*'); 
						Local:'duration_display' = string; 
						Local:'duration' = decimal; 
						Local:'seconds' = decimal; 
			//			Local:'halftime' = duration; 
						
						If:(#duration_temp -> size > 0); 
						 
							#duration_display = (string_removeleading:(#duration_temp -> get:1), -pattern='Duration: '); 
							#seconds = #duration_display -> split:':' -> last; 
							#duration_display=(duration:#duration_display); 
						 
							// calculate duration in seconds with decimal value to accurately grab frame interval rate 
							#duration = (#duration_display->second); 
							#duration = (#duration - (integer:#seconds)); 
							#duration = (decimal:#duration) + (decimal:#seconds); 
			//				#halftime = (duration(integer(#duration / 2))); 
						 
						/If; 
			
						// Insert information into the map
						$VideoInfoMap->Insert('filetype' = #filetype);
						$VideoInfoMap->Insert('dimensions' = #dimensions);
						$VideoInfoMap->Insert('width' = #width);
						$VideoInfoMap->Insert('height' = #height);
	//					$VideoInfoMap->Insert('fps' = #fps);
						$VideoInfoMap->Insert('duration' = #duration);
			
					/If;
	
				/Protect;
		
				// If $VideoInfoMap is empty, return error 7023 "Media Error"	
				If: $VideoInfoMap == (map);
					Var:'vError' = '7023';
					Var:'vOption' = 'Media file cannot be read.';
				/If;
	
				// If debugging is on, output the map
				If: $svDebug == 'Y';
					#Result += ('<strong>216: VideoInfoMap</strong> = ' $VideoInfoMap '<br>\n');
					#Result += ('<strong>216: Filepath</strong> = ' #Filepath '<br>\n');
					#Result += ('216: MediaFileExists = ' #MediaFileExists '<br>\n');
					#Result += ('216: filetype = ' #filetype '<br>\n');
					#Result += ('216: dimensions = ' #dimensions '<br>\n');
					#Result += ('216: width = ' #width '<br>\n');
					#Result += ('216: height = ' #height '<br>\n');
		//			#Result += ('216: fps = ' #fps '<br>\n');
					#Result += ('216: duration = ' #duration '</p>\n');
					Return: (Encode_Smart:(#Result));
					Return: (Encode_Smart:($VideoInfoMap));
				Else;
					Return: $VideoInfoMap;
				/If;

		 	/If;

		// If a problem with the filename, throw error 
		Else;
			$vError = '5061';
		/If;
	
	/Inline;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_MediaGetInfo';

/If;

?>