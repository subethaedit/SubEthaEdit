<?Lassoscript
// Last modified 10/30/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// Upload Files Form - Called from /admin/library.lasso

// CHANGE NOTES
// 10/30/07
// First implementation

?><!-- START Upload Files Form -->
<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;File Library</h2>
<p>Use this form to upload files to your site. Filetypes that can be uploaded are:</p>
	<ul>
		<li>Adobe Acrobat (.pdf)</li>
		<li>Adobe InDesign (.indd)</li>
		<li>Comma-Separated (.csv)</li>
		<li>Microsoft Word (.doc)</li>
		<li>Microsoft Excel (.xls)</li>
		<li>Microsoft PowerPoint (.pps, .ppt)</li>
		<li>OpenDoc Presentation (.odp)</li>
		<li>OpenDoc Spreadsheet (.ods)</li>
		<li>OpenDoc Text (.odt)</li>
		<li>Quark XPress (.qxd)</li>
		<li>Shockwave Flash (.swf)</li>
		<li>Stuffit (.sit, .sitx)</li>
		<li>Text (.txt)</li>
		<li>Extensible Markup Language (.xml)</li>
		<li>ZIP Compression (.zip)</li>
	</ul>
<form enctype="multipart/form-data" action="[Response_Filepath]" method="post">
	<table>
		<tr> 
			<td width="100" class="tablehead_10_white_right">File to Upload</td>
			<td width="340" valign="top" bgcolor="#cccccc"> 
				<input name="one" type="file">
			</td>
		</tr>
		<tr>
			<td colspan="2" valign="top" bgcolor="#666666">
				<div align="center">
					<input type="hidden" name="Process" value="1">
					<input type="hidden" name="Datatype" value="Files">
					<input type="submit" value="Upload">
				</div>
			</td>
		</tr>
	</table>
</form>
<br>
<!-- END Upload Files Form -->
