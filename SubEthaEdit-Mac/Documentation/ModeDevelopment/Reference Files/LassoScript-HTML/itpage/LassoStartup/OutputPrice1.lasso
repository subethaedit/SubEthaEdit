<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputPrice1 }
	{Description=		Outputs the already-built $vPrice_1 }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputPrice1 }
	{ExpectedResults=	HTML for Price_1 }
	{Dependencies=		$vPrice_1 must be defined, otherwise a comment will be output }
	{DevelNotes=		$vPrice_1 is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputPrice1');
	Define_Tag:'OutputPrice1',
		-Description='Outputs the Price1 (in $vPrice_1)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vPrice_1') != '';

			#Result += '<!-- OutputPrice1 -->\n';
			#Result += '<div class="Price1">'($vPrice_1)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputPrice1: Price1 is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputPrice1';

/If;
?>
