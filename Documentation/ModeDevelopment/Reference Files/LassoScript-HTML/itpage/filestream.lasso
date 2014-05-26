<?LassoScript
// Last modified 8/28/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Streams a file to user's computer (downloads to their desktop)
// This file works in conjuction with a Virtual Host Rewrite rule.
// Browser request:
// 		http://devcms.steepnbrew.com/securefiles/files/PriceListTEST.pdf
// Rewrites to an URL like this:
//		http://devcms.steepnbrew.com/filestream.lasso?File=PriceListTEST.pdf
// This forces it to require authentication through the admin.

// CHANGE NOTES
// 1/25/09
// First implementation - Basic working code came from Graphics Finder filestream.laso
// 7/23/09
// Added Robot Check
// 8/28/09 ECL
// Change redirect to admin

Include:'/siteconfig.lasso';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Start the Admin session
Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

// Debugging
// Var:'svDebug' = 'Y';

// Security Check
// NOTE: Might have to tweak this
// If privs wrong, display generate error 6004 "Access Restricted" and login form
If: (Var:'svUserPrivs_Priv') == 'Superadmin' || (Var:'svUserPrivs_Priv') == 'Admin';

	// Initialize error variables
	Var:'vError' = string;
	Var:'vOption' = string;
	
	// Convert action_params
	Var:'vFile' = (Action_Param:'File');
	
	// Manufacture the destination filepath
	// TESTING
	// $vFile = 'PriceListTEST.pdf';
	// Var:'StreamThisFile' = ('/securefiles/Files/PriceListTEST.pdf');
	Var:'StreamThisFile' = (($svSecureFilesPath)($vfile));
	Debug;
		'28: <strong>vFile</strong> =' $vFile '<br>\r';
		'28: <strong>StreamThisFile</strong> =' $StreamThisFile '<br>\r';
		'28: <strong>File Exists $StreamThisFile?</strong> = ' (File_Exists:($StreamThisFile)) '<br>\r';
	/Debug;
	
	// If no file found, immediately generate 5061 "File Not Fount" and abort page
	If: !(File_Exists:($StreamThisFile));
		Var:'vError' = '5061';
	// /If;
	Else;
	
		// Protect this block and handle errors
		Protect;
		
			Inline: -Username=$svPassThruUsername,-Password=$svPassThruPassword;
		
				LI_FileStream: -File=$StreamThisFile, -Name=$vFile;
		
				// Grab the current error and error code
				Handle: (Error_CurrentError: -ErrorCode);
					Var:'vDLErrorCode' = (Error_CurrentError: -ErrorCode);
					Var:'vDLErrorMsg' = (Error_CurrentError);
					Debug;
						'94: <strong>vDLErrorCode</strong> =' $vDLErrorCode '<br>\r';
						'94: <strong>vDLErrorMsg</strong> =' $vDLErrorMsg '<br>\r';
					/Debug;
		
					// If error message contains "no permission", something is wrong with the download folder
					If: $vDLErrorMsg >> 'no permission';
						Var:'vError' = '9001';
						Var:'vOption' = $vDLErrorMsg;
					/If;			
				/Handle;

			/Inline;

		/Protect;
	
	/If;
	
Else;

	// Set error to 6003 "Session Expired", redirect to login
	Var:'vError' = '6003';
	LI_URLRedirect: -Page='/admin/',-UseError='Y',-Error=$vError;

/If;

// Stock Error Table Code
If: (Var:'vError') != '';
	'<html>\r';
	'<head>\r';
	'\t<title>File Download Failure</title>\r';
	'\t<link href="'(Var:'svCssPath')'cms.css" rel="stylesheet" media="screen">';
	'</head>\r';
	'<body>\r';
	LI_ShowError3: -ErrNum=$vError, -Option=$vOption;
	'</body>\r';
	'</html>\r';
/If;

Debug;
	Include:($svLibsPath)'vardumpalpha.lasso';
/Debug;
?>
	