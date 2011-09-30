<?Lassoscript
// Last modified: 5/20/08 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_ListservSubscribe }
	{Description=		Processes a listserv subscribe request, returns errors to be fed to ShowError3 }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				5/20/08 }
	{Usage=				LI_ListservSubscribe: -Address='midwest@climbingcentral.com'; }
	{ExpectedResults=	Returns $vError = 3004 if OK, $vError = 3003 if e-mail is invalid,
						or redirect if e-mail is invalid }
	{Dependencies=		Requires these variables to be defined:
						$svSMTP -- SMTP Server
						$svDeveloperEmail -- Developer's e-mail address, used in debugging
						$svLibsPath -- Library path from siteconfig
						$svListserv_Name -- Name of listserv list }
	{DevelNotes=		The "Sender" param of Email_Send should be the ID or name of the form to be tracked }
	{ChangeNotes=		5/20/08 
						Status: Untested }
/Tagdocs;
*/

Var:'svCTNamespace' = 'LI_';

If: !(Lasso_TagExists:'LI_ListservSubscribe');
	Define_Tag: 'ListservSubscribe',
		-Required='Address',
		-Namespace = $svCTNamespace;

		Local:'Result' = (string);
		Local:'Error' = (string);
		Local:'Body' = (string);
		Local:'URL' = (string);

		// Check valid e-mail
		// If format wrong, output error 3003 "E-mail Format Error"
		If: (Valid_Email:(#Address)) == false;

			#Error = '3003';
			#URL = ((Response_Filepath)'?Error='(#Error)'&UserEmail='(#Address));
			If: $svDebug == 'Y';
				#Result = 'ListservSubscribe: URL = <a href="'(#URL)'">'(#URL)'</a><br>\n';
			Else;
				Redirect_URL: #URL;
			/If;
		
		// Made it through all checks, send the e-mail
		Else;
	
			// If debug is on, send e-mail to developer only, otherwise send to System Admin
			If: $svDebug == 'Y';
		
			// NOTE: "Sender" param should be the ID of the form to be tracked
			// Make sure there is no space in the "Sender" param
			Email_Send:
				-Host=$svSMTP,
				-From=$Address,
				-To=$svDeveloperEmail,
				-Subject='TrackMyBugs Listserv Subscription Request DEBUG ON',
				-Username=$svAuthUsername,
				-Password=$svAuthPassword,
				-ReplyTo=$vPostmasterEmail,
				-Sender=(($svDomain)':LI_ListservSubscribe'),
				-Body=(Include:($svLibsPath)'email_listservdevel.txt'),
				-SimpleForm;

			Else;
		
				#Body = 'subscribe ' ($svListserv_Name) ' ' (#Address) ' ';

				// NOTE: "Sender" param should be the ID of the form to be tracked
				// Make sure there is no space in the "Sender" param
				Email_Send:
					-Host=$svSMTP,
					-From=#Address,
					-To=$svListserv_Email,
					-Subject='Subscribe',
					-Username=$svAuthUsername,
					-Password=$svAuthPassword,
					-ReplyTo=$vPostmasterEmail,
					-Sender=(($svDomain)':LI_ListservSubscribe'),
					-Body=(#Body),
					-SimpleForm;

			/If;
	
			// Everything OK, kick out error 3004 "Listserv Subscription Processed"
			#Error = '3004';
	
		/If;

		#Result = #Error;

		Return: Encode_Smart(#Result);

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_ListservSubscribe';

 /If;

?>
