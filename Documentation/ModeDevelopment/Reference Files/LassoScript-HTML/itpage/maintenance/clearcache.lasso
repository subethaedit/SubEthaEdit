<?Lassoscript
// Last modified 8/31/09 by ECL

// FUNCTIONALITY
// This file clears the server's DNS cache in an attempt to straighten around a problem with the e-mail queue hanging messages

// USAGE
// http://www.yourdomain.com/maintenance/clearcache.lasso

// RESULT
// In limited testing, appears to return no reply on success.

Include:'/siteconfig.lasso';

Var:'ClearCache' = PassThru('dscacheutil -flushcache', -Username=$svSiteUsername, -Password=$svSitePassword);

'ClearCache = ' $ClearCache '<br>\n';
'Error_CurrentError = ' (Error_CurrentError) '<br>\n';

?>