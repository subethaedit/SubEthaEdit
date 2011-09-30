<?Lassoscript
// Last modified 5/12/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// User search form

// CHANGE NOTES
// 10/12/07
// Recoded for Clean URLs
// 5/12/08
// Ported changes from LBT

// Defining the DataType
Var:'vDataType' = 'User';

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/frm_user_search</strong></p>\n';
/If;

// Converting action_params
Var:'vError'=(Action_Param:'Error');
Var:'vUser_ID'=(Action_Param:'UserID');
Var:'vActive'=(Action_Param:'Active');

// Standard Error Table
If: $vError != '';
	LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
/If;
?>
<div align="left">
<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;User Search</h2>
<form action="setup_searchresults.lasso" method="post" target="_parent">
	<table width="520">
		<tr>
			<td width="120" class="tablehead_10_white_right">User Name</td>
<?Lassoscript
// Get list of Users
Var:'SQLSearchUsers'='SELECT User_ID,User_FName,User_LName,User_LoginID FROM ' $svUsersTable ' ORDER BY User_LName';
Inline: $IV_Users, -SQL=$SQLSearchUsers;
	If: $svDebug == 'Y';
		'27: SQLSearchUsers = ' $SQLSearchUsers '<br>\n';
		'27: Found_Count = ' (Found_Count) '<br>\n';
	/If;
	'\t<td bgcolor="#f5f5f5"><select name="User">\n';
	'\t\t<option value=""'; If: (Var:'vUser_ID') == ''; ' selected'; /If; '>--- Show All ---</option>\n';
	Records;
		'\t\t\t<option value="'(Field:'User_ID') '"'; If: (Field:'User_ID') == ($vUser_ID); ' selected'; /If; '>'(Field:'User_LName')', '(Field:'User_FName')', "'(Field:'User_LoginID')'"</option>\n';
	/Records;
	'\t\t</select>\n';
/Inline;
?>			</td>
		</tr>
		<tr>
			<td width="120" class="tablehead_10_white_right">User Active</td>
			<td valign="top" bgcolor="#f5f5f5">
				<select name="Active"> 
					<option value=""[If: (Var:'vActive') == ''] selected[/If]>--- Show All ---</option>
					<option value="Y"[If: (Var:'vActive') == 'Y'] selected[/If]>Active</option>
					<option value="N"[If: (Var:'vActive') == 'N'] selected[/If]>Inactive</option>
				</select>
			</td>
		</tr>
		<tr>
			<td colspan="2" bgcolor="#666666">
				<div align="center">
					<input type="hidden" name="NewQuery" value="Y">
					<input type="submit" name="-Nothing" value="Search">
					<input type="hidden" name="DataType" value="[$vDataType]">
				</div>
			</td>
		</tr>
	</table>
</form>
</div>