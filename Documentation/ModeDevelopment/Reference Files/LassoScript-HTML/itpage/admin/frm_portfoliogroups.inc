<?Lassoscript
// Last modified 6/22/09 by ECL, Landmann InterActive

// CHANGE NOTES
// 11/27/07
// First implementation
// 3/5/08
// Fixing problem with query where entries in multiple select box appear more than once
// 6/24/08
// Fixed silly problem with multiple select box being too small. Added a style to it.
// 6/22/09
// Added required label on Name field

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/frm_portfoliogroups</strong></p>\n';
/If;

// Defining the DataType
Var:'vDataType' = 'PortfolioGroup';

// Convert action_params
Include:'portfoliogroup_params.inc';

// If Edit page, get the record
If: (Response_Filepath) >> 'setup_editrecord.lasso';

	// Initialize variables
	Var:'IsSelected' = ' selected';

	// If Process = Y, form was submit, so update the record
	// Otherwise, it is a new edit so get the record
	If: $vProcess != 'Y';

		// If error 1021, action was a successful delete, so display error and abort right away
		If: $vError == '1021';
			LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
			Abort;
		/If;

		// Get the record
		Var:'SQLGetPortfolioGroups' = 'SELECT * FROM ' $svPortfolioGroupsTable ' WHERE pg_groupid = "' $vID '" LIMIT 1';
		Inline: $IV_Portfolios, -Table=$svPortfolioGroupsTable, -SQL=$SQLGetPortfolioGroups;

			If: $svDebug == 'Y';
				'<p class="debug">32: Error_CurrentError = ' (Error_CurrentError) '</p>\n';
			/If;

			// If Found_Count is wrong, the wrong User ID was passed, so dump out 2000 "No Record Found"	
			If: (Found_Count) == 0;
				$vError = '2000';
				LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
				If: $svDebug == 'Y';
					Include:($svLibsPath)'vardumpalpha.lasso';
				/If;
				Abort;
			/If;
			Var:'vPG_Name' = (Field:'PG_Name');
			Var:'vActive' = (Field:'Active');
			Var:'vDateModified' = (Field:'DateModified');
		/Inline;

		// If there is an error, dump out error 1012 "Update Failed"
		If: (Error_CurrentError) != 0;
			$vError = '2000';
		/If;

	/If;
	
/If;

If: (Var:'vID') == '';
	'<h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;Add Portfolio Group</h2>\n';
Else;
	'<h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;Edit Portfolio Group</h2>\n';
/If;

// Standard Error Table
If: $vError != '';
	LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
/If;
?>
<form action="setup_addresponse.lasso" method="post">
	<table width="500">
		<tr>
			<td width="120" class="tablehead_10_white_right">Portfolio Group Name[$svInputRequired]</td>
			<td width="280" bgcolor="#f0f0f0">
				<input type="text" name="pg_name" value="[$vpg_name]" size="32" maxlength="255">
			</td>
		</tr>
		<tr>
			<td width="120" class="tablehead_10_white_right">Active[$svInputRequired]</td>
			<td width="280" bgcolor="#f0f0f0">
				<input type="radio" name="Active" value="Y"[If: (Var:'vActive') == 'Y' || (Var:'vActive') == ''] checked[/If]>Yes&nbsp;&nbsp;
				<input type="radio" name="Active" value="N"[If: (Var:'vActive') == 'N'] checked[/If]>No
			</td>
		</tr>
[If: (Response_Filepath) >> 'setup_edit' || (Response_Filepath) >> 'setup_search']
		<tr>
			<td width="120" class="tablehead_10_white_right">Date Modified</td>
			<td width="280" bgcolor="#f0f0f0">
				[Var:'vDateModified']
			</td>
		</tr>
[/If]
		<tr>
			<td colspan="2" bgcolor="#666666">
				<div align="center">
<?Lassoscript
// If Edit page, add a hidden field to show check if page is submit
If: (Response_Filepath) >> 'editrecord';
				'\t\t\t\t<input type="hidden" name="Process" value="Y">\n';
				'\t\t\t\t<input type="hidden" name="ID" value="'($vID)'">\n';
				'\t\t\t\t<input type="hidden" name="DataType" value="PortfolioGroup">\n';
				'\t\t\t\t<input type="submit" name="Action" value="Update">\n';
				'\t\t\t\t<input type="submit" name="Action" value="Delete" onClick="return confirmDeleteContent()">\n';
Else;
				'\t\t\t\t<input type="submit" name="Action" value="Add">\n';
				'\t\t\t\t<input type="hidden" name="DataType" value="PortfolioGroup">\n';
/If; ?>			</div>
			</td>
		</tr>
	</table>
</form>
<br>
<?Lassoscript
// Assignment Portfolio Entry to Portfolio
If: (Response_Filepath) !>> 'setup_add.lasso';

?>&nbsp;<br>
<form action="setup_addresponse.lasso" method="post">
	<table width="520">
		<tr>
			<td colspan="2" bgcolor="#666666" class="tablehead_10_white">Portfolio Entries</td>
		</tr>
	</table>
	<table width="520">
		<tr>
			<td width="120" bgcolor="#666666">
				&nbsp;
			</td>
			<td valign="top" bgcolor="#cccccc">
				<select name="portfolio_entries" multiple size="10" class="medium" style="height:180px">
<?Lassoscript
// Call the CT to build the multiple select box
LI_BuildPortfolioMultiSelect: -ID=$vPortfolioGroupID;
?>
				</select>
			</td>
		</tr>
		<tr>
			<td colspan="2" bgcolor="#666666">
				<div align="center">
					<input type="hidden" name="Process" value="Y">
					<input type="hidden" name="PortfolioGroupID" value="[$vPortfolioGroupID]">
					<input type="hidden" name="DataType" value="PortfolioGroup">
					<input type="submit" name="Action" value="Assign">
				</div>
			</td>
		</tr>
	</table>
</form>
<br>
[/If]
