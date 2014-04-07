<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputMainContent }
	{Description=		Outputs the already-built $FinalContent }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				3/18/08 }
	{Usage=				OutputMainContent }
	{ExpectedResults=	Outputs the HTML in $FinalContent }
	{Dependencies=		$FinalContent must be defined, otherwise there will be no output }
	{DevelNotes=		$FinalContent is created in detail.inc.
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputMainContent');
	Define_Tag:'OutputMainContent',
		-Description='Outputs $FinalContent',
		-Optional='container',
		-Type='string';

		Local('Result') = null;
		Local('Cont') = null;

		// Check if $FinalContent is defined
		If: (Var_Defined:'FinalContent');

			#Result += '<!-- OutputMainContent -->\n';
			Local_Defined('initialvalue') ? #Result += '\t<div class="ContentPanel">\n';
			#Result += $FinalContent;
			Local_Defined('initialvalue') ? #Result += '\t</div>\n';

		Else;

			If: $svDebug == 'Y';
				#Result += '<strong>OutputMainContent: </strong>$FinalContent is undefined<br>\n';
			/If;

		/If;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputMainContent';

/If;
?>
