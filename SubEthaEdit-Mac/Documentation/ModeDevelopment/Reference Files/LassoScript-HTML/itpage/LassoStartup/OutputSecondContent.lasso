<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputSecondContent }
	{Description=		Outputs the already-built $SecondContent }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				3/18/08 }
	{Usage=				OutputSecondContent (outputs without the container HTML)
	 		 			OutputSecondContent, -container='Y' (outputs with the container HTML) }
	{ExpectedResults=	Outputs the HTML in $SecondContent }
	{Dependencies=		$SecondContent must be defined, otherwise there will be no output }
	{DevelNotes=		$SecondContent is created in detail.inc.
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputSecondContent');
	Define_Tag:'OutputSecondContent',
		-Description='Outputs $SecondContent',
		-Optional='container',
		-Type='string';

		Local('Result') = null;

		// Check if $SecondContent is defined
		If: (Var_Defined:'SecondContent');

			#Result += '<!-- OutputSecondContent -->\n';
			Local_Defined('initialvalue') ? #Result += '\t<div class="SecondContentPanel">\n';
			#Result += $SecondContent;
			Local_Defined('initialvalue') ? #Result += '\t</div>\n';

		Else;

			If: $svDebug == 'Y';
				#Result += '<strong>OutputSecondContent: </strong>$SecondContent is undefined<br>\n';
			/If;

		/If;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputSecondContent';

/If;
?>