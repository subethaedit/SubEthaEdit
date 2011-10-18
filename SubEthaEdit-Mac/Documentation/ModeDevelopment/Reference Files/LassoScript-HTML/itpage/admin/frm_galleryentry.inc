<?Lassoscript
// Last modified 7/19/09 by ECL, Landmann InterActive

// CHANGE NOTES
// 6/22/09
// First implementation
// 7/19/09
// Added $vAction = Browse check and different conditional check on form buttons

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/frm_GalleryEntry</strong></p>\n';
/If;

// Defining the DataType
Var:'vDataType' = 'GalleryEntry';

// Convert action_params
Include:'galleryentry_params.inc';

// If Edit page, get the record
If: (Response_Filepath) >> 'setup_editrecord.lasso';

	// If Process = Y, form was submit, so update the record
	// Otherwise, it is a new edit so get the record
	If: $vProcess != 'Y' && $vAction != 'Browse';

		// If error 1021, action was a successful delete, so display error and abort right away
		If: $vError == '1021';
			LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
			Abort;
		/If;

		// Get the record
		Var:'SQLGetGalleryEntries' = 'SELECT * FROM ' $svGalleryTable ' WHERE gallery_id = "' $vID '" LIMIT 1';
		Inline: $IV_Galleries, -Table=$svGalleryTable, -SQL=$SQLGetGalleryEntries;

			If: $svDebug == 'Y';
				'<p class="debug">32: Found_Count = ' (Found_Count) '<br>\n';
				'32: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
				'32: SQLGetGalleryEntries = ' ($SQLGetGalleryEntries) '<br>\n';
				'32: vProcess = ' ($vProcess) '<br>\n';
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
			Var:'vGallery_ID' = (Field:'Gallery_ID');
			Var:'vGallery_Title' = (Field:'Gallery_Title');
			Var:'vGallery_Caption' = (Field:'Gallery_Caption');
			Var:'vGallery_URL' = (Field:'Gallery_URL');
			Var:'vGallery_Thumb' = (Field:'Gallery_Thumb');
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
	'<h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;Add Gallery Entry</h2>\n';
Else;
	'<h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;Edit Gallery Entry</h2>\n';
/If;

// Standard Error Table
If: $vError != '';
	LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
/If;
?>
<form action="setup_addresponse.lasso" method="post">
	<table width="500">
		<tr>
			<td width="90" class="tablehead_10_white_right">Title</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Gallery_TItle" value="[$vGallery_TItle]" size="32" maxlength="64">
			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Caption</td>
			<td width="410" bgcolor="#f0f0f0">
				<textarea name="Gallery_Caption" cols="40" rows="2">[Var:'vGallery_Caption']</textarea>
			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">URL</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Gallery_URL" value="[$vGallery_URL]" size="48" maxlength="255">
			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Thumbnail[$svInputRequired]</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript   
Var:'image_thumb_array' = (File_ListDirectory: ($svImagesThmbPath));
If: Var:'image_thumb_array' >> '.DS_Store';
	$image_thumb_array->(Remove:1);
/If;
	'\t\t\t<select name="Gallery_Thumb">\n';
	'\t\t\t\t<option value=""'; If: (Var:'vGallery_Thumb') == ''; ' selected'; /If; '></option>\n';
		Iterate: $image_Thumb_array, (var:'temp_Thumb');
			'\t\t\t\t\t<option value="'($temp_Thumb) '"'; If: (Var:'vGallery_Thumb') == ($temp_Thumb); ' selected'; /If; '>'($temp_Thumb)'</option>\n';
		/Iterate;
	'\t\t\t</select>\n';
?>			</td>
		</tr>
		<tr>
			<td width="120" class="tablehead_10_white_right">Active[$svInputRequired]</td>
			<td width="280" bgcolor="#f0f0f0">
				<input type="radio" name="Active" value="Y"[If: (Var:'vActive') == 'Y' || (Var:'vActive') == ''] checked[/If]>Yes&nbsp;&nbsp;
				<input type="radio" name="Active" value="N"[If: (Var:'vActive') == 'N'] checked[/If]>No
			</td>
		</tr>
		<tr>
			<td colspan="2" bgcolor="#666666">
				<div align="center">
<?Lassoscript
// If Edit page, add a hidden field to show check if page is submit
If: (Response_Filepath) >> 'editrecord' && ($vAction) != 'Browse';
				'\t\t\t\t<input type="hidden" name="Process" value="Y">\n';
				'\t\t\t\t<input type="hidden" name="ID" value="'($vID)'">\n';
				'\t\t\t\t<input type="hidden" name="DataType" value="GalleryEntry">\n';
				'\t\t\t\t<input type="submit" name="Action" value="Update">\n';
				'\t\t\t\t<input type="submit" name="Action" value="Delete" onClick="return confirmDeleteContent()">\n';
Else;
				'\t\t\t\t<input type="submit" name="Action" value="Add">\n';
				'\t\t\t\t<input type="hidden" name="DataType" value="GalleryEntry">\n';
/If; ?>			</div>
			</td>
		</tr>
	</table>
</form>
<br>