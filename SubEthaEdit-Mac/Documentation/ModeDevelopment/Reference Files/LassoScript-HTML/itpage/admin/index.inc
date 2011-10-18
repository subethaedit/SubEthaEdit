<?Lassoscript
// Last modified 10/27/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Include for loginresponse page

// CHANGE NOTES
// 11/23/07
// First implementation for CMS v. 3.0
// 11/30/07
// Changing action_param vError to be copied only if submit
// 12/4/08
// Adding media files. Currently ONLY checking for .flv extensions.
// 10/27/10
// Added buttons for common tasks

// Convert action_params
If: (Action_Param:'Error') != '';
	Var:'vError' = (Action_Param:'Error');
	Var:'vOption' = (Action_Param:'Option');
/If;

// Get total number of Content Pages
Var:'SQLGetContentCount' = 'SELECT COUNT(ID) AS ContentCount FROM ' $svContentTable;
Inline: $IV_Content, -Table=$svContentTable, -SQL=$SQLGetContentCount;
	Var:'ContentCount' = (Field:'ContentCount');
/Inline;

// Get Number of Users
Var:'SQLGetUsers' = 'SELECT COUNT(ID) AS UsersCount FROM ' $svUsersTable;

// Get the Images directory listing
Var:'image_thumb_array' = (File_ListDirectory: $svImagesThmbPath);
If: $image_thumb_array >> '.DS_Store';
	$image_thumb_array->(Remove:1);
/If;
// Get the count of images
Var:'ImageCount' = ($image_thumb_array->size);

// Get the Media directory listing
Var:'media_thumb_arrayTEMP' = (File_ListDirectory: $svMediaPath);
Var:'media_thumb_array' = array;
Loop: -From=1, -To=$media_thumb_arrayTEMP->size;
	If: ($media_thumb_arrayTEMP->(Get:(Loop_Count))->EndsWith('.flv'));
		$media_thumb_array->(Insert:($media_thumb_arrayTEMP->(Get:(Loop_Count))));
	/If;
/Loop;

// Get the count of media
Var:'MediaCount' = ($media_thumb_array->size);

// Get Number of Files
// Get the directory listing
Var:'file_thumb_array' = (File_ListDirectory: $svFilesUploadPath);
If: $file_thumb_array >> '.DS_Store';
	$file_thumb_array->(Remove:1);
/If;
// Get the count of files
Var:'FileCount' = ($file_thumb_array->size);

'\t\t<br />\n';
'\t\t<a href="/admin/setup_search.lasso?DataType=Content"><img src="/site/images/button_editcontent.gif" width="140" height="40" alt="Edit Content" style="margin-right:8px;"></a>\n';
'\t\t<a href="/admin/setup_add.lasso?DataType=Content&New=Y"><img src="/site/images/button_addcontent.gif" width="140" height="40" alt="Add Content" style="margin-right:8px;"></a>\n';
'\t\t<a href="/admin/library.lasso?DataType=Images"><img src="/site/images/button_imagelibrary.gif" width="160" height="40" alt="Image Library"></a>\n';
'\t\t<div class="roundcorner500" id="nifty">\n';
'\t\t\t<h3>System Stats</h3>\n';
'\t\t\t<p class="nifty"><img src="'($svFileIconsPath)'page.png" alt="Page Icon" width="16" height="16"> <strong>'($ContentCount)'</strong> content pages managed</p>\n';
'\t\t\t<p class="nifty"><img src="'($svFileIconsPath)'photos.png" alt="Photos Icon" width="16" height="16"> <strong>'($ImageCount)'</strong> images in site</p>\n';
'\t\t\t<p class="nifty"><img src="'($svFileIconsPath)'television.png" alt="TV Icon" width="16" height="16"> <strong>'($MediaCount)'</strong> media files in site</p>\n';
'\t\t\t<p class="nifty"><img src="'($svFileIconsPath)'page_white_copy.png" alt="TV Icon" width="16" height="16"> <strong>'($FileCount)'</strong> files in site</p>\n';
'\t\t</div>\n';
?>