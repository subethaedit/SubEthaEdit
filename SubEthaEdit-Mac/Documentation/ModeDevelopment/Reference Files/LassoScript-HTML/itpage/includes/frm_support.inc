<?Lassoscript
// Last modified: 8/21/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Support form

// CHANGE NOTES
// 11/1/07
// Recoded for Clean URLs
// 3/7/07
// Added domain to e-mail subject

// Debugging
// Var:'svDebug' = 'Y';

// Convert action_params
Var:'vError'=(Action_Param:'Error');
Var:'vOption'=(Action_Param:'Option');
Var:'vProcess'=(Action_Param:'Process');
Var:'vUserName'=  (Action_Param:'UserName');
Var:'vUserEmail'=  (Action_Param:'UserEmail');
Var:'vQuestion'=(Action_Param:'Question');

//  Process the form if it is submit.
If: $vProcess == 'Y';

	// If Action_Param missing, kick out 1003 Required Information error
	If: (Var:'vUserName') == '' || (Var:'vUserEmail') == '' || (Var:'vQuestion') == '';
		Var:'vError' = '1003';
	
		If: (Var:'vUserEmail') == '';
			$vOption += 'Your Name, ';
		/If;
		If: (Var:'vUserEmail') == '';
			$vOption += 'Your E-mail, ';
		/If;
		If: (Var:'vQuestion') == '';
			$vOption += 'Question';
		/If;
		$vOption->(RemoveTrailing:', ');
	
		Var:'URL' = '/support.lasso?Error='($vError)'&Option='($vOption)'&UserName='($vUserName)'&UserEmail='($vUserEmail)'&Question='($vQuestion);
		If: $svDebug == 'Y';
			'35: URL = <a href="'($URL)'">'($URL)'</a><br>\n';
		Else;
			Redirect_URL: $URL;
		/If;
	
	/If;

	// Made it through form checks, now check valid e-mail
	If: (Valid_Email:($vUserEmail)) == false;
	
		Var:'vError' = '3003';
	
		Var:'URL' = '/support.lasso?Error='($vError)'&UserName='($vUserName)'&UserEmail='($vUserEmail)'&Question='($vQuestion);
		If: $svDebug == 'Y';
			'48: URL = <a href="'($URL)'">'($URL)'</a><br>\n';
		Else;
			Redirect_URL: $URL;
		/If;
	
	// Made it through all checks, send the e-mail
	Else;

		Var:'vFrom'=(($vUserName) ' <'($vUserEmail) '>');

		// If debug is on, send e-mail to developer only, otherwise send to System Admin
		If: $svDebug == 'Y';
	
			// 11/8/07 Webmail.us Secure SMTP Settings
			// NOTE: "Sender" param should be the ID of the form to be tracked
			// Make sure there is no space in the "Sender" param
			Email_Send:
				-Host=$svSMTP,
				-From=$vFrom,
				-To=$svDeveloperEmail,
				-Subject='CMS Support Request [' ($svDomain) '] DEBUG ON',
				-Username=$svAuthUsername,
				-Password=$svAuthPassword,
				-ReplyTo=$vFrom,
				-Sender=(($svDomain)':frm_support'),
				-Body=(Include:($svLibsPath)'email_support.txt'),
				-SimpleForm;


		Else;

			// 11/8/07 Webmail.us Secure SMTP Settings
			// NOTE: "Sender" param should be the ID of the form to be tracked
			// Make sure there is no space in the "Sender" param
			Email_Send:
				-Host=$svSMTP,
				-From=$vFrom,
				-To=$svAdminEmail,
				-Subject='CMS Support Request [' ($svDomain) ']',
				-Username=$svAuthUsername,
				-Password=$svAuthPassword,
				-ReplyTo=$vFrom,
				-Sender=(($svDomain)':frm_support'),
				-Body=(Include:($svLibsPath)'email_support.txt'),
				-SimpleForm;

		/If;

		// Everything OK, kick out error 3004 "Support Request Sent"
		Var:'vError' = '3004';

		// Standard Error Table
		If: (Var:'vError') != '';
			LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
		/If;

	/If;

Else;
?>
<div class="contentcontainerwhite600">
<form action="/support.lasso" method="post">
	<table width="520">
	<tr>
		<td colspan="2">
			<h2>Support Request</h2>
			<div align="left">
[If: $vError == '']
				Please use the form below to e-mail support. As a spam prevention measure, you will not receive a copy of the message.
<?Lassoscript
Else;
	// Standard Error Table
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;
?>
			</div>
		</td>
	</tr>
	<tr>
		<td colspan="2"><strong>NOTE: </strong>[$svInputRequired] indicates required information.</td>
	</tr>
	<tr> 
		<td width="200" bgcolor="#666666" valign="middle">
			<div align="right">
				<span class="tablehead_10_white">Your Name[$svInputRequired]</span>
			</div>
		</td>
		<td width="390" bgcolor="#CCCCCC">
			<input type="text" name="UserName" value="[Var:'vUserName']" size="24" maxlength="128">
		</td>
	</tr>
	<tr> 
		<td width="200" bgcolor="#666666" valign="middle">
			<div align="right">
				<span class="tablehead_10_white">Your E-Mail Address[$svInputRequired]</span>
			</div>
		</td>
		<td width="390" bgcolor="#CCCCCC">
			<input type="text" name="UserEmail" value="[Var:'vUserEmail']" size="36" maxlength="128">
		</td>
	</tr>
	<tr>
		<td width="200" bgcolor="#666666" valign="middle">
			<div align="right">
				<span class="tablehead_10_white">Question[$svInputRequired]</span>
			</div>
		</td>
		<td width="390" bgcolor="#CCCCCC">
			<textarea name="Question" cols="45" rows="4">[Var:'vQuestion']</textarea>
		</td>
	</tr>
	<tr>
		<td colspan="2" bgcolor="#666666"> 
			<div align="center">
				<Input Type="hidden" Name="process" Value="Y">
				<Input Type="submit" Name="-Nothing" Value="Submit">
			</div>
		</td>
	</tr>
</table>
</form>
</div>
[/If]