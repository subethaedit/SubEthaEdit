<?Lassoscript
// Last modified 5/12/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Upload User Photo Form - Called from admin/setup_editrecord.lasso?DataType=User&ID=

// CHANGE NOTES
// 11/1/07
// First implementation
// Fixed spacing on table
// 5/12/08
// Ported changes from LBT

// Defining the DataType
Var:'vDataType' = 'UserPhoto';

// Upload form submitted, now do the process
If: (Var:'vProcess') == '1' && $vDataType == 'UserPhoto';
	Include:($svLibsPath)'process_userphotoupload.inc';
/If;

'<h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;User Photo</h2>\n';

// Standard Error Table
If: (Var:'vError') != '';
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;

// Defining the User Photo Name
Var:'vUserPhotoName' = (($svUserPhotos)($vUser_ID)('.jpg'));
// Check to see if user photo exists
Var:'UserPhotoExists' = (File_Exists:$vUserPhotoName);
?>
<!-- START User Photo Form -->
<form enctype="multipart/form-data" action="[Response_Filepath]" method="post">
	<table width="500">
		<tr>
			<td width="130" rowspan="3" valign="middle"[If: $UserPhotoExists == false] bgcolor="#FFFF99"[/If]>[If: $UserPhotoExists == true]<img src="[$vUserPhotoName]" alt="User Photo">[Else]<p class="text_10_black" align="center">No user photo</p>[/If]</td>
			<td colspan="2" valign="top">Use this form to upload a new user photo.</td>
		</tr>
		<tr> 
			<td width="130" valign="middle" class="tablehead_10_white_right">File to Upload</td>
			<td width="340" valign="middle" bgcolor="#f0f0f0"> 
				<input name="one" type="file">
			</td>
		</tr>
		<tr>
			<td colspan="2" valign="middle" bgcolor="#666666">
				<div align="center">
					<input type="hidden" name="Process" value="1">
					<input type="hidden" name="Datatype" value="[$vDataType]">
					<input type="hidden" name="ID" value="[Var:'vUser_ID']">
					<input type="submit" value="Upload">
				</div>
			</td>
		</tr>
	</table>
</form>
<br>
<?Lassoscript
// Reset the error code so it doesn't display on the User form
If: (Var:'vError') != '';
	(Var:'vError') = '';
/If;
?>
<!-- END Upload Files Form -->
