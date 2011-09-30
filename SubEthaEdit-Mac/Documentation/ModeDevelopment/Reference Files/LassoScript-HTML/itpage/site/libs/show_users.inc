<?Lassoscript
// Last modified 8/15/06 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing Users

// Debugging
// Var:'svDebug' = 'Y';

// Using roundcorner500
'<div class="roundcorner500" id="nifty">\n';
'\t<h3>Existing Users</h3>\n';

// Get the users
Var:'SQLDisplayUsers' = 'SELECT User_ID,User_FName,User_LName FROM ' $svUsersTable ' ORDER BY User_LName';

Inline: $IV_Users, -SQL=$SQLDisplayUsers;
	// If Found_Count = 0, dump out simple message
	If: (Found_Count) == 0;
	'\t\t<p class="nifty">\n';
		'\t\t\tNo users found.<br>\n';
	'\t\t</p>\n';
	Else;
		'\t\t<p class="nifty">\n';
		Records;
			'\t\t\t<a href="setup_editrecord.lasso?Datatype=User&ID=' (Field:'User_ID') '&New=Y">'(Field:'User_LName')', '(Field:'User_FName')'</a>\n';
			'\t\t\t<br>\n';
		/Records;
		'\t\t</p>\n';
	/If;
/Inline;
'</div>\n';
?> 

