<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputHeadline }
	{Description=		Outputs the already-built $vHeadline }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				6/26/09 }
	{Usage=				OutputHeadline }
	{ExpectedResults=	HTML for the headline }
	{Dependencies=		$vHeadline must be defined, otherwise there will be no output }
	{DevelNotes=		$vContentHeadline is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer
						ODDITY: Use this tag when $vHeadline is not reliable, such as when there is a dropdown on the page }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputHeadline');
	Define_Tag:'OutputHeadline',
		-Description='Outputs the main page headline (in $vHeadline)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var_Defined:'vContentHeadline');

			#Result += '<!-- OutputHeadline -->\n';
			#Result += '<div class="ContentPanelHead">'($vContentHeadline)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputHeadline: Headline is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputHeadline';

/If;
?>