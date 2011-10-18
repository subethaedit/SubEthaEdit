<?Lassoscript
// Last modified 9/20/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_ShowIconByExt }
	{Description=		Displays an icon for a filename based upon the extension of the file }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				 }
	{Usage=				LI_ShowIconByExt: -Filename=('ThisFile.pdf') }
	{ExpectedResults=	/site/images/acrobat_icon.jpg
						If the extension does not match, it uses nopreview.jpg }
	{Dependencies=		The icon must exist in /site/images }
	{DevelNotes=		 }
	{ChangeNotes=		11/1/07
						First implementation
						9/20/09
						Added a few missing datatypes }
/Tagdocs;
*/
If: !(Lasso_TagExists:'LI_ShowIconByExt');
	Define_Tag: 'ShowIconByExt',
		-Namespace = $svCTNamespace,
		-Required='Filename';

		Local:'Result' = string;
	
		// Examine the filename. If it ends with a particular string, display the icon.
		// Otherwise display nopreview
		If: (#Filename->EndsWith:'QXD') || (#Filename->EndsWith:'QXP');
			#Result = ($svFileIconsPath)'quark_icon.jpg';
		Else: (#Filename->EndsWith:'DXF');
			#Result = ($svFileIconsPath)'dxf_icon.gif';
		Else: (#Filename->EndsWith:'DWG');
			#Result = ($svFileIconsPath)'dwg_icon.gif';
		Else: (#Filename->EndsWith:'ODS') || (#Filename->EndsWith:'ODP') || (#Filename->EndsWith:'ODT');
			#Result = ($svFileIconsPath)'oo_icon.jpg';
		Else: (#Filename->EndsWith:'PDF');
			#Result = ($svFileIconsPath)'acrobat_icon.jpg';
		Else: (#Filename->EndsWith:'DOC') || (#Filename->EndsWith:'PPS') || (#Filename->EndsWith:'PPT') || (#Filename->EndsWith:'XLS');
			#Result = ($svFileIconsPath)'msoffice_icon.jpg';
		Else: (#Filename->EndsWith:'GRAFFLE');
			#Result = ($svFileIconsPath)'graffle_icon.jpg';
		Else: (#Filename->EndsWith:'INDD');
			#Result = ($svFileIconsPath)'indd_icon.jpg';
		Else: (#Filename->EndsWith:'LOG');
			#Result = ($svFileIconsPath)'text_icon.jpg';
		Else: (#Filename->EndsWith:'MOV');
			#Result = ($svFileIconsPath)'mov_icon.jpg';
		Else: (#Filename->EndsWith:'MP3');
			#Result = ($svFileIconsPath)'mp3_icon.jpg';
		Else: (#Filename->EndsWith:'M4A');
			#Result = ($svFileIconsPath)'m4a_icon.jpg';
		Else: (#Filename->EndsWith:'MPG') || (#Filename->EndsWith:'MPEG');
			#Result = ($svFileIconsPath)'mpeg_icon.jpg';
		Else: (#Filename->EndsWith:'SLD');
			#Result = ($svFileIconsPath)'edwg_icon.jpg';
		Else: (#Filename->EndsWith:'SVG');
			#Result = ($svFileIconsPath)'svg_icon.jpg';
		Else: (#Filename->EndsWith:'FLA') || (#Filename->EndsWith:'SWF');
			#Result = ($svFileIconsPath)'swf_icon.jpg';
		Else: (#Filename->EndsWith:'WMV') || (#Filename->EndsWith:'AVI');
			#Result = ($svFileIconsPath)'wmv_icon.jpg';
		Else: (#Filename->EndsWith:'SIT') || (#Filename->EndsWith:'SITX');
			#Result = ($svFileIconsPath)'stuffit_icon.jpg';
		Else: (#Filename->EndsWith:'ZIP');
			#Result = ($svFileIconsPath)'zip_icon.jpg';
		Else: (#Filename->EndsWith:'XML');
			#Result = ($svFileIconsPath)'xml_icon.jpg';
		Else: (#Filename->EndsWith:'CSV');
			#Result = ($svFileIconsPath)'text_icon.jpg';
		Else: (#Filename->EndsWith:'GZ');
			#Result = ($svFileIconsPath)'gz_icon.jpg';
		Else: (#Filename->EndsWith:'TXT');
			#Result = ($svFileIconsPath)'text_icon.jpg';
		Else;
			#Result = ($svFileIconsPath)'blank_icon.jpg';
		/If;
		
		Return: Encode_Smart:(#Result);

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_ShowIconByExt';

/If;
?>