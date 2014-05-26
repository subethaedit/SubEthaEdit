<?Lassoscript
// Last modified 8/28/09 by ECL

// FUNCTIONALITY
// Process .flv and .swf file uploads
// For .flv files, the preview created is a hack, we are simply renaming the SWF icon and using that.
// This will enable the show_images.inc feature will work.
// Unfortunately this means there will be an icon file for each Flash file.

// CHANGE NOTES
// 6/5/09
// Split off this routine into this file from process_imageupload.inc
// 8/28/09 ECL
// Cleaned up debugging

// Debugging
// Var:'svDebug' = 'Y';

// Define vars for movie info and PassThru commands
Local('movie_info' = string);
Local('passthrucommand1' = string);
Local('passthrucommand2' = string);
Local('create_flv_outputfile' = string);
Local('create_placeholder' = string);

Debug;
	'18: FileExt = ' #FileExt '<br>\n';
	'18: NewFileNameFinal = ' (#NewFileNameFinal) '<br>\n';
	'18: ThisFilePathSource = ' (#ThisFilePathSource) '<br>\n';
	'18: ThisFilePath = ' (#ThisFilePath) '<br>\n';
/Debug;

// -----------------------------------------------//
// Create the SOURCE PNG image
// -----------------------------------------------//
// Deal with native .flv files first
If: (#FileExt == 'flv');

	// Make the .png preview
	Include:($svLibsPath)'process_pngpreview.inc';

	// -----------------------------------------------//
	// DELETE FILES
	// -----------------------------------------------//
	// Delete Source file
	// DISABLING THIS for .flv files
/* File_Delete(#ThisFilePathSource);
		Debug;
			'573: Deleting ' (#ThisFilePathSource )'<br>\n';
			'573: File_CurrentError = '(File_CurrentError)'<br>\n';
		/Debug;
*/
	// OVERRIDE #ThisFilePath and #NewFileName (VIDEO ONLY)
	#ThisFilePath = (($svMediaPath)(#NewFileNamePoster));
	#NewFileName = ((#NewFileNamePrefix)'.jpg');
	
	// Create thumb, medium, and large image preview for Images and Media filetypes
	Include:($svLibsPath)'process_imagepreviews.inc';

// Create preview for .swf files
Else;
	// Building the output filename
	#NewFileName = ((#NewFileNamePrefix)'.jpg');
	
	#CopyFrom = (($svFileIconsPath)'swf_icon.jpg');
	#CopyTo = (($svMediaThmbPath)(#NewFileName));
	Debug;
		'34: NewFileNameFinal = ' (#NewFileNameFinal) '<br>\n';
		'34: ThisFilePathSource = ' (#ThisFilePathSource) '<br>\n';
		'34: ThisFilePath = ' (#ThisFilePath) '<br>\n';
		'34: CopyFrom: ' #CopyFrom '<br>\n';
		'34: CopyTo: ' #CopyTo '<br>\n';
	/Debug;
	
	File_Copy: $CopyFrom, $CopyTo, -FileOverWrite;
	Debug;
		'658: File_CurrentError = ' (File_CurrentError) '<br>\n';
	/Debug;

/If;

?>