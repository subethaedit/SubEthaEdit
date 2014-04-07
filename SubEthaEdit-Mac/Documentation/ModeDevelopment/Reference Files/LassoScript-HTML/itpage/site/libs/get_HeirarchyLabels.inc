<?Lassoscript
// Define Heirarchy Labels Map
// Usage: This is not a custom tag, but should be called at the top of each
// page that wants access to the Heirarchy labels
// Then, when you want to output the label, do this:
//    Var:'ThisHeirarchyLabel' = ($HeirarchyLabels->(Find:'1')) where the Find:'1' would be the value
//    of the UserPrivs_PrivID in the Users table
// So, a typical usage would be this:
 
// Privs Map
Var:'HeirarchyLabels' = (map);

Var:'SQLGetHeirarchies'='SELECT ID, name
	FROM ' $svSiteDatabase '.' $svHeirarchyTable;
Inline: $gv_sql, -SQL=$SQLGetHeirarchies, -MaxRecords='All';
	Records;
		$HeirarchyLabels->(insert: (Field:'id') = (Field:'name'));
//			'15: ID = ' (Field:'ID') '<br>\n';
//			'15: name = ' (Field:'name') '<br>\n';
	/Records;
/Inline;

If: $svDebug == 'Y';
	'<p class="debug"><strong>get_HeirarchyLabels.inc</strong><br>\r';
	'25: HeirarchyLabels = ' ($HeirarchyLabels) '<br>\r';
	Var:'ThisHeirarchyLabel' = ($HeirarchyLabels->(Find:'1'));
	'25: ThisHeirarchyLabel = ' $ThisHeirarchyLabel '</p>\n';
/If;


?>
