<?Lassoscript
// Last modified 5/12/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// User delete form

// CHANGE NOTES
// 10/12/07
// Recoded for Clean URLs
// 5/12/08
// Ported changes from LBT

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/frm_user_delete</strong></p>\n';
/If;

// Defining the DataType
Var:'vDataType' = 'User';

// Converting action_params
Var:'vError'=(Action_Param:'Error');
Var:'vUser_ID'=(Action_Param:'ID');

// Standard Error Table
If: (Var:'vError') != '';
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;
?>
<div align="left">
<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;Delete User</h2>
<form action="setup_deleteresponse.lasso" method="post" target="_parent">
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
	'\t<td bgcolor="#f5f5f5"><select name="ID">\n';
	'\t\t<option value=""'; If: (Var:'vUser_ID') == ''; ' selected'; /If; '>--- Select a User ---</option>\n';
	Records;
		'\t\t\t<option value="'(Field:'User_ID') '"'; If: (Field:'User_ID') == ($vUser_ID); ' selected'; /If; '>'(Field:'User_LName')', '(Field:'User_FName')', "'(Field:'User_LoginID')'"</option>\n';
	/Records;
	'\t\t</select>\n';
/Inline;
?>			</td>
		</tr>
		<tr>
			<td colspan="2" bgcolor="#666666">
				<div align="center">
					<input type="submit" name="-Nothing" value="Delete">
					<input type="hidden" name="DataType" value="[$vDataType]">
				</div>
			</td>
		</tr>
	</table>
</form>
</div>
