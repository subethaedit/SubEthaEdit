<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputImageCaption }
	{Description=		Outputs the already-built $vImage_Caption }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputImageCaption }
	{ExpectedResults=	HTML for the Image Caption }
	{Dependencies=		$vImage_Caption must be defined, otherwise a comment will be output }
	{DevelNotes=		$vImage_Caption is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputImageCaption');
	Define_Tag:'OutputImageCaption',
		-Description='Outputs the image caption (in $vImage_Caption)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vImage_Caption') != '';

			#Result += '<!-- OutputImageCaption -->\n';
			#Result += '<div class="ContentPanelCaption">'($vImage_Caption)'</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputImageCaption: Image_Caption is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputImageCaption';

/If;
?>
