<?Lassoscript
// Last modified 12/9/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file processes action_params

// Copying Action_Params to vars
// Remove leading and trailing spaces
// If required is missing, output an error
// If multiple errors, they will step on each other, but not worried about it

// CHANGE NOTES
// 11/1/07
// Recoded for CMS v. 3.0
// 8/24/09
// Adding fields for image utilities and css
// Fix a logic problem with error display
// 12/9/09
// Added GoogleTracker field in sys table

Var:'vError' = (Action_Param:'Error');
Var:'vOption' = (Action_Param:'Option');
Var:'vProcess' = (Action_Param:'Process');

Var:'vSys_Domain'=(Action_Param:'Sys_Domain');
	$vSys_Domain->trim;
Var:'vSys_SMTP'=(Action_Param:'Sys_SMTP');
	$vSys_SMTP->trim;
Var:'vSys_PostmasterEmail'=(Action_Param:'Sys_PostmasterEmail');
	$vSys_PostmasterEmail->trim;
Var:'vSys_AdminEmail'=(Action_Param:'Sys_AdminEmail');
	$vSys_AdminEmail->trim;
Var:'vSys_AuthUsername'=(Action_Param:'Sys_AuthUsername');
	$vSys_AuthUsername->trim;

// Process the password
Var:'vSys_AuthPassword'=(Action_Param:'Sys_AuthPassword');
	$vSys_AuthPassword->trim;
Var:'vSysAPW'=(Encrypt_Blowfish:$vSys_AuthPassword, -Seed=$svSalt);

Var:'vSys_WebserverRoot'=(Action_Param:'Sys_WebserverRoot');
	$vSys_WebserverRoot->trim;
Var:'vSys_PathToIm'=(Action_Param:'Sys_PathToIm');
	$vSys_PathToIm->trim;
Var:'vSys_PathToffmpeg'=(Action_Param:'Sys_PathToffmpeg');
	$vSys_PathToffmpeg->trim;
Var:'vSys_PathToswftools'=(Action_Param:'Sys_PathToswftools');
	$vSys_PathToswftools->trim;
Var:'vSys_PathToPassThru'=(Action_Param:'Sys_PathToPassThru');
	$vSys_PathToPassThru->trim;
Var:'vSys_Keywords'=(Action_Param:'Sys_Keywords');
	$vSys_Keywords->trim;

Var:'vSys_Expires'=(Action_Param:'Sys_Expires');
	$vSys_Expires->trim;
Var:'vSys_Revisit'=(Action_Param:'Sys_Revisit');
	$vSys_Revisit->trim;
Var:'vSys_Robots'=(Action_Param:'Sys_Robots');
	$vSys_Robots->trim;
Var:'vSys_Author'=(Action_Param:'Sys_Author');
	$vSys_Author->trim;
Var:'vSys_Description'=(Action_Param:'Sys_Description');
	$vSys_Description->trim;
Var:'vSys_Copyright'=(Action_Param:'Sys_Copyright');
	$vSys_Copyright->trim;
Var:'vSys_Title'=(Action_Param:'Sys_Title');
	$vSys_Title->trim;
Var:'vSys_Language'=(Action_Param:'Sys_Language');
	$vSys_Language->trim;
Var:'vSys_UseFavIcon'=(Action_Param:'Sys_UseFavIcon');
	$vSys_UseFavIcon->trim;
Var:'vSys_DefaultTemplate'=(Action_Param:'Sys_DefaultTemplate');
	$vSys_DefaultTemplate->trim;
Var:'vSys_DefaultStylesheet'=(Action_Param:'Sys_DefaultStylesheet');
	$vSys_DefaultStylesheet->trim;
Var:'vSys_GoogleTracker'=(Action_Param:'Sys_GoogleTracker');
	$vSys_GoogleTracker->trim;

// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit

If: $vProcess == 'Y';
	// Superadmin checks for $vSys_WebserverRoot too
	If: $svUserPrivs_Priv == 'Superadmin';
		If: ($vSys_Domain == '') || ($vSys_SMTP == '') || ($vSys_PostmasterEmail == '') || 
			($vSys_AdminEmail == '') || ($vSys_WebserverRoot == '') || ($vSys_PathToIm == '') || 
			($vSys_Keywords == '') || ($vSys_Expires == '') || ($vSys_Revisit == '') || 
			($vSys_Robots == '') || ($vSys_Author == '') || ($vSys_Description == '') || 
			($vSys_Copyright == '') || ($vSys_Title == '') || ($vSys_Language == '') ||
			($vSys_UseFavIcon == '') || ($vSys_DefaultTemplate == '');
			$vError = '1003';
		/If;
	Else;
		If: ($vSys_Domain == '') || ($vSys_SMTP == '') || ($vSys_PostmasterEmail == '') || 
			($vSys_AdminEmail == '') || ($vSys_PathToIm == '') || 
			($vSys_Keywords == '') || ($vSys_Expires == '') || ($vSys_Revisit == '') || 
			($vSys_Robots == '') || ($vSys_Author == '') || ($vSys_Description == '') || 
			($vSys_Copyright == '') || ($vSys_Title == '') || ($vSys_Language == '') ||
			($vSys_UseFavIcon == '') || ($vSys_DefaultTemplate == '');
			$vError = '1003';
		/If;
	/If;	
/If;

// Check e-mail address, if bad output error 1102 "E-mail Format Error"
If: (Var:'vSys_PostmasterEmail') != '';
	If: (Valid_Email:($vSys_PostmasterEmail)) == false;
		// Do not step on previous Required Missing error
		If($vError == '');
			$vError = '1102';
		/If;
	/If;
/If;
If: (Var:'vSys_AdminEmail') != '';
	If: (Valid_Email:($vSys_AdminEmail)) == false;
		// Do not step on previous Required Missing error
		If($vError == '');
			$vError = '1102';
		/If;
	/If;
/If;
?>