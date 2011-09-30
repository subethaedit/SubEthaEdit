<?Lassoscript
// Last modified 7/23/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// Used to modify categories nestedset data in the $svHeirarchyTable table

// NOTES
// Parameters passed by this form:
// 	"DataType"		Value of "Node" means that we are modifying the node table
//	"NodeID"		Value of the existing node ID. Used to delete node or update name.
//	"AddNewNodeName"	Name for a new node.
//	"Action"
// 		Action = "Add New Root", means the request was an Add New Root node
// 		Action = "Update", means the request was an Update the Name or content_id of an existing node
// 		Action = "Delete", means the request was to Delete and all underlying nodes
// 		Action = "Add (Same Level)", means the request was to add a node in the heirarchy
//	"UpdateName"	Value of the name (for an existing record)
//	"NewRootName"	Value of the NEW root name requested to be created

// CHANGE NOTES
// 10/5/07
// Moved "Add New Root" to bottom of form
// 11/25/07
// Fixing HTML errors found when working on LI CMS - see /admin/manage_heirarchy.lasso
// Removed ability to assign Content ID. We are doing this a different way now,
// by assigning the heirarchy ID in the content page itself.
// Added jQuery ToolTip
// 4/30/08
// Added LI_CMSatend at bottom of page to set focus to login box
// 7/23/09
// Added Robot Check

Include:'/siteconfig.lasso';

// Debugging
// Var:'svDebug' = 'Y';

// Robot check
Include:($svLibsPath)'robotcheck.inc';

// Start the session
Session_Start: -Name=$svSessionAdminName, -Expires=$svSessionTimeout;

// Page head
Include:($svLibsPath)'page_header_admin.inc';

// Defining the DataType
Var:'vDataType' = 'Heirarchy';

// Convert action_params
If: (Action_Param:'Error') != '';
	Var:'vError' = (Action_Param:'Error');
/If;
If: (Action_Param:'Option') != '';
	Var:'vOption' = (Action_Param:'Option');
/If;

// Security check
If: (Var:'svUser_ID') != '';

// Initialize variables
Var:'OutputCloseDiv' = boolean;

// 	GROUP BY node.name
// 11/15/07
// Removing Content_ID from query
Var:'SQLSelectFullNode' = '/* Select full node */
	SELECT node.id, node.name, 
	(COUNT(parent.name) - 1) AS depth,
	node.lft, node.rgt, node.Active
	FROM ' $svHeirarchyTable ' AS node, ' $svHeirarchyTable ' AS parent
	WHERE node.lft BETWEEN parent.lft AND parent.rgt
	GROUP BY node.id
	ORDER BY node.lft';

	// Output table header
	'<table width="80%" bgcolor="#FFFFFF">\n';
	'\t<tr>\n';

	'\t\t<td colspan="11"><h2>'(LI_ShowIconByDataType)'&nbsp;&nbsp;Manage Heirarchy
	<a class="jt" href="'($svToolTipsPath)'tt_heirarchymanage.html" rel="'($svToolTipsPath)'tt_heirarchymanage.html" title="How to Use the Heirarchy"><img src="'($svImagesPath)'question_small.gif" width="22" height="22" alt="question icon"></a></h2>\n';

// Standard Error Table
If: ((Var:'vError') == '1004' && (Var:'vOption') >> 'new') ||
	(Var:'vError') == '1003' ||
	(Var:'vError') == '1021' ||
	(Var:'vError') == '1013';
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;
	'\t\t</td>\n';
	'\t</tr>\n';

	// Table Header
	'\t<tr bgcolor="#F5F5F5">\n';
	'\t\t<td width="25" class="ghost" valign="middle" align="center"><strong>ID<sup> </sup></strong></td>\n';
	'\t\t<td width="35" class="ghost" valign="middle"><strong>Depth<sup> </sup></strong></td>\n';
	'\t\t<td width="200" bgcolor="#FFFF99" valign="middle"><strong>Node Name<sup> </sup></strong></td>\n';
	'<td width="45" bgcolor="#FFFF99" valign="middle" align="center"><strong>Active<sup> </sup></strong></td>';
	'<td width="75" bgcolor="#FFFF99" valign="middle" align="center"><strong>Update<sup> </sup></strong></td>';
	'<td width="70" bgcolor="#D4CDDC" valign="middle" align="center"><strong>Delete</strong><sup>(3)</sup></td>\n';
	'<td width="260" bgcolor="#FFFFCC" valign="middle" align="center"><strong>Add</strong><sup>(1)(2)</sup></td>\n';
	'<td width="175" bgcolor="#F0F0E1" valign="middle" align="center"><strong>Move to New Parent</strong><sup>(4)</sup></td>\n';
	'<td width="80" bgcolor="#DEE4E8" valign="middle" align="center"><strong>Move Up</strong><sup>(5)</sup></td>\n';
	'<td width="20" class="ghost" valign="middle" align="center"><strong>L<sup> </sup></strong></td>\n';
	'<td width="20" class="ghost" valign="middle" align="center"><strong>R<sup> </sup></strong></td>\n';
	'\t</tr>\n';
	'\t<tr>\n';
	'\t\t<td colspan="11"><hr></td>\n';
	'\t</tr>\n';
	'</table>\n';

Inline: $IV_Heirarchy, -SQL=$SQLSelectFullNode, -Table=$svHeirarchyTable;

	If: $svDebug == 'Y';
		'<p class="debug">\n';
		'Found_Count = ' (Found_Count) '<br>\n';
		'Error_CurrentError = ' (Error_CurrentError) '<br>\n';
		'SQLSelectFullNode = ' ($SQLSelectFullNode) '<br>\n';
		'Records_Array = ' (Records_Array) '<br>\n';
		'</p>\n';
	/If;

	$OutputCloseDiv = false;

	Records;

		// Looking ahead to next record to see if we should output the closing div
		Var:'NextLoopCount' = (Math_Add:(Loop_Count),1);
		Protect;
			Var:'NextLoopDepthTemp' = (Records_Array->Get:$NextLoopCount);
		/Protect;
		Var:'NextLoopID' = ($NextLoopDepthTemp->Get:2);
		Var:'NextLoopID' = ($NextLoopDepthTemp->Get:1);
		Var:'NextLoopDepth' = (Integer($NextLoopDepthTemp->Get:3));
		If: $NextLoopDepth == 0;
			$OutputCloseDiv = true;
		Else;
			$OutputCloseDiv = false;
		/If;		

		// Copy depth to ThisNodeDepth
		Var:'ThisNodeDepth' = (Field:'depth');

		If: $svDebug == 'Y';
			'<tr><td colspan="11"><p class="debug">\n';
			'56: Loop_Count = ' (Loop_Count) '<br>\n';
			'56: NextLoopCount = ' ($NextLoopCount) '<br>\n';
			'56: Records_Array->Get:$NextLoopCount = ' (Records_Array->Get:$NextLoopCount) '<br>\n';
			'56: NextLoopID = ' ($NextLoopID) '<br>\n';
			'56: ThisNodeDepth = ' ($ThisNodeDepth) '<br>\n';
			'56: NextLoopDepth = ' ($NextLoopDepth) '<br>\n';
			'56: OutputCloseDiv = ' ($OutputCloseDiv) '<br>\n';
			'56: ID = ' (Field:'id') '<br>\n';
			'</p></td></tr>\n';
		/If;

		// Output a h2 head that is clickable to toggle panel on/off
		If: $ThisNodeDepth == 0;
			If: $NextLoopDepth != 0;
				'</table>\n';
			/If;
		/If;
		If: $ThisNodeDepth == 0;
			'<div class="panelhead" onclick="exp_coll(\''(Field:'ID')'\')" title="Click to Toggle Panel">\n';
			'\t<img src="/site/images/bullet_rightroundyellow.gif" width="20" height="24" id="image_'(Field:'ID')'" alt="icon" title="Click to Toggle Panel" align="bottom">\n';
			'\t<strong>'(Field:'name')'</strong>\n';
			'</div>\n';

//			'<div id="sp_'(Field:'ID')'" style="display:block;">\n';
			'<div id="sp_'(Field:'ID')'" style="display:none;">\n';
			$OutputCloseDiv = true;
		/If;
		'\t<form action="/admin/setup_addresponse.lasso" method="post">\n';
		'\t\t<input type="hidden" name="DataType" value="Node">\n';
		'\t\t<input type="hidden" name="New" value="Y">\n';
		'\t\t<input type="hidden" name="NodeID" value="' (Field:'ID') '">\n';
		'<table width="80%" bgcolor="#FFFFFF">\n';
		'\t<tr bgcolor="#F5F5F5">\n';
		'\t\t<td width="25" class="ghost" valign="middle">' (Field:'ID') '</td>\n';

		'\t\t<td width="35" class="ghost" valign="middle">';
		If: (Field:'depth') == 0;
			'root';
		Else;
			(Field:'depth');
		/If;
		'</td>\n';

		'\t\t<td width="200" class="tabletext_11_black" bgcolor="#FFFF99" valign="middle">';
				'<div align="left">';
				// Output bullets to indicate level if not a root node
				If: (Field:'depth') != 0;
					Loop: (Field:'depth'); '<strong>&bull;&nbsp;</strong>'; /Loop;
				/If;
				'</div>\n';
				// Bold the zero-level categories
				If: (Field:'depth') == 0;
					 '<strong>\n';
				/If;

				// Indent
				If: (Field:'depth') != 0;
					'&nbsp;&nbsp;\n';
				/If;
				'\t\t\t<input type="text" name="UpdateName" value="' (Field:'name') '" size="22" maxlength="64">\n';
				If: (Field:'depth') == 0;
					'</strong>\n';
				/If;
				'\t\t</td>\n';

		// Active
		'\t\t<td width="45" class="tabletext_11_black" bgcolor="#FFFF99" align="center" valign="middle">\n';
		'\t\t\t\t<select name="Active">\n';
		'\t\t\t\t<option value=""'; If: (Field:'Active') == ''; ' selected'; /If; '></option>\n';
		'\t\t\t\t\t<option value="Y"'; If: (Field:'Active') == 'Y'; ' selected'; /If; '>Yes</option>\n';
		'\t\t\t\t\t<option value="N"'; If: (Field:'Active') == 'N'; ' selected'; /If; '>No</option>\n';
		'\t\t\t</select>\n';
		'\t\t</td>\n';

		// Update
		'\t\t<td width="75" class="tabletext_11_black" bgcolor="#FFFF99" align="center" valign="middle">\n';
		'\t\t\t\t<input type="submit" name="Action" value="Update">';
		'\t\t</td>\n';

		// Delete
		'\t\t<td width="70" class="tabletext_11_black" bgcolor="#D4CDDC" align="center" valign="middle">\n';
		'\t\t\t\t<input type="submit" name="Action" value="Delete">\n';
		'\t\t</td>\n';

		// Add (Same Level)
		'\t\t<td width="260" class="tabletext_11_black" bgcolor="#FFFFCC" valign="middle">\n';
		'\t\t\t\tName <input type="text" name="AddNewNodeName" value="' (Var:'vAddNewNodeName') '" size="12" maxlength="64">\n';
		'<input type="submit" name="Action" value="Add (Same Level)"><br>\n';

		// Add (1 Level Lower)
		'\t\t\t\tName <input type="text" name="AddNewChildName" value="' (Var:'vAddNewChildName') '" size="12" maxlength="64">\n';
		'<input type="submit" name="Action" value="Add (1 Level Lower)">\n';
		'\t\t</td>\n';

		// Move to New Parent
		'\t\t<td width="175" class="tabletext_11_black" bgcolor="#F0F0E1" valign="middle">\n';
		'\t\t\t\tNew Parent <input type="text" name="NewParent" value="' (Var:'vNewParent') '" size="4" maxlength="6">';
		'<input type="submit" name="Action" value="Move">\n';
		'\t\t</td>\n';

		// Move Up
		'\t\t<td width="80" class="tabletext_11_black" bgcolor="#DEE4E8" align="center" valign="middle">\n';
		'\t\t\t\t<input type="submit" name="Action" value="Move Up">\n';
		'\t\t</td>\n';



		// Left and Right
		'\t\t<td width="20" class="ghost" valign="middle">' (Field:'lft') '</td>\n';
		'\t\t<td width="20" class="ghost" valign="middle">' (Field:'rgt') '</td>\n';
		'\t</tr>\n';
		'</table><!-- 262 -->\n';

		'\t</form>\n';

		// Output closing div for root node
		If: (($NextLoopDepth) == '0') && ($OutputCloseDiv == true);
			'</div><!-- ID '(Field:'id')'-->\n';
			$OutputCloseDiv = false;
		/If;

		If: $svDebug == 'Y';
			'<tr><td colspan="11"><p class="debug">147: ThisNodeDepth = ' ($ThisNodeDepth) '<br>\n';
			'147: NextLoopDepth = ' ($NextLoopDepth) '<br>\n';
			'147: OutputCloseDiv = ' ($OutputCloseDiv) '</p>\n';
			'</td></tr>\n';
		/If;

	/Records;

/Inline;

	// Add New Root Level
	'<table width="80%" bgcolor="#FFFFFF">\n';
	'\t<tr>\n';
	'\t\t<td colspan="11"><hr size="4"></td>\n';
	'\t</tr>\n';
	'\t<tr>\n';
	'\t\t<td colspan="11"><h2>Add New Root Level</h2>\n';
// Standard Error Table
If: (Var:'vError') == '1004' && (Var:'vOption') == 'root node';
	LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');
/If;
	'\t\t</td>\n';
	'\t</tr>\n';
	'\t<tr bgcolor="#F5F5F5">\n';
	'\t\t<td class="tabletext_11_black" colspan="11">\n';
	'\t\t\t<form action="/admin/setup_addresponse.lasso" method="post">\n';
	'\t\t\t\t<input type="hidden" name="DataType" value="Node">\n';
	'\t\t\t\t<input type="hidden" name="New" value="Y">\n';
	'\t\t\t\t<strong>New Root Level</strong>: <input type="text" name="NewRootName" value="' (Var:'vNewRootName') '" size="12" maxlength="64">\n';
	'\t\t\t\t<input type="submit" name="Action" value="Add New Root"> <strong>NOTE:</strong> This option is used infrequently, and only used if you want a new root level.\n';
	'\t\t\t</form>\n';
	'\t\t</td>\n';
	'\t</tr>\n';
	'\t<tr>\n';
	'\t\t<td colspan="11"><hr size="4"></td>\n';
	'\t</tr>\n';
	'</table>\n';

// Security check
Else;

	Var:'vError' = '6004';

// Cobble together a page; This is done like this because the Heirarchy page is a different format
?>
<table width="780">
	<tr>
		<td width="170">
			[Include:($svLibsPath)'navbar_main.inc']
		</td>
		<td>
			<div class="contentcontainerwhite">
<?Lassoscript

		// Standard Error Table
		LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption');

		Include:'frm_login.inc';
?>
		</td>
	</tr>
</table>
[/If]
[Include:($svIncludesPath)'build_footer.inc']
[OutputFooter]
</body>
[LI_CMSatend]
</html>
