<?Lassoscript
// Last modified 3/7/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// This is the place where images, files and templates are managed
// DataTypes are self-named.

// CHANGE NOTES
// 10/12/07
// Recoded for CMS v. 3.0
// First implementation
// 4/30/08
// Changed logout_dialog URL
// 9/26/08
// Added $vImageType to accommodate Media
// 6/16/09
// Removed unused $Status
// 7/23/09
// Added Robot Check
// 3/7/10
// Added ImageType for Templates

Include:'/siteconfig.lasso';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Start the Admin session
Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

// Debugging
// Var:'svDebug' = 'Y';

// Page head
Include:($svLibsPath)'page_header_admin.inc';

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/library</strong></p>\n';
/If;

// Setting variables
Var:'ULpath' = '/site/files/';
Var:'Process' = (Action_Param:'Process');
Var:'vError' = (Action_Param:'Error');
Var:'vOption' = (Action_Param:'Option');
Var:'vDataType' = (Action_Param:'DataType');
// Set the default datatype if it is blank
If: $vDatatype == '';
	$vDatatype = 'Images';
/If;
// This contains the filename if coming from show_files.inc
Var:'vID' = (Action_Param:'ID');
// Used to pass the untouched filename to the error tag
Var:'vIDOriginal' = $vID;
// This contains the action. The only action is Delete, coming from show_files.inc
Var:'vAction' = (Action_Param:'Action');
// This is used to determine if it is an Image or Media
// Used mainly for deletion
Var:'ImageType' = (Action_Param:'ImageType');

// Check the DataType. If no parameter passed, assume it is Images.
If: $vDatatype == 'Files';
	Var:'ULpath' = $svFilesUploadPath;
	Var:'MainHead' = 'File Library';
Else: $vDataType == 'Images';
	Var:'ULpath' = $svImagesUploadPath;
	Var:'MainHead' = 'Image Library';
Else: $vDataType == 'Templates';
	Var:'ULpath' = $svTmpltsPath;
	Var:'MainHead' = 'Template Library';
Else;
	Var:'ULpath' = $svImagesUploadPath;
	Var:'MainHead' = 'Image Library';
/If;

?><table width="780">
	<tr>
		<td width="170">
			[Include:($svLibsPath)'navbar_main.inc']
		</td>
		<td>
<?Lassoscript
// Login check
If: (Var:'svUser_ID') != '';
	
	// If form not submit, do the popup menus to select area, crag and route
	If: $Process != '1';
		If: $svDebug == 'Y';
			'<p class="debug">41: Process = ' $Process '</p>\n';
		/If;

		// Include the Upload Files form. If no parameter passed, assume it is Images.
		If: $vDataType == 'Files';
			Include:'/admin/frm_uploadfiles.inc';
			Include:($svLibsPath)'show_files.inc';
		Else: $vDataType == 'images';
			Include:'/admin/frm_uploadimages.inc';
			Include:($svLibsPath)'show_images.inc';
		Else: $vDataType == 'Templates';
			Include:'/admin/frm_uploadtmplts.inc';
			Include:($svLibsPath)'show_tmplts.inc';
		Else;
			Include:'/admin/frm_uploadimages.inc';
			Include:($svLibsPath)'show_images.inc';
		/If;

	// Upload form submitted, now do the process
	Else;	
	
		// Process the Upload
		If: $vDataType == 'Files';
			Include:($svLibsPath)'process_fileupload.inc';
		Else: $vDataType == 'images';
			Include:($svLibsPath)'process_imageupload.inc';
		Else: $vDataType == 'Templates';
			Include:($svLibsPath)'process_tmpltupload.inc';
		Else;
			Include:($svLibsPath)'process_imageupload.inc';
		/If;

		// Show the files on the server. If no parameter passed, assume it is Images.
		If: $vDataType == 'Files';
			Include:'/admin/frm_uploadfiles.inc';
			Include:($svLibsPath)'show_files.inc';
		Else: $vDataType == 'images';
			Include:'/admin/frm_uploadimages.inc';
			Include:($svLibsPath)'show_images.inc';
		Else: $vDataType == 'Templates';
			Include:'/admin/frm_uploadtmplts.inc';
			Include:($svLibsPath)'show_tmplts.inc';
		Else;
			Include:'/admin/frm_uploadimages.inc';
			Include:($svLibsPath)'show_images.inc';
		/If;
	/If;

// Not logged in
Else;

	// If not logged in, redirect to the login page with error 6003 "Session Expired"
	Redirect_URL: 'http://' ($svDomain) '/admin/login.lasso?Error=6003';

/If;
?>		</td>
	</tr>
</table>
[Include:($svIncludesPath)'build_footer.inc']
[OutputFooter]
</body>
[LI_CMSatend]
</html>
