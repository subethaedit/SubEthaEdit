<?Lassoscript
// Last modified 8/28/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Left Navbar

// CHANGE NOTES
// 10/12/07
// Recoded for CMS v. 3.0
// NOT including Groups functionality
// 12/20/07
// Changed Login/Logout links
// 4/25/08
// Fixed those damn mistmatched <div>s!
// 5/14/08
// Ported changes from LBT, mainly addition of icons, and moved one /If
// 1/15/09
// Added new datatype "Story"
// 6/19/09
// Adding new datatype "Gallery"
// 8/17/09
// Added documentation link
// 3/7/10
// Adding new datatype "Templates"
// 8/28/10
// Changed link for login and logout

// This hack saves the debug status, then we turn it off until restored
Var:'DebugStatus' = $svDebug;
Var:'svDebug' = 'N';

?>
<!-- START navbar_main -->
<div class="leftnavcontainer">
	<div id="niftysidebar" class="niftysidebar">
		<h2 onclick="ToggleDisplay('user')">User</h2>
		<div id="user">
			<p class="ltblue">
<?Lassoscript
	// Display logged-in user info
	If: (Var:'svUser_ID') != '' && (Var:'svUserPrivs_Priv') != '';
		'\t\t\t\t' (Var:'svAdmin_FName') '&nbsp;' (Var:'svAdmin_LName') '<br>\n';
		'\t\t\t\t' (Var:'svUserPrivs_Priv') '<br>\n';
	Else;
		'\t\t\t\tPrivs: Visitor<br>\n';
		// Log In link
		'\t\t\t\t<img src="'($svFileIconsPath)'lock_open.png" width="16" height="16" alt="Icon">\n';
		'\t\t\t\t<a href="login" class="menuBoxContentLink"><strong>Log In</strong></a>\n';
	/If;
?>
			</p><!-- 32 -->
<?Lassoscript
// Don't display if they are not logged in
If: (Var:'svUser_ID') != '';

	// Display links if Admin or Superadmin logged in
	If: (Var:'svUserPrivs_Priv') == 'Admin' || (Var:'svUserPrivs_Priv') == 'Superadmin';

// Display "My Profile" 
?>
			<p class="ghost"><!-- 37 -->
<?Lassoscript
			// Defining the User Photo Name
			Var:'vUserPhotoName' = (($svUserPhotos)($svUser_ID)('_icon.jpg'));
			// Check to see if user photo exists
			Var:'UserPhotoExists' = (File_Exists:$vUserPhotoName);
			If: $UserPhotoExists == true;
				'<img src="'($vUserPhotoName)'" alt="User Photo">';
			Else;
				'<img src="'($svFileIconsPath)'user_green.png" width="16" height="16" align="bottom" alt="Icon">';
			/If;
?>			<a href="http://[$svDomain]/admin/setup_editrecord.lasso?Datatype=User&ID=[$svUser_ID]&New=Y" class="menuBoxContentLink"><strong>My Profile</strong></a>
			</p><!-- 46 -->
<?Lassoscript
// Log Out link
?>
			<p class="ghost"><!-- 46 -->
			<img src="[$svFileIconsPath]lock_delete.png" width="16" height="16" align="bottom" alt="Icon">
			<a href="/logout" class="menuBoxContentLink"><strong>Log Out</strong></a>
			</p><!-- 47 -->
[/If]
		</div><!-- 47 -->
<?Lassoscript
If: (Var:'svUserPrivs_Priv') == 'Admin' || (Var:'svUserPrivs_Priv') == 'Superadmin'; ?>
		<h2 onclick="ToggleDisplay('admin')">Admin</h2>
		<div id="admin">
<?Lassoscript
// Manage Heirarchy
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]sitemap_color.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/manage_heirarchy.lasso" class="menuBoxContentLink" target="_blank"><strong>Manage Heirarchy</strong></a></p>
<?Lassoscript
// Manage Content
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]page.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=Content" class="menuBoxContentLink"><strong>Content</strong></a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_add.lasso?DataType=Content&New=Y" class="menuBoxContentLink">Add</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=Content" class="menuBoxContentLink">Search</a>
			</p>
<?Lassoscript
// Manage Testimonials
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=Testimonial" class="menuBoxContentLink"><strong>Testimonials</strong></a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_add.lasso?DataType=Testimonial&New=Y" class="menuBoxContentLink">Add</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=Testimonial" class="menuBoxContentLink">Search</a>
			</p>
<?Lassoscript
// Manage Stories
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=Story" class="menuBoxContentLink"><strong>Stories</strong></a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_add.lasso?DataType=Story&New=Y" class="menuBoxContentLink">Add</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=Story" class="menuBoxContentLink">Search</a>
			</p>
<?Lassoscript
// Manage Portfolio Groups
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=PortfolioGroup" class="menuBoxContentLink"><strong>Portfolio Groups</strong></a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_add.lasso?DataType=PortfolioGroup&New=Y" class="menuBoxContentLink">Add</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=PortfolioGroup" class="menuBoxContentLink">Search</a>
			</p>
<?Lassoscript
// Manage Portfolio Entries
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=PortfolioEntry" class="menuBoxContentLink"><strong>Portfolio Entries</strong></a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_add.lasso?DataType=PortfolioEntry&New=Y" class="menuBoxContentLink">Add</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=PortfolioEntry" class="menuBoxContentLink">Search</a>
			</p>
<?Lassoscript
// Manage Gallery Groups
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=GalleryGroup" class="menuBoxContentLink"><strong>Gallery Groups</strong></a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_add.lasso?DataType=GalleryGroup&New=Y" class="menuBoxContentLink">Add</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=GalleryGroup" class="menuBoxContentLink">Search</a>
			</p>
<?Lassoscript
// Manage Gallery Entries
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]application_view_list.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=GalleryEntry" class="menuBoxContentLink"><strong>Gallery Entries</strong></a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_add.lasso?DataType=GalleryEntry&New=Y" class="menuBoxContentLink">Add</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=GalleryEntry" class="menuBoxContentLink">Search</a>
			</p>
<?Lassoscript
// Manage Users
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]user.png" width="16" height="16" align="bottom" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=User" class="menuBoxContentLink"><strong>Users</strong></a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_add.lasso?DataType=User&New=Y" class="menuBoxContentLink">Add</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=User" class="menuBoxContentLink">Search</a><br>
			&nbsp;&nbsp;<a href="http://[$svDomain]/admin/setup_delete.lasso?DataType=User" class="menuBoxContentLink">Delete</a>
			</p>
<?Lassoscript
// Libraries
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]photos.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/library.lasso?DataType=Images" class="menuBoxContentLink"><strong>Image Library</strong></a>
			</p>
			<p class="ghost">
			<img src="[$svFileIconsPath]page_white_copy.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/library.lasso?DataType=Files" class="menuBoxContentLink"><strong>File Library</strong></a>
			</p>
			<p class="ghost">
			<img src="[$svFileIconsPath]page_copy.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/library.lasso?DataType=Templates" class="menuBoxContentLink"><strong>Templates Library</strong></a>
			</p>
<?Lassoscript
/If;

// Maintenance - Superadmin ONLY
If: (Var:'svUserPrivs_Priv') == 'Superadmin';
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]wrench.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/maintenance/maintenance.lasso?DataType=Maintenance" class="menuBoxContentLink"><strong>Maintenance</strong></a><br>
			<a href="http://[$svDomain]/maintenance/maint_viewlogs.lasso?DataType=Maintenance" class="menuBoxContentLink" style="margin-left:20px;">View Logs</a><br>
			<a href="http://[$svDomain]/maintenance/maint_cleanlogs.lasso?DataType=Maintenance" class="menuBoxContentLink" style="margin-left:20px;">Delete Logs</a><br>
			<a href="http://[$svDomain]/maintenance/clearcache.lasso?DataType=Maintenance" class="menuBoxContentLink" style="margin-left:20px;">Clear Cache</a><br>
			</p>
<?Lassoscript
// System Settings - Superadmin ONLY
?>
			<p class="ghost">
			<img src="[$svFileIconsPath]cog.png" width="16" height="16" alt="Icon">
			<a href="http://[$svDomain]/admin/setup_search.lasso?DataType=Sys" class="menuBoxContentLink"><strong>System Settings</strong></a>
			</p>
[/If]
		</div><!-- 84 -->
	</div><!-- 84 -->
[/If]

	</div><!-- 85 -->

[If: (Var:'svUser_ID') == '']
	</div><!-- 86 -->
[/If]
<!-- END Admin -->

[If: (Var:'svUser_ID') == '']
</div><!-- 91 -->
[/If]

<div class="leftnavcontainer">
	<div id="niftysidebar2" class="niftysidebar">
		<h2 onclick="ToggleDisplay('links')">Links</h2>
		<div id="links">
			<p class="ghost">
<?Lassoscript
// Documentation Form
	'\t\t\t\t<img src="'($svFileIconsPath)'help-browser.png" width="16" height="16" alt="Icon">\n';
	'<a href="http://www.itpage.ws/wiki/" class="menuBoxContentLink"><strong>Documentation</strong></a><br>\n';
// Support Form
	'\t\t\t\t<img src="'($svFileIconsPath)'help-browser.png" width="16" height="16" alt="Icon">\n';
	'<a href="http://'($svDomain)'/support.lasso" class="menuBoxContentLink"><strong>Support Request</strong></a><br>\n';

// Get Folders from the /help folder
LI_ShowDirectory: -Directory='/help/', -AsLinks=true;

?>
			</p><!-- 108 -->
		</div><!-- 108 -->
	</div><!-- 108 NIftySidebar -->
</div><!-- 108 leftnavcontainer -->
<!-- END navbar_main -->
[Var:'svDebug' = Var:'DebugStatus']