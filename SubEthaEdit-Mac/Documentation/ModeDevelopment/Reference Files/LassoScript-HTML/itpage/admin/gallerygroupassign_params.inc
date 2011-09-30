<?Lassoscript
// Last modified: 12/13/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file is included in the add pages to process action_params

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

// Pass a param "New" through the URL to indicate it is a new page
// Var:'vNew' = (Action_Param:'New');

Var:'vGalleryGroupID'=(Action_Param:'GalleryGroupID');
Var:'vGallery_Entries'=(Action_Param:'Gallery_Entries');

// Required Fields
// None
?>