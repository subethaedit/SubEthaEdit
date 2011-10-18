<?Lassoscript
// Last modified 3/13/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// This page is used as part of itPage admin area to display template previews.
// The template previews themselves are created by EasyThumb

// CHANGE NOTES
// 3/13/10
// First implementation

Include:'/siteconfig.lasso';

// Debugging
// Var:'svDebug' = 'Y';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Convert action_params
Var('ShowThisTemplate' = Action_Param('Template'));
// Build the filepath to the preview
Var('PreviewFileName' = (($svTmpltsPreviewPath)+($ShowThisTemplate)+('.jpg')));

?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
  <title>Template Preview</title>
</head>
<body>
<br>
<div align="center" class="CheckContentType">
	<img src="[$PreviewFileName]" alt="Template Preview">
</div>
</body>
</html>
