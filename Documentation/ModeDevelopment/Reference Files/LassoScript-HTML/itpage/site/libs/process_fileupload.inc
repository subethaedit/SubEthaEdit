<?Lassoscript
// Last modified 5/22/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Processes uploaded files

// CHANGE NOTES
// 10/30/07
// First implementation
// 5/20/08
// Minor debugging output tweaks
// 5/22/08
// Change upload process to deal with filenames containing multiple periods

// Debugging
// Var:'svDebug' = 'Y';

// GENERAL NOTES
// This command REFUSES to overwrite a file, do not use it
// File_ProcessUploads: -Destination=(#destPath), -FileOverwrite;

// VERSION NOTES
// This has been tested with ImageMagick v. 6.1.5 and PassThru 2.5.7 on Lasso 8.5.5
// SPECIAL NOTE FOR FILE UPLOADS: We are putting the uploaded files into the $svFilesUploadPath directory
//		and NOT moving them to a processed location (which has not been defined)

// fileReal is the actual file name, e.g. P1003852.jpg
// fileName is the name of the temporary file Lasso creates, e.g. "// /var/tmp/lasso0tmpH0QIPH46243328.uld"
// fileField is the name of the form element for the file that was uploaded
// destPath is the upload directory
// ProcessedPath is the path where high-res files are stored after they are processed
Local:'destPath' = $svFilesUploadPath;
// Local:'processedPath' = string;
Local:'thisFile' = string;
Local:'fileName' = string;
Local:'fileType' = string;
Local:'fileSize' = string;
Local:'fileReal' = string;
Local:'fileRealRaw' = string;
Local:'fileField' = string;

// Used to pass errors
Var:'vError' = '';
Var:'vOption' = '';

Inline: -Username=$svSiteUsername, -Password=$svSitePassword;

	If: (File_Uploads->Size != 0);
		Iterate: (File_Uploads), #thisFile;

			#fileName = #thisFile->(Find: 'upload.name');
			#fileType = (#thisFile->(Find: 'upload.type')->split:'/')->last;
			#fileSize = #thisFile->(Find: 'upload.size');
			#fileField = #thisFile->(Find: 'upload.fieldname');
			#fileRealRaw = #thisFile->(Find: 'upload.realname');

			If: $svDebug == 'Y';
				'<p class="debug">\n';
				'81: fileName = '#fileName '<br>\n';
				'81: fileType = '#fileType '<br>\n';
				'81: fileSize = '#fileSize '<br>\n';
				'81: fileField = '#fileField '<br>\n';
				'81: fileRealRaw = '#fileRealRaw '</p>\n';
			/If;

			// If fileType NOT .PDF, .DOC, .XLS, .PPS, .PPT, .QXD, or .INDDD, generate Error 5060 "Illegal filetype" error immediately and redirect to form
			// If: (#fileType != 'PDF') &&;
			// The above DOES NOT WORK, use this instead: (#filename->EndsWith('.mpg')
			If: (#filename->EndsWith:'.pdf') || (#filename->EndsWith:'.doc') || (#filename->EndsWith:'.xls') || 
				(#filename->EndsWith:'.pps') || (#filename->EndsWith:'.ppt') || (#filename->EndsWith:'.qxd') ||
				 (#filename->EndsWith:'.indd') || (#filename->EndsWith:'.csv') || (#filename->EndsWith:'.txt') || 
				 (#filename->EndsWith:'.ods') || (#filename->EndsWith:'.odp') || (#filename->EndsWith:'.odt') || 
				 (#filename->EndsWith:'.xml') || (#filename->EndsWith:'.zip') || (#filename->EndsWith:'.sit') || 
				 (#filename->EndsWith:'.sitx') ;
				$vError == '5060';
				Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error=5060');

				If: $svDebug == 'Y';
					'85: URL = ' $URL '<br>\n';
					'<a href="'$URL'">' $URL '</a><br>\n';
					Abort;
				Else;
					Redirect_URL: $URL;
				/If;
			/If;

			// Clean up the filename
			Local:'fileReal' =
				(String_ReplaceRegExp:(Encode_StrictURL: $fileRealRaw->(Split:'\\')->Last),
				-Find='%[\\da-f]{2}',-Replace='');
			#fileReal->Trim;

			// Grab the prefix for the file (everything before the .) and build a new unique outfile name	
			// Use the original file extension
			Local:'FilePrefix' = (#fileReal->(Split: '.'));
			// Copy the last array element to be the extension
			Local:'FileExt' = (#FilePrefix->Last);
			// Remove the last element of the array, which contains the extension
			#FilePrefix->RemoveLast;
			// Join the rest of the array into a new FilenameJoined
			Local:'FilenameJoined' = (#FilePrefix->join);
			// Create the new filename
			Local:'NewFileName' = ((#FilenameJoined) '_' (Create_UIDShort)'.'(#FileExt));
			If: $svDebug == 'Y';
				'<p class="debug">\n';
				'139: fileName = ' (#fileName) '<br>\n';
				'139: fileReal = ' (#fileReal) '<br>\n';
				'139: FilePrefix = ' (#FilePrefix) '<br>\n';
				'139: FileExt = ' (#FileExt) '<br>\n';
				'139: FilePrefix = ' (#FilePrefix) '<br>\n';
				'139: FilenameJoined = ' (#FilenameJoined) '<br>\n';
				'139: NewFileName = ' (#NewFileName) '</p>\n';
			/If;
	
			// Concatonate the path and filename
			// Filepath to the uploaded file should be something like "/uploads/P10839275.jpg"
			Local:'ThisFilePath' = (#destPath) (#NewFileName);
			If: $svDebug == 'Y';
				'<p class="debug">\n';
				'149: TypeofUpload = ' (#TypeofUpload) '<br>\n';
				'149: ThisFilePath = ' (#ThisFilePath) '</p>\n';
			/If;

			// Create the source file
			File_Create: (#ThisFilePath), -FileOverWrite;
			File_Write: (#ThisFilePath), (File_Read: (#fileName));

			// NOTE: ImageMagick conversions have been deleted here

			// Archive the original upload file, if this option is set in the siteconfig
/*			If: $svArchiveOriginalUpload == True;

				Local:('CopyFrom') = ((#destPath) (#NewFileName));
				Local:('CopyTo') = ((#processedPath) (#NewFileName));
				If: $svDebug == 'Y';
					'<p class="debug">\n';
					'272: CopyFrom: ' #CopyFrom '<br>\n';
					'272: CopyTo: ' #CopyTo '</p>\n';
				/If;
				File_Copy: $CopyFrom, $CopyTo, -FileOverWrite;

			/If;

			// Delete the original file
			File_Delete: (#ThisFilePath);
*/
			// If copy fails, set $vError to 7102 "File Upload Error" and redirect
			If: ((File_CurrentError: -ErrorCode) != '0') || ((Error_CurrentError: -ErrorCode) != '0');
				Var:'vError' = '7102';
				Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error=7102');
		
				If: $svDebug == 'Y';
					'244: URL = ' $URL '<br>\n';
					'244: File_CurrentError = ' (File_CurrentError)(File_CurrentError: -ErrorCode) '<br>\n';
					
					Abort;
				Else;
					Redirect_URL: $URL;
				/If;
		
			// Else assume upload successful, set vError to 7100 "Upload Successful" and option to NewFileName
			Else;
				Var:'vError' = '7100';
				Var:'vOption' = (#NewFileName);
			/If;

		/iterate;

	Else;
	
		// File not uploaded because upload size = 0, so set $vError to 7102 "File Upload Error" and redirect
		Var:'vError' = '7102';
//		Var:'vOption' = (#NewFileName);
		Var:'URL' = ('/admin/library.lasso?DataType='($vDataType)'&Error='$vError);

		If: $svDebug == 'Y';
			'236: URL = ' $URL '<br>\n';
			'<a href="'$URL'">' $URL '</a><br>\n';
			Abort;
		Else;
			Redirect_URL: $URL;
		/If;
	/If;

/inline;

If: $svDebug == 'Y';
	'<font color="green"><b>UPLOAD VARS</b></font><br>\n';
	'<div align="left">\n';
	'252: fileName = ' (#fileName) '<br>\n';
	'252: fileType = ' (#fileType) '<br>\n';
	'252: fileSize = ' (#fileSize) '<br>\n';
	'252: fileField = ' (#fileField) '<br>\n';
	'252: fileReal = ' (#fileReal) '<br>\n';
	'252: file_uploads = ' (file_uploads) '<br>\n';
	'252: File_CurrentError: ' (File_CurrentError: -ErrorCode) ' - <b>' (File_CurrentError) '</b><br>\n';
	'252: Error_CurrrentError: ' (Error_CurrentError: -ErrorCode) ' - <b>' (Error_CurrentError) '</b><br>\n';
	'</div>\n';
/If;
?>
