<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputText2 }
	{Description=		Outputs the already-built $vText_2 }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputText2 }
	{ExpectedResults=	HTML for Text_2 }
	{Dependencies=		$vText_2 must be defined, otherwise a comment will be output }
	{DevelNotes=		$vText_2 is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputText2');
	Define_Tag:'OutputText2',
		-Description='Outputs the Text2 (in $vText_2)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vText_2') != '';

			#Result += '<!-- OutputText2 -->\n';
			#Result += '<div class="SecondContentPanel">'($vText_2)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputText2: Text2 is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputText2';

/If;
?>