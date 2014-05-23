<?Lassoscript
// Last modified: 6/6/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Copying Action_Params to vars
// Remove leading and trailing spaces
// If required is missing, output an error
// If multiple errors, they will step on each other, but not worried about it

// CHANGE NOTES
// 2/18/08
// Removed an unnecessary conversion of action_params for Error and Option
// Corrected a problem with $Action names being wrong
// 4/3/08
// Added code for URL Fix (Issue #547)
// Added new vars $vUpdateNameSlugOthers and $vUpdateNameSlugOthersMap to use in xs_cat to
// hold data for the HeirarchySlug field in the Heirarchy table
// 6/6/09
// Fixing Issue #579, new root name converted to lower case

// Used throughout
Var:'vNew' = (Action_Param:'New');
Var:'vNodeID' = (Action_Param:'NodeID');
Var:'vActive' = (Action_Param:'Active');

// Add New Root Level Form
Var:'vNewRootName' = (Action_Param:'NewRootName');
// Process the Name to produce the URLSlug
If: $vNewRootName != '';
	$vNewRootName->trim;
	Var:'vNewRootNameSlug' = (LI_CleanSlug: -NodeName=$vNewRootName);
	Var:'vNewRootNameSlugOthers' = map;
	$vNewRootNameSlugOthers->(insert:('DateModified')=(Date_Format:(Date_GetCurrentDate),-Format='%Q %T'));
//	$vNewRootNameSlugOthers->(insert:('HeirarchySlug')=($vNewRootNameSlug));
	$vNewRootNameSlugOthers->(insert:('HeirarchySlug')=($vNewRootName));



/If;

// Manage Heirarchy Form
Var:'vUpdateName' = (Action_Param:'UpdateName');
// Process the Name to produce the URLSlug
If: $vUpdateName != '';
	$vUpdateName->trim;
	Var:'vUpdateNameSlug' = (LI_CleanSlug: -NodeName=$vUpdateName);
	// Exception: Don't need this here, as the update uses a regular SQL query
	// Var:'vUpdateNameSlugOthers' = map;
	// $vUpdateNameSlugOthers->(insert:('HeirarchySlug')=($vUpdateNameSlugOthers));
/If;

Var:'vContent_ID' = (Action_Param:'Content_ID');
Var:'vAddNewNodeName' = (Action_Param:'AddNewNodeName');
// Process the Name to produce the URLSlug
If: $vAddNewNodeName != '';
	$vAddNewNodeName->trim;
	Var:'vAddNewNodeNameSlug' = (LI_CleanSlug: -NodeName=$vAddNewNodeName);
	Var:'vAddNewNodeNameSlugOthers' = map;
	$vAddNewNodeNameSlugOthers->(insert:('DateModified')= (Date_Format:(Date_GetCurrentDate),-Format='%Q %T'));
	$vAddNewNodeNameSlugOthers->(insert:('HeirarchySlug')=($vAddNewNodeNameSlug));
/If;

Var:'vAddNewChildName' = (Action_Param:'AddNewChildName');
// Process the Name to produce the URLSlug
If: $vAddNewChildName != '';
	$vAddNewChildName->trim;
	Var:'vAddNewChildNameSlug' = (LI_CleanSlug: -NodeName=$vAddNewChildName);
	Var:'vAddNewChildNameSlugOthers' = map;
	$vAddNewChildNameSlugOthers->(insert:('DateModified')= (Date_Format:(Date_GetCurrentDate),-Format='%Q %T'));
	$vAddNewChildNameSlugOthers->(insert:('HeirarchySlug')=($vAddNewChildNameSlug));
/If;

// Move
Var:'vNewParent' = (Action_Param:'NewParent');


// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit
If: $vNew == 'Y';

	// If a new node or update, make sure the name is not blank
	If: $vAction == 'Add New Root';
		If: ($vNewRootName == '');
			Var:'vError' = '1003';
			Var:'vOption' = 'Node Name';
		/If;
	Else: $vAction == 'Update';
		If: ($vUpdateName == '') || ($vNodeID == '');
			Var:'vError' = '1003';
			Var:'vOption' = 'Node Name';
		/If;
	Else: $vAction == 'Add (Same Level)';
		If: ($vAddNewNodeName == '') || ($vNodeID == '');
			Var:'vError' = '1003';
			Var:'vOption' = 'Name';
		/If;
	Else: $vAction == 'Add (1 Level Lower)';
		If: ($vAddNewChildName == '') || ($vNodeID == '');
			Var:'vError' = '1003';
			Var:'vOption' = 'Name';
		/If;
	Else: $vAction == 'Delete';
		If: ($vNodeID == '');
			Var:'vError' = '1003';
			Var:'vOption' = 'Node ID';
		/If;
	/If;
/If;

?>