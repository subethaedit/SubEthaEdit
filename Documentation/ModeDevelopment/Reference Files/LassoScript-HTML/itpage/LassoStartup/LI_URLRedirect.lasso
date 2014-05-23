<?Lassoscript
// Last modified 6/23/08 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_URLRedirect }
	{Description=		Creates an URL redirect if live or a Link if $svDebug = 'Y'. }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				 }
	{Usage=				LI_URLRedirect: -Page='signup.lasso';
						LI_URLRedirect: -Page='setup_editrecord.lasso',-ExParams=('DataType=Group&GroupID='($vGroup_ID)'&New=Y'),-UseError='Y',-Error='1003',-Option='something', -UseArgs='Y';
						LI_URLRedirect: -Page='setup_editrecord.lasso',-ExParams=('DataType=Browser&BrowserID='($vBrowser_ID)'&New=Y'),-UseError='Y',-Error='1003',-Option='something'; }
	{ExpectedResults=	If $svDebug = Y, a link displays to be clicked on.
						If $svDebug != Y, a redirect to the page with the error and option passed
						In both cases, Client_POSTArgs are passed. }
	{Dependencies=		Expects to have $svDebug defined.
						Looks for a possible definition of $vError and $vOption. }
	{DevelNotes=		Parameters:
						-Page -- The page that is to be redirected to
						-UseError -- Whether or not to pass the error and option in the URL. Set to "Y" to pass.
						-ExParams -- Used to pass extra page parameters
						-Error -- The error code used
						-Option -- The error code option used
						-UseArgs -- Append the Client_POSTArgs if requested. Set to "Y" to pass. }
	{ChangeNotes=		5/20/08
						First implementation }
/Tagdocs;
*/

Var:'svCTNamespace' = 'LI_';
If: !(Lasso_TagExists:'LI_URLRedirect');
	Define_Tag: 'URLRedirect',
		-Required = 'Page',
		-Optional = 'ExParams',
		-Optional = 'UseError',
		-Optional = 'Error',
		-Optional = 'Option',
		-Namespace = $svCTNamespace;
	
		Local:'Result' = string;
		Local:'URL' = string;
		Local:'ErrorOut' = string;
		Local:'OptionOut' = string;

		// Append the page and leading question mark
		#URL = ((#Page)'?');

		// Append on the Extra Params, if they exist
		If: (Local:'ExParams') != '';
			#URL += (#ExParams);
		/If;

		// Append the Error, but only if requested
		If: Local:('UseError') == 'Y';

			// Copy $vError to #Error, if #Error is not supplied to tag
			If: (Local:'Error') == '';
				#ErrorOut = (Var:'vError');
			Else;
				#ErrorOut = #Error;
			/If;
			// Copy $vOption to #Option, if #Option is not supplied to tag
			If: (Local:'Option') == '';
				#OptionOut = (Var:'vOption');
			Else;
				#OptionOut = #Option;
			/If;
			// Append the Error	
			If: #ErrorOut != '';
				#URL += ('&Error='(#ErrorOut));
			/If;
			// Append the Option
			If: #OptionOut != '';
				#URL += ('&Option='(#OptionOut));
			/If;
		/If;

		If: (Local:'UseArgs') == 'Y';
			// Append Client_PostArgs
			#URL += ('&'(Client_POSTArgs));
		/If;

		// Clean up the URL
		#URL->RemoveTrailing('&');
		#URL->(Replace: '?&', '?');

		If: $svDebug == 'Y';
			#Result = ('URLRedirect: <a href="'(#URL)'">'(#URL)'</a><br>\n');
		Else;
			Redirect_URL: #URL;
		/If;

		Return: Encode_Smart(#Result);

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_URLRedirect';

 /If;

?>
