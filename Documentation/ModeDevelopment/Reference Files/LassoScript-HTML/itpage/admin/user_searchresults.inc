<?Lassoscript 
// Last modified 5/20/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// This establishes the queries and results pages for the admin Users area
// Include for Users search results
// Active users can be searched for and returned, but do not show on this page (not enough room)
// The controlling record is User_ID from the users table, which is passed as the action_param "ID"

// CHANGE NOTES
// 10/12/07
// Recoded for CMS v. 3.0
// 5/20/08
// Recoded URL Links

// Defining the DataType so Google links work
Var:'vDataType' = 'User';
Var:'vDataTypeLabel' = Var:'vDataType';

If: !(Var_Defined:'SQLQueryUser'); Session_AddVariable: -Name=$svSessionAdminName, 'SQLQueryUser'; /If;

// Debugging
// Var:'svDebug' = 'Y';

// Setting Variables for Nav Control
Var:'vNewQuery' = (Action_Param:'NewQuery');
Var:'Records_Skipped' = (Action_Param:'skip');
Var:'This_Group' = (Action_Param:'group');
Var:'Records_Per_Page' = '10';
Var:'SkipCount' = integer;
Var:'Records_Found' = integer;
Var:'Group_Size' = (Math_Mult:(Var:'Records_Per_Page'),5);

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/user_searchresults</strong></p>\n';
/If;

// Get Label Maps
// Include:($svLibsPath)'get_labels.inc';

// Create the query if NewQuery = Y
If: Var:'vNewQuery' == 'Y';

	Var:'vUser' = (Action_Param:'User');
	Var:'vActive' = (Action_Param:'Active');
	Var:'SQLUser' = string;
	Var:'SQLActive' = string;
	Var:'SQLQueryUser' = '';
	Var:'SQLQuerySuffix' = '';
	Var:'svSearch_Params' = '';
	Var:'svSearch_ParamsURL' = '';

	// Include the code for building the search params phrase
	Include:($svLibsPath)'searchparamsuser_build.inc';

/If;

// Define the suffix (same for any query)
Var:'SQLQuerySuffix' = ' ORDER BY User_LName, User_FName';

// Constructing the query
If: (Var:'SQLQueryUser') == '';

	var:'SQLQueryUser' = (string);
	var:'SQLQueryLimit' = (string);
	Var:'SQLQueryUser' = 'SELECT ID, User_ID, User_LoginID, User_FName, User_LName, User_Active FROM '
		$svSiteDatabase '.' $svUsersTable ' WHERE ';

	// USER SEARCH
	If: Var:'vUser' != '';
		Var:'SQLUser' = 'User_ID = "' $vUser;
		$SQLQueryUser += $SQLUser '"';
		If: Var:'vActive' != '';
			$SQLQueryUser += ' AND ';
		/If;
	/If;

	// ACTIVE SEARCH
	If: Var:'vActive' != '';
		Var:'SQLActive' = 'User_Active = "' $vActive '"';
		$SQLQueryUser += $SQLActive;
	/If;

	// Add suffix
	$SQLQueryUser += $SQLQuerySuffix;

	// SEARCHES EVERYTHING
	// If no search params passed, redefine the query to get everything
	If: ($vUser == '') && ($vActive == '');
		Var:'SQLQueryUser' = 'SELECT ID, User_ID, User_LoginID, User_FName, User_LName, User_Active FROM '
		$svSiteDatabase '.' $svUsersTable ' ' $SQLQuerySuffix;
	/If;

	If: $svDebug == 'Y';
		'93: vUser = ' (Var:'vUser') '<br>\n';
		'93: vActive = ' (Var:'vActive') '<br>\n';
	/If;

/If;
	
// Performing Search
Inline: $IV_Users, 
	-skiprecords=(var:'Records_Skipped'),
	-MaxRecords=(Var:'Records_Per_Page'),
	-SQL=$SQLQueryUser;

	If: $svDebug == 'Y';
		'109: Error = ' (Error_CurrentError) '<br>\n';
		'109: Found_Count = ' (Found_Count) '<br>\n';
	/If;
	
	// If no records found, immediate redirect with error
	If: (Found_Count) == 0;
		Var:'vError'='2000';
		LI_URLRedirect: -Page='setup_search.lasso',-UseError='Y',-Error=$vError,-UseArgs='Y';
	/If;

	// If only one record, redirect immediately to editrecord
	// This shortcut allows users to skip past the search results page if there is only one record found
	If: (Var:'vUser') != '' && (Found_Count) == 1;
		LI_URLRedirect: -Page='setup_editrecord.lasso',-ExParams=('Datatype=User&ID='($vUser)'&New=Y');
	/If;
?>
<!-- Search Results-->
<table width="525">
	<tr>
		<td colspan="3" valign="top">
			<div align="left">
				<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;[Var:'vDataTypeLabel'] Search Results</h2>
				<p><font color="red">[Var:'svSearch_Params', -EncodeNone]</font>&nbsp;&nbsp;
				<a href="http://[$svDomain]/admin/setup_search.lasso[$svSearch_ParamsURL]&Datatype=User">Search Again</a></p>
			</div>
		</td>
	</tr>
	<tr bgcolor="#000000">
		<td width="235" valign="middle" class="tablehead_10_white">User Name</td>
		<td width="150" valign="middle" class="tablehead_10_white">Login ID</td>
		<td width="70" valign="middle" class="tablehead_10_white">Active</td>
	</tr>
<?Lassoscript
Records;
	Var:'vUser_ID' = (Field:'User_ID');
	Var:'vUser_FName' = (Field:'User_FName');
	Var:'vUser_LName' = (Field:'User_LName');
	Var:'vUser_LoginID' = (Field:'User_LoginID');
	Var:'vUser_Active' = (Field:'User_Active');
?>
	<tr<?Lassoscript If: (Loop_Count) %2 == 0; ' bgcolor="#F5F5F5"'; Else; ' bgcolor="#FFFFFF"'; /If; ?> >
		<td valign="middle" width="235" align="left">
			<strong><a href="setup_editrecord.lasso?ID=[Var:'vUser_ID']&DataType=[Var:'vDatatype']&New=Y" class="DataRowLink">[Var:'vUser_LName'], [Var:'vUser_FName']</a></strong></td>
		<td valign="middle" width="150" align="left">
			[$vUser_LoginID]
		</td>
		<td valign="middle" width="70" align="left">
			[$vUser_Active]
		</td>
	</tr>
[/Records]
	<tr>
		<td colspan="3" valign="middle" bgcolor="#cccccc">&nbsp;</td>
	</tr>
	<tr>
		<td colspan="3" valign="middle" align="left" bgcolor="#f5f5f5">
		[Include:($svLibsPath)'nav_control.inc']
		</td>
	</tr>
</table>
[/Inline]
<br>
