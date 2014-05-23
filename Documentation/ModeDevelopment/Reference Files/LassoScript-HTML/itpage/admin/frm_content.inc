<?Lassoscript
// Last modified 11/24/10 by ECL, Landmann InterActive

// CHANGE NOTES
// 10/12/07
// Recoded for Clean URLs
// 11/15/07
// Switched fields CategoriesID to HeirarchyID, removed SectionID as it is now obsolete
// 1/17/08
// Changed Subhead input box to textarea
// 2/18/08
// Added code to remove .svn directories from displaying on template popup
// 4/2/08
// Added code for URL Fix (Issue #547)
// 6/25/08
// Silly spacing changes that were missed before to make all columns same width
// 6/5/09
// Adding .swf to Media Array
// 6/22/09
// Added gallery feature
// 11/2/09
// Changed path to ckeditor to remove extra leading slash
// Made SEO panel toggleable
// 11/23/09
// Added SortOrder
// Took off tooltips, as there seems to be some sort of conflict with ckeditor
// Made Image Caption input a bit wider
// 11/24/10
// Add ShowInNav field
// Added check against $svCSSIgnoreArray for stylesheets to ignore when creating stylesheet select list
// 11/30/10
// Added "Duplicate" this page functionality

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/frm_content</strong></p>\n';
/If;

// Convert action_params
Include:'content_params.inc';

// If Edit page, get the record
If: (Response_Filepath) >> 'setup_editrecord.lasso';

	// If Process = Y, form was submit, so update the record
	// Otherwise, it is a new edit so get the record
	If: $vProcess != 'Y';

		// If error 1021, action was a successful delete, so display error and abort right away
		If: $vError == '1021';
			LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
			Abort;
		/If;

		// Get the record
		Var:'SQLGetContent' = 'SELECT * FROM ' $svContentTable ' WHERE ID = "' $vID '" LIMIT 1';
		Inline: $IV_Content, -Table=$svContentTable, -SQL=$SQLGetContent;

			If: $svDebug == 'Y';
				'<p class="debug">32: Error_CurrentError = ' (Error_CurrentError) '</p>\n';
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
			Var:'vHeirarchyID' = (Field:'HeirarchyID');
			Var:'vHeadline' = (Field:'Headline');
			Var:'vSubhead' = (Field:'Subhead');
			Var:'vAuthor' = (Field:'Author');
			Var:'vText_1' = (Field:'Text_1');
			Var:'vText_2' = (Field:'Text_2');
			Var:'vImage_thumb' = (Field:'Image_thumb');
			Var:'vImage_med' = (Field:'Image_med');
			Var:'vImage_large' = (Field:'Image_large');
			Var:'vImage_title' = (Field:'Image_title');
			Var:'vImage_caption' = (Field:'Image_caption');
			Var:'vMedia_File' = (Field:'Media_File');
			Var:'vPrice_1' = (Field:'Price_1');
			Var:'vPrice_2' = (Field:'Price_2');
			Var:'vURL' = (Field:'URL');
			Var:'vActive' = (Field:'Active');
			Var:'vActiveFrom' = (Field:'ActiveFrom');
			Var:'vActiveTo' = (Field:'ActiveTo');
			Var:'vDateModified' = (Field:'DateModified');
			Var:'vPageKeywords' = (Field:'PageKeywords');
			Var:'vPageAuthor' = (Field:'PageAuthor');
			Var:'vPageDescription' = (Field:'PageDescription');
			Var:'vPageCopyright' = (Field:'PageCopyright');
			Var:'vPageTitle' = (Field:'PageTitle');
			Var:'vPageTemplate' = (Field:'PageTemplate');
			Var:'vPageStylesheet' = (Field:'PageStylesheet');
			Var:'vPortfolioGroupID' = (Field:'PortfolioGroupID');
			Var:'vGalleryGroupID' = (Field:'GalleryGroupID');
			Var:'vTestimonial' = (Field:'Testimonial');
			Var:'vStory' = (Field:'Story');
			Var:'vSortOrder' = (Field:'SortOrder');
			Var:'vShowInNav' = (Field:'ShowInNav');
			Var:'vAttachPopup' = (Field:'AttachPopup');
		/Inline;

		// If there is an error, dump out error 1012 "Update Failed"
		If: (Error_CurrentError) != 0;
			$vError = '2000';
		/If;

	/If;
	
/If;

If: (Var:'vID') == '';
	'<h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;Add Content</h2>\n';
Else;
	'<h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;Edit Content</h2>\n';
/If;

// Standard Error Table
If: $vError != '';
	LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
/If;
?>
<form action="setup_addresponse.lasso" method="post">
	<table width="500">
		<tr>
			<td width="90" class="tablehead_10_white_right">Navigation[$svInputRequired]</td>
			<td width="410" bgcolor="#f0f0f0">
<strong>Heirarchy</strong>
[LI_BuildCategorySelect: -Tooltip='N']
&nbsp;&nbsp;&nbsp;&nbsp;<strong>Navigation Sort Order</strong>
				<select name="SortOrder" id="SortOrder">
					<option value=""[If: (Var:'vSortOrder') == ''] selected[/If]></option>
					<option value="1"[If: (Var:'vSortOrder') == '1'] selected[/If]>1</option>
					<option value="2"[If: (Var:'vSortOrder') == '2'] selected[/If]>2</option>
					<option value="3"[If: (Var:'vSortOrder') == '3'] selected[/If]>3</option>
					<option value="4"[If: (Var:'vSortOrder') == '4'] selected[/If]>4</option>
					<option value="5"[If: (Var:'vSortOrder') == '5'] selected[/If]>5</option>
					<option value="6"[If: (Var:'vSortOrder') == '6'] selected[/If]>6</option>
					<option value="7"[If: (Var:'vSortOrder') == '7'] selected[/If]>7</option>
					<option value="8"[If: (Var:'vSortOrder') == '8'] selected[/If]>8</option>
					<option value="9"[If: (Var:'vSortOrder') == '9'] selected[/If]>9</option>
				</select>
				<div style="clear: both;"></div>
				<div class="dp-date-label"><strong>Active</strong> <input type="radio" name="Active" value="Y"[If: (Var:'vActive') == 'Y' || (Var:'vActive') == ''] checked[/If]> Yes
				<input type="radio" name="Active" value="N"[If: (Var:'vActive') == 'N'] checked[/If]> No
&nbsp;&nbsp;&nbsp;&nbsp;
				<strong>Active From / To</strong>&nbsp;&nbsp;</div>
				<input type="text" name="ActiveFrom" id="date1" value="[If($vActiveFrom != '0000-00-00')][$vActiveFrom][/If]" size="12" class="date-pick">
				<input type="text" name="ActiveTo" id="date2" value="[If($vActiveTo != '0000-00-00')][$vActiveTo][/If]" size="12" class="date-pick">
				<br>
				<div style="clear: both;"></div>
				<strong>Show in Navigation</strong>&nbsp;<input type="radio" name="ShowInNav" id="ShowInNavY" value="Y"[If: (Var:'vShowInNav') == 'Y' || (Var:'vShowInNav') == ''] checked[/If]> Yes
				<input type="radio" name="ShowInNav" id="ShowInNavN" value="N"[If: (Var:'vShowInNav') == 'N'] checked[/If]> No
&nbsp;&nbsp;&nbsp;&nbsp;
				<strong>Attach Contact Popup</strong>&nbsp;<input type="radio" name="AttachPopup" id="AttachPopupY" value="Y"[If: (Var:'vAttachPopup') == 'Y' || (Var:'vAttachPopup') == ''] checked[/If]> Yes
				<input type="radio" name="AttachPopup" id="AttachPopupN" value="N"[If: (Var:'vAttachPopup') == 'N'] checked[/If]> No
			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Headline[$svInputRequired]</td>
			<td width="410" bgcolor="#f0f0f0">
				<textarea name="Headline" id="Headline" cols="45" rows="1">[$vHeadline]</textarea>
			</td>
		</tr>
[If: $svSubheadActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Subhead</td>
			<td width="410" bgcolor="#f0f0f0">
				<textarea name="Subhead" id="Subhead" cols="45" rows="1">[$vSubhead]</textarea>
			</td>
		</tr>
[/If]
[If: $svAuthorActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Author</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Author" id="Author" value="[$vAuthor]" size="24" maxlength="64">
			</td>
		</tr>
[/If]
[If: $svText1Active == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Text 1</td>
			<td width="410" bgcolor="#f0f0f0">
				<textarea name="Text_1" id="Text_1" cols="60" rows="10">[$vText_1]</textarea>
			</td>
		</tr>
<!-- Activate CKEditor for the Text field -->
<script type="text/javascript">
	CKEDITOR.replace( 'Text_1' );
</script>
[/If]
[If: $svText2Active == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Text 2</td>
			<td width="410" bgcolor="#f0f0f0">
				<textarea name="Text_2" id="Text_2" cols="60" rows="10">[$vText_2]</textarea>
			</td>
		</tr>
<!-- Activate CKEditor for the Text field -->
<script type="text/javascript">
	CKEDITOR.replace( 'Text_2' );
</script>
[/If]
[If: $svImageThumbActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Thumbnail<br>Image Name</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript   
Var:'image_thumb_array' = (File_ListDirectory: ($svImagesThmbPath));
If: Var:'image_thumb_array' >> '.DS_Store';
	$image_thumb_array->(Remove:1);
/If;
	'\t\t\t<select name="Image_Thumb" id="Image_Thumb">\n';
	'\t\t\t\t<option value=""'; If: (Var:'vImage_Thumb') == ''; ' selected'; /If; '></option>\n';
		Iterate: $image_Thumb_array, (var:'temp_Thumb');
			'\t\t\t\t\t<option value="'($temp_Thumb) '"'; If: (Var:'vImage_Thumb') == ($temp_Thumb); ' selected'; /If; '>'($temp_Thumb)'</option>\n';
		/Iterate;
	'\t\t\t</select>\n';
?>			</td>
		</tr>
		[/If]
[If: $svImageMedActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Medium<br>Image Name</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript   
Var:'image_med_array' = (File_ListDirectory: ($svImagesThmbPath));
If: Var:'image_med_array' >> '.DS_Store';
	$image_med_array->(Remove:1);
/If;
	'\t\t\t<select name="Image_Med" id="Image_Med">\n';
	'\t\t\t\t<option value=""'; If: (Var:'vImage_Med') == ''; ' selected'; /If; '></option>\n';
		Iterate: $image_Thumb_array, (var:'temp_Med');
			'\t\t\t\t\t<option value="'($temp_Med) '"'; If: (Var:'vImage_Med') == ($temp_Med); ' selected'; /If; '>'($temp_Med)'</option>\n';
		/Iterate;
	'\t\t\t</select>\n';
?>			</td>
		</tr>
[/If]
[If: $svImageLargeActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Large<br>
					Image Name</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript   
Var:'image_large_array' = (File_ListDirectory: ($svImagesThmbPath));
If: Var:'image_large_array' >> '.DS_Store';
	$image_large_array->(Remove:1);
/If;
	'\t\t\t<select name="Image_Large" id="Image_Large">\n';
	'\t\t\t\t<option value=""'; If: (Var:'vImage_Large') == ''; ' selected'; /If; '></option>\n';
		Iterate: $image_Large_array, (var:'temp_Large');
			'\t\t\t\t\t<option value="'($temp_Large) '"'; If: (Var:'vImage_Large') == ($temp_Large); ' selected'; /If; '>'($temp_Large)'</option>\n';
		/Iterate;
	'\t\t\t</select>\n';
?>			</td>
		</tr>
[/If]
[If: $svImageTitleActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Image Title</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Image_Title" id="Image_Title" value="[$vImage_Title]" size="16" maxlength="20">
			</td>
		</tr>
[/If]
[If: $svImageCaptionActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Image Caption</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Image_Caption" id="Image_Caption" value="[$vImage_Caption]" size="55" maxlength="255">
			</td>
		</tr>
[/If]

		<tr>
			<td width="90" class="tablehead_10_white_right">Media File</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript   
// Get the Media directory listing
Var:'media_arrayTEMP' = (File_ListDirectory: $svMediaPath);
Var:'media_array' = array;
Loop: -From=1, -To=$media_arrayTEMP->size;
	If: ($media_arrayTEMP->(Get:(Loop_Count))->EndsWith('.flv')) ||
		($media_arrayTEMP->(Get:(Loop_Count))->EndsWith('.swf'));
		$media_array->(Insert:($media_arrayTEMP->(Get:(Loop_Count))));
	/If;
/Loop;
// Clean out empty .flv entry - Why does this happen?
Loop: -From=1, -To=$media_arrayTEMP->size;
	If: ($media_arrayTEMP->(Get:(Loop_Count))->Equals('.flv'));
		$media_array->(Remove:1);
	/If;
/Loop;
	'\t\t\t<select name="Media_File" id="Media_File">\n';
	'\t\t\t\t<option value=""'; If: (Var:'vMedia_File') == ''; ' selected'; /If; '></option>\n';
		Iterate: $media_array, (var:'temp_Media');
			'\t\t\t\t\t<option value="'($temp_Media) '"'; If: (Var:'vMedia_File') == ($temp_Media); ' selected'; /If; '>'($temp_Media)'</option>\n';
		/Iterate;
	'\t\t\t</select>\n';
?>			</td>
		</tr>

[If: $svPrice1Active == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Price 1</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Price_1" id="Price_1" value="[$vPrice_1]" size="10" maxlength="15">
			</td>
		</tr>
[/If]
[If: $svPrice2Active == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">Price 2</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="Price_2" id="Price_2" value="[$vPrice_2]" size="10" maxlength="15">
			</td>
		</tr>
[/If]
[If: $svURLActive == 'Y']
		<tr>
			<td width="90" class="tablehead_10_white_right">URL</td>
			<td width="410" bgcolor="#f0f0f0">
				<input type="text" name="URL" id="URL" value="[$vURL]" size="64" maxlength="128">
			</td>
		</tr>
[/If]
		<tr>
			<td width="90" class="tablehead_10_white_right">Page Template</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript   
Var:'TemplatesArray' = (File_ListDirectory: ($svTmpltsPath));
If: Var:'TemplatesArray' >> '.DS_Store';
	$TemplatesArray->(Remove:1);
/If;
If: Var:'TemplatesArray' >> '.svn';
	$TemplatesArray->(Remove:1);
/If;
'\t\t\t<select name="PageTemplate" id="PageTemplate">\n';
'\t\t\t\t<option value=""'; If: (Var:'vPageTemplate') == ''; ' selected'; /If; '></option>\n';
	Iterate: $TemplatesArray, (Local:'i');
		'\t\t\t\t\t<option value="'(#i) '"'; If: (Var:'vPageTemplate') == ($i); ' selected'; /If; '>'(#i)'</option>\n';
	/Iterate;
'\t\t\t</select>\n';
?>			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Page Stylesheet</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript   
Var:'StylesheetsArray' = (File_ListDirectory: ($svCSSPath));
If: Var:'StylesheetsArray' >> '.DS_Store';
	$StylesheetsArray->(Remove:1);
/If;
If: Var:'StylesheetsArray' >> '.svn';
	$StylesheetsArray->(Remove:1);
/If;
'\t\t\t<select name="PageStylesheet" id="PageStylesheet">\n';
'\t\t\t\t<option value=""'; If: (Var:'vPageStylesheet') == ''; ' selected'; /If; '></option>\n';
	Iterate: $StylesheetsArray, (Local:'i');
		If(!($svCSSIgnoreArray->Contains(#i)));
		'\t\t\t\t\t<option value="'(#i) '"'; If: (Var:'vPageStylesheet') == ($i); ' selected'; /If; '>'(#i)'</option>\n';
		/If;
	/Iterate;
'\t\t\t</select>\n';
?>			</td>
		</tr>

		<tr>
			<td width="90" class="tablehead_10_white_right">Portfolio Group</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript
				Var:'SQLSearchPortfolioGroups' = 'SELECT * FROM ' $svPortfolioGroupsTable ' WHERE Active = "Y"';
				Inline: $IV_Portfolios, -SQL=$SQLSearchPortfolioGroups;
					'\t\t\t\t<select name="PortfolioGroupID" id="PortfolioGroupID">\n';
					'\t\t\t\t\t<option value=""'; If: (Var:'vPortfolioGroupID') == ''; ' selected'; /If; '></option>\n';
					Records;
						'\t\t\t\t\t<option value="'(Field:'pg_groupid') '"'; If: (Var:'vPortfolioGroupID') == (Field:'pg_groupid'); ' selected'; /If; '>'(Field:'pg_name')'</option>\n';
					/Records;
					'\t\t\t\t</select>\n';
		        /Inline;

?>[Output_None]<!-- &nbsp;&nbsp;&nbsp;&nbsp;<span class="ghost"><a class="jt" href="[$svToolTipsPath]tt_portfoliogroup.html" rel="[$svToolTipsPath]tt_portfoliogroup.html" title="About Portfolio Groups"><img src="/site/images/question_16_trans.gif" width="16" height="16" alt="question icon"></a></span> -->[/Output_None]</td>
		</tr>

		<tr>
			<td width="90" class="tablehead_10_white_right">Gallery Group</td>
			<td width="410" bgcolor="#f0f0f0">
<?Lassoscript
				Var:'SQLSearchGalleryGroups' = 'SELECT * FROM ' $svGalleryGroupsTable ' WHERE Active = "Y"';
				Inline: $IV_Galleries, -SQL=$SQLSearchGalleryGroups;
					'\t\t\t\t<select name="GalleryGroupID" id="GalleryGroupID">\n';
					'\t\t\t\t\t<option value=""'; If: (Var:'vGalleryGroupID') == ''; ' selected'; /If; '></option>\n';
					Records;
						'\t\t\t\t\t<option value="'(Field:'gg_groupid') '"'; If: (Var:'vGalleryGroupID') == (Field:'gg_groupid'); ' selected'; /If; '>'(Field:'gg_name')'</option>\n';
					/Records;
					'\t\t\t\t</select>\n';
		        /Inline;

?>[Output_None]<!-- &nbsp;&nbsp;&nbsp;&nbsp;<span class="ghost"><a class="jt" href="[$svToolTipsPath]tt_gallerygroup.html" rel="[$svToolTipsPath]tt_gallerygroup.html" title="About Gallery Groups"><img src="/site/images/question_16_trans.gif" width="16" height="16" alt="question icon"></a></span> -->[/Output_None]</td>
		</tr>

		<tr>
			<td width="90" class="tablehead_10_white_right">Show Testimonials</td>
			<td width="410" bgcolor="#f0f0f0">
				<select name="Testimonial" id="Testimonial">
					<option value=""[If: (Var:'vTestimonial') == ''] selected[/If]></option>
					<option value="All"[If: (Var:'vTestimonial') == 'All'] selected[/If]>All</option>
					<option value="Random"[If: (Var:'vTestimonial') == 'Random'] selected[/If]>Random</option>
				</select>
			</td>
		</tr>

		<tr>
			<td width="90" class="tablehead_10_white_right">Show Stories</td>
			<td width="410" bgcolor="#f0f0f0">
				<select name="Story" id="Story">
					<option value=""[If: (Var:'vStory') == ''] selected[/If]></option>
					<option value="All"[If: (Var:'vStory') == 'All'] selected[/If]>All</option>
					<option value="Random"[If: (Var:'vStory') == 'Random'] selected[/If]>Random</option>
				</select>
			</td>
		</tr>
	</table>

<h2 class="panelhead" onclick="exp_coll('2')"><img src="/site/images/bullet_rightroundyellow.gif" width="20" height="24" id="image_2" alt="icon" title="Click to Toggle Panel" align="bottom"> SEO Tailoring</h2>
<div id="sp_2" style="display:none;">
	<table width="500">
		<tr>
			<td colspan="2" bgcolor="#333333" class="tablehead_10_white" valign="middle">Page-level SEO Tailoring Overrides</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Keywords</td>
			<td width="410" valign="top" bgcolor="#f0f0f0">
				<textarea name="PageKeywords" id="PageKeywords" cols="45" rows="6">[Var:'vPageKeywords']</textarea>
			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Author</td>
			<td width="410" valign="top" bgcolor="#f0f0f0">
				<input type="text" name="PageAuthor" id="PageAuthor" value="[Var:'vPageAuthor']" size="48" maxlength="255"> 
			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Description</td>
			<td width="410" valign="top" bgcolor="#f0f0f0">
				<textarea name="PageDescription" id="PageDescription" cols="45" rows="6">[Var:'vPageDescription']</textarea>
			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Copyright</td>
			<td width="410" valign="top" bgcolor="#f0f0f0">
				<input type="text" name="PageCopyright" id="PageCopyright" value="[Var:'vPageCopyright']" size="48" maxlength="255"> 
			</td>
		</tr>
		<tr>
			<td width="90" class="tablehead_10_white_right">Title</td>
			<td width="410" valign="top" bgcolor="#f0f0f0">
				<textarea name="PageTitle" id="PageTitle" cols="45" rows="2">[Var:'vPageTitle']</textarea>
			</td>
		</tr>
[If: (Response_Filepath) >> 'setup_edit' || (Response_Filepath) >> 'setup_search']
		<tr>
			<td width="90" class="tablehead_10_white_right">Date Modified</td>
			<td width="410" bgcolor="#f0f0f0">
				[Var:'vDateModified']
			</td>
		</tr>
[/If]
	</table>
</div>
	<table width="500">
		<tr>
			<td colspan="2" valign="top" bgcolor="#666666">
				<div align="center">
<?Lassoscript
// If Edit page, add a hidden field to show check if page is submit
If: (Response_Filepath) >> 'editrecord';
				'\t\t\t\t<input type="hidden" name="Process" value="Y">\n';
				'\t\t\t\t<input type="hidden" name="ID" value="'($vID)'">\n';
				'\t\t\t\t<input type="hidden" name="DataType" value="Content">\n';
				'\t\t\t\t<input type="submit" name="Action" value="Update">\n';
				'\t\t\t\t<input type="submit" name="Action" value="Duplicate">\n';
				'\t\t\t\t<input type="submit" name="Action" value="Delete" onClick="return confirmDeleteContent()">\n';
Else;
				'\t\t\t\t<input type="submit" name="Action" value="Add">\n';
				'\t\t\t\t<input type="hidden" name="DataType" value="Content">\n';
/If; ?>			</div>
			</td>
		</tr>
	</table>
</form>
<br>