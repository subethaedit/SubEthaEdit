<?Lassoscript
// Last modified 5/12/08 by ECL, Landmann InterActive

// DEVELOPER'S NOTES
// This is to display the search params on the "You searched for" area of the search results page

// CHANGE NOTES
// 10/12/07
// Recoded for CMS v. 3.0

// Debugging
// Var:'svDebug' = 'Y';

Var:'svSearch_Params' = (string);
Var:'svSearch_ParamsURL' = (string);
// Add initial question mark to start query string for URL
$svSearch_ParamsURL += '?Datatype=User&';

// Get the User Name
If: Var:'vUser' != '';

	Inline: $IV_Users, 'User_ID' = $vUser;
		Var:'vUserNameLabel' = (Field:'User_FName') ' ' (Field:'User_LName');
	/Inline;

	$svSearch_Params += ('<strong>User:</strong> ' ($vUserNameLabel));
	$svSearch_Params += ', ';
	$svSearch_ParamsURL += ('User='($vUser) '&');
/If;

// User Active
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

If: ((Var:'vUser') == '') && ((Var:'vActive') == '');
	$svSearch_Params = ('<strong>Users:</strong> All');
/If;

?>