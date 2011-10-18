<?Lassoscript
// Last modified 6/22/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file processes action_params

// CHANGE NOTES
// 6/22/09
// First implementation

// Copying Action_Params to vars
// Remove leading and trailing spaces
// If required is missing, output an error
// If multiple errors, they will step on each other, but not worried about it

If: (Action_Param:'Error') != '';
	Var:'vError' = (Action_Param:'Error');
/If;
If: (Action_Param:'Option') != '';
	Var:'vOption' = (Action_Param:'Option');
/If;
Var:'vID' = (Action_Param:'ID');
// Copy ID to be used in Assignments
Var:'vGalleryGroupID' = ($vID);

// Pass a param "New" through the URL to indicate it is a new page
Var:'vNew' = (Action_Param:'New');

Var:'vProcess' = (Action_Param:'Process');

Var:'vgg_name'=(Action_Param:'gg_name');
	$vgg_name->trim;
Var:'vgg_text'=(Action_Param:'gg_text');
	$vgg_text->trim;
Var:'vActive'=(Action_Param:'Active');
	$vActive->trim;

// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit
If: $vNew != 'Y';
	If: ($vgg_name == '') || ($vActive == '');
		Var:'vError' = '1003';
		Var:'vOption' = 'Gallery Group Name';
	/If;
/If;

// OPTIONAL FIELDS
// None

// Create name to display
Var:'vDisplayName' = $vgg_name;
?>