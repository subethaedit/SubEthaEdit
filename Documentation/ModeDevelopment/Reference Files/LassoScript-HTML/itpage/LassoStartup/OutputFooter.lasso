<?Lassoscript
// Last modified 9/12/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputFooter }
	{Description=		Outputs the already-built $FooterContent }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				3/18/08 }
	{Usage=				OutputFooter }
	{ExpectedResults=	Outputs the HTML in $FooterContent }
	{Dependencies=		$FooterContent must be defined, otherwise there will be no output }
	{DevelNotes=		$FooterContent is created in detail.inc.
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputFooter');
	Define_Tag:'OutputFooter',
		-Description='Outputs $FooterContent, which contains the left nav content for the LI CMS 3.0';

		Local('Result') = null;

		// Check if $FooterContent is defined
		If: (Var_Defined:'FooterContent');

			#Result += '<!-- OutputFooter -->\n';
			#Result += ($FooterContent);
			Return: (Encode_Smart:(#Result));

		Else;

			If: $svDebug == 'Y';
				'<strong>OutputFooter: </strong>$FooterContent is undefined<br>\n';
			/If;

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputFooter';

/If;
?>