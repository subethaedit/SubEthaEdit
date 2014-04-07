<?Lassoscript
// Last modified 1/15/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Include for Story add response page

// CHANGE NOTES
// 1/15/09
// First implementation

// Debugging
// Var:'svDebug' = 'Y';

// Converting action_params
Var:'vError' = '';
Var:'vOption' = '';
// The action_param "Action" is passed by the frm_story.inc form to indicate whether it is an add or edit
// Action = Update, means the request was an Edit (from frm_story.inc)
// Action = Add, means the request was an Add (from frm_story.inc)
Var:'vAction' = (Action_Param:'Action');

If: $svDebug == 'Y';
	'<br>\r';
	'<b>story_addresponse.inc</b><br>\r';
/If;

// Checking referrer to make sure it's only posting from the Add page
// ============= ADD ========
If: $vAction == 'Add';

	// Convert action_params
	Include:'story_params.inc';

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to add the record
		Var:'SQLQueryAddStory' = '/* SQLQueryAddStory */
		INSERT INTO ' $svSiteDatabase '.' $svStoriesTable
			' SET
				Story_Head="' (Encode_SQL:$vStory_Head) '",
				Story_Comment="'(Encode_SQL:$vStory_Comment) '",
				Story_Name="' (Encode_SQL:$vStory_Name) '",
				Story_Thumb="' (Encode_SQL:$vStory_Thumb) '",
				Active="'			(Encode_SQL:$vActive) '",
				DateCreated="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '",
				DateModified="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '";
				SELECT LAST_INSERT_ID() AS NewStoryID;';
			
			If: $svDebug == 'Y';
				'128: SQLQueryAddStory = ' $SQLQueryAddStory '<br>\n';
			/If;
		
			Inline: $IV_Stories, -Table=$svStoriesTable, -SQL=$SQLQueryAddStory;
				
				If:(Error_CurrentError)==(Error_NoError);
			
					// If no error, Add was successful, dump out Error 1001 "Add Successful"
					// Copying NewStoryID to vNewID to use in links
					Var:'vError' = '1001';
					Var:'vOption' = (Var:'vHeadline');
					Var:'vNewID' = (Field:'NewStoryID');
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
	Include:'story_params.inc';
	Var:'vID' = '';
	Var:'vID' = (Action_Param:'ID');

	// Copying the ID to vNewID to build link
	// This is so we can just use vNewID at bottom of page for both add and edit
	Var:'vNewID'=(Var:'vID');

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to Update the record
		// Not changing the Date_Created fields
		Var:'SQLUpdateStories' = '/* SQLUpdateStories */
		UPDATE ' $svStoriesTable ' SET
			Story_Head="' (Encode_SQL:$vStory_Head) '",
			Story_Comment="'(Encode_SQL:$vStory_Comment) '",
			Story_Name="' (Encode_SQL:$vStory_Name) '",
			Story_Thumb="' (Encode_SQL:$vStory_Thumb) '",
			Active="'			(Encode_SQL:$vActive) '",
			DateModified="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '"
			WHERE ID = "' $vID '"';

		If: $svDebug == 'Y';
			'224: SQLUpdateStories = ' $SQLUpdateStories '<br>\n';
		/If;
	
		Inline: $IV_Stories, -Table=$svStoriesTable, -SQL=$SQLUpdateStories;
			
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

// ============= DELETE ========
Else: $vAction == 'Delete';

	// Convert action_params
	Var:'vID'=(Action_Param:'ID');
		
	// Build the Delete Query
	Var:'SQLDeleteQuery' = (string);
	Var:'SQLDeleteQuery' = 'DELETE FROM ' $svSiteDatabase'.'$svStoriesTable ' WHERE ID = "' $vID '"';
	
	// Delete the record
	Inline: $IV_Stories, -SQL=$SQLDeleteQuery;
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
	View the record for <a href="setup_editrecord.lasso?Datatype=Story&ID=[Var:'vNewID']&New=Y"><b>Record [$vNewID]</b></a>
</div>
<?Lassoscript
	Else;
		Var:'URL' = ('setup_add.lasso?Error='$vError'&Option='$vOption'&'(Client_POSTArgs));
		If: $svDebug == 'Y';
			'342: URL = ' $URL '<br>';
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
		Var:'URL' = ('setup_editrecord.lasso?Datatype=Story&ID='$vNewID'&New=Y&Error='$vError'&Option='$vOption);
	Else;
		Var:'URL' = ('setup_editrecord.lasso?New=Y&Error='$vError'&Option='$vOption'&'(Client_POSTArgs));
	/If;
	If: $svDebug == 'Y';
		'362: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
	Else;
		Redirect_URL: $URL;
	/If;
/If;

// ============= DELETE ========
// If Action = Delete, redirect to editrecord page
If: $vAction == 'Delete';
	Var:'URL' = ('setup_search.lasso?Datatype=Story&Error='$vError'&Option='$vOption);
	If: $svDebug == 'Y';
		'257: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
	Else;
		Redirect_URL: $URL;
	/If;
/If;
?>
