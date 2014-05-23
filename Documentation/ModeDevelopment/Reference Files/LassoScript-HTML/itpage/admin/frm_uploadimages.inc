<?Lassoscript
// Last modified 8/28/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Upload Images Form - Called from /admin/upload_files.lasso

// CHANGE NOTES
// 10/30/07
// First implementation
// 12/4/08
// Changed allowed filetypes
// 6/12/09
// Adding .flv and .swf
// 8/28/09
// Modiifying behavior of form to respect whether ffmpeg and swftools are installed

?><!-- START Upload Images Form -->
<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;Image Library&nbsp;&nbsp;<a class="jt" href="[$svToolTipsPath]tt_managemedia.html" rel="[$svToolTipsPath]tt_managemedia.html" title="Tips on Managing Media"><img src="[$svImagesPath]question_small.gif" width="22" height="22" alt="question icon"></a></h2>
<form enctype="multipart/form-data" action="[Response_Filepath]" method="post">
	<table>
		<tr>
			<td colspan="2" valign="top" bgcolor="#FFFFFF">Use this form to upload images to your Image Library. Filetypes that can be uploaded are:
			<ul>
				<li>Image Files (.ai, .gif, .jpg, .tif, .png, .psd)</li>
<?Lassoscript
If($svMediaExtArray->size != 0);

	Var('MovieExtensions' = string);
	$MovieExtensions += '\t\t\t\t<li>Movie Files (';
	
	Iterate:$svMediaExtArray, (Local:'i');
		$MovieExtensions += ('.'+(#i)+', ');
	/Iterate;

	$MovieExtensions->RemoveTrailing(', ');
	$MovieExtensions += ')&nbsp;&nbsp;';
	(Var:'MovieExtensions', -EncodeNone);
/If;

?>			</ul>
			</td>
		</tr>
		<tr> 
			<td width="100" class="tablehead_10_white_right">Image to Upload</td>
			<td width="340" valign="top" bgcolor="#cccccc"> 
				<input name="one" type="file">
			</td>
		</tr>
		<tr>
			<td colspan="2" valign="top" bgcolor="#666666">
				<div align="center">
					<input type="hidden" name="Process" value="1">
					<input type="hidden" name="Datatype" value="Images">
					<input type="submit" value="Upload">
				</div>
			</td>
		</tr>
	</table>
</form>
<br>
<!-- END Upload Images Form -->