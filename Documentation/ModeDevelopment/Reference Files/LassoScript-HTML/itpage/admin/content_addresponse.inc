<?Lassoscript
// Last modified 11/30/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Include for content add response page

// CHANGE NOTES
// 10/12/07
// Recoded for CMS v. 3.0
// 11/15/07
// Added five new fields for SEO tailoring: Keywords, Author, Description, Copyright, Title
// Switched fields CategoriesID to HeirarchyID, removed SectionID as it is now obsolete
// 4/2/08
// Added code for URL Fix (Issue #547)
// 1/15/09
// Added Story field
// 6/22/09
// Added gallery feature
// 8/25/09
// Adding page stylesheet
// 11/24/09
// Add Show in Navigation field
// 11/30/10
// Added "Duplicate" this page functionality

// Debugging
// Var:'svDebug' = 'Y';

// Converting action_params
Var:'vError' = '';
Var:'vOption' = '';
// The action_param "Action" is passed by the frm_content.inc form to indicate whether it is an add or edit
// Action = Update, means the request was an Edit (from frm_content.inc)
// Action = Add, means the request was an Add (from frm_content.inc)
// Action = Duplicate, means the request was to duplicate an existing page (from frm_content.inc). Treated same as "add".
Var:'vAction' = (Action_Param:'Action');

If: $svDebug == 'Y';
	'<br>\r';
	'<b>content_addresponse.inc</b><br>\r';
/If;

// Checking referrer to make sure it's only posting from the Add page
// ============= ADD ========
If( ($vAction == 'Add') || ($vAction == 'Duplicate') );

	// Convert action_params
	Include:'content_params.inc';

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to add the record
		Var:'SQLQueryAddContent' = '/* SQLQueryAddContent */
		INSERT INTO ' $svSiteDatabase '.' $svContentTable
			' SET
				HeirarchyID="' 		(Encode_SQL:$vHeirarchyID) '",
				Headline="'	 		(Encode_SQL:$vHeadline) '",
				URLSlug="'	 		(Encode_SQL:$vURLSlug) '",
				Subhead="' 			(Encode_SQL:$vSubhead) '",
				Author="' 			(Encode_SQL:$vAuthor) '",
				Text_1="' 			(Encode_SQL:$vText_1) '",
				Text_2="'			(Encode_SQL:$vText_2) '",
				Image_thumb="'		(Encode_SQL:$vImage_thumb) '",
				Image_med="'		(Encode_SQL:$vImage_med) '",
				Image_large="'		(Encode_SQL:$vImage_large) '",
				Image_title="'		(Encode_SQL:$vImage_title) '",
				Image_caption="'	(Encode_SQL:$vImage_caption) '",
				Media_File="'		(Encode_SQL:$vMedia_File) '",
				Price_1="'			(Encode_SQL:$vPrice_1) '",
				Price_2="'	 		(Encode_SQL:$vPrice_2) '",
				URL="'				(Encode_SQL:$vURL) '",
				PageKeywords="'		(Encode_SQL:$vPageKeywords) '",
				PageAuthor="'		(Encode_SQL:$vPageAuthor) '",
				PageDescription="'	(Encode_SQL:$vPageDescription) '",
				PageCopyright="' 	(Encode_SQL:$vPageCopyright) '",
				PageTitle="'  		(Encode_sql:$vPageTitle) '",
				PageTemplate="' 	(Encode_sql:$vPageTemplate) '",
				PageStylesheet="' 	(Encode_sql:$vPageStylesheet) '",
				PortfolioGroupID="' (Encode_sql:$vPortfolioGroupID) '",
				GalleryGroupID="' 	(Encode_sql:$vGalleryGroupID) '",
				Testimonial="'	 	(Encode_sql:$vTestimonial) '",
				Story="'		 	(Encode_sql:$vStory) '",
				SortOrder="'		(Encode_SQL:$vSortOrder) '",
				Active="'			(Encode_SQL:$vActive) '",
				ActiveFrom="'		(Encode_SQL:$vActiveFrom) '",
				ActiveTo="'			(Encode_SQL:$vActiveTo) '",
				ShowInNav="'		(Encode_SQL:$vShowInNav) '",
				AttachPopup="'		(Encode_SQL:$vAttachPopup) '",
				DateCreated="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '",
				DateModified="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '";
				SELECT LAST_INSERT_ID() AS NewContentID;';
			
			If: $svDebug == 'Y';
				'128: SQLQueryAddContent = ' $SQLQueryAddContent '<br>\n';
			/If;
		
			Inline: $IV_Content, -Table=$svContentTable, -SQL=$SQLQueryAddContent;
				
				If:(Error_CurrentError)==(Error_NoError);
			
					// If no error, Add was successful, dump out Error 1001 "Add Successful"
					// Copying ContentID to vNewID to use in links
					Var:'vError' = '1001';
					Var:'vOption' = (Var:'vHeadline');
					Var:'vNewID' = (Field:'NewContentID');
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
	Include:'content_params.inc';
	Var:'vID' = '';
	Var:'vID' = (Action_Param:'ID');

	// Copying the ID to vNewID to build link
	// This is so we can just use vNewID at bottom of page for both add and edit
	Var:'vNewID'=(Var:'vID');

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Construct the query to Update the record
		// Not changing the Date_Created fields
		Var:'SQLUpdateContent' = '/* SQLUpdateContent */
		UPDATE ' $svContentTable ' SET
			HeirarchyID="'	 	(Encode_SQL:$vHeirarchyID) '",
			Headline="'	 		(Encode_SQL:$vHeadline) '",
			URLSlug="'	 		(Encode_SQL:$vURLSlug) '",
			Subhead="' 			(Encode_SQL:$vSubhead) '",
			Author="' 			(Encode_SQL:$vAuthor) '",
			Text_1="' 			(Encode_SQL:$vText_1) '",
			Text_2="'			(Encode_SQL:$vText_2) '",
			Image_thumb="'		(Encode_SQL:$vImage_thumb) '",
			Image_med="'		(Encode_SQL:$vImage_med) '",
			Image_large="'		(Encode_SQL:$vImage_large) '",
			Image_title="'		(Encode_SQL:$vImage_title) '",
			Image_caption="'	(Encode_SQL:$vImage_caption) '",
			Media_File="'		(Encode_SQL:$vMedia_FIle) '",
			Price_1="'			(Encode_SQL:$vPrice_1) '",
			Price_2="'	 		(Encode_SQL:$vPrice_2) '",
			URL="'				(Encode_SQL:$vURL) '",
			PageKeywords="' 	(Encode_SQL:$vPageKeywords) '",
			PageAuthor="'		(Encode_SQL:$vPageAuthor) '",
			PageDescription="' 	(Encode_SQL:$vPageDescription) '",
			PageCopyright="'  	(Encode_SQL:$vPageCopyright) '",
			PageTitle="'  		(Encode_sql:$vPageTitle) '",
			PageTemplate="'  	(Encode_sql:$vPageTemplate) '",
			PageStylesheet="'  	(Encode_sql:$vPageStylesheet) '",
			PortfolioGroupID="' (Encode_sql:$vPortfolioGroupID) '",
			GalleryGroupID="' 	(Encode_sql:$vGalleryGroupID) '",
			Testimonial="'	 	(Encode_sql:$vTestimonial) '",
			Story="'		 	(Encode_sql:$vStory) '",
			SortOrder="'		(Encode_SQL:$vSortOrder) '",
			Active="'			(Encode_SQL:$vActive) '",
			ActiveFrom="'		(Encode_SQL:$vActiveFrom) '",
			ActiveTo="'			(Encode_SQL:$vActiveTo) '",
			ShowInNav="'		(Encode_SQL:$vShowInNav) '",
			AttachPopup="'		(Encode_SQL:$vAttachPopup) '",
			DateModified="'		(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '"

			WHERE ID = "' $vID '"';

		If: $svDebug == 'Y';
			'224: SQLUpdateContent = ' $SQLUpdateContent '<br>\n';
		/If;
	
		Inline: $IV_Content, -Table=$svContentTable, -SQL=$SQLUpdateContent;
			
			If:(Error_CurrentError)==(Error_NoError);
		
				// If no error, Update was successful, dump out Error 1011 "Update Successful"
				Var:'vError' = '1011';
				Var:'vOption' = (Var:'vDisplayName');
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
	Var:'SQLDeleteQuery' = 'DELETE FROM ' $svSiteDatabase'.'$svContentTable ' WHERE ID = "' $vID '"';
	
	// Delete the record
	Inline: $IV_Content, -SQL=$SQLDeleteQuery;
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
If( ($vAction == 'Add') || ($vAction == 'Duplicate') );
	// Standard Error Table
	If: (Var:'vError') == '1001' ;
		li_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');

// Edit New Listing Link -->
?>
<div align="left">
	View the record for <a href="setup_editrecord.lasso?Datatype=Content&ID=[Var:'vNewID']&New=Y"><b>[$vDisplayName]</b></a>
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
		Var:'URL' = ('setup_editrecord.lasso?Datatype=Content&ID='$vNewID'&New=Y&Error='$vError'&Option='$vOption);
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
	Var:'URL' = ('setup_editrecord.lasso?Datatype=Content&Error='$vError'&Option='$vOption);
	If: $svDebug == 'Y';
		'257: URL = ' $URL '<br>';
		'<a href="'$URL'">' $URL '</a><br>\n';
	Else;
		Redirect_URL: $URL;
	/If;
/If;
?>
