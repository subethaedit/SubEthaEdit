<?Lassoscript
// Last modified 11/22/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file is called by urlhandler_atbegin.lasso (usually in the site's Lasso Startup folder)
// It does URL mapping to provide clean URLs

// TESTING
// Substitute ($vResponse_Filepath) for (Response_Filepath)

// Debugging
// DON'T use $svDebug, just enable the code that displays (Content_Body)

// USAGE NOTES
// IMPORTANT! This file must produce a $vID, or else output will go to default home page
// Need an Apache directive that handles extensionless files to get this to work

// FUNCTIONALITY OUTLINE
// 1. Get the whole heirarchy+content tree
// 2. Compare the Response_Filepath to the tree
// 3. Set the value of vID to be ContentID
// 4. Look up the RootID for the ContentID page. Used to control navigation panels show/hide.

// DEVELOPER'S NOTES
// Working model for this is in /devel/nestedset_viewSite.lasso

// CHANGE NOTES
// 4/3/08
// Adding fix for handling extended characters (Issue #547)
// 7/20/09
// Added a redirect for /admin/login.lasso
// 8/13/09
// Move map definitions to top of file to fix .lasso files throwing errors
// Replaced $__HTML_REPLY__ with (Content_Body) - finally!
// 8/21/09
// Cleaned up debugging code
// 9/11/09
// Moved a few more var declarations to assist in debugging
// 11/23/09
// Added SortOrder to Content query
// 11/24/09
// Add ShowInNav check - ShowInNav must be == Y for content page to display in dropdown
// 12/13/09
// Added index.lasso to the "do not process" check to fix problem with home page dropdowns
// 12/21/09
// Added new var $ProcessCleanURLs to provide more fine-grained control of Clean URLs pages
// 3/8/10
// Extracted the code to build various heirarchy arrays and maps and put it in /site/libs/build_heirmaps.inc
// Added a check for template pages
// 8/13/10
// Added $svIsDevelSite
// 8/28/10
// Added clean URLs for admin, login and logout
// 11/22/10
// Moved build_heirmaps in order for generate_google_sitemap.lasso to function

// Check for devel site, look for leading "dev" in site name
Var('svIsDevelSite' = boolean);
(Server_Name)->(BeginsWith('dev')) ? $svIsDevelSite = true | $svIsDevelSite = false;

Include:'/siteconfig.lasso';

// TESTING
// Page head
// (Content_Body) += Include:($svLibsPath)'page_header_devel.inc';

// Initialize vars - DO NOT MOVE or .lasso pages will throw errors
Var:'ContentIDMap' = map;
Var:'ContentPathMap' = map;
Var:'ContentHeadMap' = map;
Var:'ContentHeirIDMap' = map;
Var:'URLLabelMap' = (lp_array);

// Log_Critical: 'urlhandler 38: ' ($svDomain)' -- BEGIN Response_Filepath = ' (Response_Filepath);

// Set $ProcessCleanURLs which controls whether or not to process this page with Clean URLS
Var('ProcessCleanURLs' = false);

// First look at detail.lasso
If: ((Response_Filepath)->(endswith:'/detail.lasso'));
	$ProcessCleanURLs = true;
// Next look at index.lasso
Else: ((Response_Filepath) == '/index.lasso');
	$ProcessCleanURLs = true;
// Is this a template rendering page?
Else: ((Response_filepath) >> 'preview_template.lasso');
	$ProcessCleanURLs = false;
Else: ((Response_filepath) >> 'preview.lasso');
	$ProcessCleanURLs = false;
// Next look for any .lasso or .lassoapp file
Else: (Response_Filepath)->(endswith:'.lasso') || (Response_filepath)->(endswith:'.lassoapp');
	$ProcessCleanURLs = false;
// Finally catch everything else
Else;
	$ProcessCleanURLs = true;
/If;

// Intercept request for admin or login pages.
If(
	(Response_Filepath)->(endswith:'/admin/') ||
	(Response_Filepath)->(endswith:'/admin') ||
	(Response_Filepath)->(endswith:'/admin/login') ||
	(Response_Filepath)->(endswith:'/login/') ||
	(Response_Filepath)->(endswith:'/login/') ||
	(Response_Filepath)->(endswith:'/login')
	);

	(Content_Body) = include('/admin/login.lasso');
	LI_CMSatend;
	Abort;

// Logout
Else(
	(Response_Filepath)->(endswith:'/admin/logout') ||
	(Response_Filepath)->(endswith:'/logout/') ||
	(Response_Filepath)->(endswith:'/logout')
	);

	(Content_Body) = include('/admin/login.lasso?Action=logout');
	LI_CMSatend;
	Abort;

/If;

// Build the heirarchy maps
// Need to do this REGARDLESS of whether it's a clean URL, so generate_google_sitemap.lasso functions
Include(($svLibsPath)+'build_heirmaps.inc');

// Process the Clean URLs page
If: $ProcessCleanURLs == true;

	// Log Request
	// Log_Critical: 'urlhandler 46: ' ($svDomain)' -- BEGIN Response_Filepath = ' (Response_Filepath);

	// Run site - Use absolute path!
	(Content_Body) = include:  '/detail.lasso';
	LI_CMSatend;
	Abort;

/If;

?>
