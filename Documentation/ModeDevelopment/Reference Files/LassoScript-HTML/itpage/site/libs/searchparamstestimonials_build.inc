<?Lassoscript
// Last modified 12/1/07 by ECL, Landmann InterActive

// DEVELOPER'S NOTES
// This is to display the search params on the "You searched for" area of the search results page

// CHANGE NOTES
// 12/1/07
// First implementation

// Debugging
// Var:'svDebug' = 'Y';

Var:'svSearch_Params' = (string);
Var:'svSearch_ParamsURL' = (string);
// Add initial question mark to start query string for URL
$svSearch_ParamsURL += '?Datatype='($vDataType)'&';

// Search For
If: Var:'vSearchFor' != '';
	$svSearch_Params += ('<strong>Search for:</strong> '($vSearchFor));
	$svSearch_Params += ', ';
	$svSearch_ParamsURL += ('SearchFor='($vSearchFor) '&');
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

If: ((Var:'vSearchFor') == '') && ((Var:'vActive') == '');
	$svSearch_Params = ('<strong>Testimonials:</strong> All');
/If;

?>