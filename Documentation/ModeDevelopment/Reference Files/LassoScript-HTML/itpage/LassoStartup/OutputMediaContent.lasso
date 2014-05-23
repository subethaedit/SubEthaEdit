<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputMediaContent }
	{Description=		Outputs the already-built $MediaContent }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				3/18/08 }
	{Usage=				OutputMediaContent }
	{ExpectedResults=	Outputs the HTML in $MediaContent }
	{Dependencies=		$MediaContent must be defined, otherwise there will be no output }
	{DevelNotes=		$MediaContent is created in detail.inc.
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputMediaContent');
	Define_Tag:'OutputMediaContent',
		-Description='Outputs $MediaContent',
		-Optional='container',
		-Type='string';

		Local('Result') = null;
		Local('Cont') = null;

		// Check if $MediaContent is defined
		If: (Var_Defined:'MediaContent');

			#Result += '<!-- OutputMediaContent -->\n';
			Local_Defined('initialvalue') ? #Result += '\t<div class="ContentPanel">\n';
			#Result += $MediaContent;
			Local_Defined('initialvalue') ? #Result += '\t</div>\n';

		Else;

			If: $svDebug == 'Y';
				#Result += '<strong>OutputMediaContent: </strong>$MediaContent is undefined<br>\n';
			/If;

		/If;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputMediaContent';

/If;
?>
