<?Lassoscript
// Last modified 11/15/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// Content search form

// CHANGE NOTES
// 10/12/07
// Recoded for Clean URLs
// 11/15/07
// Switched fields CategoriesID to HeirarchyID, removed SectionID as it is now obsolete

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/frm_content_search</strong></p>\n';
/If;

// Converting action_params
Var:'vError'=(Action_Param:'Error');
Var:'vHeirarchyID' = (Action_Param:'HeirarchyID');
Var:'vHeadline' = (Action_Param:'Headline');
Var:'vImage_Large' = (Action_Param:'Image_Large');
Var:'vActive' = (Action_Param:'Active');

// Standard Error Table
If: $vError != '';
	LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
/If;
?>
<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;Content Search</h2>
	<form action="setup_searchresults.lasso" method="post" target="_parent">
	<table width="520">
		<tr>
			<td width="90" class="tablehead_10_white_right">Heirarchy</td>
			<td width="410" bgcolor="#f0f0f0">
[LI_BuildCategorySelect: -Tooltip='N']
			</td>
		</tr>
[If: $svHeadlineActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Headline</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Headline" value="[Var:'vHeadline']" size="32" maxlength="64">
			</td>
		</tr>
[/If]
[If: $svImageLargeActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Large Image Name</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Image_Large" value="[Var:'vImage_Large']" size="20" maxlength="32">
			</td>
		</tr>
[/If]
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
					<input type="hidden" name="DataType" value="Content">
					<input type="submit" name="-Nothing" value="Search">
				</div>
			</td>
		</tr>
	</table>
</form>
<br>