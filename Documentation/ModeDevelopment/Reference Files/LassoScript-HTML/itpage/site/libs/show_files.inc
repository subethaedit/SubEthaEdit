<?Lassoscript
// Last modified 4/5/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing content pages
// Adapted from File Grid

// CHANGE NOTES
// 2/18/08
// Added code to remove .svn directories from displaying on template popup
// 4/5/09
// Added ShowError just above File Library panel to more closely mirrow how image uploads work
// Added error codes so error message would show

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

	File_Delete:(($svFilesUploadPath)($vID));
	If: (File_CurrentError) != 'No Error';
		#DeleteError = true;
	/If;
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
Var:'image_thumb_array' = (File_ListDirectory: $svFilesUploadPath);
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
	'\t<h3 class="nifty">File Library</h3>\n';
	'\t\t\t<p class="nifty">No files found.</p>\n';
	'\t\t</div>\n';
Else;
	'\t\t<div class="imagepanel" id="nifty">\n';
	'\t<h3 class="imagepanel">File Library</h3>\n';
	'\t\t\t<p class="nifty">Files that have been uploaded to your site are displayed below.<br>\n</p>\n';
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
			'\t\t\t\t<a href="'($svFilesUploadPath)($ThisPosition)'" target="_blank"><img src="'(LI_ShowIconByExt: -Filename=$ThisPosition)'" alt="'($ThisPosition)'"><br>\n'($ThisPosition)'</a><br>\n';
			'\t\t\t\t<a href="library.lasso?ID='($ThisPosition)'&Action=Delete&Datatype='($vDataType)'" title="Delete this File"><img src="'($svImagesPath)'trash_icon_12.png" width="12" height="15" alt="Trash Can Icon" align="middle"></a><br>\n';

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
//	'\t</tr>\n';
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