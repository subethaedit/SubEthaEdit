<?Lassoscript
// Last modified 5/20/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Include for user add response page

// Debugging
// Var:'svDebug' = 'Y';

// Converting action_params
Var:'vError' = '';
Var:'vOption' = '';
// The action_param "Action" is passed by the frm_user.inc form to indicate whether it is an add or edit
// Action = Update, means the request was an Edit (from frm_user.inc)
// Action = Add, means the request was an Add (from frm_user.inc)
Var:'vAction' = (Action_Param:'Action');

If: $svDebug == 'Y';
	'<p class="debug"><strong>user_addresponse.inc</strong></p>\n';
/If;

// Checking action to make sure it's only posting from the Add page
// ============= ADD ========
If: $vAction == 'Add';

	// Convert action_params
	Include:'user_params.inc';

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

		// Query Users database
		// Searching for Login ID
		// If user does not exist, then add them. This avoids multiple entries of the same file
		Var:'SQLSearchUsers'='SELECT User_LoginID FROM ' $svUsersTable ' WHERE User_LoginID = "' $vUser_LoginID '"';
		Inline: $IV_Users, -SQL=$SQLSearchUsers;
	
			If: $svDebug == 'Y';
				'<p class="debug">\n';
				'27: SQLSearchUsers ' $SQLSearchUsers '<br>\r';
				'27: Found in Users? ' (Found_Count) '</p>\r';
			/If;
	
			// If no user found, add the record
			If: (Found_Count) == 0;
	
				// Fix special data problems
				// Create User_ID
				Var:'NewCreateUID' = Create_UID;
		
				// Encrypt the password
				Var:'vUser_LoginPW'=(Encrypt_MD5:($vUser_LoginPWTemp));
		
				// Create name to display
				Var:'vDisplayName' = $vUser_FName ' ' $vUser_LName;
			
				// Construct the query to add the User
				Var:'SQLAddUser' = '
				INSERT INTO ' $svUsersTable'  (
					User_ID,
					Userprivs_PrivID,
					User_LoginID,
					User_LoginPW,
					User_FName,
					User_LName,
					User_Company,
					User_Dept,
					User_Address1,
					User_Address2,
					User_City,
					States_StateAbbrev,
					User_Zip,
					User_Country,
					User_Email,
					User_Notify,
					User_WorkPhone,
					User_HomePhone,
					User_CellPhone,
					User_Fax,
					User_Website,
					User_Chat,
					User_QuestionID,
					User_Answer,
					User_Comments,
					User_Active,
					User_LastAccess,
					DateCreated,
					DateModified
					) 
				VALUES ("'
					$NewCreateUID '",
					"'(Encode_SQL:(Var:'vUserprivs_PrivID'))'",
					"'(Encode_SQL:(Var:'vUser_LoginID'))'",
					"'(Encode_SQL:(Var:'vUser_LoginPW'))'",
					"'(Encode_SQL:(Var:'vUser_FName'))'",
					"'(Encode_SQL:(Var:'vUser_LName'))'",
					"'(Encode_SQL:(Var:'vUser_Company'))'",
					"'(Encode_SQL:(Var:'vUser_Dept'))'",
					"'(Encode_SQL:(Var:'vUser_Address1'))'",
					"'(Encode_SQL:(Var:'vUser_Address2'))'",
					"'(Encode_SQL:(Var:'vUser_City'))'",
					"'(Encode_SQL:(Var:'vState_Abbrev'))'",
					"'(Encode_SQL:(Var:'vUser_Zip'))'",
					"'(Encode_SQL:(Var:'vUser_Country'))'",
					"'(Encode_SQL:(Var:'vUser_Email'))'",
					"'(Encode_SQL:(Var:'vUser_Notify'))'",
					"'(Encode_SQL:(Var:'vUser_WorkPhone'))'",
					"'(Encode_SQL:(Var:'vUser_HomePhone'))'",
					"'(Encode_SQL:(Var:'vUser_CellPhone'))'",
					"'(Encode_SQL:(Var:'vUser_Fax'))'",
					"'(Encode_SQL:(Var:'vUser_Website'))'",
					"'(Encode_SQL:(Var:'vUser_Chat'))'",
					"'(Encode_SQL:(Var:'vUser_QuestionID'))'",
					"'(Encode_SQL:(Var:'vUser_Answer'))'",
					"'(Encode_SQL:(Var:'vUser_Comments'))'",
					"'(Encode_SQL:(Var:'vUser_Active'))'",
					"0000-00-00",
					"'(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '",
					"'(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '");';
			
					If: $svDebug == 'Y';
						'<p class="debug">\n';
						'128: SQLAddUser = ' $SQLAddUser '</p>\n';
					/If;
			
				Inline: $IV_Users, -SQL=$SQLAddUser;
					
					If:(Error_CurrentError)==(Error_NoError);
				
						// If no error, Add was successful, dump out Error 1001 "Add Successful"
						Var:'vError' = '1001';
						Var:'vOption' = (Var:'vDisplayName');
						If: $svDebug == 'Y';
							'<p class="debug">\n';
							'137: vError = ' $vError '<br>\n';
							'137: vOption = ' $vOption '<br>\n';
							'137: vDisplayName = ' $vDisplayName '</p>\n';
						/If;
				
						// Copying just-added record ID to vNewUserID to build link
						// Copying NewCreateUID for new user to vNewUserID to build link
						Var:'vNewUserID' = $NewCreateUID;

						// Send an e-mail to the new user
						// 11/8/07 Webmail.us Secure SMTP Settings
						// NOTE: "Sender" param should be the ID of the form to be tracked
						// Make sure there is no space in the "Sender" param
						Email_Send:
							-Host=$svSMTP,
							-From=$svPostmasterEmail,
							-To=$vUser_Email,
							-Subject='Welcome to the CMS',
							-Username=$svAuthUsername,
							-Password=$svAuthPassword,
							-ReplyTo=$svPostmasterEmail,
							-Sender=(($svDomain)':/admin/user_addresponse'),
							-Body=(Include:($svLibsPath)'email_newuser.txt'),
							-SimpleForm;

					// There was an error
					Else;
						Var:'vError' = (Error_CurrentError);
					/If;
				
				/Inline;
			
			// User found in Users table, output 5026 "Duplicate User" error
			Else;
				Var:'vError' = '5026';
			/If;	

		/Inline;

	/If;

// ============= EDIT ========
// Action = Update, means the request came from the Edit page
Else: $vAction == 'Update';

	// Convert action_params
	Include:'user_params.inc';
	Var:'vUser_ID' = '';
	Var:'vUser_ID' = (Action_Param:'ID');

	// Copying the User ID to vNewUserID to build link
	// This is so we can just use vNewUserID at bottom of page for both add and edit
	Var:'vNewUserID'=(Var:'vUser_ID');

	// If an error was generated from the Params, no point continuing, so bail immediately
	If: $vError == '';

			// If no user found, add the record
			If: (Found_Count) == 0;
	
				// Fix special data problems
		
				// Encrypt the password
				Var:'vUser_LoginPW'=(Encrypt_MD5:($vUser_LoginPWTemp));
		
				// Create name to display
				Var:'vDisplayName' = $vUser_FName ' ' $vUser_LName;
			
				// Construct the query to Update the User
				// Not changing the User_LastAccess or Date_Created fields
				// Use two different queries, one if the password WAS submit, another if it wasn't
				// The only difference is if the password WAS submit, add it to the UPDATE
				If: (Var:'vUser_LoginPW') != '';
					Var:'SQLUpdateUser' = '
					UPDATE ' $svUsersTable ' SET
						Userprivs_PrivID = "'(Encode_SQL:(Var:'vUserprivs_PrivID'))'",
						User_LoginID = "'(Encode_SQL:(Var:'vUser_LoginID'))'",
						User_LoginPW = "'(Encode_SQL:(Var:'vUser_LoginPW'))'",
						User_FName = "'(Encode_SQL:(Var:'vUser_FName'))'",
						User_LName = "'(Encode_SQL:(Var:'vUser_LName'))'",
						User_Company = "'(Encode_SQL:(Var:'vUser_Company'))'",
						User_Dept = "'(Encode_SQL:(Var:'vUser_Dept'))'",
						User_Address1 = "'(Encode_SQL:(Var:'vUser_Address1'))'",
						User_Address2 = "'(Encode_SQL:(Var:'vUser_Address2'))'",
						User_City = "'(Encode_SQL:(Var:'vUser_City'))'",
						States_StateAbbrev = "'(Encode_SQL:(Var:'vState_Abbrev'))'",
						User_Zip = "'(Encode_SQL:(Var:'vUser_Zip'))'",
						User_Country = "'(Encode_SQL:(Var:'vUser_Country'))'",
						User_Email = "'(Encode_SQL:(Var:'vUser_Email'))'",
						User_Notify = "'(Encode_SQL:(Var:'vUser_Notify'))'",
						User_WorkPhone = "'(Encode_SQL:(Var:'vUser_WorkPhone'))'",
						User_HomePhone = "'(Encode_SQL:(Var:'vUser_HomePhone'))'",
						User_CellPhone = "'(Encode_SQL:(Var:'vUser_CellPhone'))'",
						User_Fax = "'(Encode_SQL:(Var:'vUser_Fax'))'",
						User_Website = "'(Encode_SQL:(Var:'vUser_Website'))'",
						User_Chat = "'(Encode_SQL:(Var:'vUser_Chat'))'",
						User_QuestionID = "'(Encode_SQL:(Var:'vUser_QuestionID'))'",
						User_Answer = "'(Encode_SQL:(Var:'vUser_Answer'))'",
						User_Comments = "'(Encode_SQL:(Var:'vUser_Comments'))'",
						User_Active = "'(Encode_SQL:(Var:'vUser_Active'))'",
						DateModified = "'(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '"
						WHERE User_ID = "' $vUser_ID '"';
				Else;
					Var:'SQLUpdateUser' = '
					UPDATE ' $svUsersTable ' SET
						Userprivs_PrivID = "'(Encode_SQL:(Var:'vUserprivs_PrivID'))'",
						User_LoginID = "'(Encode_SQL:(Var:'vUser_LoginID'))'",
						User_FName = "'(Encode_SQL:(Var:'vUser_FName'))'",
						User_LName = "'(Encode_SQL:(Var:'vUser_LName'))'",
						User_Company = "'(Encode_SQL:(Var:'vUser_Company'))'",
						User_Dept = "'(Encode_SQL:(Var:'vUser_Dept'))'",
						User_Address1 = "'(Encode_SQL:(Var:'vUser_Address1'))'",
						User_Address2 = "'(Encode_SQL:(Var:'vUser_Address2'))'",
						User_City = "'(Encode_SQL:(Var:'vUser_City'))'",
						States_StateAbbrev = "'(Encode_SQL:(Var:'vState_Abbrev'))'",
						User_Zip = "'(Encode_SQL:(Var:'vUser_Zip'))'",
						User_Country = "'(Encode_SQL:(Var:'vUser_Country'))'",
						User_Email = "'(Encode_SQL:(Var:'vUser_Email'))'",
						User_Notify = "'(Encode_SQL:(Var:'vUser_Notify'))'",
						User_WorkPhone = "'(Encode_SQL:(Var:'vUser_WorkPhone'))'",
						User_HomePhone = "'(Encode_SQL:(Var:'vUser_HomePhone'))'",
						User_CellPhone = "'(Encode_SQL:(Var:'vUser_CellPhone'))'",
						User_Fax = "'(Encode_SQL:(Var:'vUser_Fax'))'",
						User_Website = "'(Encode_SQL:(Var:'vUser_Website'))'",
						User_Chat = "'(Encode_SQL:(Var:'vUser_Chat'))'",
						User_QuestionID = "'(Encode_SQL:(Var:'vUser_QuestionID'))'",
						User_Answer = "'(Encode_SQL:(Var:'vUser_Answer'))'",
						User_Comments = "'(Encode_SQL:(Var:'vUser_Comments'))'",
						User_Active = "'(Encode_SQL:(Var:'vUser_Active'))'",
						DateModified = "'(Date_Format:(Date_GetCurrentDate),-DateFormat='%Q') '"
						WHERE User_ID = "' $vUser_ID '"';
					/If;

						If: $svDebug == 'Y';
							'<p class="debug">\n';
							'224: SQLUpdateUser = ' $SQLUpdateUser '</p>\n';
						/If;
			
				Inline: $IV_Users, -SQL=$SQLUpdateUser;
					
					If:(Error_CurrentError)==(Error_NoError);
				
						// If no error, Update was successful, dump out Error 1011 "Update Successful"
						Var:'vError' = '1011';
						Var:'vOption' = (Var:'vDisplayName');
						If: $svDebug == 'Y';
							'<p class="debug">\n';
							'233: vError = ' $vError '<br>\n';
							'233: vOption = ' $vOption '</p>\n';
						/If;
				
					// There was an error
					Else;
						Var:'vError' = (Error_CurrentError);
					/If;
				
				/Inline;

			// Found_Count = 0
			/If;

		// vError == ''
		/If;
		
// Referrer not good, somebody is messing with us
// Dump out error 9002, "Database Error"
Else;
	Var:'vError' = '9002';
/If;


// Deal with the results of the processing

// ============= ADD  ========
// If any other error other than 1001 "Add Successful" do a redirect
If: $vAction == 'Add';
	// Standard Error Table
	If: (Var:'vError') == '1001';
		LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
// Edit New Listing Link
?>
<div align="left">
	View the record for <a href="setup_editrecord.lasso?Datatype=User&ID=[Var:'vNewUserID']&New=Y"><strong>[$vDisplayName]</strong></a>
</div>
<?Lassoscript
	Else;
		LI_URLRedirect: -Page='setup_add.lasso',-UseError='Y',-Error=$vError,-Option=$vOption,-UseArgs='Y';
	/If;
/If;

// ============= EDIT ========
// If vAction = Edit, Always redirect to edit page
// If record updated OK, will get a 1011 "Update Successful" message, but do NOT pass the Params, only the ID
// This forces the system to do a new lookup
If: $vAction == 'Update';
	If: (Var:'vError') == '1011';
		LI_URLRedirect: -Page='setup_editrecord.lasso',-ExParams=('Datatype=User&ID='($vNewUserID)'&New=Y'),-UseError='Y',-Error=$vError,-Option=$vOption;
	Else;
		LI_URLRedirect: -Page='setup_editrecord.lasso',-ExParams='New=Y',-UseError='Y',-Error=$vError,-Option=$vOption,-UseArgs='Y';
	/If;
/If;

?>
