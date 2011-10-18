<?Lassoscript
// Last modified 3/8/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// This page displays a template preview

// Debugging
// Var('svDebug' = 'Y');

'<!-- preview_template -->\n';

// Get the Content ID of the special page "Template Preview"
Var:'SQLGetPreviewID' = '/* 15 RenderPage - $SQLGetPreviewID */
SELECT * FROM '$svSiteDatabase'.'$svContentTable' WHERE Headline = "Template Preview" LIMIT 1';
Inline: $IV_Content, -SQL=$SQLGetPreviewID;

	// $PreviewID is passed to /admin/preview.lasso which calls /includes/build_detail.inc
	// to look up the content
	Var('PreviewID' = (Field('id')));
	Var('vHeirarchyID' = (Field('HeirarchyID')));

	Debug;
		('21: SQLGetPreviewID = ' ($SQLGetPreviewID) '<br>\n');
		('21: Found_Count = ' (Found_Count) '<br>\n');
		('21: Error_CurrentError = ' (Error_CurrentError) '<br>\n');
		('21: vID = '+($vID)+'<br>\n');
		('21: vHeirarchyID = '+($vHeirarchyID)+'<br>\n');
	/Debug;

/Inline;

// Convert action_params
Var('PreviewTemplate' = Action_Param('Template'));

// Build the heirarchy maps
Include(($svLibsPath)+'build_heirmaps.inc');

// Include the detail page. There was a change to build_detail.inc to see if $PreviewTemplate exists.
Include('/admin/preview.lasso');

?>