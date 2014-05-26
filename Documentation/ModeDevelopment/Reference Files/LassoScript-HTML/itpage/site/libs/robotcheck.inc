<?Lassoscript
// Last modified 5/1/08

// FUNCTIONALITY
// This file will set the http status header to denied if detecting a robot
// It is used on admin pages or anywhere we don't want a robot snooping around

// DEPENDENCIES
// lp_client_isBot
// setHTTPstatus

// CHANGE NOTES
// 5/1/08
// First implementation

// Do not allow bots into Admin pages
If: ((lp_client_isBot) == true) && ((Response_Filepath) >> 'admin');

	// Set the http status to 403 Forbidden
	setHTTPstatus: '403 Forbidden';

	Abort;

/If;

?>