<?Lassoscript
// Last modified: 4/3/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing Testimonials pages

// Debugging
// Var:'svDebug' = 'Y';

// CHANGE NOTES
// 4/3/08
// Fixed incorrect wording in Found_Count = 0 message

'<div class="roundcorner500" id="nifty">\n';
'\t<h3>Existing Portfolio Groups</h3>\n';

// Get the users
Var:'SQLDisplayPortfolioGroups' = 'SELECT * FROM ' $svPortfolioGroupsTable ' ORDER BY DateModified DESC LIMIT 25';

Inline: $IV_Portfolios, -SQL=$SQLDisplayPortfolioGroups;

	// If Found_Count = 0, dump out simple message
	If: (Found_Count) == 0;
	'\t\t<p class="nifty">\n';
		'\t\t\tNo portfolio groups found.<br>\n';
	'\t\t</p>\n';
	Else;
		'\t\t<p class="nifty">\n';
		'\t\t\tThe 25 most-recent records and their active status are displayed below.<br>\n<br>\n';
		Records;
			'\t\t\t<a href="setup_editrecord.lasso?ID=' (Field:'pg_groupid') '&New=Y&Datatype='($vDatatype)'">'(Field:'pg_name')'</a> ';
			'<span class="ghost">';
			If: (Field:'Active') == 'Y'; ' Active'; Else;  ' Inactive'; /If;
			' (ID ' (Field:'pg_groupid') ')</span><br>\n';
		/Records;
		'\t\t</p>\n';
	/If;
/Inline;
'</div>\n';
'<br>\n';
?> 
