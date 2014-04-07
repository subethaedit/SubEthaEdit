<?Lassoscript
// Last modified 1/15/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing content pages
// Adapted from File Grid

// Debugging
// Var:'svDebug' = 'N';

// CHANGE NOTES
// 1/15/09
// First implementation

// Initialize vars for nav control
Var:'Records_Skipped' = 0;
If: (Action_Param:'skip');
	$Records_Skipped = (Action_Param:'skip');
/If;
Var:'This_Group' = (Action_Param:'group');
Var:'Records_Per_Page' = '15';
Var:'Group_Size' = (Math_Mult:(Var:'Records_Per_Page'),5);
Var:'SkipCount' = integer;
Var:'Records_Found' = integer;

// Initialize vars to display file matrix
Var:'image_thumb_array' = array;
Var:'LoopFrom' = integer;
Var:'LoopTo' = integer;
Var:'ThisPosition' = integer;

// Initialize the vars to display the table

// Get the records
Var:'SQLSearchStoriesIndiv' = 'SELECT ID, Story_Head, Story_Comment, Story_Name, Story_Thumb
FROM ' $svStoriesTable;
Inline: $IV_Stories, -Table=$svStoriesTable, -SQL=$SQLSearchStoriesIndiv;

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
		'\t<h3 class="nifty">Story Entries</h3>\n';
		'\t\t\t<p class="nifty">No story entries found.</p>\n';
		'\t\t</div>\n';
	Else;
		'\t\t<div class="imagepanel" id="nifty2">\n';
		'\t<h3 class="nifty">Story Entries</h3>\n';
		'\t\t\t<p class="nifty">Existing story entries are listed below in order by ID.<br>\n</p>\n';
		$LoopTo = (Math_Add: $Records_Skipped, $Records_Per_Page);
		$LoopFrom = (Math_Add: $Records_Skipped, 1);
/*		If: $svDebug == 'Y';
			'<p class="debug">\n';
			'60: LoopFrom = ' ($LoopFrom) '<br>\n';
			'60: LoopTo = ' ($LoopTo) '<br>\n';
			'60: Records_Skipped = ' ($Records_Skipped) '</p>\n';
		/If;
*/
		Loop: -From=$LoopFrom, -To=$LoopTo;
			Protect;
				Local:'ThisPosition' = ($image_thumb_array->Get:(Loop_Count));
				Local:'ThisPosition_StoryID' = ($ThisPosition->Get:1);
				Local:'ThisPosition_StoryHead' = ($ThisPosition->Get:2);
				Local:'ThisPosition_StoryComment' = (String_Extract: -startposition=1, -endposition=300, ($ThisPosition->Get:3));
					If:(String_Length:$ThisPosition_StoryComment) >> 300;
						$ThisPosition_StoryComment += '.&nbsp;.&nbsp;';
					/If;
				Local:'ThisPosition_StoryName' = ($ThisPosition->Get:4);
				Local:'ThisPosition_StoryThumb' = ($ThisPosition->Get:5);
/*				If: $svDebug == 'Y';
				'<p class="debug">\n';
					'\tLoop_Count = ' (Loop_Count) '<br>\n';
					'\tThisPosition_StoryID = ' (#ThisPosition_StoryID) '<br>\n';
					'\tThisPosition_StoryHead = ' (#ThisPosition_StoryHead) '<br>\n';
					'\tThisPosition_StoryComment = ' (#ThisPosition_StoryComment) '<br>\n';
					'\tThisPosition_StoryName = ' (#ThisPosition_StoryName) '<br>\n';
					'\tThisPosition_StoryThumb = ' (#tThisPosition_StoryThumb) '</p>\n';
				/If;
*/
		'<table width="100%" bgcolor="#F0F0F0">\n';
		'\t<tr>\n';
		'\t\t<td width="140">\n';
				// Datatype for this link is different because we want to go to the Story Entry
				'\t\t\t<p class="niftycenter">\n';
				If: $ThisPosition_StoryThumb != '';
					'\t\t\t\t<img src="'($svImagesThmbPath)($ThisPosition_StoryThumb)'" alt="'($ThisPosition_StoryThumb)'" title="ID '($ThisPosition_StoryID)'">\n';
				/If;

			'\t\t</p></td>\n';
			'\t\t<td>\n';

				'\t\t\t<a href="setup_editrecord.lasso?ID=' ($ThisPosition_StoryID) '&New=Y&Datatype=Story">\n';
				'\t\t\t\t<strong>';

				If: ($ThisPosition_StoryHead != ''); $ThisPosition_StoryHead; Else; '(ID '$ThisPosition_StoryID')'; /If;
				'</strong></a><br>\n';

				'\t\t\t\t<strong>'($ThisPosition_StoryName)'</strong><br>\n';
				'\t\t\t\t'($ThisPosition_StoryComment)'<br>\n';
				'\t\t\n';

			'\t\t</td>\n';
			'\t</tr>\n';
			'</table>\n';

			/Protect;
		/Loop;
		// Navigation control
		'\t\t\t<p class="niftycenter">';
		Include:($svLibsPath)'nav_control_grid.inc';
		'\t\t\t</p>\n';
	/If;

	'\t\t</div>\n';

/Inline;
?> 