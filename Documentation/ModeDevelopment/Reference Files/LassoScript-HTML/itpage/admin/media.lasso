<?Lassoscript
// Last modified 8/27/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// An admin page used to play media files
// Displays a video and associated poster frame with a name of .png in $svMediaPath
// Flash embed code is from <http://www.w3schools.com/flash/flash_inhtml.asp>

// DEPENDENCIES
// Uses the LI_MediaGetInfo to get info about a file
// Uses FlowPlayerLight.swf, which must be in the /site/libs folder
// and /site/js/flashembed.min.js

// CHANGE NOTES
// 9/26/08
// First implementaiton
// 12/2/08
// Getting rid of fps
// 6/5/09
// Adding .swf playing ability
// 7/23/09
// Added Robot Check
// 8/27/09
// Adding 28 pixels to $VideoHeight to allow for controller. Fixes a distortion problem.

// NOTES
// Media files must be located in /media/
// Video will NOT DISPLAY if there are no width or height values

Include:'/siteconfig.lasso';

// Debugging
// Var:'svDebug' = 'Y';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Convert action_params
Var:'ThisMediaFile' = (Action_Param:'ID');
// Used to determine if we are processing a Flash file
Var('IsSWF' = false);
// Used to hold info about a .swf file
Var('SWFInfo' = map);

Var:'vError' = (Action_Param:'Error');
Debug;
	'30: ThisMediaFile = ' ($ThisMediaFile) '<br>\n';
/Debug;

// Process .swf
If: ($ThisMediaFile->(EndsWith:'swf'));
	$IsSWF = true;
	// Zero out $vError, as LI_MediaGetInfo cannot handle .swf files and should probably be modified
	$vError = string;
Else;
	$IsSWF = false;
/If;
Debug;
	'40: IsSWF = ' ($IsSWF) '<br>\n';
/Debug;

// Process other files (.flv, etc.)
// $JunkMediaVar is not actually used for anything else.
Var:'JunkMediaVar' = (LI_MediaGetInfo: -Filepath=($ThisMediaFile));
Debug;
	'37: JunkMediaVar = ' ($JunkMediaVar) '<br>\n';
//	'37: SWFInfo = ' ($SWFInfo) '<br>\n';
/Debug;

// Process .swf files
If: $IsSWF == true;
	Var('VideoWidth' = $SWFInfo->Find('SWFWidth'));
	Var('VideoHeight' = $SWFInfo->Find('SWFHeight'));
//	Var('VideoRate' = $SWFInfo->Find('SWFRate'));
//	Var('VideoFrames' = $SWFInfo->Find('SWFFrames'));
//	Var('VideoHTML' = $SWFInfo->Find('SWFHTML'));

	Debug;
		'202: VideoWidth = ' ($VideoWidth) '<br>\n';
		'202: VideoHeightTEMP = ' ($VideoHeightTEMP) '<br>\n';
		'202: VideoHeight = ' ($VideoHeight) '<br>\n';
//		'202: VideoRate = ' ($VideoRate) '<br>\n';
//		'202: VideoFrames = ' ($VideoFrames) '<br>\n';
//		'202: VideoHTML = ' ($VideoHTML) '<br>\n';
	/Debug;

// Process other files (.flv, etc.)
Else;

	Var:'VideoWidth' = ($VideoInfoMap->(Find:'width'));
	// Add 28 pixels for controller
	Var('VideoHeightTEMP' = (Integer($VideoInfoMap->(Find:'height'))));
	Var('VideoHeight' =  (Math_Add:($VideoHeightTEMP),28));
	Var:'VideoDimensions' = ($VideoInfoMap->(Find:'dimensions'));
//	Var:'VideoFPS' = ($VideoInfoMap->(Find:'fps'));
	Var:'VideoDuration' = ($VideoInfoMap->(Find:'duration'));

	Debug;
		'202: ThisMediaFile = ' ($ThisMediaFile) '<br>\n';
		'202: VideoInfoMap = ' ($VideoInfoMap) '<br>\n';
		'202: VideoWidth = ' ($VideoWidth) '<br>\n';
		'202: VideoHeightTEMP = ' ($VideoHeightTEMP) '<br>\n';
		'202: VideoHeight = ' ($VideoHeight) '<br>\n';
		'202: VideoDimensions = ' ($VideoDimensions) '<br>\n';
//		'202: VideoFPS = ' ($VideoFPS) '<br>\n';
		'202: VideoDuration = ' ($VideoDuration) '<br>\n';
	/Debug;

/If;

// Page head must be done this way as we are modifying the JS

?><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>  
	<title>Play Media</title>
	<meta http-equiv="content-type" content="text/html; charset=utf-8">
	<script type="text/javascript" src="[$svJSPath]flashembed.min.js"></script>
	<link rel="stylesheet" type="text/css" href="[$svCssPath]media.css">
[If: $IsSWF == false]	<script>
		flashembed("VideoPlaceholder", 
		{
			src:'[$svLibsPath]FlowPlayerLight.swf',
			width: [Var('VideoWidth')],
			height: [Var('VideoHeight')]
		},
		{config: {   
			autoPlay: false,
			autoBuffering: true,
			controlBarBackgroundColor:'#999999',
			controlBarGloss:'high',
			showFullScreenButton: false,
			initialScale: 'scale',
			loop: false,
[NoProcess]
			menuItems: [true, true, true, true, false, false, false],
[/NoProcess]
			videoFile: 'http://[$svDomain][$svMediaPath][$ThisMediaFile]'
		}} 
	);
	</script>[/If]
</head>
<body>
<h2>Play Media File</h2>
<?Lassoscript

// Standard Error Table
If: $vError != '';
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
Else;

	// Output .swf file
	If: $IsSWF == true;

		// Include the .swf object/embed HTML
		Include(($svIncludesPath)('build_swfHTML.inc'));
		// Output the .swf HTML
		$swfHTML;

	Else;
?>
<!-- Video Placeholder -->
<div id="VideoPlaceholder"></div>
<p class="text_12_black"><span class="ghost">[$ThisMediaFile]</span></p>
<?Lassoscript
	/If;   // $IsSWF = true
/If;  // If $vError

Debug;
	Include:($svLibsPath)'vardumpalpha.lasso';
/Debug;
?>
</body>
</html>
