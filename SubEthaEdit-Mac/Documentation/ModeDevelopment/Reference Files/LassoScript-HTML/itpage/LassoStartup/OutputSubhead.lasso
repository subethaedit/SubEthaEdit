<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputSubhead }
	{Description=		Outputs the already-built $vSubhead }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputSubhead }
	{ExpectedResults=	HTML for the Subhead }
	{Dependencies=		$vSubhead must be defined, otherwise a comment will be output }
	{DevelNotes=		$vSubhead is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputSubhead');
	Define_Tag:'OutputSubhead',
		-Description='Outputs the subhead (in $vSubhead)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vSubhead') != '';

			#Result += '<!-- OutputSubhead -->\n';
			#Result += '\t<div class="ContentPanelSubhead">'($vSubhead)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputSubhead: Subhead is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputSubhead';

/If;
?>
