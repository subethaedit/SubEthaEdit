<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputAuthor }
	{Description=		Outputs the already-built $vAuthor }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputAuthor }
	{ExpectedResults=	HTML for the Author }
	{Dependencies=		$vAuthor must be defined, otherwise a comment will be output }
	{DevelNotes=		$vAuthor is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputAuthor');
	Define_Tag:'OutputAuthor',
		-Description='Outputs the author (in $vAuthor)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vAuthor') != '';

			#Result += '<!-- OutputAuthor -->\n';
			#Result += '<div class="ContentPanelAuthor">'($vAuthor)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputAuthor: Author is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputAuthor';

/If;
?>