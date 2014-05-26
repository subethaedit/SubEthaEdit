<?Lassoscript
// Last modified 9/24/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Builds the Page Footer variable $FooterContent

// CHANGE NOTES
// 12/17/07
// Recoded for CMS v. 3.0
// 6/15/09
// Made FooterLink ulc - stylesheets are case-sensitive!
// 12/9/09
// Added GoogleTracker field in sys table
// 9/24/10
// Moved GoogleTracker to OutputPageBottom

Var:'FooterContent' = '<div class="footer">\n';
$FooterContent += '<a href="http://www.itpage.ws/" target="_blank" class="FooterLink">Powered by</a>&nbsp;&nbsp;<a href="http://www.itpage.ws/" target="_blank" class="FooterLink"><img src="'(Var:'svImagesPath')'logos/';
If: (Response_Filepath) >> 'admin' || (Response_Filepath) >> 'support' || (Response_Filepath) >> 'maintenance' || (Response_Filepath) >> 'reset';
	$FooterContent += 'itPage-Logo-Bug.png';
Else;
	// Gallery pages -- Will use different logo if $vGalleryGroupID is defined
	If: (Var:'GalleryArray');
		$FooterContent += 'itpage-Logo-Bug-Black.jpg';
	// NORMAL footer content -- NOT for galleries or pages with dark backgrounds
	Else;
		$FooterContent += 'itPage-Logo-Bug.png';
	/If;
/If;
	$FooterContent += '" alt="itPage Bug" align="middle" width="55" height="32"></a>&nbsp;&nbsp;<a href="http://www.itpage.ws/" target="_blank" class="FooterLink">Content Management System for Lasso</a>\n';
$FooterContent += '</div>\n';

// If: $svDebug == 'Y' || (Client_IP) >> '66.170.10.';
If: $svDebug == 'Y';
	$FooterContent += (Include: ($svLibsPath)'vardumpalpha.lasso');
/If;
?>
