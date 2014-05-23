<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputImageLarge }
	{Description=		Outputs the already-built $vImage_Large }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputImageLarge }
	{ExpectedResults=	HTML for the Large Image }
	{Dependencies=		$vImage_Large must be defined, otherwise a comment will be output }
	{DevelNotes=		$vImage_Large is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputImageLarge');
	Define_Tag:'OutputImageLarge',
		-Description='Outputs the large image (in $vImage_Large)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vImage_Large') != '';

			#Result += '<!-- OutputImageLarge -->\n';
			#Result += '\t<div class="ContentPanelImage">\n';
			#Result += '\t\t<img src="'($svImagesLrgPath)($vImage_Large)'" alt="'($vImage_Large)'">\n';
			#Result += '\t</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputImageLarge: Image_Large is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputImageLarge';

/If;
?>