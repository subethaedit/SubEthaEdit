<?Lassoscript
// Last modified 7/19/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file processes action_params

// Copying Action_Params to vars
// Remove leading and trailing spaces
// If required is missing, output an error
// If multiple errors, they will step on each other, but not worried about it

// CHANGE NOTES
// 6/22/09
// First implementation
// 7/19/09
// Added $vAction = Browse check

If: (Action_Param:'Error') != '';
	Var:'vError' = (Action_Param:'Error');
/If;
If: (Action_Param:'Option') != '';
	Var:'vOption' = (Action_Param:'Option');
/If;
Var:'vID' = (Action_Param:'ID');

// Pass a param "New" through the URL to indicate it is a new page
Var:'vNew' = (Action_Param:'New');

Var:'vProcess' = (Action_Param:'Process');

Var:'vAction' = (Action_Param:'Action');

Var:'vGallery_Title' = (Action_Param:'Gallery_Title');
	$vGallery_Title->trim;
Var:'vGallery_Caption' = (Action_Param:'Gallery_Caption');
	$vGallery_Caption->trim;
Var:'vGallery_URL' = (Action_Param:'Gallery_URL');
	$vGallery_URL->trim;
Var:'vGallery_Thumb' = (Action_Param:'Gallery_Thumb');
	$vGallery_Thumb->trim;
Var:'vActive'=(Action_Param:'Active');
	$vActive->trim;

// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit
If: (((Response_Filepath) >> 'setup_add') || ((Response_Filepath) >> 'setup_editrecord'))
	&&
	(($vAction == 'Add') || ($vAction == 'Update'));
	If: ($vGallery_Thumb == '') || ($vActive == '');
		Var:'vError' = '1003';
		Var:'vOption' = 'Thumbnail';
	/If;
/If;

// Create name to display
// Use the Record ID
?>