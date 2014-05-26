<?Lassoscript 
// Last modified 10/30/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Detail page

// CHANGE NOTES
// 12/18/07
// Recoded for CMS v 3.0
// 6/9/09
// Added Build Dropdowns
// 7/7/09
// Added Build Gallery
// 10/30/09 
// Removed siteconfig as it is already included in urlhandler.

// Debugging
// Var:'svDebug' = 'Y';

// Build the Page Content Variables
Include:($svIncludesPath)'build_detail.inc';

// Build Navigation
Include:($svIncludesPath)'build_nav.inc';

// Build Dropdowns
Include:($svIncludesPath)'build_dropdown.inc';

// Build Gallery
// This check for zero is necessary because the default value is zero on GalleryGroupID
If: (Var:'vGalleryGroupID') != '' && (Var:'vGalleryGroupID') != '0';
	Include:($svIncludesPath)'build_gallery.inc';
/If;

// Build the Portfolio - Do not include on Quicksearch pages
If: (Var:'SearchType') != 'QS';
	Include:($svIncludesPath)'build_portfolio.inc';
/If;

// Build the Footer
Include:($svIncludesPath)'build_footer.inc';

// Call the Header
Include:($svLibsPath)'page_header.inc';

// Call the Template
Include:($svTmpltsPath)($svSys_DefaultTemplate);

?>
