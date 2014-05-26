<?Lassoscript
// Last modified 7/17/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing content pages
// Adapted from File Grid

// Debugging
// Var:'svDebug' = 'N';

// CHANGE NOTES
// 7/17/09
// Changed sort order to Descending

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
Var:'SQLSearchTestimonialsIndiv' = 'SELECT ID, Testimonial_Head, Testimonial_Comment, Testimonial_Name, Testimonial_Thumb
FROM ' $svTestimonialsTable ' ORDER BY ID DESC';
Inline: $IV_Testimonials, -Table=$svTestimonialsTable, -SQL=$SQLSearchTestimonialsIndiv;

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
		'\t<h3 class="nifty">Testimonial Entries</h3>\n';
		'\t\t\t<p class="nifty">No testimonial entries found.</p>\n';
		'\t\t</div>\n';
	Else;
		'\t\t<div class="imagepanel" id="nifty2">\n';
		'\t<h3 class="nifty">Testimonial Entries</h3>\n';
		'\t\t\t<p class="nifty">Existing testimonial entries are listed below in descending order by ID.<br>\n</p>\n';
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
				Local:'ThisPosition_TestimonialID' = ($ThisPosition->Get:1);
				Local:'ThisPosition_TestimonialHead' = ($ThisPosition->Get:2);
				Local:'ThisPosition_TestimonialComment' = (String_Extract: -startposition=1, -endposition=300, ($ThisPosition->Get:3));
					If:(String_Length:$ThisPosition_TestimonialComment) >> 300;
						$ThisPosition_TestimonialComment += '.&nbsp;.&nbsp;';
					/If;
				Local:'ThisPosition_TestimonialName' = ($ThisPosition->Get:4);
				Local:'ThisPosition_TestimonialThumb' = ($ThisPosition->Get:5);
/*				If: $svDebug == 'Y';
				'<p class="debug">\n';
					'\tLoop_Count = ' (Loop_Count) '<br>\n';
					'\tThisPosition_TestimonialID = ' (#ThisPosition_TestimonialID) '<br>\n';
					'\tThisPosition_TestimonialHead = ' (#ThisPosition_TestimonialHead) '<br>\n';
					'\tThisPosition_TestimonialComment = ' (#ThisPosition_TestimonialComment) '<br>\n';
					'\tThisPosition_TestimonialName = ' (#ThisPosition_TestimonialName) '<br>\n';
					'\tThisPosition_TestimonialThumb = ' (#tThisPosition_TestimonialThumb) '</p>\n';
				/If;
*/
		'<table width="100%" bgcolor="#F0F0F0">\n';
		'\t<tr>\n';
		'\t\t<td width="140">\n';
				// Datatype for this link is different because we want to go to the Testimonial Entry
				'\t\t\t<p class="niftycenter">\n';
				If: $ThisPosition_TestimonialThumb != '';
					'\t\t\t\t<img src="'($svImagesThmbPath)($ThisPosition_TestimonialThumb)'" alt="'($ThisPosition_TestimonialThumb)'" title="ID '($ThisPosition_TestimonialID)'">\n';
				/If;

			'\t\t</p></td>\n';
			'\t\t<td>\n';

				'\t\t\t<a href="setup_editrecord.lasso?ID=' ($ThisPosition_TestimonialID) '&New=Y&Datatype=Testimonial">\n';
				'\t\t\t\t<strong>';

				If: ($ThisPosition_TestimonialHead != ''); $ThisPosition_TestimonialHead; Else; '(ID '$ThisPosition_TestimonialID')'; /If;
				'</strong></a><br>\n';

				'\t\t\t\t'($ThisPosition_TestimonialComment)'<br>\n';
				'\t\t\t\t<strong>'($ThisPosition_TestimonialName)'</strong><br>\n';
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