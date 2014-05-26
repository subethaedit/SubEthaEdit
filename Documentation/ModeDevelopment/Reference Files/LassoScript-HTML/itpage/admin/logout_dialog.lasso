<?Lassoscript
// Used with permission from Tami Williams, 12/20/07
// Part of a system that auto-logs out user after 30 minutes
// Scripts are in page_header_admin.inc and warnings.js
// FUNCTIONALITY
// The site session has a 30 minute limit and this page appears after 29 minutes of inactivity
// This window re-sets the site session limit to 29 minutes & will automatically log out & end the session in 2 minutes IF it is not cancelled
// Because of auto-logout in 2 minutes the logout time is really 29 minutes + 2 minutes
// So the session will last 31 minutes total before automatic logout
	   
Include:'/siteconfig.lasso';

// Start the Admin session
Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Landmann InterActive CMS - Pending Logout</title>
	[Content_Type: 'text/html; charset=iso-8859-1']
	[$__http_header__ += 'Expires:Fri, 26 Mar 1999 23:59:59 GMT\r\n']
	[$__http_header__ += 'Pragma: no-cache\r\n']
	<meta name="MSSmartTagsPreventParsing" content="true">
	<meta name="distribution" content="global">
	<meta name="language" content="en">
	<meta  name="robots"  content="noindex,nofollow">
	<link rel="stylesheet" type="text/css" href="[$svCssPath]admin.css">
	<script language="JavaScript" type="text/javascript">
	[html_comment]
	// this window stays up for 2 minutes then automatically logs out if the user doesn't click on anything
	
	function logout_submit() {
			window.opener.StopCountdown();
			window.opener.location.href='login.lasso?Action=logout';
			self.close();
		}

		function logout_cancel() {
			window.opener.counter = 0;
			window.opener.Countdown();
			self.close();
		}
		
	// 2 * 60 * 1000 => 1000 = 1 sec, x 60 = 1 min, 2 =  for 2 minutes
	
	// [/html_comment]
	</script>
</head>
<body bgcolor="#FFFFFF" onBlur="window.focus();" onload="setTimeout('logout_submit()',2 * 60 *  1000)">
<br>
<div class="containeralert">
	<p><strong>Logout</strong><br>
	<br>
	Selecting the Logout button will erase the current session and clear the current username and password from your Web browser, making it impossible for another user to use your browser to visit the site with the authentication information you have provided.<br>
	<br>
	<strong>If you do nothing your current session will be automatically logged out after 2 minutes of inactivity, after which you will need to sign in again to continue.</strong><br>
	<br>
	For maximum security, we recommend that all users close their browser window immediately after logging out.<br>
	<form>
		<input type="button" name="Submit" value="Logout" onClick="logout_submit()">
		<input type="button" name="Submit" value="Cancel" onClick="logout_cancel()">
	</form>
	</p>
</div>
</body>
</html>
