<?Lassoscript
// Last modified: 10/25/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing content pages
// Adapted from File Grid

// Debugging
// Var:'svDebug' = 'N';

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
var:'column_counter'= 0;
var:'row_counter'= 1;

// Get the records
Var:'SQLSearchGalleries' = 'SELECT * FROM ' $svGalleryTable;
Inline: $IV_Galleries, -Table=$svGalleryTable, -SQL=$SQLSearchGalleries;

	Var:'image_thumb_array' = (Records_Array);
	Var:'ImageCount' = ($image_thumb_array->size);
/*	If: $svDebug == 'Y';
		'<p class="debug">\n';
		'41: image_thumb_array = ' ($image_thumb_array) '<br>\n';
		'41: ImageCount = ' ($ImageCount) '</p>\n';
	/If;
*/	
	// If array empty, dump out message
	If: $ImageCount == 0;
		'\t\t<div class="imagepanel" id="nifty2">\n';
		'\t<h3 class="nifty">Gallery Entries</h3>\n';
		'\t\t\t<p class="nifty">No gallery entries found.</p>\n';
		'\t\t</div>\n';
	Else;
		'\t\t<div class="imagepanel" id="nifty2">\n';
		'\t<h3 class="nifty">Gallery Entries</h3>\n';
		'\t\t\t<p class="nifty">Existing gallery entries are listed below in order by ID.<br>\n</p>\n';
		$LoopTo = (Math_Add: $Records_Skipped, $Records_Per_Page);
		$LoopFrom = (Math_Add: $Records_Skipped, 1);
/*		If: $svDebug == 'Y';
			'<p class="debug">\n';
			'60: LoopFrom = ' ($LoopFrom) '<br>\n';
			'60: LoopTo = ' ($LoopTo) '<br>\n';
			'60: Records_Skipped = ' ($Records_Skipped) '</p>\n';
		/If;
*/
		'<table width="100%" bgcolor="#F0F0F0">\n';
		'\t<tr>\n';
		$column_counter = 0;
		Loop: -From=$LoopFrom, -To=$LoopTo;
			$column_counter = (Math_Add: $column_counter, 1);
			'\t\t<td>\n';
			'\t\t\t<div align="center">\n';
			Protect;
				Local:'ThisPosition' = ($image_thumb_array->Get:(Loop_Count));
				Local:'ThisPosition_GalleryID' = ($ThisPosition->Get:1);
				Local:'ThisPosition_GalleryTitle' = ($ThisPosition->Get:2);
				Local:'ThisPosition_GalleryCaption' = ($ThisPosition->Get:3);
				Local:'ThisPosition_GalleryURL' = ($ThisPosition->Get:4);
				Local:'ThisPosition_GalleryThumb' = ($ThisPosition->Get:5);
/*				If: $svDebug == 'Y';
				'<p class="debug">\n';
					'\tLoop_Count = ' (Loop_Count) '<br>\n';
					'\tThisPosition_GalleryID = ' (#ThisPosition_GalleryID) '<br>\n';
					'\tThisPosition_GalleryTitle = ' (#ThisPosition_GalleryTitle) '<br>\n';
					'\tThisPosition_GalleryCaption = ' (#ThisPosition_GalleryCaption) '<br>\n';
					'\tThisPosition_GalleryURL = ' (#ThisPosition_GalleryURL) '<br>\n';
					'\tThisPosition_GalleryThumb = ' (#ThisPosition_GalleryThumb) '</p>\n';
				/If;
*/
				'\t\t\t\t<strong>'($ThisPosition_GalleryTitle)'</strong><br>\n';
				// Datatype for this link is different because we want to go to the Gallery Entry
				'\t\t\t<a href="setup_editrecord.lasso?ID=' ($ThisPosition_GalleryID) '&New=Y&Datatype=GalleryEntry">\n';
				'\t\t\t\t<img src="'($svImagesThmbPath)($ThisPosition_GalleryThumb)'" alt="'($ThisPosition_GalleryThumb)'" title="ID '($ThisPosition_GalleryID)'"></a><br>\n';
				'\t\t\t\t'($ThisPosition_GalleryCaption)'<br>\n';
				'\t\t\t<p class="ghost">'(#ThisPosition_GalleryThumb) '</p>\n';
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

/Inline;
?> 