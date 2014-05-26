<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputNavLeft }
	{Description=		Outputs the already-built $FinalLeftNavContent }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				3/18/08 }
	{Usage=				OutputNavLeft }
	{ExpectedResults=	Outputs the HTML in $FinalLeftNavContent }
	{Dependencies=		$FinalLeftNavContent must be defined, otherwise there will be no output }
	{DevelNotes=		$FinalLeftNavContent is created in detail.inc.
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputNavLeft');
	Define_Tag:'OutputNavLeft',
		-Description='Outputs $FinalLeftNavContent, which contains the left nav content for the LI CMS 3.0';

		Local('Result') = null;

		// Check if $FinalLeftNavContent is defined
		If: (Var_Defined:'FinalLeftNavContent');

			$FinalLeftNavContent += '<!-- OutputNavLeft -->\n';
			Return: (Encode_Smart:($FinalLeftNavContent));

		Else;

			If: $svDebug == 'Y';
				'<strong>OutputNavLeft: </strong>$FinalLeftNavContent is undefined<br>\n';
			/If;

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputNavLeft';

/If;
?>