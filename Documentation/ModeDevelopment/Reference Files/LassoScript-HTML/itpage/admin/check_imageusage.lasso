<?Lassoscript
// Last modified 3/7/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// This page is used as part of itPage admin area to check usage of an image or template.
// It will look in all content, testimonial, etc. tables to see if it is used.

// CHANGE NOTES
// 7/23/09
// Added Robot Check
// 3/7/10
// Added checking for templates

Include:'/siteconfig.lasso';

// Debugging
// Var:'svDebug' = 'Y';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Start the Admin session
// Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

// Convert action_params
Var('TheImage' = Action_Param('ID'));
Var('vDatatype' = Action_Param('DataType'));

// This is used to control whether or not we have found any data for this image, and display an error
Var:'HaveImageData' = false;

?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
  <title>Check Image Usage</title>
</head>
<body>
<?Lassoscript
// CHECK CONTENT TABLE ---------------------------------------------------------
Var:'SQLQueryContent' = 'SELECT C.ID, C.HeirarchyID, C.Headline, C.Active,
node.HeirarchySlug
FROM ' $svSiteDatabase '.' $svContentTable '  AS C
LEFT JOIN ' $svSiteDatabase '.' $svHeirarchyTable '  AS node
	ON node.id = C.HeirarchyID
WHERE Image_Med = "' $TheImage '"
OR  Image_Large = "' $TheImage '"
OR  PageTemplate = "' $TheImage '"
ORDER BY Headline ASC';
Inline: $IV_Content, -Table=$svContentTable, -SQL=$SQLQueryContent;
	Debug;
		'SQLQueryContent = ' ($SQLQueryContent) '<br>\n';
		'Error = ' (Error_CurrentError) '<br>\n';
		'Found_Count = ' (Found_Count) '<br>\n';
	/Debug;

	If: Found_Count > 0;

		$HaveImageData = true;

?><h2 class="CheckContentType"><img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon"> Content Pages</h2>
<table width="380">
	<tr>
		<td width="270" class="CheckContentTableHead">Edit Link</td>
		<td width="30" class="CheckContentTableHead">Active</td>
	</tr>
<?Lassoscript
		Records;
			Var:'vID' = (Field:'ID');
			Var:'vActive' = (Field:'Active');
			Var:'ThisURLPath' = ((Field:'HeirarchySlug')'/'(String_LowerCase:(Encode_URLPath:(Field:'Headline'))));

?>	<tr <?Lassoscript If: (Loop_Count) %2 == 0; 'bgcolor="#F5F5F5"'; Else; 'bgcolor="#FFFFFF"'; /If; ?>>
		<td width="270" class="CheckContentText">
			<strong><a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y">[$ThisURLPath]</strong>
		</td>
		<td width="30" class="CheckContentText">[$vActive]</td>
	</tr>
[/Records]
</table>
[/If][/Inline]
<?Lassoscript
// CHECK GALLERY -----------------------------------------------------------------
Var:'SQLGalleryEntries' = 'SELECT * FROM ' $svSiteDatabase '.' $svGalleryTable ' 
WHERE Gallery_Thumb = "' $TheImage '" ORDER BY gallery_id';
Inline: $IV_Galleries, -Table=$svGalleryTable, -SQL=$SQLGalleryEntries;
	Debug;
		'SQLGalleryEntries = ' ($SQLGalleryEntries) '<br>\n';
		'Error = ' (Error_CurrentError) '<br>\n';
		'Found_Count = ' (Found_Count) '<br>\n';
	/Debug;

	If: Found_Count > 0;

		$HaveImageData = true;

?><br>
<h2 class="CheckContentType"><img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon"> Gallery Entries</h2>
<table width="380">
	<tr>
		<td width="130" class="CheckContentTableHead">Gallery Thumb</td>
		<td width="140" class="CheckContentTableHead">Edit Link</td>
		<td width="30" class="CheckContentTableHead">Active</td>
	</tr>
<?Lassoscript
	Records;
		Var:'vID' = (Field:'gallery_ID');
		Var:'vActive' = (Field:'Active');
		Var:'vGallery_Thumb' = (Field:'Gallery_Thumb');

?>	<tr <?Lassoscript If: (Loop_Count) %2 == 0; 'bgcolor="#F5F5F5"'; Else; 'bgcolor="#FFFFFF"'; /If; ?>>
		<td width="130" class="CheckContentText">
			<a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y"><img src="[$svImagesThmbPath][$TheImage]" alt="[$vGallery_Thumb]"></a>
		</td>
		<td width="140" class="CheckContentText">
			<strong><a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y">[$vID]</strong>
		</td>
		<td width="30" class="CheckContentText">[$vActive]</td>
	</tr>
[/Records]
</table>
[/If][/Inline]


<?Lassoscript
// CHECK STORIES -----------------------------------------------------------------
Var:'SQLStoryEntries' = 'SELECT * FROM ' $svSiteDatabase '.' $svStoriesTable ' 
WHERE Story_Thumb = "' $TheImage '" ORDER BY id';
Inline: $IV_Stories, -Table=$svStoriesTable, -SQL=$SQLStoryEntries;
	Debug;
		'SQLStoryEntries = ' ($SQLStoryEntries) '<br>\n';
		'Error = ' (Error_CurrentError) '<br>\n';
		'Found_Count = ' (Found_Count) '<br>\n';
	/Debug;

	If: Found_Count > 0;

		$HaveImageData = true;

?><br>
<h2 class="CheckContentType"><img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon"> Stories</h2>
<table width="380">
	<tr>
		<td width="130" class="CheckContentTableHead">Story Thumb</td>
		<td width="140" class="CheckContentTableHead">Edit Link</td>
		<td width="30" class="CheckContentTableHead">Active</td>
	</tr>
<?Lassoscript
	Records;
		Var:'vID' = (Field:'ID');
		Var:'vActive' = (Field:'Active');
		Var:'vStory_Thumb' = (Field:'Story_Thumb');

?>	<tr <?Lassoscript If: (Loop_Count) %2 == 0; 'bgcolor="#F5F5F5"'; Else; 'bgcolor="#FFFFFF"'; /If; ?>>
		<td width="130" class="CheckContentText">
			<a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y"><img src="[$svImagesThmbPath][$TheImage]" alt="[$vStory_Thumb]"></a>
		</td>
		<td width="140" class="CheckContentText">
			<strong><a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y">[$vID]</strong>
		</td>
		<td width="30" class="CheckContentText">[$vActive]</td>
	</tr>
[/Records]
</table>
[/If][/Inline]
<?Lassoscript
// CHECK TESTIMONIAL --------------------------------------------------------------
Var:'SQLTestimonial' = 'SELECT * FROM ' $svSiteDatabase '.' $svTestimonialsTable ' 
WHERE Testimonial_Thumb = "' $TheImage '" ORDER BY id';
Inline: $IV_Testimonials, -Table=$svTestimonialsTable, -SQL=$SQLTestimonial;
	Debug;
		'SQLTestimonial = ' ($SQLTestimonial) '<br>\n';
		'Error = ' (Error_CurrentError) '<br>\n';
		'Found_Count = ' (Found_Count) '<br>\n';
	/Debug;

	If: Found_Count > 0;

		$HaveImageData = true;

?><br>
<h2 class="CheckContentType"><img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon"> Testimonials</h2>
<table width="380">
	<tr>
		<td width="130" class="CheckContentTableHead">Testimonial Thumb</td>
		<td width="140" class="CheckContentTableHead">Edit Link</td>
		<td width="30" class="CheckContentTableHead">Active</td>
	</tr>
<?Lassoscript
	Records;
		Var:'vID' = (Field:'ID');
		Var:'vActive' = (Field:'Active');
		Var:'vTestimonial_Thumb' = (Field:'Testimonial_Thumb');

?>	<tr <?Lassoscript If: (Loop_Count) %2 == 0; 'bgcolor="#F5F5F5"'; Else; 'bgcolor="#FFFFFF"'; /If; ?>>
		<td width="130" class="CheckContentText">
			<a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y"><img src="[$svImagesThmbPath][$TheImage]" alt="[$vTestimonial_Thumb]"></a>
		</td>
		<td width="140" class="CheckContentText">
			<strong><a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y">[$vID]</strong>
		</td>
		<td width="30" class="CheckContentText">[$vActive]</td>
	</tr>
[/Records]
</table>
[/If][/Inline]
<?Lassoscript
// CHECK PORTFOLIO -----------------------------------------------------------------
Var:'SQLPortfolioEntries' = 'SELECT * FROM ' $svSiteDatabase '.' $svPortfolioTable ' 
WHERE Portfolio_Thumb = "' $TheImage '" ORDER BY Portfolio_id';
Inline: $IV_Portfolios, -Table=$svPortfolioTable, -SQL=$SQLPortfolioEntries;
	Debug;
		'SQLPortfolioEntries = ' ($SQLPortfolioEntries) '<br>\n';
		'Error = ' (Error_CurrentError) '<br>\n';
		'Found_Count = ' (Found_Count) '<br>\n';
	/Debug;

	If: Found_Count > 0;

		$HaveImageData = true;

?><br>
<h2 class="CheckContentType"><img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon"> Portfolio Entries</h2>
<table width="380">
	<tr>
		<td width="130" class="CheckContentTableHead">Portfolio Thumb</td>
		<td width="140" class="CheckContentTableHead">Edit Link</td>
		<td width="30" class="CheckContentTableHead">Active</td>
	</tr>
<?Lassoscript
	Records;
		Var:'vID' = (Field:'Portfolio_ID');
		Var:'vActive' = (Field:'Active');
		Var:'vPortfolio_Thumb' = (Field:'Portfolio_Thumb');

?>	<tr <?Lassoscript If: (Loop_Count) %2 == 0; 'bgcolor="#F5F5F5"'; Else; 'bgcolor="#FFFFFF"'; /If; ?>>
		<td width="130" class="CheckContentText">
			<a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y"><img src="[$svImagesThmbPath][$TheImage]" alt="[$vPortfolio_Thumb]"></a>
		</td>
		<td width="140" class="CheckContentText">
			<strong><a href="/admin/setup_editrecord.lasso?ID=[Var:'vID']&DataType=[Var:'vDatatype']&New=Y">[$vID]</strong>
		</td>
		<td width="30" class="CheckContentText">[$vActive]</td>
	</tr>
[/Records]
</table>
<?Lassoscript

	/If;

/Inline;

// CHECK SYS TABLE  ---------------------------------------------------------
Var:'SQLQueryContent' = 'SELECT sys_DefaultTemplate
FROM ' $svSiteDatabase '.' $svSysTable ' WHERE sys_DefaultTemplate = "' $TheImage '"';
Inline: $IV_Sys, -Table=$svSysTable, -SQL=$SQLQueryContent;
	Debug;
		'SQLQueryContent = ' ($SQLQueryContent) '<br>\n';
		'Error = ' (Error_CurrentError) '<br>\n';
		'Found_Count = ' (Found_Count) '<br>\n';
	/Debug;

	If: Found_Count > 0;

		$HaveImageData = true;

?><h2 class="CheckContentType"><img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon"> System Default</h2>
<table width="380">
	<tr>
		<td width="270" class="CheckContentTableHead">Edit Link</td>
		<td width="30" class="CheckContentTableHead"></td>
	</tr>
<?Lassoscript
			Var:'ThisURLPath' = '/admin/setup_search.lasso?DataType=Sys';

?>	<tr>
		<td colspan="2" class="CheckContentText">
			<strong><a href="[$ThisURLPath]">[$ThisURLPath]</strong>
		</td>
	</tr>
</table>
[/If][/Inline]
<?Lassoscript
// Display error if no images are found
If: $HaveImageData == false;
	// Set error variable depending upon DataType
	If: $vDatatype == 'Images';
		Var:'vError' = '7024';
	Else: $vDatatype == 'Templates';
		Var:'vError' = '7025';
	Else;
		Var:'vError' = '7024';
	/If;
	// Standard Error Table
	LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
/If;

// Use this to delete/modify data records
// SHOULD be called from Library page
// Include:($svLibsPath)'library_moddata.inc';

?></body>
</html>
