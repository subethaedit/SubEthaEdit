<?Lassoscript
// Last modified 11/15/07 by ECL, Landmann InterActive

// DEVELOPER'S NOTES
// This is to display the search params on the "You searched for" area of the search results page

// CHANGE NOTES
// 10/12/07
// Recoded for CMS v. 3.0
// 11/15/07
// Switched fields CategoriesID to HeirarchyID

// Debugging
// Var:'svDebug' = 'Y';

Var:'svSearch_Params' = (string);
Var:'svSearch_ParamsURL' = (string);
// Add initial question mark to start query string for URL
$svSearch_ParamsURL += '?Datatype=Content&';

// Heirarchy
If: Var:'vHeirarchyID' != '';
	$svSearch_Params += ('<strong>Heirarchy:</strong> '($HeirarchyLabels->(Find:$vHeirarchyID)));
	$svSearch_Params += ', ';
	$svSearch_ParamsURL += ('HeirarchyID='($vHeirarchyID) '&');
/If;

// Get the Headline
If: Var:'vHeadline' != '';
	$svSearch_Params += ('<strong>Headline:</strong> ' ($vHeadline));
	$svSearch_Params += ', ';
	$svSearch_ParamsURL += ('Headline='($vHeadline) '&');
/If;

// Large Image
If: Var:'vImage_Large' != '';
	$svSearch_Params += ('<strong>Large Image:</strong> ' ($vImage_Large));
	$svSearch_Params += ', ';
	$svSearch_ParamsURL += ('Image_Large='($vImage_Large) '&');
/If;

// Active
If: Var:'vActive' != '';
	If: Var:'vActive' == 'Y';
		Var:'ThisActiveLabel' = 'Active';
	Else: Var:'vActive' == 'N';
		Var:'ThisActiveLabel' = 'Inactive';
	/If;
	$svSearch_Params += ('<strong>Active:</strong> ' ($ThisActiveLabel));
	$svSearch_ParamsURL += ('Active='($vActive) '&');
/If;

// Remove trailing comma
$svSearch_Params->RemoveTrailing(', ');
// Remove trailing ampersand
$svSearch_ParamsURL->RemoveTrailing('&');

If: ((Var:'vHeirarchyID') == '') && ((Var:'vHeadlineActive') == '') && ((Var:'vImage_Large') == '') && ((Var:'vActive') == '');
	$svSearch_Params = ('<strong>Content:</strong> All');
/If;

?>