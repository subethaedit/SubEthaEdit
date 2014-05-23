<?Lassoscript
// Last modified 8/11/10 by ECL, Landmann InterActive

// CHANGE NOTES
// 2/18/08
// Reworked for CMS 3.0
// Totally new URL Handler that uses text-only paths
// e.g.: http://devel.landmanninteractive.com/news/new-site-launches/chalmers-jewelers
// 4/3/08
// Added code for URL Fix (Issue #547). Now using $ThisLevelNameSlug, $ThisNodeNameSlug and $vURLSlug
// 1/26/09
// Tweaked HTML output. No functionality changes.
// 11/24/09
// Add ShowInNav check - ShowInNav must be == Y for content page to display in dropdown
// 12/9/09
// Added SortOrder to Content query
// 8/11/10
// Tweaked the close div output

// NOTES
// Indent levels are controlled by a stylesheet named indent[indentlevel] that matches the depth of the heirarchy. See cms.css.

// This hack saves the debug status, then we turn it off until restored
Var:'DebugStatus' = $svDebug;

// Debugging
// Var:'svDebug' = 'Y';

/* ----------------------------------------- */
/* --- LEFT NAV CONTENT -------------------- */
/* ----------------------------------------- */
Var:'FinalLeftNavContent' = string;
$FinalLeftNavContent = '<!-- START build_nav -->\n<br>\n';

// Get the entire navigation heirarchy
Var:'SQLSelectFullNode' = '/* Select full node */
	SELECT node.id, node.name, node.HeirarchySlug,
	(COUNT(parent.name) - 1) AS depth
	FROM ' $svHeirarchyTable ' AS node, ' $svHeirarchyTable ' AS parent
	WHERE node.lft BETWEEN parent.lft AND parent.rgt
	AND node.Active = "Y"
	GROUP BY node.id
	ORDER BY node.lft';

Inline: $IV_Heirarchy, -SQL=$SQLSelectFullNode, -Table=$svHeirarchyTable;

	If: $svDebug == 'Y';
		'<p class="debug">\n';
		'Found_Count = ' (Found_Count) '<br>\n';
		'Error_CurrentError = ' (Error_CurrentError) '<br>\n';
		'SQLSelectFullNode = ' ($SQLSelectFullNode) '<br>\n';
		'Records_Array = ' (Records_Array) '</p>\n';
	/If;

	// Used to determine whether or not to output the final </div>
	Var:'OutputCloseDiv' = false;
	// Used to define the ParentID of the record being examined
	Var:'ParentID' = integer;

	// START container for left navbar
	$FinalLeftNavContent += '<div class="leftnavcontainer">\n';

	// Include the Quicksearch form
	$FinalLeftNavContent += (Include:($svIncludesPath)'frm_quicksearch.inc');
	
	Records;
		// Looking ahead to next record to see if we should output the closing div
		Var:'NextLoopCount' = (Math_Add:(Loop_Count),1);
		Protect;
			Var:'NextLoopDepthTemp' = (Records_Array->Get:$NextLoopCount);
		/Protect;
		Var:'NextLoopID' = ($NextLoopDepthTemp->Get:2);
		Var:'NextLoopDepth' = ($NextLoopDepthTemp->Get:3);
		If: $NextLoopDepth == 0;
			$OutputCloseDiv = true;
		/If;		

/*		If: $svDebug == 'Y';
			'<p class="debug">\n';
//			'56: Loop_Count = ' (Loop_Count) '<br>\n';
//			'56: NextLoopCount = ' ($NextLoopCount) '<br>\n';
//			'56: NextLoopCount->Get:2 = ' (Records_Array->Get:$NextLoopCount) '<br>\n';
//			'56: NextLoopID = ' ($NextLoopID) '<br>\n';
//			'56: NextLoopDepth = ' ($NextLoopDepth) '<br>\n';
//			'56: OutputCloseDiv = ' ($OutputCloseDiv) '<br>\n';
			'56: ID = ' (Field:'id') '<br>\n';
			'56: vContentHeirarchyID = ' $vContentHeirarchyID '</p>\n';
			'</p>\n';
		/If;
*/
		// Copy depth to ThisNodeDepth
		Var:'ThisNodeDepth' = (Field:'depth');

		If: $ThisNodeDepth == 0;

			// Define whether to show or hide the lower levels for this category
			// Here we check if the Heirarchy ID matches the record being examined, OR if the RootID for this level matches the record being examined
			// $vHeirarchyID and $vRootID come from urlhandler.inc
			If: ((Var:'vHeirarchyID') == (Field:'id')) || (Var:'vRootID') == (Field:'id');
				Var:'ShowThisLevel' = 'show';
				Var:'ShowThisClass' = 'on';
//				Var:'ThisLevelName' = (Field:'name');
			Else;
				Var:'ShowThisLevel' = 'hide';
				Var:'ShowThisClass' = 'off';
//				Var:'ThisLevelName' = (Field:'name');
			/If;

			Var:'ThisLevelNameSlug' = (Field:'HeirarchySlug');

			If: $svDebug == 'Y';
				$FinalLeftNavContent += '<p class="debug">\n';
				$FinalLeftNavContent += '88: ID = ' (Field:'id') '<br>\n';
				$FinalLeftNavContent += '88: vHeirarchyID = ' $vHeirarchyID '<br>\n';
				$FinalLeftNavContent += '88: ShowThisLevel = '($ShowThisLevel)'</p>';
			/If;

			// Add a horizontal rule at the top of all but the first
			If: (Loop_Count) > 1;
				$FinalLeftNavContent += '</div><!-- 118a -->\n';
				$FinalLeftNavContent += '<hr class="leftnav">\n';
			Else((Loop_Count) == 1);
				$FinalLeftNavContent += '</div><!-- 118b -->\n';
			/If;
			// Output the opening indent0 node
//			$FinalLeftNavContent += '<p class="indent0'($ShowThisClass)'"><!-- 102 -->';
			If: $svDebug == 'Y';
				$FinalLeftNavContent += '<span class="ghost">ID = '(Field:'ID')'&nbsp;</span>';
			/If;

			// Copy the Node Head
			Var:'ThisNodeName' = (Field:'name');
			Var:'ThisNodeNameSlug' = (Field:'HeirarchySlug');

			// Look for content for this Heirarchy node
			// Display page links ONLY if there is MORE THAN ONE content page. If only one page, don't display it.
			Var:'SQLGetContentCount' = 'SELECT COUNT(ID) AS ContentCount, ID, Headline, URLSlug
FROM '$svSiteDatabase'.'$svContentTable'
WHERE HeirarchyID = "' (Field:'id') '"
AND Active="Y" AND ShowInNav="Y" GROUP BY ID
ORDER BY SortOrder ASC';

			Inline: $IV_Content, -SQL=$SQLGetContentCount;

				// Only one record, display the head only
				If: (Found_Count) == 1;
// Disabled - not used here
//					Var:'ContentIDLink' = (Field:'id');
//					Var:'vHeadline' = (Field:'Headline');
					// Display the Node Head
					$FinalLeftNavContent += ('<p class="indent'($ThisNodeDepth)($ShowThisClass)'"><!-- 121 Node Name --><strong>');
					$FinalLeftNavContent += ('<a href="/'(String_LowerCase:(Encode_URLPath:($ThisNodeNameSlug)))'" class="LeftColLink">'($ThisNodeName)'</a></strong></p>\n');
				// More than one link, display a list of links
				Else;
					// Display the Node Head
					$FinalLeftNavContent += ('<p class="indent'($ThisNodeDepth)($ShowThisClass)'"><!-- 136 Node Name --><strong>');
					$FinalLeftNavContent += ('<a href="/'(String_LowerCase:(Encode_URLPath:($ThisNodeNameSlug)))'" class="LeftColLink">'($ThisNodeName)'</a></strong></p>\n');
					// Display records if it is the current heirarchy node
					If: $ShowThisLevel == 'show';

						Records;
							Var:'ContentIDLink' = (Field:'id');
							Var:'vHeadline' = (Field:'Headline');
							Var:'vURLSlug' = (Field:'URLSlug');
							If: $svDebug == 'Y';
								$FinalLeftNavContent += '<span class="ghost">135: ContentIDLink = '($ContentIDLink)'&nbsp;</span>';
							/If;
							// Change the style to linkcurrentpage if this page is the current page
							If: $vID == $ContentIDLink;
								$FinalLeftNavContent += ('<a href="/'(String_LowerCase:(Encode_URLPath:($ThisLevelNameSlug))'/'(Encode_URLPath:($vURLSlug)))'" class="indent'($ThisNodeDepth)'"><span class="linkcurrentpage">'($vHeadline)'</span></a><br>\n');
							Else;
								$FinalLeftNavContent += ('<a href="/'(String_LowerCase:(Encode_URLPath:($ThisLevelNameSlug))'/'(Encode_URLPath:($vURLSlug)))'" class="indent'($ThisNodeDepth)'">'($vHeadline)'</a><br>\n');
							/If;
						/Records;
					/If;
				/If;
			/Inline;

 			$FinalLeftNavContent += ('<div id="Category'(Field:'id')'">\n');
			$OutputCloseDiv = true;

		/If;

		If: $ThisNodeDepth != 0;

			// Show only if $ShowThisLevel = show
			If: $ShowThisLevel == 'show';

				// Uncomment to output bullets to indicate level if not a root node
				// '<strong>';
				// Loop: ($ThisNodeDepth); '&bull;&nbsp;'; /Loop;
				// '</strong>';
				// Loop: ($ThisNodeDepth); '&nbsp;&nbsp;'; /Loop;
	
				If: $svDebug == 'Y';
					$FinalLeftNavContent += '<span class="ghost">171: HeirarchyID = '(Field:'id')'</span><br>\n';
				/If;

				// Copy the Node Head
				Var:'ThisNodeName' = (Field:'name');

				// Look for content for this Heirarchy node
				// Display link ONLY if there is a content page
				Var:'SQLGetContentCount' = 'SELECT COUNT(ID) AS ContentCount, ID, HeirarchyID, Headline, URLSlug
FROM '$svSiteDatabase'.'$svContentTable'
WHERE HeirarchyID = "' (Field:'id') '"
AND Active="Y"  AND ShowInNav="Y" GROUP BY ID
ORDER BY SortOrder ASC';
				Inline: $IV_Content, -SQL=$SQLGetContentCount;
					If: (Found_Count) > 0;
					// Display the Node Head
						$FinalLeftNavContent += ('<p class="indent'($ThisNodeDepth)'"><!-- 168 Node Name --><strong>'($ThisNodeName)'</strong></p>\n');
						Records;
							Var:'ContentIDLink' = (Field:'id');
							Var:'HeirarchyID' = (Field:'HeirarchyID');
							Var:'vHeadline' = (Field:'Headline');
							Var:'vURLSlug' = (Field:'URLSlug');
							If: $svDebug == 'Y';
								$FinalLeftNavContent += '<span class="ghost">175: ContentIDLink = '($ContentIDLink)'</span><br>\n';
							/If;

//							If: $svDebug == 'Y';
//								$FinalLeftNavContent += '<span class="ghost">192: ParentIDMap = '($ParentIDMap)'</span><br>\n';
//								$FinalLeftNavContent += '<span class="ghost">192: ParentID = '($ParentID)'</span><br>\n';
//							/If;

							// Clean the URLSlug - Replace spaces with dashes
							Local:'out' = ($ContentPathMap->(find:($ContentIDLink)));
								#out->replace(' ','-');
								// Replace periods and percent marks
								// #out->replace('.','&#46;')&replace('%5c','&#92;');
							Var:'LinkContentPath' = (String_LowerCase:(#out));
							
							If: $svDebug == 'Y';
								$FinalLeftNavContent += '<span class="ghost">201: LinkContentPath = '($LinkContentPath)'</span><br>\n';
							/If;

							// Change the style to linkcurrentpage if this page is the current page
							If: $vID == $ContentIDLink;
								$FinalLeftNavContent += ('<a href="'($LinkContentPath)'" class="indent'($ThisNodeDepth)'"><span class="linkcurrentpage">'($vHeadline)'</span></a><br>\n');
							Else;
								$FinalLeftNavContent += ('<a href="'($LinkContentPath)'" class="indent'($ThisNodeDepth)'">'($vHeadline)'</a><br>\n');
							/If;
						/Records;
					/If;
				/Inline;
			/If;
		/If;

//		If: $svDebug == 'Y';
//			'147: ThisNodeDepth = ' ($ThisNodeDepth) '<br>\n';
//			'147: NextLoopDepth = ' ($NextLoopDepth) '<br>\n';
//			'147: OutputCloseDiv = ' ($OutputCloseDiv) '<br>\n';
//		/If;

		// Output closing div for indent0 node
		If: (($NextLoopDepth) == '0') && ($OutputCloseDiv == true);
			$FinalLeftNavContent += ('</div><!-- '(Field:'name')'-->\n');
			$OutputCloseDiv = false;
		/If;
	/Records;

/Inline;
$FinalLeftNavContent += '<!-- END build_nav -->\n';

// END container for left navbar
$FinalLeftNavContent += '</div><!-- leftnavcontainer -->\n';

// Restore Debugging
Var:'svDebug' = Var:'DebugStatus';

?>
