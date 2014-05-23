<?Lassoscript
// Last modified 11/30/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file processes action_params

// Copying Action_Params to vars
// Remove leading and trailing spaces
// If required is missing, output an error
// If multiple errors, they will step on each other, but not worried about it

// CHANGE NOTES
// 11/30/07
// First implementation

If: (Action_Param:'Error') != '';
	Var:'vError' = (Action_Param:'Error');
/If;
If: (Action_Param:'Option') != '';
	Var:'vOption' = (Action_Param:'Option');
/If;
Var:'vID' = (Action_Param:'ID');
// Copy ID to be used in Assignments
Var:'vPortfolioGroupID' = ($vID);

// Pass a param "New" through the URL to indicate it is a new page
Var:'vNew' = (Action_Param:'New');

Var:'vProcess' = (Action_Param:'Process');

Var:'vpg_name'=(Action_Param:'pg_name');
	$vpg_name->trim;
Var:'vActive'=(Action_Param:'Active');
	$vActive->trim;

// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit
If: $vNew != 'Y';
	If: ($vpg_name == '') || ($vActive == '');
		Var:'vError' = '1003';
		Var:'vOption' = 'Portfolio Group Name';
	/If;
/If;

// OPTIONAL FIELDS
// None

// Create name to display
Var:'vDisplayName' = $vpg_name;
?>