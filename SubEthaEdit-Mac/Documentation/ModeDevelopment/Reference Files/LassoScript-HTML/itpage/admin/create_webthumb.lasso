<?Lassoscript
// Last modified 3/13/10 by Eric Landmann

// FUNCTIONALITY
// This file creates webthumbs from a web page using the EasyThumb service.

// USAGE
// Debugging off
// /admin/create_webthumb.lasso?Template=1kbGrid7e_PF1_Col2.html
// Debugging on
// /admin/create_webthumb.lasso?Template=1kbGrid7e_PF1_Col2.html&Debug=Y

Include('/siteconfig.lasso');

// Debugging
// Var('svDebug' = 'Y');

// TEMPORARILY INCLUDE EasyThumb CT UNTIL IT IS FULLY DEBUGGED
// Include('/admin/it_easythumb.inc');

// Convert action_params
Var('ConvertThisFile' = Action_Param('Template'));
Var('EasyThumbDebug' = Action_Param('Debug'));
Var('vDatatype' = 'Templates');

// Prepare filepaths
Var('ConvertThisURL' = ('http://'+($svDomain)+'/admin/preview_template.lasso?Template='+($ConvertThisFile)));
// Used for the preview (converted) filename. Append ".jpg" onto the filename.
Var('PreviewFileName' = (($svTmpltsPreviewPath)+($ConvertThisFile)+'.jpg'));

Debug;
	'15: $ConvertThisURL = ' $ConvertThisURL '<br>\n';
	'15: $PreviewFileName = ' $PreviewFileName '<br>\n';
/Debug;


// Go get the thumbs from EasyThumb
it_easythumb(
	-url=$ConvertThisURL,
	-userid=$svEasyThumbUserID,
	-apikey=$svEasyThumbAPIKey,
	-file=$PreviewFileName,
	-size='medium2',
	-debug=$EasyThumbDebug);

Var('PreviewFileExists' = (File_Exists($PreviewFileName)));

Debug;
	('45: $PreviewFileName = ' $PreviewFileName '<br>\n');
	('45: $PreviewFileExists = ' $PreviewFileExists '<br>\n');
	('45: Error_CurrentError = ' (Error_CurrentError) '<br>\n');
	('45: File_CurrentError = ' (File_CurrentError) '<br>\n');
	('45: vError = ' (Var('vError')) '<br>\n');
	('45: vOption = ' (Var('vOption')) '<br>\n');
/Debug;

// Finally redirect back to Templates page
LI_URLRedirect: -Page='library.lasso',-ExParams=('DataType='($vDataType)),-UseError='Y',-Error=$vError,-Option=$vOption,-UseArgs='N';

?>
