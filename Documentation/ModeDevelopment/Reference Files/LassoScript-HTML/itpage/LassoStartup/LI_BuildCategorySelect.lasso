<?Lassoscript
// Last modified 11/11/07 by ECL, Landmann InterActive

/*
Tagdocs;
	{Tagname=			LI_BuildCategorySelect }
	{Description=		Creates <select> list of all nodes in the Heirarchy }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				11/11/07 }
	{Usage=				LI_BuildCategorySelect: -Tooltip='Y'; }
	{ExpectedResults=	A <select> list of all heirarchy nodes }
	{Dependencies=		}
	{DevelNotes=		}
	{ChangeNotes=		11/11/07 - Recoded for itPage v 3.0 }
/Tagdocs;
*/

// Define the system vars
Var:'svCTNamespace' = 'LI_';
Var:'svHeirarchyTable' = 'cms_heirarchy';

If: !(Lasso_TagExists:'LI_BuildCategorySelect');

	Define_Tag: 'BuildCategorySelect',
		-Namespace = $svCTNamespace,
		-Required = 'Tooltip';
	
		Local:'Result' = string;
		Local:'DebugOutput' = string;
		Local:'SQLSelectFullNode' = string;
		
		#SQLSelectFullNode = '/* LI_BuildCategorySelect - Select full node */
			SELECT node.id, node.name,
			(COUNT(parent.name) - 1) AS depth
			FROM ' $svHeirarchyTable ' AS node, ' $svHeirarchyTable ' AS parent
			WHERE node.lft BETWEEN parent.lft AND parent.rgt
			GROUP BY node.id
			ORDER BY node.lft';
		
		Inline: $IV_Heirarchy, -SQL=#SQLSelectFullNode, -Table=$svHeirarchyTable;
		
			If: $svDebug == 'Y';
				#DebugOutput += '<p class="debugCT">\n';
				#DebugOutput += 'Found_Count = ' (Found_Count) '<br>\n';
				#DebugOutput += 'Error_CurrentError = ' (Error_CurrentError) '<br>\n';
				#DebugOutput += 'SQLSelectFullNode = ' (#SQLSelectFullNode) '<br>\n';
				#DebugOutput += 'Records_Array = ' (Records_Array) '<br>\n';
				#DebugOutput += '</p>\n';
			/If;
		
			#Result += '<select name="HeirarchyID">\n';
			#Result += '\t<option value=""';
			If: (Var:'vHeirarchyID') == '';
				#Result += ' selected';
			/If;
			#Result+= '></option>\n';
		
			Records;
		
				If: (Field:'depth') == 0;

					#Result += '\t<option value="'(Field:'ID')'" class="indent0"';
					If: (Var:'vHeirarchyID') == (Field:'ID');
						#Result += ' selected';
					/If;
					#Result+= ('>'(Field:'name')'</option>\n');
		
				Else;
		
					// This is a little oddular, but we are calling a style that matches the depth of the heirarchy
					#Result += ('\t<option value="'(Field:'ID')'"');
					If: (Var:'vHeirarchyID') == (Field:'ID');
						#Result += ' selected';
					/If;
					#Result += '>';
					// Output spaces to indicate level if not a root node
					Loop: (Field:'depth');
						#Result += '&nbsp;&nbsp;&nbsp;';
					/Loop;
					#Result += ((Field:'name')'</option>\n');
		
				/If;
		
			/Records;
		
		/Inline;
		
		#Result += '</select>\n';
		
		// Append on the ToolTip
		If: #Tooltip == 'Y';
			#Result += ('&nbsp;&nbsp;<a class="jt" href="'($svToolTipsPath)'tt_heirarchyselect.html" rel="'($svToolTipsPath)'tt_heirarchyselect.html" title="How to Use the Heirarchy"><img src="'($svImagesPath)'question_16_trans.gif" width="16" height="16" alt="question icon"></a><br>\n');
		/If;

		// If Debug on, output debugging info
		If: $svDebug == 'Y';

			#DebugOutput += '<p class="debugCT"><strong>LI_BuildCategorySelect_CT</strong><br>\n';
			#DebugOutput += 'Error_CurrentError = ' (Error_CurrentError) '<br>\n';
			#DebugOutput += 'Custom Tag Loaded - LI_BuildCategorySelect</p>\n';
			#DebugOutput += #Result;

			Return: Encode_Smart:(#DebugOutput);

		Else;
		
			Return: Encode_Smart:(#Result);

		/If;

	/Define_Tag;

	// Log tag loading
	Log_Critical: 'Custom Tag Loaded - LI_BuildCategorySelect';

/If;

?>
