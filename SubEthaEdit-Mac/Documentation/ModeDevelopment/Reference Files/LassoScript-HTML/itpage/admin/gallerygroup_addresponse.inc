<?Lassoscript
// Last modified: 7/20/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Include for Gallery Group add response page

// CHANGE NOTES
// 6/22/09
// First implementation
// 7/20/09
// Added code to delete $svGG2GalleryTable entries when Gallery Group is deleted

// Debugging
// Var:'svDebug' = 'Y';

// Converting action_params
Var:'vError' = '';
Var:'vOption' = '';
// The action_param "Action" is passed by the frm_gallery.inc form to indicate whether it is an add or edit
// Action = Update, means the request was an Edit (from frm_gallery.inc)
// Action = Add, means the request was an Add (from frm_gallery.inc)
Var:'vAction' = (Action_Param:'Action');

If: $svDebug == 'Y';
	'<br>\r';
	'<b>gallerygroup_addresponse.inc</b><br>\r';
/If;

// Checking referrer to make sure it's only posting from the Add page
// ============= ADD ========
If: $vAction == 'Add';

	// Convert action_params
	Include:'gallerygroup_params.inc';

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to add the record
		Var:'SQLQueryAddGallery' = '/* SQLQueryAddGallery */
		INSERT INTO ' $svSiteDatabase '.' $svGalleryGroupsTable
			' SET
				gg_name="'		(Encode_SQL:$vgg_name) '",
				gg_text="'		(Encode_SQL:$vgg_text) '",
				Active="'		(Encode_SQL:$vActive) '",
				DateCreated="'	(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '",
				DateModified="'	(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '";
				SELECT LAST_INSERT_ID() AS NewGalleryID;';
			
			If: $svDebug == 'Y';
				'128: SQLQueryAddGallery = ' $SQLQueryAddGallery '<br>\n';
			/If;
		
			Inline: $IV_Galleries, -Table=$svGalleryGroupsTable, -SQL=$SQLQueryAddGallery;
				
				If:(Error_CurrentError)==(Error_NoError);
			
					// If no error, Add was successful, dump out Error 1001 "Add Successful"
					// Copying NewGalleryID to vNewID to use in links
					Var:'vError' = '1001';
					Var:'vOption' = (Var:'vgg_name');
					Var:'vNewID' = (Field:'NewGalleryID');
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
	Include:'gallerygroup_params.inc';
	Var:'vID' = '';
	Var:'vID' = (Action_Param:'ID');

	// Copying the ID to vNewID to build link
	// This is so we can just use vNewID at bottom of page for both add and edit
	Var:'vNewID'=(Var:'vID');

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to Update the record
		// Not changing the Date_Created fields
		Var:'SQLUpdateGallery' = '/* SQLUpdateGallery */
		UPDATE ' $svGalleryGroupsTable ' SET
			gg_name="'		(Encode_SQL:$vgg_name) '",
			gg_text="'		(Encode_SQL:$vgg_text) '",
			Active="'		(Encode_SQL:$vActive) '",
			DateModified="'	(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '"
			WHERE gg_groupid = "' $vID '"';

		If: $svDebug == 'Y';
			'224: SQLUpdateGallery = ' $SQLUpdateGallery '<br>\n';
		/If;
	
			Inline: $IV_Galleries, -Table=$svGalleryGroupsTable, -SQL=$SQLUpdateGallery;
			
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
	Include:'gallerygroupassign_params.inc';

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// First delete all current assignments, then add the new ones
		Var:'SQLDeleteGG2G' = 'DELETE FROM ' $svGG2GalleryTable ' WHERE gg_groupid = "'(Var:'vGalleryGroupID')'";';
		Inline: $IV_Galleries, -SQL=$SQLDeleteGG2G;
		/Inline;
		
		// Construct the query to Update the Project
		Var:'GalleryEntryArray' = (array);

		// Append an extra return to fix problem of only one item being submit
		Var:'GalleryEntryArray' = (Var:'vGallery_Entries')->(split:'\r');
		If: $svDebug == 'Y';
			'271: GalleryEntryArray = ' $GalleryEntryArray '<br>\n';
		/If;

		// Initialize the query string
		Var:'SQLAddGG2G' = (string);

		Iterate: $GalleryEntryArray, (local:'i');

			// Copy the current iterate data to a local var for insertion into the query
			Local:'ThisArrayElement'= (#i);
			
			// Iterate through the Groups array, adding each INSERT command to the end
			$SQLAddGG2G += 'INSERT INTO ' $svGG2GalleryTable ' (
				gg_groupid,
				gallery_id)
				VALUES
				("'(Var:'vGalleryGroupID')'",
				"'(#ThisArrayElement)'");';
			If: $svDebug == 'Y';
				'285: ThisArrayElement = ' #ThisArrayElement '<br>\n';
				'285: SQLAddGG2G = ' $SQLAddGG2G '<br>\n';
			/If;

		/Iterate;

		// Add the record
		Inline: $IV_Galleries, -SQL=$SQLAddGG2G;
		/Inline;

		If:(Error_CurrentError)==(Error_NoError);
	
			// If no error, Update was successful, dump out Error 1011 "Update Successful"
			Var:'vError' = '1011';
			Var:'vOption' = 'gallery group assignment';
	
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
	Var:'SQLDeleteQuery' = 'DELETE FROM ' $svSiteDatabase'.'$svGalleryGroupsTable ' WHERE gg_groupid = "' $vID '"';
	
	// Delete the record
	Inline: $IV_Galleries, -SQL=$SQLDeleteQuery;
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

	// Build the Delete Query
	Var:'SQLDeleteGGQuery' = (string);
	Var:'SQLDeleteGGQuery' = 'DELETE FROM ' $svSiteDatabase'.'$svGG2GalleryTable ' WHERE gg_groupid = "' $vID '"';
	
	// Delete the record
	Inline: $IV_Galleries, -SQL=$SQLDeleteGGQuery;
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
				'239: URL: ' $URL '<br>\n';
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
	View the record for <a href="setup_editrecord.lasso?Datatype=GalleryGroup&ID=[Var:'vNewID']&New=Y"><b>[$vgg_name]</b></a>
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
		Var:'URL' = ('setup_editrecord.lasso?Datatype=GalleryGroup&ID='$vNewID'&New=Y&Error='$vError'&Option='$vOption);
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
		Var:'URL' = ('setup_editrecord.lasso?Datatype=GalleryGroup&ID='$vGalleryGroupID'&New=Y&Error='$vError'&Option='$vOption);
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
	Var:'URL' = ('setup_search.lasso?Datatype=GalleryGroup&Error='$vError'&Option='$vOption);
	If: $svDebug == 'Y';
		'307: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
	Else;
		Redirect_URL: $URL;
	/If;
/If;
?>
