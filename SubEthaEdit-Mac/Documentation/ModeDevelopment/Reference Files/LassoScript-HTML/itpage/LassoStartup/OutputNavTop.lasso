<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputNavTop }
	{Description=		Outputs the already-built $FinalTopNavContent }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				3/18/08 }
	{Usage=				OutputNavTop }
	{ExpectedResults=	Outputs the HTML in $FinalTopNavContent }
	{Dependencies=		$FinalTopNavContent must be defined, otherwise there will be no output }
	{DevelNotes=		$FinalTopNavContent is created in detail.inc.
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputNavTop');
	Define_Tag:'OutputNavTop',
		-Description='Outputs $FinalTopNavContent, which contains the left nav content for the LI CMS 3.0';

		Local('Result') = null;

		// Check if $FinalTopNavContent is defined
		If: (Var_Defined:'FinalTopNavContent');

			$FinalTopNavContent += '<!-- OutputNavTop -->\n';
			Return: (Encode_Smart:($FinalTopNavContent));

		Else;

			If: $svDebug == 'Y';
				'<strong>OutputNavTop: </strong>$FinalTopNavContent is undefined<br>\n';
			/If;

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputNavTop';

/If;
?>