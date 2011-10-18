<?Lassoscript
// Last modified 5/20/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Multi-purpose delete response file for ALL datatypes

// CHANGE NOTES

// Debugging
// Var:'svDebug' = 'Y';

 // Convert action_params
Var:'vID' = (Action_Param:'ID');
Var:'vDataType' = (Action_Param:'DataType');
Var:'vError' = (Action_Param:'Error');
Var:'vOption' = (Action_Param:'Option');

// Build the Delete Query based upon DataType
Var:'SQLDeleteQuery' = (string);
Var:'vThisTable' = (string);

If: $vDataType == 'User';
	Var:'SQLDeleteQuery' = 'DELETE FROM ' $svSiteDatabase'.'$svUsersTable ' WHERE User_ID = "' $vID '"';
	Var:'vThisTable' = $svUsersTable;

// Otherwise somebody is messing with us, output a bogus query so it fails
Else;
	Var:'SQLDeleteQuery' = 'DELETE FROM ' $svSiteDatabase'.'$svUsersTable ' WHERE User_ID IS NULL';
	Var:'vThisTable' = $svUsersTable;
/If;

// Delete the record
Inline: $IV_Users, -Table=$vThisTable, -SQL=$SQLDeleteQuery;
	// If delete successful, output 1021 "Deletion Successful"
	If: (Error_Code) == '0';
		Var:'vError'='1021';
	Else;
		Var:'vError'='1022';
		Var:'vOption'=(Error_CurrentError);
		LI_URLRedirect: -Page='setup_delete.lasso',-UseError='Y',-Error=$vError, -UseArgs='Y';
	/If;
/Inline;

If: $svDebug == 'Y';
	'57: vDataType = ' ($vDataType) '<br>\n';
	'57: SQLDeleteQuery = ' ($SQLDeleteQuery) '<br>\n';
	'57: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	'57: Error_Code = ' (Error_Code) '<br>\n';
	'57: Found_Count = ' (Found_Count) '<br>\n';
/If;

// Standard Error Table
If: (Var:'vError') != '';
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;
?>