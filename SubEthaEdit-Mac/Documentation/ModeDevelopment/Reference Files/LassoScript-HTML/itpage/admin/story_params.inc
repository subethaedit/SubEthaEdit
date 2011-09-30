<?Lassoscript
// Last modified 1/15/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file is included in the add pages to process action_params

// Copying Action_Params to vars
// Remove leading and trailing spaces

// CHANGE NOTES
// 1/15/09
// First implementation

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

Var:'vStory_Comment'=(Action_Param:'Story_Comment');
	$vStory_Comment->trim;
Var:'vActive'=(Action_Param:'Active');
	$vActive->trim;

// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit
If: $vNew != 'Y';
	If: ($vStory_Comment == '') || ($vActive == '');
		Var:'vError' = '1003';
		Var:'vOption' = 'Story Text';
	/If;
/If;

// OPTIONAL FIELDS
Var:'vStory_Head'=(Action_Param:'Story_Head');
	$vStory_Head->trim;
Var:'vStory_Name'=(Action_Param:'Story_Name');
	$vStory_Name->trim;
Var:'vStory_Thumb'=(Action_Param:'Story_Thumb');
	$vStory_Thumb->trim;

// Create name to display
// Since only the comment is required, we will pass the ID
?>