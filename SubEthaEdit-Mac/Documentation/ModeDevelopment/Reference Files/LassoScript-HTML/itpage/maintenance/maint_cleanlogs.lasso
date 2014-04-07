<?Lassoscript
// Last modified 5/12/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Used to access the maintenance area

// CHANGE NOTES
// 10/12/07
// Recoded for CMS v. 3.0

Include:'/siteconfig.lasso';

// Start the session
Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

// Page head
Include:($svLibsPath)'page_header_admin.inc';

// Defining the DataType
Var:'vDataType' = 'Maintenance';

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
<?Lassoscript
// Login check
If: (Var:'svUser_ID') != '';

	'<h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;Cleaning Logs</h2>\n';
	
	Log_Critical('MAINTENANCE -  CLEAN LOGS');
	
	Inline: -Nothing, -Username=$svSiteUsername, -Password=$svSitePassword;
	
	'<p><strong>Directory:</strong> /logs/</p>\n';
	
		Local('KillLogs') = ('rm ' ($svWebserverRoot) '/logs/*.*');
		Local('KillLogsResult') = PassThru(#KillLogs, -username=$svSiteUsername, -password=$svSitePassword);
		
		If: $svDebug == 'Y';
			'KillLogs: ' #KillLogs '<br>\n';
			'KillLogsResult: ' #KillLogsResult '<br>\n';
		/If;
		// Log_Critical:'EvalPass263: KillLogs: ' #KillLogs;
		// Log_Critical:'EvalPass263: KillLogsResult: ' #KillLogsResult;
		
		'<br>\n';
		'++++++++++++++++++<br>\n';
	'<strong>END MAINTENANCE </strong> Clean Logs ' (Date) '<br>\n';
		'++++++++++++++++++<br>\n';
	
	/Inline;

Else;

// Dump out error 6004 "Access Restricted"
	Var:'vError' = '6004';

	// Standard Error Table
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');

/If;
?>
			</div>
		</td>
	</tr>
</table>
[Include:($svIncludesPath)'build_footer.inc']
</body>
</html>
