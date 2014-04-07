<?Lassoscript
// Last modified 7/23/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Reset password page

// CHANGE NOTES
// 12/12/07
// Recoded for CMS v. 3.0
// 7/23/09
// Added Robot Check

Include:'/siteconfig.lasso';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Start the Admin session
Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

// Page head
Include:($svLibsPath)'page_header_admin.inc';

// Debugging
// Var:'svDebug' = 'Y';
?>
<table width="780">
	<tr>
		<td width="170">
			[Include:($svLibsPath)'navbar_main.inc']
		</td>
		<td>
			<div class="contentcontainerwhite">
[Include:'/admin/frm_reset.inc']
			</div>
		</td>
	</tr>
</table>
[Include:($svIncludesPath)'build_footer.inc']
</body>
</html>
