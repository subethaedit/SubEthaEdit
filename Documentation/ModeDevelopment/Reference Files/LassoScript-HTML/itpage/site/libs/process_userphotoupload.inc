<?Lassoscript
// Last modified 5/20/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Processes uploaded user photo

// CHANGE NOTES
// 5/6/08
// Added an "icon" version of the user's photo
// 5/12/08
// Ported changes from LBT
// Replaced (Response_Filepath) in URL with calling page name
// Fixed bug with tiff files not being resized when they have reported size and width=0; now we just redirect with error
// 5/20/08
// Recorded URL Links

// Debugging
// Var:'svDebug' = 'Y';

// GENERAL NOTES
// This command REFUSES to overwrite a file, do not use it
// File_ProcessUploads: -Destination=(#destPath), -FileOverwrite;
// File is named with the User ID

// VERSION NOTES
// This has been tested with ImageMagick version 6.1.5 and PassThru 2.5.7 on Lasso 8.5.5
// This routine downsizes the photo in one shot, not using a "source" image, then makes an icon version

// Defining thumbnail sizes
Local:'thumbwidth' = integer;
Local:'thumbheight' = integer;
Local:'thumbwidth' = 110;
Local:'thumbheight' = 110;
Local:'iconheight' = 30;
Local:'iconwidth' = 30;
Local:'converting' = string;

// fileReal is the actual file name, e.g. P1003852.jpg
// fileName is the name of the temporary file Lasso creates, e.g. "// /var/tmp/lasso0tmpH0QIPH46243328.uld"
// destPath is the upload directory
Local:'destPath' = $svUserPhotos;
Local:'thisFile' = string;
Local:'fileName' = string;
Local:'fileReal' = string;
Local:'fileRealRaw' = string;


// Used to pass errors
Var:'vError' = '';
Var:'vOption' = '';

Inline: -Username=$svSiteUsername, -Password=$svSitePassword;

	If: (File_Uploads->Size != 0);

		Iterate: (File_Uploads), #thisFile;

			#fileName = #thisFile->(Find: 'upload.name');
			#fileRealRaw = #thisFile->(Find: 'upload.realname');

			If: $svDebug == 'Y';
				'<p class="debug">\n';
				'81: fileName = '#fileName '<br>\n';
				'81: fileRealRaw = '#fileRealRaw '</p>\n';
			/If;

			// If filename does NOT end with .JPG,  .GIF, .TIF, .PNG, or .PSD, generate Error 5060 "Illegal filetype" error
			// immediately and redirect to form
			If: (#filename->EndsWith:'.JPEG') || (#filename->EndsWith:'.GIF') || (#filename->EndsWith:'.TIFF') || (#filename->EndsWith:'.PNG') || (#filename->EndsWith:'.PSD');
				$vError == '5060';
				LI_URLRedirect: -Page=(Response_Filepath),-ExParams=('DataType='($vDataType)),-UseError='Y',-Error=$vError;
			/If;

			// Clean up the filename
			#fileReal =
				(String_ReplaceRegExp:(Encode_StrictURL: #fileRealRaw->(Split:'\\')->Last),
				-Find='%[\\da-f]{2}',-Replace='');
			#fileReal->Trim;

			// Grab the prefix for the file (everything before the .) and build a new unique outfile name	
			// Naming the icon file with "_icon"
			Local:'FilePrefix' = (#fileReal->(Split: '.'));
			Local:'NewFileName' = (($vUser_ID)'.jpg');
			Local:'NewIconFileName' = (($vUser_ID)'_icon.jpg');
			If: $svDebug == 'Y';
				'111: fileName = ' (#fileName) '<br>\n';
				'111: FilePrefix = ' (#FilePrefix) '<br>\n';
				'111: NewFileName = ' (#NewFileName) '<br>\n';
			/If;
	
			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			// 	Make Thumb version
			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			// Concatonate the path and filename
			// Filepath to the uploaded file should be something like "/uploads/P10839275.jpg"
			Local:'ThisFilePath' = (#destPath) (#NewFileName);
			If: $svDebug == 'Y';
				'119: ThisFilePath = ' (#ThisFilePath) '<br>\n';
			/If;

			// Create the source file
			File_Create: (#ThisFilePath), -FileOverWrite;
			File_Write: (#ThisFilePath), (File_Read: (#fileName));

			// Defining variables for the destination files
			Local:'ULPath_ImageThumbOUT' = (($svWebserverRoot) (#destPath) (#NewFileName));
			Local:'ULPath_ImageIconOUT' = (($svWebserverRoot) (#destPath) (#NewIconFileName));

			Local('MakeThumb') = ($svPathToIM 'convert -density 72x72 -colorspace RGB -resize "' (#thumbWidth) 'x' (#thumbHeight) '" "' ($svWebserverRoot) (#ThisFilePath) '" "' (#ULPath_ImageThumbOUT) '"');
			
			// Run the PassThru command to convert the file
			Local('converting') = PassThru(#MakeThumb, -username=$svPassThruUsername, -password=$svPassThruPassword);

			If: $svDebug == 'Y';
				'195: MakeThumb = ' (#MakeThumb) '<br>\n';
				'195: converting = ' (#converting) '<br>\n';
			/If;



			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			// 	Make Icon version
			// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			// Concatonate the path and filename
			// Filepath to the uploaded file should be something like "/uploads/P10839275.jpg"
			Local:'ThisIconFilePath' = (#destPath) (#NewIconFileName);
			If: $svDebug == 'Y';
				'119: ThisIconFilePath = ' (#ThisIconFilePath) '<br>\n';
			/If;

			// Create the source file
			File_Create: (#ThisIconFilePath), -FileOverWrite;
			File_Write: (#ThisIconFilePath), (File_Read: (#fileName));

			// Defining variables for the destination files
			Local:'ULPath_ImageIconOUT' = (($svWebserverRoot) (#destPath) (#NewIconFileName));

			Local('MakeIcon') = ($svPathToIM 'convert -density 72x72 -colorspace RGB -resize "' (#IconWidth) 'x' (#iconHeight) '" "' ($svWebserverRoot) (#ThisIconFilePath) '" "' (#ULPath_ImageiconOUT) '"');
			
			// Run the PassThru command to convert the file
			Local('converting') = PassThru(#MakeIcon, -username=$svPassThruUsername, -password=$svPassThruPassword);

			If: $svDebug == 'Y';
				'195: MakeIcon = ' (#MakeIcon) '<br>\n';
				'195: converting = ' (#converting) '<br>\n';
			/If;


			// If copy fails, set $vError to 7101 "File Upload Error" and redirect
			If: ((File_CurrentError: -ErrorCode) != '0') || ((Error_CurrentError: -ErrorCode) != '0');
				Var:'vError' = '7101';
				Var:'Option' = '7101';
				LI_URLRedirect: -Page=(Response_Filepath),-ExParams=('DataType='($vDataType)'&ID='($vUser_ID)),-UseError='Y',-Error=$vError,-Option=$vOption;
		
			// Else assume upload successful, set vError to 7100 "Upload Successful" and option to NewFileName
			Else;
				Var:'vError' = '7100';
				Var:'vOption' = (#NewFileName);
			/If;

		/iterate;

	Else;
	
		// File not uploaded because upload size = 0, so set $vError to 7101 "Upload Failed" and redirect
		Var:'vError' = '7102';
		Var:'vOption' = '7101';
		LI_URLRedirect: -Page=(Response_Filepath),-ExParams=('DataType='($vDataType)'&ID='($vUser_ID)),-UseError='Y',-Error=$vError,-Option=$vOption;

	/If;

/inline;

If: $svDebug == 'Y';
	'<font color="green"><strong>UPLOAD VARS</strong></font><br>\n';
	'<div align="left">\n';
	'252: fileName = ' (#fileName) '<br>\n';
	'256: fileReal = ' (#fileReal) '<br>\n';
	'257: file_uploads = ' (file_uploads) '<br>\n';
	'258: File_CurrentError: ' (File_CurrentError: -ErrorCode) ' - <strong>' (File_CurrentError) '</strong><br>\n';
	'259: Error_CurrrentError: ' (Error_CurrentError: -ErrorCode) ' - <strong>' (Error_CurrentError) '</strong><br>\n';
	'</div>\n';
/If;
?>
