<?Lassoscript
// Last modified: 10/25/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing content pages

// Debugging
// Var:'svDebug' = 'Y';

'<div class="roundcorner500" id="nifty">\n';
'\t<h3>Existing Content</h3>\n';

// Get the users
Var:'SQLDisplayContent' = 'SELECT ID, Headline, Active FROM ' $svContentTable ' ORDER BY DateModified DESC LIMIT 25';

Inline: $IV_Content, -SQL=$SQLDisplayContent;
	// If Found_Count = 0, dump out simple message
	If: (Found_Count) == 0;
	'\t\t<p class="nifty">\n';
		'\t\t\tNo content found.<br>\n';
	'\t\t</p>\n';
	Else;
		'\t\t<p class="nifty">\n';
		'\t\t\tThe 25 most-recent records and their active status are displayed below.<br>\n<br>\n';
		Records;
			'\t\t\t<a href="setup_editrecord.lasso?ID=' (Field:'ID') '&New=Y&Datatype=Content">'(Field:'Headline') '</a> ';
			'<span class="ghost">';
			If: (Field:'Active') == 'Y'; ' Active'; Else;  ' Inactive'; /If;
			' (ID ' (Field:'ID') ')</span><br>\n';
		/Records;
		'\t\t</p>\n';
	/If;
/Inline;
'</div>\n';
?> 
