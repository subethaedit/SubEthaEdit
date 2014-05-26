<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputText1 }
	{Description=		Outputs the already-built $vText_1 }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputText1 }
	{ExpectedResults=	HTML for Text_1 }
	{Dependencies=		$vText_1 must be defined, otherwise a comment will be output }
	{DevelNotes=		$vText_1 is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputText1');
	Define_Tag:'OutputText1',
		-Description='Outputs the Text1 (in $vText_1)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vText_1') != '';

			#Result += '<!-- OutputText1 -->\n';
			#Result += '<div class="ContentPanel">'($vText_1)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputText1: Text1 is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputText1';

/If;
?>
