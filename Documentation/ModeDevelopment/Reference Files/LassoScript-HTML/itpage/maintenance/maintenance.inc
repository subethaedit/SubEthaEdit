<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// This page is the include file for the maintenance functions

// CHANGE NOTES
// 8/15/06
// Added workgroup functionality
// 8/31/09
// Added Clear Cache
// Changed user privs necessary to access this page to Superadmin level

// Debugging
// Var:'svDebug' = 'Y';

// Login check - Superadmin ONLY
If: (Var:'svUserPrivs_Priv') == 'Superadmin';
?>
<table width="425">
	<tr>
		<td colspan="2" valign="top">
			<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;Maintenance</h2>
			<div align="left"><font color="red"><strong>CAUTION:</strong></font> These maintenance functions should be used only by experienced personnel or under the direction of Tech Support.</div>
		</td>
	</tr>
	<tr height="10">
		<td colspan="2">&nbsp;</td>
	</tr>
	<tr bgcolor="#C9C9C9" height="10">
		<td colspan="2">&nbsp;</td>
	</tr>
	<tr height="10">
		<td colspan="2">&nbsp;</td>
	</tr>
	<tr>
		<td width="120" valign="top" align="left"><a href="/maintenance/maint_viewlogs.lasso">View Logs</a></td>
		<td width="255" valign="top" align="left">View individual logfiles in browser</td>
	</tr>
	<tr>
		<td colspan="2">&nbsp;</td>
	</tr>
	<tr>
		<td width="120" valign="top" align="left"><a href="/maintenance/maint_cleanlogs.lasso" onclick="return confirmDeleteFiles()">Delete Logs</a></td>
		<td width="255" valign="top" align="left"><img src="/site/images/caution_small.gif" width="22" height="22" alt="caution" align="middle">&nbsp;This will DELETE all System Logs. There is no recovery.</td>
	</tr>
	<tr height="10">
		<td colspan="2">&nbsp;</td>
	</tr>
	<tr>
		<td width="120" valign="top" align="left"><a href="/maintenance/clearcache.lasso" target="_blank">Clear DNS Cache</a></td>
		<td width="255" valign="top" align="left">Clears the DNS server's DNS cache.</td>
	</tr>
	<tr height="10">
		<td colspan="2">&nbsp;</td>
	</tr>
	<tr bgcolor="#C9C9C9" height="10">
		<td colspan="2">&nbsp;</td>
	</tr>
</table>
<?Lassoscript
Else;
	// Dump out error 6004 "Access Restricted"
	Var:'vError' = '6004';
	// Standard Error Table
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;
?>