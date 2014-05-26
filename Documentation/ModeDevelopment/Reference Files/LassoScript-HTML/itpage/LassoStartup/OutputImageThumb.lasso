<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputImageThumb }
	{Description=		Outputs the already-built $vImage_Thumb }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				7/6/09 }
	{Usage=				OutputImageThumb }
	{ExpectedResults=	HTML for the Thumb Image }
	{Dependencies=		$vImage_Thumb must be defined, otherwise a comment will be output }
	{DevelNotes=		$vImage_Thumb is defined in build_detail.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputImageThumb');
	Define_Tag:'OutputImageThumb',
		-Description='Outputs the thumb image (in $vImage_Thumb)';

		Local('Result') = null;

		// Check if var is defined
		If: (Var:'vImage_Thumb') != '';

			#Result += '<!-- OutputImageThumb -->\n';
			#Result += '\t<div class="ContentPanelImage">\n';
			#Result += '\t\t<img src="'($svImagesThmbPath)($vImage_Thumb)'" alt="'($vImage_Thumb)'">\n';
			#Result += '\t</div>\n';
			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputImageThumb: Image_Thumb is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputImageThumb';

/If;
?>