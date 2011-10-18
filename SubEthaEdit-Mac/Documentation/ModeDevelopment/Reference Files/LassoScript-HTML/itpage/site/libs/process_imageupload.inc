<?Lassoscript
// Last modified 3/8/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Processes uploaded images
// NOTE ABOUT FLASH FILES: .swf files cannot be processed as media files, because we cannot build a preview.
//		Instead, they are handled by the Files upload and are treated as any other file.

// CHANGE NOTES
// 10/30/07
// First implementation
// Minor debugging output changes
// 4/30/08
// Increased medium height and width to 400 px
// 9/20/08
// Fixed broken video upload functionality
// 9/30/08
// Changing where the poster frame is grabbed.
// 12/3/08
// Making much more robust. Deleting temp files, MediaConvertErrorsArray for checking errors thrown by ffmpeg,
// more thorough logging, revise filetpes accepted
// 12/24/08
// Changed move of processed file to $svImagesUploadProcessedPath
// 6/5/09
// Finishing Flash (.flv, .swf) upload code
// Split processing into two includes, as it was getting too confusing
// 10/22/09
// Added client IP and Error_CurrentError to logging
// 3/8/10
// Moved images sizes to siteconfig (e.g. $svImageLargeWidth)

// Debugging
// Var:'svDebug' = 'Y';

// GENERAL NOTES
// This command REFUSES to overwrite a file, do not use it
// File_ProcessUploads: -Destination=(#destPath), -FileOverwrite;

// VERSION NOTES
// This has been tested with:
// 		ImageMagick v. 6.5.0
//		PassThru 2.5.7
//		Lasso 8.5.6
// 		ffmpeg v. 19548 downloaded on 11/28/08

// Defining thumbnail sizes
Local:'largewidth' = integer;
Local:'largeheight' = integer;
Local:'mediumwidth' = integer;
Local:'mediumheight' = integer;
Local:'thumbwidth' = integer;
Local:'thumbheight' = integer;
Local:'largewidth' = $svImageLargeWidth;
Local:'largeheight' = $svImageLargeHeight;
Local:'mediumwidth' = $svImageMediumWidth;
Local:'mediumheight' = $svImageMediumHeight;
Local:'thumbwidth' = $svImageThumbWidth;
Local:'thumbheight' = $svImageThumbHeight;
Local:'converting' = string;
// Used to indicate whether the original is too small to resize.
// If ResizeOK is true, the original is large and can be resized
// If it is false, the original is small and will not be resized
Local:'ResizeOK' = true;
// Used to provide a comment about resize check
Local:'ResizeComment' = string;
// Vars for ImageMagick command strings
Local:'MakeLarge' = string;
Local:'MakeMedium' = string;
Local:'MakeThumb' = string;
// fileReal is the actual file name, e.g. P1003852.jpg
// fileName is the name of the temporary file Lasso creates, e.g. "// /var/tmp/lasso0tmpH0QIPH46243328.uld"
// fileField is the name of the form element for the file that was uploaded
// destPath is the upload directory
// ProcessedPath is the path where high-res files are stored after they are processed
Local:'destPath' = string;
Local:'processedPath' = string;
Local:'thisFile' = string;
Local:'fileName' = string;
Local:'fileType' = string;
Local:'fileSize' = string;
Local:'fileReal' = string;
Local:'fileRealRaw' = string;
Local:'fileField' = string;
// Used to store the image filename being processed
Local:'ThisFilePathSource' = string;
Local:'ThisFilePath' = string;
Local:'NewFileName' = string;
Local:'FilePrefix' = string;
Local:'FileExt' = string;
Local:'FilenameJoined' = string;
// IMAGE upload directories; This is the upload folder path from web root
Local:'ULPath_ImageLargeOUT' = string;
Local:'ULPath_ImageMedOUT' = string;
Local:'ULPath_ImageThumbOUT' = string;
// MEDIA (Audio and Video) upload directories; This is the upload folder path from web root
Local:'ULpath_MediaLargeOUT' = string;
Local:'ULpath_MediaMedOUT' = string;
Local:'ULpath_MediaThumbOUT' = string;
// Used for Media output filename
Local:'NewFileNamePrefix' = string;
Local:'NewFileNameFinal' = string;
// Used for "Poster" frame (a .png file) that is fed to image previews routine in process_imagepreviews.inc
Local:'NewFileNamePoster' = string;
Local:'TypeofUpload' = string;
// Used to Stop Processing if there are unrecoverable errors
Local:'KeepGoing' = true;
// Used for copying
Local:'CopyFrom' = string;
Local:'CopyTo' = string;
// Used to store various error messages from ffmpeg. Encountering one of these will result in a corrupt file,
// so we need to STOP processing
// THIS MESSAGE IS OK, and results from a "ffmpeg -i" command
// "At least one output file must be specified"
Var:'MediaConvertErrorsArray' = (array:
	'Error while opening codec for output stream',
	'Audio resampler only works with 16 bits per sample, patch welcome.',
	'audio object type 23 not supported');
// Used to acquire information from images
Local:'ImgInfoHeight' = string;
Local:'ImgInfoWidth' = string;

// Disabled these - declaring these does no good as they are returned as bytes from PassThru
// Local:'height' = integer;
// Local:'width' = integer;

// Used to pass errors
Var:'vError' = string;
Var:'vOption' = string;

Inline: -Username=$svSiteUsername, -Password=$svSitePassword;

	If: (File_Uploads->Size != 0);

		// Initialize Log Files
		// Create log file uniquely named by date if it does not already exist
		Var('svLogDate' = (Date_Format:(Date_GetCurrentDate),-DateFormat='%m%d%Y'));
		Var('svLogFile' = ('/logs/uploadlog' ($svLogDate) '.log'));
		If: (!File_Exists($svLogFile));
			File_Create($svLogFile);
			File_Chmod:($svLogFile), -u='rwx', -g='rwx', -o='rx';
		/If;
		// Write the Logfile header
		Log: ($svLogFile);
			'\n';
			'========== START UPLOAD ==========\n';
			'   Date:      ' (Server_Date: -Extended) ' ' (Server_Time: -Extended) '\n';
			'   Client IP: ' (Client_IP) '\n';
		/Log;

		Iterate: (File_Uploads), #thisFile;

			#fileName = #thisFile->(Find: 'upload.name');
			#fileType = (#thisFile->(Find: 'upload.type')->split:'/')->last;
			#fileSize = #thisFile->(Find: 'upload.size');
			#fileField = #thisFile->(Find: 'upload.fieldname');
			#fileRealRaw = #thisFile->(Find: 'upload.realname');
			Debug;
				'81: fileName = '#fileName '<br>\n';
				'81: fileType = '#fileType '<br>\n';
				'81: fileSize = '#fileSize '<br>\n';
				'81: fileField = '#fileField '<br>\n';
				'81: fileRealRaw = '#fileRealRaw '<br>\n';
			/Debug;

			// svDocExtArray contains a list of all allowed file extensions
			// svImageExtArray contains a list of all allowed image extensions
			// svMediaExtArray contains a list of all allowed image extensions
			// These are defined in the siteconfig
			Debug;
				'90: svDocExtArray = ' ($svDocExtArray) '<br>\n';
				'90: svImageExtArray = ' ($svImageExtArray) '<br>\n';
				'90: svMediaExtArray = ' ($svMediaExtArray) '<br>\n';
			/Debug;

			// Clean up the filename
			#fileReal =
				(String_ReplaceRegExp:(Encode_StrictURL: #fileRealRaw->(Split:'\\')->Last),
				-Find='%[\\da-f]{2}',-Replace='');
			#fileReal->Trim;

			// Grab the prefix for the file (everything before the .) and build a new unique outfile name	
			// Use the original file extension
			#FilePrefix = (#fileReal->(Split: '.'));
			// Copy the last array element to be the extension
			#FileExt = (#FilePrefix->Last);
			// Remove the last element of the array, which contains the extension
			#FilePrefix->RemoveLast;
			// Join the rest of the array into a new FilenameJoined
			#FilenameJoined = (#FilePrefix->join);
			Debug;
				'118: fileReal = ' (#fileReal) '<br>\n';
				'118: FilePrefix = ' (#FilePrefix) '<br>\n';
				'118: FileExt = ' (#FileExt) '<br>\n';
				'118: FilenameJoined = ' (#FilenameJoined) '<br>\n';
			/Debug;

			// -----------------------------------------------//
			// "Image" Filetype?
			// -----------------------------------------------//
			If: ($svImageExtArray->contains(#FileExt));
			
				// Set Type of Upload and Destination Path
				#TypeofUpload = 'Image';
				#destPath = $svImagesUploadPath;
				#processedPath = $svImagesUploadProcessedPath;

				// Grab the prefix for the file (everything before the .) and build a new unique outfile name	
				Local:'FilePrefix' = (#fileReal->(Split: '.'));
				#NewFileName = ((#FilePrefix->Get:1) '_' (Create_UIDShort) '.jpg');
		
				// Concatonate the path and filename
				// Filepath to the uploaded file should be something like "/uploads/P10839275.jpg"
				#ThisFilePath = (#destPath) (#NewFileName);
				Debug;
					'207: ThisFilePath = ' (#ThisFilePath) '<br>\n';
				/Debug;
	
				// Create the source file
				File_Create: (#ThisFilePath), -FileOverWrite;
				File_Write: (#ThisFilePath), (File_Read: (#fileName));
	
				// Create thumb, medium, and large image preview for Images and Media filetypes
				Include:($svLibsPath)'process_imagepreviews.inc';
	
				// Archive the original upload file, if this option is set in the siteconfig
				If: $svArchiveOriginalUpload == True;
	
					#CopyFrom = ((#destPath) (#NewFileName));
					#CopyTo = ((#processedPath) (#NewFileName));
					Debug;
						'211: CopyFrom: ' #CopyFrom '<br>\n';
						'211: CopyTo: ' #CopyTo '<br>\n';
					/Debug;
					File_Copy: $CopyFrom, $CopyTo, -FileOverWrite;
	
				/If;
	
				// Delete the original file
				File_Delete: (#ThisFilePath);

				// If copy fails, set $vError to 7102 "File Upload Error" and redirect
				If: ((File_CurrentError: -ErrorCode) != '0') || ((Error_CurrentError: -ErrorCode) != '0');
					Var:'vError' = '7102';
					Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error=7102');
			
					If: $svDebug == 'Y';
						'244: URL = <a href="' $URL '">' $URL '</a><br>';
						Abort;
					Else;
						Redirect_URL: $URL;
					/If;
			
				// Else assume upload successful, set vError to 7100 "Upload Successful" and option to NewFileName
				Else;
					Var:'vError' = '7100';
					Var:'vOption' = (#NewFileName);
				/If;

			// -----------------------------------------------//
			// "Video" filetype?
			// -----------------------------------------------//
			Else: ($svMediaExtArray->contains(#FileExt));

				// Set Type of Upload and Destination Path
				#TypeofUpload = 'Media';
				#destPath = $svMediaPath;
				#processedPath = null;
			
				// Create the new filenames
				#NewFileNamePrefix = ((#FilenameJoined) '_' (Create_UIDShort));
				#NewFileName = ((#NewFileNamePrefix)'.'(#FileExt));
				#NewFileNameFinal = ((#NewFileNamePrefix)('.flv'));
				#NewFileNamePoster = ((#NewFileNamePrefix)('.png'));
				// Concatonate the path and filename
				#ThisFilePathSource = (#destPath) (#NewFileName);
				#ThisFilePath = (#destPath) (#NewFileNameFinal);
				Debug;
					'295: NewFileNamePrefix = ' (#NewFileNamePrefix) '<br>\n';
					'295: NewFileName = ' (#NewFileName) '<br>\n';
					'295: NewFileNameFinal = ' (#NewFileNameFinal) '<br>\n';
					'295: ThisFilePathSource = ' (#ThisFilePathSource) '<br>\n';
					'295: ThisFilePath = ' (#ThisFilePath) '<br>\n';
				/Debug;

				// Create the source file
//				File_Create: (#ThisFilePath), -FileOverWrite;
//				File_Write: (#ThisFilePath), (File_Read: (#fileName));
				File_Create: (#ThisFilePathSource), -FileOverWrite;
				File_Write: (#ThisFilePathSource), (File_Read: (#fileName));

				// Log the File Info
				Log: ($svLogFile);
					'fileType = '#fileType '\n';
					'fileSize = '#fileSize '\n';
					'fileRealRaw = '#fileRealRaw '\n';
				/Log;

				// -----------------------------------------------//
				// Determine if we have a .swf file or something else
				// -----------------------------------------------//
				// Checking EITHER Filetype OR FileExt, "just in case" one isn't set correctly
				If:(#filetype == 'x-shockwave-flash') || (#FileExt == 'flv') || (#FileExt == 'swf'); 
					// PROCESS SWF
					Include(($svLibsPath)('process_swf.inc'));
				Else;
					// PROCESS FLV
					Include(($svLibsPath)('process_video.inc'));
				/If;

				// If there is a file error, set $vError to 7102 "File Upload Error" and redirect
				If: ((File_CurrentError: -ErrorCode) != '0') || ((Error_CurrentError: -ErrorCode) != '0');
					Var:'vError' = '7102';
					Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error='($vError)'');
			
					If: $svDebug == 'Y';
						'599: URL = <a href="' $URL '">' $URL '</a><br>';
						Abort;
					Else;
						Redirect_URL: $URL;
					/If;
			
				// Else assume upload successful, set vError to 7100 "Upload Successful" and option to NewFileName
				Else;
					Var:'vError' = '7100';
					Var:'vOption' = (#NewFileName);
				/If;


			// -----------------------------------------------//
			// Not Image or Video, redirect with error
			// -----------------------------------------------//
			Else;
				$vError = '5060';
				Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error='($vError));

				If: $svDebug == 'Y';
					'622: URL = ' $URL '<br>\n';
					'<a href="'$URL'">' $URL '</a><br>\n';
					Abort;
				Else;
					Redirect_URL: $URL;
				/If;
			/If;

		/iterate;

	// File not uploaded because upload size = 0, so set $vError to 7102 "File Upload Error" and redirect
	Else;
		Var:'vError' = '7102';
		// Var:'vOption' = (#NewFileName);
		Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error='$vError);

		If: $svDebug == 'Y';
			'640: URL = <a href="'$URL'">' $URL '</a><br>\n';
			Abort;
		Else;
			Redirect_URL: $URL;
		/If;
	/If;

// Write the Logfile header
Log: ($svLogFile);
	'   Filename:  ' (#fileReal) '\n';
//	'   Error = ' (Error_CurrentError) '\n';
	'========== END UPLOAD ==========\n';
/Log;

/inline;

?>
