<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputPrice2 }
	{Description=		Outputs the already-built $vPrice_2 }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputPrice2 }
	{ExpectedResults=	HTML for Price_2 }
	{Dependencies=		$vPrice_2 must be defined, otherwise a comment will be output }
	{DevelNotes=		$vPrice_2 is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputPrice2');
	Define_Tag:'OutputPrice2',
		-Description='Outputs the Price2 (in $vPrice_2)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vPrice_2') != '';

			#Result += '<!-- OutputPrice2 -->\n';
			#Result += '<div class="Price2">'($vPrice_2)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputPrice2: Price2 is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputPrice2';

/If;
?>