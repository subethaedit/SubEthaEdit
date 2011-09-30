<?Lassoscript
// Last modified 9/15/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputURL }
	{Description=		Outputs the already-built $vURL }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				9/15/09 }
	{Usage=				OutputURL }
	{ExpectedResults=	HTML for the URL }
	{Dependencies=		$vURL must be defined, otherwise there will be no output }
	{DevelNotes=		$vURL is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer
	{ChangeNotes=		9/15/09
						First implementation. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputURL');
	Define_Tag:'OutputURL',
		-Description='Outputs $vURL, if defined';

		Local('Result') = null;

		// Check if var is defined
		If: (Var_Defined:'vURL');

			#Result += '<!-- OutputURL -->\n';
			#Result += '<div class="ContentPanelURL"><a href="'($vURL)'" target="_blank" class="ContentPanel">'($vURL)'</a></div><br>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputURL: URL is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputURL';

/If;
?>