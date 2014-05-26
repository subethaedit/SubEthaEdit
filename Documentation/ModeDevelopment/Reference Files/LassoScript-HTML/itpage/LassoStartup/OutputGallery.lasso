<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputGallery }
	{Description=		Outputs a Gallery }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				1/14/09 }
	{Usage=				OutputGallery }
	{ExpectedResults=	Outputs the html code containing the entire gallery }
	{Dependencies=		$GalleryArray must be defined, otherwise you will get a page but with no gallery pictures }
	{DevelNotes=		This tag is merely a convenience to make it easy for a designer or coder to output a Gallery }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputGallery');
	Define_Tag:'OutputGallery',
		-Description='Outputs the html code containing a Gallery';

		Local('Result') = null;

		// Check if $DropdownHTML is defined
		If: (Var_Defined:'GalleryArray');

			#Result = '<!-- START OutputGallery -->\n';
			#Result += '<div id="main_image"></div>\n';
			#Result += '\t<ul class="gallery_final_unstyled">\n';

			Iterate: $GalleryArray, (Local:'i');
				Var:'ThisID' = #i->find('id');
				Var:'ThisFilename' = #i->find('Filename');
				Var:'ThisImageAlt' = #i->find('ImageAlt');
				Var:'ThisImageCaption' = #i->find('ImageCaption');
				Var:'ThisGalleryText' = #i->find('GalleryGroupText');

				If: $svDebug == 'Y';
					#Result += ('<p class="debugCT"><strong>OutputGallery</strong>\n');
					#Result += ('Response_Filepath = ' (Response_Filepath) '<br>\n');
					#Result += ('ThisID = ' ($ThisID) '<br>\n');
					#Result += ('ThisFilename = ' ($ThisFilename) '<br>\n');
					#Result += ('ThisImageAlt = ' ($ThisImageAlt) '<br>\n');
					#Result += ('ThisImageCaption = ' ($ThisImageCaption) '<br>\n');
					#Result += ('ThisGalleryText = ' ($ThisGalleryText) '</p>\n');
				/If;

				// Build the output list item (picture and link) to display
				#Result += '\t<li';
				// Process the default image being viewed
				If: (Response_Filepath) !>> '#';
					#Result += ' class="active"';
				/If;
				#Result += ('><img src="'($svImagesLrgPath)($ThisFilename)'" alt="'($ThisImageAlt)'" title="'($ThisImageCaption)'"></li>\n');
			
			/Iterate;
			
			#Result += ('\t</ul>
		<p class="GalleryNavContainer"><a href="#" onclick="$.galleria.prev(); return false;" class="GalleryNav">&laquo; previous</a> | <a href="#" onclick="$.galleria.next(); return false;" class="GalleryNav">next &raquo;</a></p>\n');
			If: (Var:'ThisGalleryText') != '';
// This is a hack to fix the situation where the Gallery Text does not flow with the rest of the page when resized.
// Style sheet should probably be fixed to resolve this.
//				#Result += ('\t<div class="GalleryGroupText">' ($ThisGalleryText) '</div>\n');
				#Result += ('\t<div class="GalleryContainer">' ($ThisGalleryText) '</div>\n');
			/If;
			#Result += '<!-- END OutputGallery -->\n';

			Return: (Encode_Smart:(#Result));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputGallery: GalleryArray is undefined -->\n';

			If: $svDebug == 'Y';
				#Result += '<strong>OutputGallery: </strong>GalleryArray is undefined<br>\n';
			/If;

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputGallery';

/If;
?>
