<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputDateModified }
	{Description=		Outputs the already-built $vDateModified }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputDateModified }
	{ExpectedResults=	HTML for the DateModified }
	{Dependencies=		$vDateModified must be defined, otherwise a comment will be output }
	{DevelNotes=		$vDateModified is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputDateModified');
	Define_Tag:'OutputDateModified',
		-Description='Outputs the DateModified (in $vDateModified)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vDateModified') != '';

			#Result += '<!-- OutputDateModified -->\n';
			#Result += '<div class="ContentPanelDate">'($vDateModified)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputDateModified: DateModified is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputDateModified';

/If;
?>