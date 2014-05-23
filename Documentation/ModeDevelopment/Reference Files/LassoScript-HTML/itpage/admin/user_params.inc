<?Lassoscript
// Last modified 10/2/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file is included in the add pages to process action_params

// Copying Action_Params to vars
// Remove leading and trailing spaces
// Password is MD5 encrypted
// If required is missing, output an error
// If multiple errors, they will step on each other, but not worried about it

// CHANGE NOTES
// 10/12/07
// Recoded for Clean URLs
// 10/2/09
// Correct the comment (above) about encryption

If: (Action_Param:'Error') != '';
	Var:'vError' = (Action_Param:'Error');
/If;
If: (Action_Param:'Option') != '';
	Var:'vOption' = (Action_Param:'Option');
/If;

// Pass a param "New" through the URL to indicate it is a new page
Var:'vNew' = (Action_Param:'New');

Var:'vUser_ID' = '';
Var:'vUser_ID' = (Action_Param:'ID');
Var:'vProcess' = (Action_Param:'Process');

Var:'vUserprivs_PrivID'=(Action_Param:'Privs');
	$vUserprivs_PrivID->trim;
Var:'vUser_LoginID'=(Action_Param:'LoginID');
	$vUser_LoginID->trim;
Var:'vUser_LoginPWTemp'=(Action_Param:'Pass');
	$vUser_LoginPWTemp->trim;
Var:'vUser_FName'=(Action_Param:'FName');
	$vUser_FName->trim;
Var:'vUser_LName'=(Action_Param:'LName');
	$vUser_LName->trim;
Var:'vUser_QuestionID'=(Action_Param:'Question');
	$vUser_QuestionID->trim;
Var:'vUser_Answer'=(Action_Param:'Answer');
	$vUser_Answer->trim;
Var:'vUser_Active'=(Action_Param:'Active');
	$vUser_Active->trim;
Var:'vUser_Email'=(Action_Param:'Mail');
	$vUser_Email->trim;
Var:'vUser_Notify'=(Action_Param:'Notify');

// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit
// Checking for password only on ADD pages
If: $vNew != 'Y';
	If: (Response_Filepath) >> 'setup_add.lasso';

		If: ($vUserprivs_PrivID == '') || ($vUser_LoginID == '')
			|| ($vUser_LoginPWTemp == '') || ($vUser_FName == '') || ($vUser_Email == '')
			|| ($vUser_LName == '') || ($vUser_QuestionID == '') || ($vUser_Answer == '') || ($vUser_Active == '');
			Var:'vError' = '1003';
			Var:'vOption' = 'a required field';
		/If;

	// If link is passed from the editrecord page, do not check for missing fields
	Else: (Referrer_URL) >> 'setup_editrecord.lasso';

		// Do nothing

	Else;
		If: ($vUserprivs_PrivID == '') || ($vUser_LoginID == '')
			|| ($vUser_FName == '') || ($vUser_Email == '')
			|| ($vUser_LName == '') || ($vUser_QuestionID == '') || ($vUser_Answer == '') || ($vUser_Active == '');
			Var:'vError' = '1003';
			Var:'vOption' = 'a required field';
		/If;
	/If;
/If;


// OPTIONAL FIELDS
	Var:'vUser_Company'=(Action_Param:'Company');
		$vUser_Company->trim;
	Var:'vUser_Dept'=(Action_Param:'Dept');
		$vUser_Dept->trim;
	Var:'vUser_Address1'=(Action_Param:'Address1');
		$vUser_Address1->trim;
	Var:'vUser_Address2'=(Action_Param:'Address2');
		$vUser_Address2->trim;
	Var:'vUser_City'=(Action_Param:'City');
		$vUser_City->trim;
	Var:'vState_Abbrev'=(Action_Param:'State');
		$vState_Abbrev->trim;
	Var:'vUser_Zip'=(Action_Param:'Zip');
		$vUser_Zip->trim;
	Var:'vUser_Country'=(Action_Param:'Country');
		$vUser_Country->trim;

	// Check e-mail address, if bad output error 1102 "E-mail Format Error"
	If: (Var:'vUser_Email') != '';
		If: (Valid_Email:($vUser_Email)) == false;
			Var:'vError' = '1102';
		/If;
	/If;

	Var:'vUser_WorkPhone'=(Action_Param:'WorkPhone');
		$vUser_WorkPhone->trim;
	Var:'vUser_HomePhone'=(Action_Param:'HomePhone');
		$vUser_HomePhone->trim;
	Var:'vUser_CellPhone'=(Action_Param:'CellPhone');
		$vUser_CellPhone->trim;
	Var:'vUser_Fax'=(Action_Param:'Fax');
		$vUser_Fax->trim;
	Var:'vUser_Website'=(Action_Param:'Website');
		$vUser_Website->trim;
	Var:'vUser_Chat'=(Action_Param:'Chat');
		$vUser_Chat->trim;
	Var:'vUser_Comments'=(Action_Param:'Comments');
		$vUser_Comments->trim;
?>