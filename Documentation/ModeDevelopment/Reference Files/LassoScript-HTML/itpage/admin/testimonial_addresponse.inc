<?Lassoscript
// Last modified: 11/27/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// Include for Testimonial add response page

// CHANGE NOTES
// 11/27/07
// First implementation
// 12/1/07
// Changing redirect for delete to go to setup_search

// Debugging
// Var:'svDebug' = 'Y';

// Converting action_params
Var:'vError' = '';
Var:'vOption' = '';
// The action_param "Action" is passed by the frm_testimonial.inc form to indicate whether it is an add or edit
// Action = Update, means the request was an Edit (from frm_testimonial.inc)
// Action = Add, means the request was an Add (from frm_testimonial.inc)
Var:'vAction' = (Action_Param:'Action');

If: $svDebug == 'Y';
	'<br>\r';
	'<b>testimonial_addresponse.inc</b><br>\r';
/If;

// Checking referrer to make sure it's only posting from the Add page
// ============= ADD ========
If: $vAction == 'Add';

	// Convert action_params
	Include:'testimonial_params.inc';

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to add the record
		Var:'SQLQueryAddTestimonial' = '/* SQLQueryAddTestimonial */
		INSERT INTO ' $svSiteDatabase '.' $svTestimonialsTable
			' SET
				Testimonial_Head="' (Encode_SQL:$vTestimonial_Head) '",
				Testimonial_Comment="'(Encode_SQL:$vTestimonial_Comment) '",
				Testimonial_Name="' (Encode_SQL:$vTestimonial_Name) '",
				Testimonial_Thumb="' (Encode_SQL:$vTestimonial_Thumb) '",
				Active="'			(Encode_SQL:$vActive) '",
				DateCreated="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '",
				DateModified="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '";
				SELECT LAST_INSERT_ID() AS NewTestimonialID;';
			
			If: $svDebug == 'Y';
				'128: SQLQueryAddTestimonial = ' $SQLQueryAddTestimonial '<br>\n';
			/If;
		
			Inline: $IV_Testimonials, -Table=$svTestimonialsTable, -SQL=$SQLQueryAddTestimonial;
				
				If:(Error_CurrentError)==(Error_NoError);
			
					// If no error, Add was successful, dump out Error 1001 "Add Successful"
					// Copying NewTestimonialID to vNewID to use in links
					Var:'vError' = '1001';
					Var:'vOption' = (Var:'vHeadline');
					Var:'vNewID' = (Field:'NewTestimonialID');
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
	Include:'testimonial_params.inc';
	Var:'vID' = '';
	Var:'vID' = (Action_Param:'ID');

	// Copying the ID to vNewID to build link
	// This is so we can just use vNewID at bottom of page for both add and edit
	Var:'vNewID'=(Var:'vID');

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to Update the record
		// Not changing the Date_Created fields
		Var:'SQLUpdateTestimonials' = '/* SQLUpdateTestimonials */
		UPDATE ' $svTestimonialsTable ' SET
			Testimonial_Head="' (Encode_SQL:$vTestimonial_Head) '",
			Testimonial_Comment="'(Encode_SQL:$vTestimonial_Comment) '",
			Testimonial_Name="' (Encode_SQL:$vTestimonial_Name) '",
			Testimonial_Thumb="' (Encode_SQL:$vTestimonial_Thumb) '",
			Active="'			(Encode_SQL:$vActive) '",
			DateModified="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '"
			WHERE ID = "' $vID '"';

		If: $svDebug == 'Y';
			'224: SQLUpdateTestimonials = ' $SQLUpdateTestimonials '<br>\n';
		/If;
	
		Inline: $IV_Testimonials, -Table=$svTestimonialsTable, -SQL=$SQLUpdateTestimonials;
			
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
	Var:'SQLDeleteQuery' = 'DELETE FROM ' $svSiteDatabase'.'$svTestimonialsTable ' WHERE ID = "' $vID '"';
	
	// Delete the record
	Inline: $IV_Testimonials, -SQL=$SQLDeleteQuery;
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
	View the record for <a href="setup_editrecord.lasso?Datatype=Testimonial&ID=[Var:'vNewID']&New=Y"><b>Record [$vNewID]</b></a>
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
		Var:'URL' = ('setup_editrecord.lasso?Datatype=Testimonial&ID='$vNewID'&New=Y&Error='$vError'&Option='$vOption);
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
	Var:'URL' = ('setup_search.lasso?Datatype=Testimonial&Error='$vError'&Option='$vOption);
	If: $svDebug == 'Y';
		'257: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
	Else;
		Redirect_URL: $URL;
	/If;
/If;
?>
