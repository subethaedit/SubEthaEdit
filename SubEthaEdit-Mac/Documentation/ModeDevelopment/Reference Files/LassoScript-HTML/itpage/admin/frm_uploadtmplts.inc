<?Lassoscript
// Last modified 9/18/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// Upload Templates Form - Called from /admin/library.lasso

// CHANGE NOTES
// 10/30/07
// First implementation
// 9/18/10
// Fixed misspelling on Datatype

?><!-- START Upload Templates Form -->
<h2>[LI_ShowIconByDataType]&nbsp;&nbsp;Templates Library</h2>
<p>Use this form to upload templates to your site.</p>
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
					<input type="hidden" name="Datatype" value="Templates">
					<input type="submit" value="Upload">
				</div>
			</td>
		</tr>
	</table>
</form>
<br>
<!-- END Upload Templates Form -->
