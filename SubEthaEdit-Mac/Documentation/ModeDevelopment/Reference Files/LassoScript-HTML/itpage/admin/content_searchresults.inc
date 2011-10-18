<?Lassoscript 
// Last modified 11/15/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// This establishes the queries and results pages for the admin Content area
// The controlling record is ID from the content table, which is passed as the action_param "ID"

// CHANGE NOTES
// 10/12/07
// Recoded for CMS v. 3.0
// 11/15/07
// Switched fields CategoriesID to HeirarchyID

// Start the session
Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

If: !(Var_Defined:'SQLQueryContent'); Session_AddVariable: -Name=$svSessionAdminName, 'SQLQueryContent'; /If;

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
	'<p class="debug"><strong>/admin/content_searchresults</strong></p>\n';
/If;

// Get Heirarchy Labels
Include:($svLibsPath)'get_HeirarchyLabels.inc';

// Create the query if NewQuery = Y
If: Var:'vNewQuery' == 'Y';

	Var:'vHeirarchyID' = (Action_Param:'HeirarchyID');
	Var:'vHeadline' = (Action_Param:'Headline');
	Var:'vImage_Large' = (Action_Param:'Image_Large');
	Var:'vActive' = (Action_Param:'Active');

	Var:'SQLHeirarchyID' = string;
	Var:'SQLHeadline' = string;
	Var:'SQLImageLarge' = string;
	Var:'SQLActive' = string;

	Var:'SQLQueryContent' = '';
	Var:'SQLQuerySuffix' = '';
	Var:'svSearch_Params' = '';
	Var:'svSearch_ParamsURL' = '';

	// Include the code for building the search params phrase
	Include:($svLibsPath)'searchparamscontent_build.inc';

/If;

// Define the suffix (same for any query)
Var:'SQLQuerySuffix' = ' ORDER BY Headline';

// Constructing the query
If: (Var:'SQLQueryContent') == '';

	var:'SQLQueryContent' = (string);
	var:'SQLQueryLimit' = (string);
	Var:'SQLQueryContent' = 'SELECT ID, HeirarchyID, Headline, Image_Large, Active
		FROM ' $svSiteDatabase '.' $svContentTable ' WHERE ';

	// CATEGORIES ID SEARCH
	If: Var:'vHeirarchyID' != '';
		Var:'SQLHeirarchyID' = 'HeirarchyID = "' $vHeirarchyID '"';
		$SQLQueryContent += $SQLHeirarchyID;
		If: Var:'vHeadline' != '' || Var:'vImage_Large' != '' || Var:'vActive' != '';
			$SQLQueryContent += ' AND ';
		/If;
	/If;

	// HEADLINE
	If: Var:'vHeadline' != '';
		Var:'SQLHeadline' = 'Headline LIKE "%' $vHeadline '%"';
		$SQLQueryContent += $SQLHeadline;
		If: Var:'vImage_Large' != '' || Var:'vActive' != '';
			$SQLQueryContent += ' AND ';
		/If;
	/If;

	// IMAGE LARGE
	If: Var:'vImage_Large' != '';
		Var:'SQLImageLarge' = 'Image_Large LIKE "%' $vImage_Large '%"';
		$SQLQueryContent += $SQLImageLarge;
		If: Var:'vActive' != '';
			$SQLQueryContent += ' AND ';
		/If;
	/If;

	// ACTIVE
	If: Var:'vActive' != '';
		Var:'SQLActive' = 'Active = "' $vActive '"';
		$SQLQueryContent += $SQLActive;
	/If;


	// Add suffix
	$SQLQueryContent += $SQLQuerySuffix;

	// SEARCHES EVERYTHING
	// If no search params passed, redefine the query to get everything
	If: ($vHeirarchyID == '') && ($vHeadline == '') && ($vImage_Large == '') && ($vActive == '');
		Var:'SQLQueryContent' = '';
		Var:'SQLQueryContent' = 'SELECT ID, HeirarchyID, Headline, Image_Large, Active
		FROM ' $svSiteDatabase '.' $svContentTable ' ORDER BY Headline ASC';
	/If;

	If: $svDebug == 'Y';
		'116: vHeirarchyID = ' (Var:'vHeirarchyID') '<br>\n';
		'116: vHeadline = ' (Var:'vHeadline') '<br>\n';
		'116: vImage_Large = ' (Var:'vImage_Large') '<br>\n';
		'116: vActive = ' (Var:'vActive') '<br>\n';
	/If;

/If;
	
// Performing Search
Inline: $IV_Content, 
	-skiprecords=(var:'Records_Skipped'),
	-MaxRecords=(Var:'Records_Per_Page'),
	-SQL=$SQLQueryContent;

	If: $svDebug == 'Y';
		'131: Error = ' (Error_CurrentError) '<br>\n';
		'131: Found_Count = ' (Found_Count) '<br>\n';
	/If;
	
	// If no records found, immediate redirect with error
	If: (Found_Count) == 0;
		Var:'vError'='2000';
		Var:'URL' = ('setup_search.lasso?Error='$vError'&'(Client_POSTArgs));
		If: $svDebug == 'Y';
			'140: URL: ' $URL '<br>\n';
			'<a href="'$URL'">' $URL '</a><br>\n';
		Else;
			Redirect_URL: $URL;
		/If;
	/If;

	// FIX THIS

	// If only one record, redirect immediately to editrecord
	// This shortcut allows users to skip past the search results page if there is only one record found
	If: (Found_Count) == 1;
		Var:'URL' = ('setup_editrecord.lasso?ID='(Field:'ID')'&DataType='(Var:'vDatatype')'&New=Y');
		If: $svDebug == 'Y';
			'155: URL: ' $URL '<br>\n';
			'<a href="'$URL'">' $URL '</a><br>\n';
		Else;
			Redirect_URL: $URL;
		/If;
	/If;
?>
<!-- Search Results-->
<table width="525">
	<tr>
		<td colspan="5" valign="top">
			<div align="left">
				<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;Content Search Results</h2>
				<p><font color="red">[Var:'svSearch_Params', -EncodeNone]</font>&nbsp;&nbsp;
				<a href="http://[$svDomain]/admin/setup_search.lasso[$svSearch_ParamsURL]">Search Again</a></p>
			</div>
		</td>
	</tr>
	<tr bgcolor="#000000">
		<td width="20" valign="middle" class="tablehead_10_white"><strong>ID</strong></td>
		<td width="150" valign="middle" class="tablehead_10_white"><strong>Heirarchy</strong></td>
		<td width="270" valign="middle" class="tablehead_10_white"><strong>Headline</strong></td>
		<td width="60" valign="middle" class="tablehead_10_white"><strong>Large Image</strong></td>
		<td width="20" valign="middle" class="tablehead_10_white"><strong>Active</strong></td>
	</tr>
<?Lassoscript
Records;
	Var:'vID' = (Field:'ID');
	Var:'vHeirarchyID' = (Field:'HeirarchyID');
	Var:'vHeadline' = (Field:'Headline');
	Var:'vImage_Large' = (Field:'Image_Large');
	Var:'vActive' = (Field:'Active');
	Var:'ThisHeirarchyLabel' = ($HeirarchyLabels->(Find:$vHeirarchyID));
?>	<tr <?Lassoscript If: (Loop_Count) %2 == 0; 'bgcolor="#F5F5F5"'; Else; 'bgcolor="#FFFFFF"'; /If; ?>>
		<td valign="top" width="20" class="tabletext_10_black">
			<strong><a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y">[Var:'vID']</a></strong></td>
		<td valign="top" width="150" class="tabletext_10_black">
			<strong>[$ThisHeirarchyLabel]</strong>
		</td>
		<td valign="top" width="270" class="tabletext_10_black">
			[$vHeadline]
		</td>
		<td valign="top" width="60" class="tabletext_10_black">
			[$vImage_Large]
		</td>
		<td valign="top" width="20" class="tabletext_10_black">
			[$vActive]
		</td>
	</tr>
[/Records]
	<tr>
		<td colspan="5" valign="top" bgcolor="#cccccc">&nbsp;</td>
	</tr>
	<tr>
		<td colspan="5" valign="middle" align="left" bgcolor="#f5f5f5">
			[Include:($svLibsPath)'nav_control.inc']
		</td>
	</tr>
</table>
[/Inline]
<br>
