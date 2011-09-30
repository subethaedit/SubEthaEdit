<?Lassoscript
// Last modified 3/7/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing templates

// CHANGE NOTES
// 3/7/10
// First implementation

// Debugging
// Var:'svDebug' = 'Y';

// Initialize vars for nav control
Var:'Records_Skipped' = 0;
If: (Action_Param:'skip');
	$Records_Skipped = (Action_Param:'skip');
/If;
Var:'This_Group' = (Action_Param:'group');
Var:'Records_Per_Page' = 15;
Var:'Group_Size' = (Math_Mult:(Var:'Records_Per_Page'),5);
Var:'SkipCount' = integer;
Var:'Records_Found' = integer;

// Initialize vars to display file matrix
Var:'image_thumb_array' = array;
Var:'LoopFrom' = integer;
Var:'LoopTo' = integer;
Var:'ThisPosition' = integer;

// Initialize the vars to display the table
var:'column_limit' = 5;
var:'column_counter' = 0;
var:'row_counter' = 1;

// *************** START DELETE ***************
// If Action=Delete, delete the indicated file, then proceed
If: $vAction == 'Delete';

	// Look for delete errors
	Local('DeleteError' = false);

	// Delete the template
	File_Delete(($svTmpltsPath)($vID));
	If: (File_CurrentError) != 'No Error';
		#DeleteError = true;
	/If;

	// Delete the Preview. Have to Protect this as the preview may not exist.
	Protect;
		File_Delete(($svTmpltsPreviewPath)+($vID)+('.jpg'));
		#DeleteError = false;
	/Protect;

	Debug;
		'38: File_CurrentError = ' (File_CurrentError) '<br>\n';
		'38: Error_CurrentError = ' (Error_CurrentError) '</p>\n';
	/Debug;

	// Set the error code
	If: #DeleteError == true;
		$vError = '1022';
		$vOption = (File_CurrentError);
	Else;
		$vError = '1023';
		$vOption = ($vID);
	/If;
/If;
// *************** END DELETE ***************

// Get the directory listing
Var:'image_thumb_array' = (File_ListDirectory: $svTmpltsPath);
If: $image_thumb_array >> '.DS_Store';
	$image_thumb_array->(Remove:1);
/If;
If: Var:'TemplatesArray' >> '.svn';
	$TemplatesArray->(Remove:1);
/If;

Var:'ImageCount' = ($image_thumb_array->size);
// 'ImageCount = ' $ImageCount '<br>\n';

// Standard Error
If: (Var:'vError') != '';
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;


// If array empty, dump out message
If: $ImageCount == 0;
	'\t\t<div class="imagepanel" id="nifty">\n';
	'\t<h3 class="nifty">Template Library</h3>\n';
	'\t\t\t<p class="nifty">No templates found.</p>\n';
	'\t\t</div>\n';
Else;
	'\t\t<div class="imagepanel" id="nifty">\n';
	'\t<h3 class="imagepanel">Template Library</h3>\n';
	'\t\t\t<p class="nifty">Templates that have been uploaded to your site are displayed below.<br>\n</p>\n';
	$LoopTo = (Math_Add: $Records_Skipped, $Records_Per_Page);
	$LoopFrom = (Math_Add: $Records_Skipped, 1);
	If: $svDebug == 'Y';
		'65: LoopFrom = ' ($LoopFrom) '<br>\n';
		'65: LoopTo = ' ($LoopTo) '<br>\n';
		'65: Records_Skipped = ' ($Records_Skipped) '</p>\n';
	/If;
	'<table width="100%" bgcolor="#F0F0F0">\n';
	'\t<tr>\n';
	$column_counter = 0;
	Loop: -From=$LoopFrom, -To=$LoopTo;
		$column_counter = (Math_Add: $column_counter, 1);
		'\t\t<td>\n';
		'\t\t\t<div align="center">\n';
		Protect;
			Var:'ThisPosition' = ($image_thumb_array->Get:(Loop_Count));
			If: $svDebug == 'Y';
				'\t\t\t\tLoop_Count = ' (Loop_Count) '<br>\n';
			/If;
// Check to see if preview exists. If it does, use it. Otherwise display generic using LI_ShowIconByExt.
Var('PreviewFileName' = (($svTmpltsPreviewPath)+($ThisPosition)+('.jpg')));
Var('PreviewFileExists' = (File_Exists($PreviewFileName)));
// If preview exists, display in show_template.lasso popup
If($PreviewFileExists);
			'\t\t\t\t<a href="show_template.lasso?Template='($ThisPosition)'&height=300&width=450" class="thickbox" title="Template Preview &mdash; '(#ThisPosition)'">\n';
			'\t\t\t\t<img src="'($PreviewFileName)'" width="120" alt="'($ThisPosition)'"><br>\n'($ThisPosition)'</a><br>\n';
// If preview does NOT exist, check to see if EasyThumb User ID is set (in siteconfig).
// If it is set, we expect the EasyThumb service to be available.
Else;
	// Previews do NOT exist, change the link to create them
	If($svEasyThumbUserID);
			'\t\t\t\t<a href="/admin/create_webthumb.lasso?Template='($ThisPosition)'" title="Click to Generate Preview of '($ThisPosition)'"><img src="'(LI_ShowIconByExt: -Filename=$ThisPosition)'" alt="'($ThisPosition)'"><br>\n'($ThisPosition)'</a><br>\n';
	Else;
			'\t\t\t\t<a href="/admin/create_webthumb.lasso?Template='($ThisPosition)'" title="Click to Generate Preview of '($ThisPosition)'"><img src="'(LI_ShowIconByExt: -Filename=$ThisPosition)'" alt="'($ThisPosition)'"><br>\n'($ThisPosition)'</a><br>\n';
	/If;
/If;
			// Delete Template Link
			'\t\t\t\t<a href="library.lasso?ID='($ThisPosition)'&Action=Delete&Datatype='($vDataType)'" title="Delete this Template"><img src="'($svImagesPath)'trash_icon_12.png" width="12" height="15" alt="Trash Can Icon" align="middle"></a>\n';

			// Check Image Usage Link
			'\t\t\t\t&nbsp;&nbsp;&nbsp;\n';
			'\t\t\t\t<!-- 350 --><a href="check_imageusage.lasso?Datatype='($vDatatype)'&ID='(#ThisPosition)'&height=450&width=500" class="thickbox" title="Check Usage of '(#ThisPosition)'"><img src="'($svFileIconsPath)'layout_link.png" width="16" height="16" alt="Layout Link Icon" align="middle"></a>\n';

		/Protect;
		'\t\t\t</div>\n';
		'\t\t</td>\n';
		// Add closing </tr> if end of column
		If: ($column_counter == $column_limit);
			'\t</tr><!-- 74 -->\n';
			$column_counter = 0;
			If: ((Loop_Count) != $LoopTo);
				'\t<tr><!-- 77 -->\n';
			/if;
		/if;
	/Loop;
	'\t<tr>\n';
	'\t\t<td valign="middle" colspan="'($column_limit)'" align="center">';
	// Navigation control
	Include:($svLibsPath)'nav_control_grid.inc';
	'\t\t</td>\n';
	'\t</tr>\n'
	'</table>\n';
	'\t\t</div>\n';

/If;
?> 