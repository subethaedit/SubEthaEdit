<?Lassoscript
// Last modified 6/22/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Displays existing Testimonials pages

// Debugging
// Var:'svDebug' = 'Y';

// CHANGE NOTES
// 6/22/09
// First implementation

'<div class="roundcorner500" id="nifty">\n';
'\t<h3>Existing Gallery Groups</h3>\n';

// Get the users
Var:'SQLDisplayGalleries' = 'SELECT * FROM ' $svGalleryGroupsTable ' ORDER BY DateModified DESC LIMIT 25';

Inline: $IV_Galleries, -SQL=$SQLDisplayGalleries;

	// If Found_Count = 0, dump out simple message
	If: (Found_Count) == 0;
	'\t\t<p class="nifty">\n';
		'\t\t\tNo gallery groups found.<br>\n';
	'\t\t</p>\n';
	Else;
		'\t\t<p class="nifty">\n';
		'\t\t\tThe 25 most-recent records and their active status are displayed below.<br>\n<br>\n';
		Records;
			'\t\t\t<a href="setup_editrecord.lasso?ID=' (Field:'gg_groupid') '&New=Y&Datatype='($vDatatype)'">'(Field:'gg_name')'</a> ';
			'<span class="ghost">';
			If: (Field:'Active') == 'Y'; ' Active'; Else;  ' Inactive'; /If;
			' (ID ' (Field:'gg_groupid') ')</span><br>\n';
		/Records;
		'\t\t</p>\n';
	/If;
/Inline;
'</div>\n';
'<br>\n';
?> 
