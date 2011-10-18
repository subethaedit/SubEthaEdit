<?Lassoscript
// Last modified 8/23/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Create thumb, medium, and large image preview for Images and Media filetypes

// CHANGE NOTES
// 6/12/09
// Cosmetic display changes
// 6/22/09
// Modified size-checking code for #height and #width to convert it to an integer before comparing
// 8/23/09
// Fix problem with resizing very small images

// Defining variables for the destination files
If: #TypeofUpload == 'Image';
	Local:'ULPath_ImageLargeOUT' = (($svWebserverRoot) ($svImagesLrgPath) (#NewFileName));
	Local:'ULPath_ImageMedOUT' =   (($svWebserverRoot) ($svImagesMdPath) (#NewFileName));
	Local:'ULPath_ImageThumbOUT' = (($svWebserverRoot) ($svImagesThmbPath) (#NewFileName));
Else: #TypeofUpload == 'Media';
	Local:'ULPath_ImageLargeOUT' = (($svWebserverRoot) ($svMediaLrgPath) (#NewFileName));
	Local:'ULPath_ImageMedOUT' =   (($svWebserverRoot) ($svMediaMdPath) (#NewFileName));
	Local:'ULPath_ImageThumbOUT' = (($svWebserverRoot) ($svMediaThmbPath) (#NewFileName));
/If;

// Get size and filetype info from the image
// This is used below to check size of image to use appropriate resizing dimensions
Local:'ImgInfoHeight' = ($svPathToIM 'identify -format %h "' ($svWebserverRoot) (#ThisFilePath) '"');
Local:'ImgInfoWidth' = ($svPathToIM 'identify -format %w "' ($svWebserverRoot) (#ThisFilePath) '"');
Local:'ImgInfoFileType' = ($svPathToIM 'identify -format %e "' ($svWebserverRoot) (#ThisFilePath) '"');
Local:'height' = (Integer(PassThru(#ImgInfoHeight, -username=$svPassThruUsername, -password=$svPassThruPassword)));
Local:'width' = (Integer(PassThru(#ImgInfoWidth, -username=$svPassThruUsername, -password=$svPassThruPassword)));
Local:'filetype' = (Mime_Type(PassThru(#ImgInfoFileType, -username=$svPassThruUsername, -password=$svPassThruPassword)));
Debug;
	'152: ThisFilePath = ' (#ThisFilePath) '<br>\n';
	'152: NewFileName = ' (#NewFileName) '<br>\n';
	'152: TypeofUpload = ' (#TypeofUpload) '<br>\n';
	'152: <b>height</b> = ' (#height) '<br>\n';
	'152: <b>width</b> = ' (#width) '<br>\n';
	'152: <b>filetype</b> = ' (#filetype) '<br>\n';
/Debug;

// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// 	Make Large version
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// Determine if original is too small to be resized.
// If image size is greater than largest, resize is OK
If: (#height > #largeheight) || (#width > #largewidth);
	#ResizeOK = true;
Else;
	#ResizeOK = false;
/If;
Debug;
	'170: <strong>Make Large ResizeOK</strong> = ' (#ResizeOK) '<br>\n';
/Debug;
If: #ResizeOK == false;
	#ResizeComment = 'Image Height or Width LESS THAN large image, make large version, BUT NO RESIZE (keep it small)\n';
	#MakeLarge = ($svPathToIM 'convert -density 72x72 -colorspace RGB "' ($svWebserverRoot) (#ThisFilePath) '" "' (#ULPath_ImageLargeOUT) '"');
Else;
	#ResizeComment = 'Image Height or Width GREATER THAN large image, make large version, RESIZE IT<br>\n';
	#MakeLarge = ($svPathToIM 'convert -density 72x72 -colorspace RGB -resize ' (#largewidth) 'x' (#largeHeight)  ' "' ($svWebserverRoot) (#ThisFilePath) '" "' (#ULPath_ImageLargeOUT) '"');
/If;
Debug;
	'174: ResizeComment = ' (#ResizeComment) '<br>\n';
	'174: MakeLarge = ' (#MakeLarge) '<br>\n';
/Debug;

// Run the PassThru command to convert the file
Local('converting') = PassThru(#MakeLarge, -username=$svPassThruUsername, -password=$svPassThruPassword);

// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// 	Make Medium version
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// If image size is greater than largest, resize is OK
If: (#height > #mediumheight) || (#width > #mediumwidth);
	#ResizeOK = true;
Else;
	#ResizeOK = false;
/If;
Debug;
	'180: <strong>Make Large ResizeOK</strong> = ' (#ResizeOK) '<br>\n';
/Debug;
If: #ResizeOK == false;
	#ResizeComment = 'Image Height or Width LESS THAN medium image, make medium version, BUT NO RESIZE (keep it small)\n';
	#MakeMedium = ($svPathToIM 'convert -density 72x72 -colorspace RGB "' ($svWebserverRoot) (#ThisFilePath) '" "' (#ULPath_ImageMedOUT) '"');
Else;
	#ResizeComment = 'Image Height or Width GREATER THAN medium image, make medium version, RESIZE IT\n';
	#MakeMedium = ($svPathToIM 'convert -density 72x72 -colorspace RGB -resize "' (#mediumWidth) 'x' (#mediumHeight) '" "' ($svWebserverRoot) (#ThisFilePath) '" "' (#ULPath_ImageMedOUT) '"');
/If;
Debug;
	'184: ResizeComment = ' (#ResizeComment) '<br>\n';
	'183: MakeMedium = ' (#MakeMedium) '<br>\n';
/Debug;

// Run the PassThru command to convert the file
Local('converting') = PassThru(#MakeMedium, -username=$svPassThruUsername, -password=$svPassThruPassword);

// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// 	Make Thumb version
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// If image size is greater than largest, resize is OK
If: (#height > #thumbheight) || (#width > #thumbwidth);
	#ResizeOK = true;
Else;
	#ResizeOK = false;
/If;
Debug;
	'180: <strong>Make Large ResizeOK</strong> = ' (#ResizeOK) '<br>\n';
/Debug;
If: #ResizeOK == false;
	#ResizeComment = 'Image Height or Width LESS THAN thumb image, make thumb version, BUT NO RESIZE (keep it small)\n';
	#MakeThumb = ($svPathToIM 'convert -density 72x72 -colorspace RGB "' ($svWebserverRoot) (#ThisFilePath) '" "' (#ULPath_ImageThumbOUT) '"');
Else;
	#ResizeComment = 'Image Height or Width GREATER THAN thumb image, make thumb version, RESIZE IT\n';
	#MakeThumb = ($svPathToIM 'convert -density 72x72 -colorspace RGB -resize "' (#thumbWidth) 'x' (#thumbHeight) '" "' ($svWebserverRoot) (#ThisFilePath) '" "' (#ULPath_ImageThumbOUT) '"');
/If;
Debug;
	'200: ResizeComment = ' (#ResizeComment) '<br>\n';
	'200: MakeThumb = ' (#MakeThumb) '<br>\n';
/Debug;

// Run the PassThru command to convert the file
Local('converting') = PassThru(#MakeThumb, -username=$svPassThruUsername, -password=$svPassThruPassword);

?>