<?Lassoscript
// Last modified 8/17/09 by ECL

// FUNCTIONALITY
// This file defines globals to determine whether various utilities are installed
// We check to see that the program really exists.
// This is a simple check for a file at that location. It does NOT check that it is a valid install!

// CHANGE NOTES
// 8/17/09
// First implementation.

// Debugging
// Var:'svDebug' = 'Y';

Debug;
	'svPlatform = ' ($svPlatform) '<br>\n';
/Debug;

// Look for ffmpeg installation
If:!(Global_Defined:'gvffmpegInstalled');
	Global:'gvffmpegInstalled' = boolean;

	// Start with it false, then set to true if program found
	$gvffmpegInstalled = false;

	(File_Exists:($svPathToffmpeg)) ? $gvffmpegInstalled = true;

/If;
Debug;
	'svPathToffmpeg = ' ($svPathToffmpeg) '<br>\n';
	'gvffmpegInstalled = ' ($gvffmpegInstalled) '<br>\n';
/Debug;


// Look for swftools installation
If:!(Global_Defined:'gvswftoolsInstalled');
	Global:'gvswftoolsInstalled' = boolean;

	// Start with it false, then set to true if program found
	$gvswftoolsInstalled = false;

	(File_Exists:($svPathToswftools)) ? $gvswftoolsInstalled = true;

/If;
Debug;
	'svPathToswftools = ' ($svPathToswftools) '<br>\n';
	'gvswftoolsInstalled = ' ($gvswftoolsInstalled) '<br>\n';
/Debug;

// Look for PassThru installation
// NOTE: For this to work, Lasso must be configurations with file permissions
// to allow searching on the path ///
If:!(Global_Defined:'gvPassThruInstalled');
	Global:'gvPassThruInstalled' = boolean;

	// Start with it false, then set to true if program found
	$gvPassThruInstalled = false;

	(File_Exists:($svPathToPassThru)) ? $gvPassThruInstalled = true;

/If;
Debug;
	'svPathToPassThru = ' ($svPathToPassThru) '<br>\n';
	'gvPassThruInstalled = ' ($gvPassThruInstalled) '<br>\n';
/Debug;

?>
