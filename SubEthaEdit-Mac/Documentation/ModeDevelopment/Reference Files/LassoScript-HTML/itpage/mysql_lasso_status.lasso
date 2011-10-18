<?Lassoscript
// Last modified 7/23/09 by ECL, Landmann InterActive

// CHANGE NOTES
// 7/23/09
// Added Robot Check

Include:'/siteconfig.lasso';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

Inline: -Database=$svSiteDatabase,
	-Table=$svContentTable,
	-Username=$svSiteUsername,
	-Password=$svSitePassword,
	-SQL='SELECT COUNT(id) AS ContentCount FROM cms_content';
	
	If: (Found_Count) != 0;
		'The Server is Up.<br>\nFound Count: ' (Field:'ContentCount');
	Else;
		'The Server is Down.<br>\nFound Count: ' (Field:'ContentCount');
	/If;

/Inline;


?>