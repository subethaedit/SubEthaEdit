<?Lassoscript
// Last modified: 6/6/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Include file used in response page to modify nodes

// CHANGE NOTES
// 9/19/07
// First implementation
// 11/15/07
// Removed ability to assign Content ID. We are doing this a different way now,
// by assigning the heirarchy ID in the content page itself.
// 4/3/08
// Added code for URL Fix (Issue #547)
// Added -othersmap to xs_cat commands to add an additional field for HeirarchySlug
// Fixed DateModified not being set
// 6/6/09
// Fixing Issue #579, new root name converted to lower case

// Debugging
// Var:'svDebug' = 'Y';

// Zeroing out Error and Option
Var:'vError' = '';
Var:'vOption' = '';

If: $svDebug == 'Y';
	'<br>\n';
	'<b>node_modify.inc</b><br>\n';
	'24: vNew = ' (Var:'vNew') '<br>\n';
	'24: vError = ' (Var:'vError') '<br>\n';
	'24: vOption = ' (Var:'vOption') '<br>\n';
/If;

// Convert action_params
Include:'node_params.inc';

// If an error was generated from the Params, no point continuing, so bail immediately
If: $vError == '';

	// Possible Actions:
	// 		Action = "Add New Root", means the request was an Add New Root node
	// 		Action = "Update", means the request was an Update the Name of an existing node
	// 		Action = "Delete This Node", means the request was to delete this node and all underlying nodes
	// 		Action = "Add (Same Level)", means the request was to add a node in the heirarchy
	//				 at THE SAME LEVEL as the displayed level
	// 		Action = "Add (1 Level Lower)", means the request was to add a node in the heirarchy
	//				 at ONE LEVEL BELOW the displayed level
	
	// ============= ADD NEW ROOT ========
	If: $vAction == 'Add New Root';
	
		// Add New Root Node
		// There is no additional checking, because there can be nodes with the same name at different levels
		Local:'NewRootID' = (xs_cat->(addRoot(-cattable=$svHeirarchyTable,-txt=$vNewRootName,-othersmap=$vNewRootNameSlugOthers)));
		'51: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
		'51: #NewRootID = ' (#NewRootID) '<br>\n';

		// If no error and NewRootID equals something, Add was successful, dump out Error 1004 "Add Successful"
		If:(Error_CurrentError)==(Error_NoError) && (#NewRootID != '');
			Var:'vError' = '1004';
			Var:'vOption' = 'root node';
			If: $svDebug == 'Y';
				'59: vError = ' $vError '<br>\n';
				'59: vOption = ' $vOption '<br>\n';
			/If;

		// There was an error
		Else;
			Var:'vError' = (Error_CurrentError);
		/If;
	
	// ============= Update ========
	// Action = "Update"
	Else: $vAction == 'Update';
	
		// ************* START Update Name *************
		// Construct the query to Update the nestedset
		Var:'SQLUpdateNode' = '/* SQLUpdateNode */
			UPDATE ' $svHeirarchyTable ' SET
			Name = "'(Encode_SQL:(Var:'vUpdateName'))'",
			DateModified = "'(Date_Format:(Date_GetCurrentDate),-Format='%Q %T')'",
			HeirarchySlug = "'(Encode_SQL:(Var:'vUpdateNameSlug'))'"
			WHERE id = "' $vNodeID '"';

		If: $svDebug == 'Y';
			'91: vNodeID = ' $vNodeID '<br>\n';
			'91: vUpdateName = ' $vUpdateName '<br>\n';
			'91: SQLUpdateNode ' $SQLUpdateNode '<br>\n';
		/If;
	
		Inline: $IV_Heirarchy, -SQL=$SQLUpdateNode;

			// If no error, Update was successful, dump out Error 6000 "Update Successful"
			If:(Error_CurrentError)==(Error_NoError);
				Var:'vError' = '1013';
				Var:'vOption' = $vUpdateName;
				If: $svDebug == 'Y';
					'103: vError = ' $vError '<br>\n';
					'103: vOption = ' $vOption '<br>\n';
				/If;
		
			// There was an error
			Else;
				Var:'vError' = (Error_CurrentError);
			/If;
		
		/Inline;
		// ************* END Update Name *************

		// ************* START Update Active *************
		// Use this to collect IDs for later modification
		Var:'SubTreeSQLIDsArray' = array;
		Var:'SQLSelectPartialNode' = (xs_cat->(subTreeSQL(-cattable=$svHeirarchyTable,-id=$vNodeID,-depth=10,-relative=true)));
		
		Inline: $IV_Heirarchy, -SQL=$SQLSelectPartialNode, -Table=$svHeirarchyTable;
		
			If: $svDebug == 'Y';
				'123: Found_Count = ' (Found_Count) '<br>\n';
				'123: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
				'123: SQLSelectPartialNode = ' ($SQLSelectPartialNode) '<br>\n';
			/If;
		
			Records;
				// Insert ID into array. We will use this array to modify Active records later
				$SubTreeSQLIDsArray->insert:(Field:'id');
			/Records;
		
			If: $svDebug == 'Y';
				'134: SubTreeSQLIDsArray = ' $SubTreeSQLIDsArray '<br>\n';
				'134: SubTreeSQLIDsArray->size = ' $SubTreeSQLIDsArray->size '<br>\n';
			/If;
		
		/Inline;
		
		Var:'SQLUpdatePartialNode' = '/* Update Active Field - $SQLUpdatePartialNode */
		UPDATE ' $svHeirarchyTable ' SET Active = "' $vActive '" WHERE (\n';
		
		Iterate: $SubTreeSQLIDsArray, (Local:'i');
			$SQLUpdatePartialNode += '\tid = "'(#i)'" OR \n';
		/Iterate;
		
		$SQLUpdatePartialNode += $SQLUpdatePartialNode->(RemoveTrailing:' OR \n');
		$SQLUpdatePartialNode += ');';
		
		Inline: $IV_Heirarchy, -SQL=$SQLUpdatePartialNode, -Table=$svHeirarchyTable;
			If: $svDebug == 'Y';
				'151: SQLUpdatePartialNode = ' ($SQLUpdatePartialNode) '<br>\n';
				'151: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
			/If;
		/Inline;
	
	// ============= Add (Same Level) OR Add (1 Level Lower) ========
	Else: ($vAction == 'Add (Same Level)') || ($vAction == 'Add (1 Level Lower)');
	
		// Add (Same Level)
		If: $vAction == 'Add (Same Level)';
			Local:'NewNodeID' = (xs_cat->(addSibling(-cattable=$svHeirarchyTable,-txt=$vAddNewNodeName,-id=$vNodeID,-othersmap=$vAddNewNodeNameSlugOthers)));
		Else: $vAction == 'Add (1 Level Lower)';
			Local:'NewNodeID' = (xs_cat->(addChild(-cattable=$svHeirarchyTable,-txt=$vAddNewChildName,-id=$vNodeID,-othersmap=$vAddNewChildNameSlugOthers)));
		/If;
		'173: $vAddNewChildName = ' (Var:'vAddNewChildName') '<br>\n';
		'173: $vAddNewChildNameSlug = ' (Var:'vAddNewChildNameSlug') '<br>\n';
		'173: $vAddNewChildNameSlugOthers = ' (Var:'vAddNewChildNameSlugOthers') '<br>\n';
		'173: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
		'173: #NewNodeID = ' (#NewNodeID) '<br>\n';

		// If no error, Add was successful, dump out Error 1004 "Add Successful"
		If:(Error_CurrentError)==(Error_NoError);
			Var:'vError' = '1004';
			If: $vAction == 'Add (Same Level)';
				Var:'vOption' = 'new node (same level)';
			Else: $vAction == 'Add (1 Level Lower)';
				Var:'vOption' = 'new node (1 level lower)';
			/If;
			If: $svDebug == 'Y';
				'185: vError = ' $vError '<br>\n';
				'185: vOption = ' $vOption '<br>\n';
			/If;

		// There was an error
		Else;
			Var:'vError' = (Error_CurrentError);
		/If;
	
	// ============= DELETE NODE ========
	Else: $vAction == 'Delete';
	
		// Delete Node and All Children
		Local:'DeleteResult' = (xs_cat->(deleteNode(-cattable=$svHeirarchyTable,-id=$vNodeID)));
		'204: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
		'204: #DeleteResult = ' (#DeleteResult) '<br>\n';
	
		// If no error, Add was successful, dump out Error 1004 "Add Successful"
		If:(Error_CurrentError)==(Error_NoError);
			Var:'vError' = '1021';
			If: $svDebug == 'Y';
				'211: vError = ' $vError '<br>\n';
			/If;
	
		// There was an error
		Else;
			Var:'vError' = (Error_CurrentError);
		/If;
	
	// ============= MOVE TO NEW PARENT NODE ========
	Else: $vAction == 'Move';
	
		Local:'MoveResult' = (xs_cat->(moveNodeTo(-cattable=$svHeirarchyTable,-id=$vNodeID,-newparent=$vNewParent)));
		'228: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	
		// If no error, Add was successful, dump out Error 1004 "Add Successful"
		If:(Error_CurrentError)==(Error_NoError);
			Var:'vError' = '1013';
			Var:'vOption' = 'the heirarchy';
			If: $svDebug == 'Y';
				'235: vError = ' $vError '<br>\n';
				'235: vOption = ' $vOption '<br>\n';
			/If;
		
		// There was an error
		Else;
			Var:'vError' = (Error_CurrentError);
		/If;
	
	// ************* MOVE UP *************
	Else: $vAction == 'Move Up';
	
		Local:'MoveResult' = (xs_cat->(moveNode(-cattable=$svHeirarchyTable,-id=$vNodeID)));
		'251: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
		'251: vNodeID = ' ($vNodeID) '<br>\n';
	
		// If no error, Add was successful, dump out Error 1004 "Add Successful"
		If:(Error_CurrentError)==(Error_NoError);
			Var:'vError' = '1013';
			Var:'vOption' = 'the heirarchy';
			If: $svDebug == 'Y';
				'258: vError = ' $vError '<br>\n';
				'258: vOption = ' $vOption '<br>\n';
			/If;
		
		// There was an error
		Else;
			Var:'vError' = (Error_CurrentError);
		/If;
	
	// ========== SOMETHING ELSE =========
			
	// Referrer not good, somebody is messing with us
	// Dump out error 9002, "Database Error"
	Else;
		Var:'vError' = '9002';
	/If;

/If; // Error from node_params.inc

// Deal with the results of the processing
// Simply redisplay the heirarchy page
Var:'URL' = ('/admin/manage_heirarchy.lasso?Error='$vError'&Option='$vOption'&'(Client_POSTArgs));
If: $svDebug == 'Y';
	'186: URL = ' $URL '<br>';
	'<a href="'$URL'">' $URL '</a><br>\n';
Else;
	Redirect_URL: $URL;
/If;

?>
