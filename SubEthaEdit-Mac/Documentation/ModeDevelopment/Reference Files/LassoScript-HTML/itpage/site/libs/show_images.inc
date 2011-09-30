<?Lassoscript
// Last modified: 3/7/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing content pages
// Adapted from File Grid

// CHANGE NOTES
// 9/29/08
// Adding Video preview to Images listing
// Modifying delete to delete the .png Poster Frames
// 12/19/08
// Fixed incorrect <a href going to Media path instead of Images path
// 6/5/09
// Adding an ignore for .svn to the media array
// Finshed .swf display
// 6/12/09
// Fixing problem with delete link
// 7/13/09
// Added an include to modify/delete database entries upon image deletion
// 3/7/10
// Added Datatype to link

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
Var:'media_thumb_array' = array;
Var:'media_files_array' = array;
Var:'media_files_clean_array' = array;
Var:'LoopFrom' = integer;
Var:'LoopTo' = integer;
Local('ThisPosition' = string);
Local('ThisPositionLink' = string);

// Initialize the vars to display the table
var:'column_limit' = 5;
var:'column_counter' = 0;
var:'row_counter' = 1;

// *************** START DELETE ***************
// If Action=Delete, delete the indicated file, then proceed
If: $vAction == 'Delete';

	// Look for delete errors
	Local('DeleteError' = false);

	If: (#ImageType == 'Media');

		// SPECIAL for Media Only
		// Delete the media file (ALL media type)
		File_Delete:(($svMediaPath)($vID));
		If: (File_CurrentError) != 'No Error';
			#DeleteError = true;
		/If;
		Debug;
			'48: Delete Media File<br>\n';
			'48: Filename = ' ($vID) '<br>\n';
			'48: File_CurrentError = ' (File_CurrentError) '<br>\n';
			'48: DeleteError = ' (#DeleteError) '<br>\n';
		/Debug;

		// Check for .swf files - These don't have medium or large images
		If: ($vID->EndsWith('.swf'));
	
			// Modify the filename to remove the .flv extension
			$vID->(RemoveTrailing('.swf'));
			$vID += ('.jpg');
	
			// Delete thumb. Flash file preview are put in $svMediaPath
			File_Delete:(($svMediaThmbPath)($vID));
			If: (File_CurrentError) != 'No Error';
				#DeleteError = true;
			/If;
			Debug;
				'60: Delete Thumb Image<br>\n';
				'60: Filename = ' ($vID) '<br>\n';
				'60: File_CurrentError = ' (File_CurrentError) '<br>\n';
				'60: DeleteError = ' (#DeleteError) '<br>\n';
			/Debug;

		// Not an .swf, so delete all previews
		Else;

			// Modify the filename to remove the .flv extensions
			$vID->(RemoveTrailing('.flv'));
			$vID += ('.jpg');
	
			// Delete thumb
			File_Delete:(($svMediaThmbPath)($vID));
			If: (File_CurrentError) != 'No Error';
				#DeleteError = true;
			/If;
			Debug;
				'99: Delete Thumb Image<br>\n';
				'99: Filename = ' ($vID) '<br>\n';
				'99: File_CurrentError = ' (File_CurrentError) '<br>\n';
				'99: DeleteError = ' (#DeleteError) '<br>\n';
			/Debug;
	
			// Delete medium
			File_Delete:(($svMediaMdPath)($vID));
			If: (File_CurrentError) != 'No Error';
				#DeleteError = true;
			/If;
			Debug;
				'111: Delete Medium Image<br>\n';
				'111: Filename = ' ($vID) '<br>\n';
				'111: File_CurrentError = ' (File_CurrentError) '<br>\n';
				'111: DeleteError = ' (#DeleteError) '<br>\n';
			/Debug;
			// Delete large
			File_Delete:(($svMediaLrgPath)($vID));
			If: (File_CurrentError) != 'No Error';
				#DeleteError = true;
			/If;
			Debug;
				'122: Delete Large Image<br>\n';
				'122: Filename = ' ($vID) '<br>\n';
				'122: File_CurrentError = ' (File_CurrentError) '<br>\n';
				'122: DeleteError = ' (#DeleteError) '<br>\n';
			/Debug;
	
			// Modify the filename to delete the .png (Poster Frame) file
			$vID->(RemoveTrailing('.jpg'));
			$vID += ('.png');
	
			// Delete the Poster Frame
			File_Delete:(($svMediaPath)($vID));
			If: (File_CurrentError) != 'No Error';
				#DeleteError = true;
			/If;
			Debug;
				'139: Delete Poster Frame<br>\n';
				'139: Filename = ' ($vID) '<br>\n';
				'139: File_CurrentError = ' (File_CurrentError) '<br>\n';
				'139: DeleteError = ' (#DeleteError) '<br>\n';
			/Debug;

		/If;

	// Everything else is probably an image
	Else;

		// Delete thumb
		File_Delete:(($svImagesThmbPath)($vID));
		If: (File_CurrentError) != 'No Error';
			#DeleteError = true;
		/If;
		Debug;
			'155: Delete Thumb Image<br>\n';
			'155: Filename = ' ($vID) '<br>\n';
			'155: File_CurrentError = ' (File_CurrentError) '<br>\n';
			'155: DeleteError = ' (#DeleteError) '<br>\n';
		/Debug;
		// Delete medium
		File_Delete:(($svImagesMdPath)($vID));
		If: (File_CurrentError) != 'No Error';
			#DeleteError = true;
		/If;
		Debug;
			'156: Delete Medium Image<br>\n';
			'156: Filename = ' ($vID) '<br>\n';
			'156: File_CurrentError = ' (File_CurrentError) '<br>\n';
			'156: DeleteError = ' (#DeleteError) '<br>\n';
		/Debug;
		// Delete large
		File_Delete:(($svImagesLrgPath)($vID));
		If: (File_CurrentError) != 'No Error';
			#DeleteError = true;
		/If;
		Debug;
			'177: Delete Large Image<br>\n';
			'177: Filename = ' ($vID) '<br>\n';
			'177: File_CurrentError = ' (File_CurrentError) '<br>\n';
			'177: DeleteError = ' (#DeleteError) '<br>\n';
		/Debug;
	/If;

	// Set the error code
	If: #DeleteError == true;
		$vError = '1022';
		$vOption = (File_CurrentError);
	Else;
		$vError = '1023';
		$vOption = ($vIDOriginal);
	/If;


	// DELETE/MODIFY DATABASE ENTRIES
	Include(($svLibsPath)'library_moddata.inc');

/If;
// *************** END DELETE ***************

// Get the Images directory listing
$image_thumb_array = (File_ListDirectory: $svImagesThmbPath);
If: $image_thumb_array >> '.DS_Store';
	$image_thumb_array->(Remove:1);
/If;
If: $image_thumb_array >> '.svn';
	$image_thumb_array->(Remove:1);
/If;

// Get the Media directory listing
$media_thumb_array = (File_ListDirectory: $svMediaThmbPath);
If: $media_thumb_array >> '.DS_Store';
	$media_thumb_array->(Remove:1);
/If;
If: $media_thumb_array >> '.svn';
	$media_thumb_array->(Remove:1);
/If;

// Get the Media files listing
$media_files_array = (File_ListDirectory: $svMediaPath);
If: $media_files_array >> '.DS_Store';
	$media_files_array->(Remove:1);
/If;
If: $media_files_array >> '.svn';
	$media_files_array->(Remove:1);
/If;
// Get rid of thumbnail folders
$media_files_array->(RemoveAll('large/'));
$media_files_array->(RemoveAll('med/'));
$media_files_array->(RemoveAll('thumb/'));

// Cleanse $media_thumb_array, removing .png files (poster frames)
// This results in an array of only media files
Loop:($media_files_array->Size);
	Local('ThisArrayElement' = ($media_files_array->(Get(Loop_Count))));
	If: !(#ThisArrayElement->EndsWith('png')) && !(#ThisArrayElement->EndsWith('jpg'));
		$media_files_clean_array->insert(#ThisArrayElement);
	/If;
/Loop;
// Debug;
//	'190: <strong>media_files_array</strong> = ' ($media_files_array) '<br>\n';
//	'190: <strong>media_files_clean_array</strong> = ' ($media_files_clean_array) '<br>\n';
// /Debug;

// Abort;

// Merge the Media Clean Array into the Image array
$image_thumb_array->(Merge: $media_files_clean_array);

// Sort the array as now it is out of order
$image_thumb_array->Sort;
// Debug;
//	'192: <strong>image_thumb_array</strong> = ' ($image_thumb_array) '<br>\n';
// /Debug;

// Get how many images in the array
Var:'ImageCount' = ($image_thumb_array->size);

// Standard Error
If: (Var:'vError') != '';
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;

// Debugging
// Var:'svDebug' = 'N';

// If array empty, dump out message
If: $ImageCount == 0;
	'\t\t<div class="imagepanel" id="nifty">\n';
	'\t<h3 class="nifty">Image Library</h3>\n';
	'\t\t\t<p class="nifty">No images found.</p>\n';
	'\t\t</div>\n';
Else;
	'\t\t<div class="imagepanel" id="nifty">\n';
	'\t<h3 class="nifty">Image Library</h3>\n';
	'\t\t\t<p class="nifty">Images that have been uploaded to your site are displayed below.<br>\n</p>\n';
	$LoopTo = (Math_Add: $Records_Skipped, $Records_Per_Page);
	$LoopFrom = (Math_Add: $Records_Skipped, 1);
	Debug;
		'207: LoopFrom = ' ($LoopFrom) '<br>\n';
		'207: LoopTo = ' ($LoopTo) '<br>\n';
		'207: Records_Skipped = ' ($Records_Skipped) '<br>\n';
		'207: <strong>image_thumb_array</strong> = ' ($image_thumb_array) '<br>\n';
	/Debug;
	'<table width="100%" bgcolor="#F0F0F0">\n';
	'\t<tr>\n';
	$column_counter = 0;
	Loop: -From=$LoopFrom, -To=$LoopTo;
		$column_counter = (Math_Add: $column_counter, 1);
		'\t\t<td>\n';
		'\t\t\t<div align="center">\n';
		Protect;
			#ThisPosition = ($image_thumb_array->Get:(Loop_Count));
			// Determine which type of file it is - Image or Media
			// Check to see if the file is in the media array. If not, it must be an image.
//			If: $media_thumb_array->Contains(#ThisPosition);
			If: $media_files_clean_array->Contains(#ThisPosition);
				Local('ImageType' = 'Media');
			Else;
				Local('ImageType' = 'Image');
			/If;
			Debug;
//				'\t\t\t\tLoop_Count = ' (Loop_Count) '<br>\n';
				'\t\t\t\ThisPosition = ' (#ThisPosition) '<br>\n';
				'\t\t\t\tImageType = ' (#ImageType) '<br>\n';
//				'\t\t\t\tImagePreviewThmbPath = ' (#ImagePreviewThmbPath) '<br>\n';
//				'\t\t\t\tImagePreviewLrgPath = ' (#ImagePreviewLrgPath) '<br>\n';
			/Debug;

// We have to consider how to build a link, as some of the files are Images, and some are Media
// First build a link for Media
If: #ImageType == 'Media';

	#ThisPositionLink = (#ThisPosition);

	// Check for .swf file
	If: #ThisPosition->EndsWith('.swf');
		// Manufacture the link
		'\t\t\t\t<!-- 318 --><a href="media.lasso?ID='(#ThisPositionLink)'" target="_blank"><img src="'($svFileIconsPath)'swf_icon.jpg" width="66" height="73" alt="'(#ThisPosition)'" Title="This is a Flash animation. Click to play."><br>\n';
		'\t\t\t\t'(#ThisPosition)'</a><br>\n';
		'\t\t\t\t<a href="library.lasso?ID='(#ThisPositionLink)'&Action=Delete&Datatype='($vDataType)'&ImageType='(#ImageType)'" title="Delete this Image"><img src="'($svImagesPath)'trash_icon_12.png" width="12" height="15" alt="Trash Can Icon" align="middle"></a>\n';
	// Check for .flv file
	Else: #ThisPosition->EndsWith('.flv');
		// Manufacture the link
		#ThisPosition->(RemoveTrailing('.flv'));
		#ThisPosition += ('.jpg');
		'\t\t\t\t<!-- 326 --><a href="media.lasso?ID='(#ThisPositionLink)'" target="_blank"><img src="'($svMediaThmbPath)(#ThisPosition)'" alt="'(#ThisPosition)'" Title="This image is a video. Click to play."></a><br>\n';
		'\t\t\t\t<img src="'($svFileIconsPath)'television.png" alt="TV Icon" Title="This image is a video. Click the link to play." width="16" height="16"><br>\n';
		'\t\t\t\t<a href="media.lasso?ID='(#ThisPositionLink)'" target="_blank">'(#ThisPositionLink)'</a><br>\n';
		'\t\t\t\t<a href="library.lasso?ID='(#ThisPositionLink)'&Action=Delete&Datatype='($vDataType)'&ImageType='(#ImageType)'" title="Delete this Image"><img src="'($svImagesPath)'trash_icon_12.png" width="12" height="15" alt="Trash Can Icon" align="middle"></a>\n';
	// Other media files (not .swf)
	Else;
		// Manufacture the link
		'\t\t\t\t<!-- 333 --><a href="media.lasso?ID='(#ThisPositionLink)'" target="_blank"><img src="'($svMediaThmbPath)(#ThisPosition)'" alt="'(#ThisPosition)'" Title="This image is a video. Click to play."></a><br>\n';
		'\t\t\t\t<img src="'($svFileIconsPath)'television.png" alt="TV Icon" Title="This image is a video. Click the link to play." width="16" height="16"><br>\n';
		'\t\t\t\t<a href="media.lasso?ID='(#ThisPositionLink)'" target="_blank">'(#ThisPositionLink)'</a><br>\n';
		'\t\t\t\t<a href="library.lasso?ID='(#ThisPositionLink)'&Action=Delete&Datatype='($vDataType)'&ImageType='(#ImageType)'" title="Delete this Image"><img src="'($svImagesPath)'trash_icon_12.png" width="12" height="15" alt="Trash Can Icon" align="middle"></a>\n';
	/If;

	// Check Image Usage Link - Displays for every type of image
	'\t\t\t\t&nbsp;&nbsp;&nbsp;\n';
	'\t\t\t\t<!-- 350 --><a href="check_imageusage.lasso?Datatype='($vDatatype)'&ID='(#ThisPosition)'&height=450&width=500" class="thickbox" title="Check Usage of '(#ThisPosition)'"><img src="'($svFileIconsPath)'layout_link.png" width="16" height="16" alt="Layout Link Icon" align="middle"></a>\n';

// Other files (not Media)
Else;
		'\t\t\t\t<!-- 340 --><a href="'($svImagesLrgPath)(#ThisPosition)'" target="_blank"><img src="'($svImagesThmbPath)(#ThisPosition)'" alt="'(#ThisPosition)'"><br>\n';
		'\t\t\t\t'(#ThisPosition)'</a><br>\n';
		'\t\t\t\t<!-- 342 --><a href="library.lasso?ID='(#ThisPosition)'&Action=Delete&Datatype='($vDataType)'&ImageType='(#ImageType)'" title="Delete this Image"><img src="'($svImagesPath)'trash_icon_12.png" width="12" height="15" alt="Trash Can Icon" align="middle"></a>\n';

		// Check Image Usage Link - Displays for every type of image
		'\t\t\t\t&nbsp;&nbsp;&nbsp;\n';
		'\t\t\t\t<!-- 350 --><a href="check_imageusage.lasso?Datatype='($vDatatype)'&ID='(#ThisPosition)'&height=450&width=500" class="thickbox" title="Check Usage of '(#ThisPosition)'"><img src="'($svFileIconsPath)'layout_link.png" width="16" height="16" alt="Layout Link Icon" align="middle"></a>\n';

/If;

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