<?Lassoscript
// Last modified 1/15/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Stories search form

// CHANGE NOTES
// 1/15/09
// First implementation

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/frm_storiessearch</strong></p>\n';
/If;

// Defining the DataType
Var:'vDataType' = 'Story';

// Converting action_params
Var:'vError'=(Action_Param:'Error');
Var:'vSearchFor' = (Action_Param:'SearchFor');
Var:'vActive' = (Action_Param:'Active');

// Standard Error Table
If: $vError != '';
	LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
/If;
?>
<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;Story Search</h2>
<form action="setup_searchresults.lasso" method="post">
	<table width="520">
		<tr>
			<td width="90" class="tablehead_10_white_right">Search For</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="SearchFor" value="[$vSearchFor]" size="32" maxlength="255">
			</td>
		</tr>
		<tr>
			<td width="120" class="tablehead_10_white_right">Active</td>
			<td valign="top" bgcolor="#f0f0f0">
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
					<input type="hidden" name="DataType" value="Story">
					<input type="submit" name="-Nothing" value="Search">
				</div>
			</td>
		</tr>
	</table>
</form>
<br>