<?Lassoscript
// Last modified 11/11/07 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_AssetPreviewLink }
	{Description=		Builds a link to either a large version of the graphic (for photos) or the play_media page (for movies) }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				1/13/07 }
	{Usage=				LI_AssetPreviewLink: -IDAsset='450' }
	{ExpectedResults=	An HTML link }
	{Dependencies=		 }
	{DevelNotes=		STATUS: OBSOLETE. This could be reworked to look at $svImageExtArray and $svMediaExtArray }
	{ChangeNotes=		 }
/Tagdocs;
*/
// Define the system vars
Var:'svCTNamespace' = 'LI_';

If: !(Lasso_TagExists:'LI_AssetPreviewLink');
	Define_Tag: 'AssetPreviewLink',
		-Namespace = $svCTNamespace,
		-Required='IDAsset';

		Local:'Result' = string;
		Local:'SQLGetAssetPreview' = string;
		Local:'Filename' = string;
		Local:'Filetype' = string;
		Local:'FullPathTo_Jumbo' = string;
	
		#SQLGetAssetPreview = '/* LI_AssetPreviewLink */
		SELECT Filename,Filetype,FullPathTo_Jumbo FROM ' $svImagesTable ' WHERE ID = "' #IDAsset '" LIMIT 1';

		Inline: $IV_SearchImages, -Table=$svImagesTable, -SQL=#SQLGetAssetPreview;
			If: (Found_Count) == 1;
				#Filename = (Field:'Filename');
				#Filetype = (Field:'Filetype');
				#FullPathTo_Jumbo = (Field:'FullPathTo_Jumbo');
			Else;
				#Filetype = '<!-- Invalid ID passed! -->';
				#Filetype = null;
				#FullPathTo_Jumbo = null;
			/If;
		/Inline;

		// If no Jumbo or Filetype
		// NOTE: .MP3 is a hack, have to do it this way since the filetype is "PS", for some reason.
		// Bug report is filed, Bug #277
		// NOT DISPLAYING.AVI files!
		If: #FullPathTo_Jumbo != '';
			If: (#Filetype == 'M4P') || (#Filetype == 'MOV') || (#Filetype == 'MPG') || (#Filetype == 'WMV');
				#Result = '<a href="http://'($svDomain)'/play_media.lasso?ID='(#IDAsset)'" target="_blank" title="Play '(#Filename)'">Play '(#Filename)'</a>&nbsp;&nbsp;&nbsp;&nbsp;';
			Else;
				#Result = '<a href="'(#FullPathTo_Jumbo)'" target="_blank" title="View Large Preview">View Large Preview</a>&nbsp;&nbsp;&nbsp;&nbsp;';
			/If;
		Else: (#Filename->(EndsWith:('mp3')));
			#Result = '<a href="http://'($svDomain)'/play_media.lasso?ID='(#IDAsset)'" target="_blank" title="Play '(#Filename)'">Play '(#Filename)'</a>&nbsp;&nbsp;&nbsp;&nbsp;';

		// Otherwise output nothing, as there is no Jumbo version available to display
		Else;
			#Result = null;
		/If;
		
		Return: Encode_Smart:(#Result);

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_AssetPreviewLink';

/If;
?>