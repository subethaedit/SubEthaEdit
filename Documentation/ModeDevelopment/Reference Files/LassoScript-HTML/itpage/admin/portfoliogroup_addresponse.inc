<?Lassoscript
// Last modified: 11/30/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// Include for Portfolio Group add response page

// CHANGE NOTES
// 11/30/07
// First implementation
// 12/1/07
// Changing redirect for delete to go to setup_search

// Debugging
// Var:'svDebug' = 'Y';

// Converting action_params
Var:'vError' = '';
Var:'vOption' = '';
// The action_param "Action" is passed by the frm_portfoliogroup.inc form to indicate whether it is an add or edit
// Action = Update, means the request was an Edit (from frm_portfoliogroup.inc)
// Action = Add, means the request was an Add (from frm_portfoliogroup.inc)
Var:'vAction' = (Action_Param:'Action');

If: $svDebug == 'Y';
	'<br>\r';
	'<b>portfoliogroup_addresponse.inc</b><br>\r';
/If;

// Checking referrer to make sure it's only posting from the Add page
// ============= ADD ========
If: $vAction == 'Add';

	// Convert action_params
	Include:'portfoliogroup_params.inc';

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to add the record
		Var:'SQLQueryAddPortfolioGroup' = '/* SQLQueryAddPortfolioGroup */
		INSERT INTO ' $svSiteDatabase '.' $svPortfolioGroupsTable
			' SET
				pg_name="'		(Encode_SQL:$vpg_name) '",
				Active="'		(Encode_SQL:$vActive) '",
				DateCreated="'	(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '",
				DateModified="'	(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '";
				SELECT LAST_INSERT_ID() AS NewPortfolioGroupID;';
			
			If: $svDebug == 'Y';
				'128: SQLQueryAddPortfolioGroup = ' $SQLQueryAddPortfolioGroup '<br>\n';
			/If;
		
			Inline: $IV_Portfolios, -Table=$svPortfolioGroupsTable, -SQL=$SQLQueryAddPortfolioGroup;
				
				If:(Error_CurrentError)==(Error_NoError);
			
					// If no error, Add was successful, dump out Error 1001 "Add Successful"
					// Copying NewPortfolioGroupID to vNewID to use in links
					Var:'vError' = '1001';
					Var:'vOption' = (Var:'vpg_name');
					Var:'vNewID' = (Field:'NewPortfolioGroupID');
					If: $svDebug == 'Y';
						'137: vError = ' $vError '<br>\n';
					/If;
			
				// There was an error
				Else;
					Var:'vError' = (Error_CurrentError);
				/If;
			
			/Inline;

	/If;

// ============= EDIT ========
// Action = Update, means the request came from the Edit page
Else: $vAction == 'Update';

	// Convert action_params
	Include:'portfoliogroup_params.inc';
	Var:'vID' = '';
	Var:'vID' = (Action_Param:'ID');

	// Copying the ID to vNewID to build link
	// This is so we can just use vNewID at bottom of page for both add and edit
	Var:'vNewID'=(Var:'vID');

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to Update the record
		// Not changing the Date_Created fields
		Var:'SQLUpdatePortfolioGroup' = '/* SQLUpdatePortfolioGroup */
		UPDATE ' $svPortfolioGroupsTable ' SET
			pg_name="'		(Encode_SQL:$vpg_name) '",
			Active="'		(Encode_SQL:$vActive) '",
			DateModified="'	(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '"
			WHERE pg_groupid = "' $vID '"';

		If: $svDebug == 'Y';
			'224: SQLUpdatePortfolioGroup = ' $SQLUpdatePortfolioGroup '<br>\n';
		/If;
	
			Inline: $IV_Portfolios, -Table=$svPortfolioGroupsTable, -SQL=$SQLUpdatePortfolioGroup;
			
			If:(Error_CurrentError)==(Error_NoError);
		
				// If no error, Update was successful, dump out Error 1011 "Update Successful"
				Var:'vError' = '1011';
				Var:'vOption' = (Var:'vID');
				If: $svDebug == 'Y';
					'233: vError = ' $vError '<br>\n';
				/If;
		
			// There was an error
			Else;
				Var:'vError' = (Error_CurrentError);
			/If;
		
		/Inline;

	// vError == ''
	/If;

// ============= ASSIGN ========
Else: $vAction == 'Assign';
	// Convert action_params
	Include:'portfoliogroupassign_params.inc';

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// First delete all current assignments, then add the new ones
		Var:'SQLDeletePG2P' = 'DELETE FROM ' $svPG2PortfolioTable ' WHERE pg_groupid = "'(Var:'vPortfolioGroupID')'";';
		Inline: $IV_Portfolios, -SQL=$SQLDeletePG2P;
		/Inline;
		
		// Construct the query to Update the Project
		Var:'PortfolioEntryArray' = (array);

		// Append an extra return to fix problem of only one item being submit
		Var:'PortfolioEntryArray' = (Var:'vPortfolio_Entries')->(split:'\r');
		If: $svDebug == 'Y';
			'271: PortfolioEntryArray = ' $PortfolioEntryArray '<br>\n';
		/If;

		// Initialize the query string
		Var:'SQLAddPG2P' = (string);

		Iterate: $PortfolioEntryArray, (local:'i');

			// Copy the current iterate data to a local var for insertion into the query
			Local:'ThisArrayElement'= (#i);
			
			// Iterate through the Groups array, adding each INSERT command to the end
			$SQLAddPG2P += 'INSERT INTO ' $svPG2PortfolioTable ' (
				pg_groupid,
				portfolio_id)
				VALUES
				("'(Var:'vPortfolioGroupID')'",
				"'(#ThisArrayElement)'");';
			If: $svDebug == 'Y';
				'285: ThisArrayElement = ' #ThisArrayElement '<br>\n';
				'285: SQLAddPG2P = ' $SQLAddPG2P '<br>\n';
			/If;

		/Iterate;

		// Add the record
		Inline: $IV_Portfolios, -SQL=$SQLAddPG2P;
		/Inline;

		If:(Error_CurrentError)==(Error_NoError);
	
			// If no error, Update was successful, dump out Error 1011 "Update Successful"
			Var:'vError' = '1011';
			Var:'vOption' = 'portfolio group assignment';
	
		// There was an error
		Else;
			Var:'vError' = (Error_CurrentError);
		/If;
		

	// vError == ''
	/If;

	If: $svDebug == 'Y';
		'311: vError = ' $vError '<br>\n';
		'311: vOption = ' $vOption '<br>\n';
	/If;

// ============= DELETE ========
Else: $vAction == 'Delete';

	// Convert action_params
	Var:'vID'=(Action_Param:'ID');
		
	// Build the Delete Query
	Var:'SQLDeleteQuery' = (string);
	Var:'SQLDeleteQuery' = 'DELETE FROM ' $svSiteDatabase'.'$svPortfolioGroupsTable ' WHERE pg_groupid = "' $vID '"';
	
	// Delete the record
	Inline: $IV_Portfolios, -SQL=$SQLDeleteQuery;
		// If delete successful, output 1021 "Deletion Successful" and go ahead and delete attachments,
		If: (Error_Code) == '0';
			Var:'vError' = '1021';
			Var:'vOption' = $vID;
		// If delete failed, output error 1022, "Delete Failed"
		Else;
			Var:'vError' = '1022';
			Var:'vOption' = (Error_CurrentError);
			Var:'URL' = ('setup_addresponse.lasso?Error='$vError'&Option='$vOption);
			If: $svDebug == 'Y';
				'191: URL: ' $URL '<br>\n';
				'<a href="'$URL'">' $URL '</a><br>\n';
			Else;
				Redirect_URL: $URL;
			/If;
		/If;
	/Inline;

		
// Action is wrong, somebody is messing with us
// Dump out error 9002, "Database Error"
Else;
	Var:'vError' = '9002';
/If;


// Deal with the results of the processing

// ============= ADD  ========
// If any other error other than 1001 "Add Successful" do a redirect
If: $vAction == 'Add';
	// Standard Error Table
	If: (Var:'vError') == '1001' ;
		li_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');

// Edit New Listing Link -->
?>
<div align="left">
	View the record for <a href="setup_editrecord.lasso?Datatype=PortfolioGroup&ID=[Var:'vNewID']&New=Y"><b>[$vpg_name]</b></a>
</div>
<?Lassoscript
	Else;
		Var:'URL' = ('setup_add.lasso?Error='$vError'&Option='$vOption'&'(Client_POSTArgs));
		If: $svDebug == 'Y';
			'259: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
		Else;
			Redirect_URL: $URL;
		/If;
	/If;
/If;


// ============= EDIT ========
// If vAction = Edit, Always redirect to edit page
// If record updated OK, will get a 1011 "Update Successful" message, but do NOT pass the Params, only the ID
// This forces the system to do a new lookup
If: $vAction == 'Update';
	If: (Var:'vError') == '1011';
		Var:'URL' = ('setup_editrecord.lasso?Datatype=PortfolioGroup&ID='$vNewID'&New=Y&Error='$vError'&Option='$vOption);
	Else;
		Var:'URL' = ('setup_editrecord.lasso?New=Y&Error='$vError'&Option='$vOption'&'(Client_POSTArgs));
	/If;
	If: $svDebug == 'Y';
		'279: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
	Else;
		Redirect_URL: $URL;
	/If;
/If;

// ============= ASSIGN  ========
// If any other error other than 1011 "Add Successful" do a redirect
If: $vAction == 'Assign';
	If: (Var:'vError') == '1011';
		Var:'URL' = ('setup_editrecord.lasso?Datatype=PortfolioGroup&ID='$vPortfolioGroupID'&New=Y&Error='$vError'&Option='$vOption);
	Else;
		Var:'URL' = ('setup_editrecord.lasso?New=Y&Error='$vError'&Option='$vOption'&'(Client_POSTArgs));
	/If;
	If: $svDebug == 'Y';
		'295: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
	Else;
		Redirect_URL: $URL;
	/If;
/If;

// ============= DELETE ========
// If Action = Delete, redirect to editrecord page
If: $vAction == 'Delete';
	Var:'URL' = ('setup_search.lasso?Datatype=PortfolioGroup&Error='$vError'&Option='$vOption);
	If: $svDebug == 'Y';
		'307: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
	Else;
		Redirect_URL: $URL;
	/If;
/If;
?>
