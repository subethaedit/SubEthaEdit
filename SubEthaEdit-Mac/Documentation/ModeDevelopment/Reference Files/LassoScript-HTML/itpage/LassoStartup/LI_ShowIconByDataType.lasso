<?Lassoscript
// Last modified 3/7/10 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_ShowIconByDataType }
	{Description=		Displays an icon for a DataType }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				6/23/08 }
	{Usage=				LI_ShowIconByDataType }
	{ExpectedResults=	<img src> for an icon }
	{Dependencies=		It is expected that $vDatatype exists.
						$svFileIconsPath needs to be defined in siteconfig. }
	{DevelNotes=		If $vDatatype doesn't exist, there will be no output. }
	{ChangeNotes=		6/23/08
						First implementation - Modified from original tag on LBT
						1/15/09
						Added new datatype "Story"
						6/22/09
						Added new datatypes "GalleryGroup" and "GalleryEntry" }
/Tagdocs;
*/

Var:'svCTNamespace' = 'LI_';

If: !(Lasso_TagExists:'LI_ShowIconByDataType');
	Define_Tag: 'ShowIconByDataType',
		-Namespace = $svCTNamespace;

		Local:'Result' = string;
	
		If: (Var:'vDataType') == 'Project';
			#Result = '<img src="'($svFileIconsPath)'box.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'User';
			#Result = '<img src="'($svFileIconsPath)'user.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'User';
			#Result = '<img src="'($svFileIconsPath)'user.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Heirarchy';
			#Result = '<img src="'($svFileIconsPath)'sitemap_color.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Content';
			#Result = '<img src="'($svFileIconsPath)'page.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Testimonial';
			#Result = '<img src="'($svFileIconsPath)'application_view_list.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Story';
			#Result = '<img src="'($svFileIconsPath)'application_view_list.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'PortfolioGroup';
			#Result = '<img src="'($svFileIconsPath)'application_view_list.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'PortfolioEntry';
			#Result = '<img src="'($svFileIconsPath)'application_view_list.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'GalleryGroup';
			#Result = '<img src="'($svFileIconsPath)'application_view_list.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'GalleryEntry';
			#Result = '<img src="'($svFileIconsPath)'application_view_list.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Images';
			#Result = '<img src="'($svFileIconsPath)'photos.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Files';
			#Result = '<img src="'($svFileIconsPath)'page_white_copy.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Templates';
			#Result = '<img src="'($svFileIconsPath)'page_copy.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Support';
			#Result = '<img src="'($svFileIconsPath)'help-browser.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Maintenance';
			#Result = '<img src="'($svFileIconsPath)'wrench.png" width="16" height="16" align="bottom" alt="Icon">';
		Else: (Var:'vDataType') == 'Sys';
			#Result = '<img src="'($svFileIconsPath)'cog.png" width="16" height="16" align="bottom" alt="Icon">';

		// If no match, return nothing
		Else;
			#Result = string;
		/If;		

		Return: Encode_Smart:(#Result);

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_ShowIconByDataType';

/If;
?>

