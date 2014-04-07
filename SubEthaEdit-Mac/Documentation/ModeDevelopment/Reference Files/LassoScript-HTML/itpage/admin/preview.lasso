<?Lassoscript 
// Last modified 3/8/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Previews a template - This page is a derivative of detail.lasso

// CHANGE NOTES
// 3/8/10
// First implementation

// Debugging
// Var:'svDebug' = 'Y';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Start the Admin session
// Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

'<!-- preview -->\n';

// Login check
// If: (Var:'svUser_ID') != '';

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
	// Check to see if template exists. If it does not, set error 5061 "file not found" and redirect
	Var:'TemplateExists' = (File_Exists:($svTmpltsPath)($svSys_DefaultTemplate));
	If: $TemplateExists == true;
		Include:($svTmpltsPath)($svSys_DefaultTemplate);
	Else;
		// Set error to 5061 "File not found", redirect to library
		Var('vError' = '5061');
		LI_URLRedirect: -Page='admin/library.lasso',-UseError='Y',-Error=$vError, -UseArgs='Y';
	/If;

/*
Else;

	// Set error to 6003 "Session Expired", redirect to login
	Var:'vError' = '6003';
	LI_URLRedirect: -Page='login.lasso',-UseError='Y',-Error=$vError;

/If;
*/
?>
