<?Lassoscript
// Last modified 7/23/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Setup add functions

// $ACTION VALUES
// The action_param "Action" is passed by the form to indicate whether it is an add or edit
// Possible Actions:
// 		Action = "Update", means the request was an Edit
// 		Action = "Add New Root", means the request was an Add New Root node
// 		Action = "Update Name", means the request was an Update the Name of an existing node
// 		Action = "Delete This Node", means the request was to delete this node and all underlying nodes
// 		Action = "Add New Node", means the request was to add a node in the heirarchy
//				 at ONE LEVEL BELOW the displayed level

// CHANGE NOTES
// 11/23/07
// Recoded for CMS v. 3.0
// 11/29/07
// Moving login check to kill session before navbar is displayed
// 4/30/08
// Added LI_CMSatend at bottom of page to set focus to login box
// 5/20/08
// Recoded URL Links
// 1/15/09
// Added new datatype "Story"
// 6/19/09
// Adding new datatype "Gallery"
// 7/23/09
// Added Robot Check

Include:'/siteconfig.lasso';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Start the Admin session
Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

// Convert action_params
Var:'vDataType' = (Action_Param:'DataType');
Var:'vNew' = (Action_Param:'New');
Var:'vAction' = (Action_Param:'Action');

// Page head
Include:($svLibsPath)'page_header_admin.inc';

// Debugging
// Var:'svDebug' = 'Y';

If: $svDebug == 'Y';
	'<p class="debug"><strong>/admin/setup_addresponse</strong></p>\n';
	'39: vDataType = ' ($vDataType) '<br>\n';
	'39: vAction = ' ($vAction) '</p>\n';
/If;
?>
<table width="780">
	<tr>
		<td width="170">
			[Include:($svLibsPath)'navbar_main.inc']
		</td>
		<td>
			<div class="contentcontainerwhite">
<?Lassoscript
// Security check
// If privs wrong, display generate error 6004 "Access Restricted" and login form
If: (Var:'svUserPrivs_Priv') == 'Superadmin' || (Var:'svUserPrivs_Priv') == 'Admin';

	If: $vDataType == 'Node';
		Include:'/admin/node_modify.inc';
	Else: $vDataType == 'User';
		Include:'/admin/user_addresponse.inc';
	Else: $vDataType == 'Content';
		Include:'/admin/content_addresponse.inc';
	Else: $vDataType == 'Testimonial';
		Include:'/admin/testimonial_addresponse.inc';
	Else: $vDataType == 'story';
		Include:'/admin/story_addresponse.inc';
	Else: $vDataType == 'PortfolioGroup';
		Include:'/admin/portfoliogroup_addresponse.inc';
	Else: $vDataType == 'PortfolioEntry';
		Include:'/admin/portfolioentry_addresponse.inc';
	Else: $vDataType == 'GalleryGroup';
		Include:'/admin/gallerygroup_addresponse.inc';
	Else: $vDataType == 'GalleryEntry';
		Include:'/admin/galleryentry_addresponse.inc';
	Else: $vDataType == 'Sys';
		Include:'/admin/frm_sys.inc';

	// If wrong parameter passed, end the session, set error to 6004 "Access Restricted" redirect to login
	Else;

		Session_End: -Name=$svSessionAdminName;
		Var:'svUser_ID' = '';
		Var:'svUserLoginID' = ''; 
		Var:'svUserPrivs_Priv' = '';

		Var:'vError' = '6004';
		LI_URLRedirect: -Page='login.lasso',-UseError='Y',-Error=$vError;
	/If;

Else;

	// Set error to 6003 "Session Expired", redirect to login
	Var:'vError' = '6003';
	LI_URLRedirect: -Page='login.lasso',-UseError='Y',-Error=$vError;

/If;
?>
			</div>
		</td>
	</tr>
</table>
[Include:($svIncludesPath)'build_footer.inc']
[OutputFooter]
</body>
[LI_CMSatend]
</html>
