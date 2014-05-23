<?Lassoscript
// Last modified 11/29/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file builds maps and arrays for the heirarchy and content
// It is used primarily by the urlhandler

// CHANGE NOTES
// 3/8/10
// First implementation. This code was pulled verbatim from the urlhandler so it could be called in a few different places.
// 11/29/10
// Adding date range functionality

// (Content_Body) += '<b>START build_heirmaps</b><br>\n';
'<!-- START build_heirmaps -->\n';

Output_None;

		// Initialize vars
		// Some are set to "null" so we don't wind up with a value of 0, which screws up conditonals
		Var:'vHeirarchyID' = null;			// Contains the ID of the Heirarchy level for this page
		Var:'vID' = null;					// Contains the ID of the Content page from the Content table
		Var:'HeirarchyIDKey' = null;		// Used to fetch the ID of the Heirarchy level if there is no Content page
		Var:'IsRoot' = boolean;				// Set to true if the requested page is at the root heirarchy level
		Var:'URLLabel' = string;			// Used to output the URL Label
		Var:'URLLabelArray' = array;		// Used to store breadcrumb-style data
		Var:'ThisFieldDepth' = integer;		// Depth of the current record being examined
		Var:'LastFieldDepth' = integer;		// Used to check the depth of the record BEFORE the one being examined
		Var:'NextLoopCount' = integer;		// A counter
		Var:'PrevName' = string;			// Used to manipulate the name on the link
		Var:'LevelDifference' = integer;	// Used to calculate the numeric difference between levels
	
		// Used to store a map of Heirarchy ID and "full" heirarchy address
		// SAMPLE DATA
		// $URLLabelMap = map: (28)=(/Products/Graphics Finder);

		// Used to output the skeleton of page links - FOR VISUALIZATION PURPOSES ONLY, not used in live site
		// Var:'URLSkeleton' = string;
	
		// Create a map for the full URL and ContentID, key is the PATH
		// USAGE: Use this to look up the Content ID **when the path is known**
		// SAMPLE DATA
		/* $ContentIDMap = map:
			(/eCommerce/eCommerce)=(6),
			(/Contact/Contact)=(7),
			(/Content Management/Steven Behrend Photography)=(10),
			(/Products/MyPass/Mypass Launched)=(58),
			(/Products/LBT/Issue Tracking)=(67),
			(/News/New Site Launches/Chalmers Jewelers)=(77),
			(/Custom Development/USBank)=(89) */
	
		// Create a map for the full URL and ContentID, key is the ID
		// USAGE: This is used to get the URL link **when the ContentID is known**
		//        It is the opposite of $ContentIDMap
		// SAMPLE DATA
		/* $ContentPathMap = map:
			(6)=(/eCommerce/eCommerce),
			(7)=(/Contact/Contact),
			(10)=(/Content Management/Steven Behrend Photography),
			(58)=(/Products/MyPass/Mypass Launched),
			(67)=(/Products/LBT/Issue Tracking),
			(77)=(/News/New Site Launches/Chalmers Jewelers),
			(89)=(/Custom Development/USBank) */
	
		// Create an array to hold all ContentIDs and their headlines
		// USAGE:
		// SAMPLE DATA
		/* $ContentHeadMap = map: (2)=(Client Area), (3)=(Specialized Application Development), (4)=(Design & Authoring), (5)=(Content Management System), (6)=(eCommerce), (7)=(Contact), (10)=(Steven Behrend Photography), (20)=(Graphics Finder v. 2 Released), (27)=(KEE Architecture), (52)=(WisCondos), (53)=(Workgroup Digital Assets Management), (60)=(New Online Service Launched), (58)=(Mypass Launched), (59)=(Brass Light Gallery), (66)=(Eric Landmann Speaks at Lasso Summit 06), (68)=(Software Products for IT and Graphics Professionals), (77)=(Chalmers Jewelers), (84)=(Brass Light Gallery Online Store), (92)=(Staff and Testimonials), (89)=(USBank), (110)=(Green County Habitat for Humanity), (106)=(New Developments at Landmann InterActive), (111)=(Granite Publishing), (109)=(Would you like an easy way to control your website?), (116)=(Eric Landmann Presents at Lasso Summit 07), (117)=(Green County Habitat for Humanity), (118)=(Hestad Law), (119)=(Chalmers Jewelers), (130)=(Graphics Finder v. 3.1 Released), (125)=(Bonjour Barber and Styling Salon), (131)=(World Travel Images), (126)=(Destree Consulting), (132)=(Associated Machinery Sales), (128)=(Video On Your Site), (129)=(News Items of Interest) */
	
		// Create an array for the HeirarchyID and all ContentIDs that are connected to that HeirarchyID
		// USAGE: This is to see if there are any content pages connected to a particular HeirarchyID
		// SAMPLE DATA
		/* $ContentHeirIDMap = map: (2)=(array: (5), (10), (27), (110), (111), (118), (119), (125), (126)), (23)=(array: (3), (59), (52), (89)), (24)=(array: (109)), (30)=(array: (20), (130)), (25)=(array: (4)), (31)=(array: (60)), (26)=(array: (68)), (32)=(array: (66), (116)), (28)=(array: (53)), (34)=(array: (77), (117)), (29)=(array: (106)), (40)=(array: (7)), (41)=(array: (58)), (42)=(array: (6), (84), (131), (132)), (38)=(array: (92)), (39)=(array: (2)), (62)=(array: (128)), (67)=(array: (129)) */
	
		// Copy Response_Filepath to var for processing. Use decode_urlpath
		Var:'ResponseFilepathEval' = (String_LowerCase:((Decode_URLPath:(Response_Filepath))));
	
		// Log ResponseFilepathEval
		// Log_Critical: 'urlhandler 58: ' ($svDomain)' -- ResponseFilepathEval = ' ($ResponseFilepathEval);
	
	
		// TESTING OVERRIDE
		// $ResponseFilepathEval = '/Products/Graphics Finder/Workgroup Digital Assets Management';
	
		Var:'SQLSelectFullNode' = '/* urlhandler.inc - Select full node */
			/* SELECT node.id, node.name, */
			/* (COUNT(parent.name) - 1) AS depth */
			SELECT node.id, node.HeirarchySlug,
			(COUNT(parent.HeirarchySlug) - 1) AS depth
			FROM ' $svHeirarchyTable ' AS node, ' $svHeirarchyTable ' AS parent
			WHERE node.lft BETWEEN parent.lft AND parent.rgt
			AND node.Active = "Y"
			GROUP BY node.id
			ORDER BY node.lft';
		
		Inline: $IV_Heirarchy, -SQL=$SQLSelectFullNode, -Table=$svHeirarchyTable;
		
//			(Content_Body) += '<p class="debug">\n';
//			(Content_Body) += 'Found_Count = ' (Found_Count) '<br>\n';
//			(Content_Body) += 'Error_CurrentError = ' (Error_CurrentError) '<br>\n';
//			(Content_Body) += 'SQLSelectFullNode = ' ($SQLSelectFullNode) '<br>\n';
//			(Content_Body) += 'Records_Array = ' (Records_Array) '</p>\n';
	
			Records;
		
				Local('ThisHeirID' = (Field:'id'));
				$NextLoopCount = (Math_Add:(Loop_Count),1);
				$ThisFieldDepth = (Field:'depth');
		
				Protect;
					Var:'NextFieldDepthTemp' = (Records_Array->Get:$NextLoopCount);
				/Protect;
				Var:'NextLoopID' = ($NextFieldDepthTemp->Get:2);
				Var:'NextFieldDepth' = ($NextFieldDepthTemp->Get:3);
		
				// Calculate the diffference between levels
				$LevelDifference = (Math_Sub: $ThisFieldDepth, $LastFieldDepth);
	
//				(Content_Body) += '<p class="debug">\n';
//				(Content_Body) += '122: LastFieldDepth = ' $LastFieldDepth '<br>\n';
//				(Content_Body) += '122: ThisFieldDepth = ' $ThisFieldDepth '<br>\n';
//				(Content_Body) += '122: NextFieldDepth = ' $NextFieldDepth '<br>\n';
//				(Content_Body) += '122: LevelDifference = ' ($LevelDifference) '<br>\n';
//				(Content_Body) += '122: PrevName = ' ($PrevName) '</p>\n';
	
				// If depth = 0, OVERWRITE the URLLabel
				If: $ThisFieldDepth == 0;
	
					$URLLabel = '/' (Field:'HeirarchySlug');
		
					// REINITIALIZE the array
					$URLLabelArray = array;
					$URLLabelArray->insert:(('/')(Field:'HeirarchySlug'));
	
					// UPDATE THE MAP
					$URLLabelMap->(insertpair:(#ThisHeirID) = (('/')(Field:'HeirarchySlug')));
	
				Else;
					If: $LastFieldDepth == $ThisFieldDepth;
	
						// Add current name to the label
						$URLLabel += '/' (Field:'HeirarchySlug');
						// Remove old name from the label
						$URLLabel->RemoveLeading:('/'($PrevName));
						
						// Remove previous name from the array
						$URLLabelArray->RemoveLast;
						// Add current name to the array
						$URLLabelArray->insert:(('/')(Field:'HeirarchySlug'));
						
						// Update the map
						Var:'InsertThis' = string;
							 Iterate: $URLLabelArray, (Var:'myItem'); 
								$InsertThis += $myItem; 
							 /Iterate; 
						$URLLabelMap->(insertpair:(#ThisHeirID) = ($InsertThis));
	
					Else: $LastFieldDepth > $ThisFieldDepth;
	
						// REMOVE the previous name
						$URLLabel->RemoveTrailing:('/'($PrevName));
						// CONCATONATE the existing name
						$URLLabel += '/' (Field:'HeirarchySlug');
		
						// REMOVE the previous name from the array
						Var:'LevelDifferenceLoop' = (Math_Abs:$LevelDifference);
						// Add one for fencepost error
						$LevelDifferenceLoop = (Math_Add:$LevelDifferenceLoop, 1);
						Loop: $LevelDifferenceLoop;
							$URLLabelArray->RemoveLast;
						/Loop;
		
						$URLLabelArray->insert:('/' (Field:'HeirarchySlug'));
		
						// UPDATE THE MAP
						Var:'InsertThis' = string;
							 Iterate: $URLLabelArray, (Var:'myItem'); 
								$InsertThis += $myItem; 
							 /Iterate; 
						$URLLabelMap->(insertpair:(#ThisHeirID) = ($InsertThis));
	
					Else: $LastFieldDepth < $ThisFieldDepth;
	
						// Add current name to the label
						$URLLabel += '/' (Field:'HeirarchySlug');
						// Add current name to the array
						$URLLabelArray->insert:(('/')(Field:'HeirarchySlug'));
						// Update the map
						Var:'InsertThis' = string;
							 Iterate: $URLLabelArray, (Var:'myItem'); 
								$InsertThis += $myItem; 
							 /Iterate; 
						$URLLabelMap->(insertpair:(#ThisHeirID) = ($InsertThis));
						// Remove old name from the label
						$URLLabel->RemoveLeading:('/'($PrevName));
					/If;
				/If;
		
				// Uncomment to see the URL Skeleton
				// Create the Skeleton
				// Iterate: $URLLabelArray, (Var:'myItem');
				//	$URLSkeleton += $myItem;
				// /Iterate; 
				// $URLSkeleton += '<br>\n';
	
				// Uncomment to see data added for each loop
				// (Content_Body) += '<p class="debug"><strong>urlhandler.inc LINE 205</strong><br>\n';
				// (Content_Body) += '<b>LABEL</b> URLLabel = ' ($URLLabel) '<br>\n';
				// (Content_Body) += '<b>ARRAY</b> URLLabelArray = ' ($URLLabelArray) '<br>\n';
				// (Content_Body) += '<b>MAP</b> URLLabelMap = ' ($URLLabelMap) '<br>\n';
				// (Content_Body) += '<b>SKELETON</b> URLSkeleton = ' ($URLSkeleton) '</p>\n';
	
				// Copy current name to PrevName for use in removal
				$PrevName = (Field:'HeirarchySlug');
				// Switch FieldDepth values for next cycle
				$LastFieldDepth = $ThisFieldDepth;
		
				// Create $ContentHeirIDMap
				Local('ContentTempArray' = array);
				// Define $ContentHeirMap
				Var:'SQLGetHeirMap' = 'SELECT ID FROM '$svSiteDatabase'.'$svContentTable' WHERE HeirarchyID = "' (#ThisHeirID) '"
				AND Active="Y"
				AND ShowInNav="Y"
				AND (ActiveTo >= CURDATE())
				AND ( (CURDATE() > ActiveFrom) OR (CURDATE() = ActiveFrom) )
				ORDER BY SortOrder ASC';
				Inline: $IV_Content,  -Table=$svContentTable, -SQL=$SQLGetHeirMap;
				// (Content_Body) += '258: Found_Count = ' (Found_Count) '<br>\n';
					If: (Found_Count) > 0;
						Records;
						Local('ThisContentID' = (Field:'id'));
							#ContentTempArray->(insert:(#ThisContentID));
							// (Content_Body) += '265: ContentTempArray = ' (#ContentTempArray) '<br>\n';
						/Records;
						$ContentHeirIDMap->(insert((#ThisHeirID) = (#ContentTempArray)));
					/If;
				/Inline;
	
			/Records;
		
		/Inline;
	
		// (Content_Body) += '<p class="debug"><strong>urlhandler.inc LINE 221</strong><br>\n';
		// (Content_Body) += '<b>URLLabelMap</b> = ' ($URLLabelMap) '<br>\n';
		// (Content_Body) += '<b>URLSkeleton</b> = ' ($URLSkeleton) '</p>\n';
	
		// (Content_Body) += '<h3>URL Handler</h3>\n';
		// (Content_Body) += '<p class="debug"><i>Produced by iterating $URLLabelMap, then getting content associated with each HeirarchyID</i><br>\n';
	
		// SAMPLE QUERY
		/* Get Content Records (ActiveDate) */
		/* SELECT ID, Headline, URLSlug, HeirarchyID, AttachPopup, ActiveFrom, ActiveTo
		FROM cms_content
		WHERE Active="Y"
		AND HeirarchyID = 78
		AND (ActiveTo >= CURDATE())
		AND ( (CURDATE()) > ActiveFrom OR ( CURDATE() = ActiveFrom)  )
		ORDER BY SortOrder ASC */
		Iterate: $URLLabelMap, (Var:'myItem'); 
			Var:'MyItemID' = ($myItem->Get:1);
			Var:'MyItemLabel' = ($myItem->Get:2);
			Var:'SQLGetContent' = 'SELECT ID, Headline, URLSlug, HeirarchyID, AttachPopup FROM '$svSiteDatabase'.'$svContentTable' WHERE HeirarchyID = "' ($MyItemID) '"
			AND Active="Y"
			AND (ActiveTo >= CURDATE())
			AND ( (CURDATE() > ActiveFrom) OR (CURDATE() = ActiveFrom) )
			ORDER BY SortOrder ASC';
			Inline: $IV_Content,  -Table=$svContentTable, -SQL=$SQLGetContent;
				If: (Found_Count) > 0;
					Records;		
						Var:'vContentID' = (Field:'ID');
						Var:'HasPopup' = (Field:'AttachPopup');
						// (Content_Body) += '<span class="ghost"><b>HeirarchyID ' ($MyItemID) '</b></span><br>\n';
						// (Content_Body) += '<span class="ghost"><b>ContentID ' ($vContentID) '</b></span><br>\n';
						($myItemLabel)('/')(Field:'URLSlug');
						// Insert the ID and URL into the maps
						$ContentIDMap->(insert:(($MyItemLabel)('/')(Field:'URLSlug')) = ($vContentID));
						// Decorate link with Contact Popup but ONLY if not a bot
						If(($HasPopup == 'Y') && ((lp_client_isBot) == false));
							$ContentPathMap->(insert:($vContentID) = (('/contact_popup.lasso?GoTo=')($MyItemLabel)('/')(Field:'URLSlug')));
						Else;
							$ContentPathMap->(insert:($vContentID) = (($MyItemLabel)('/')(Field:'URLSlug')));
						/If;
						$ContentHeadMap->(insert:($vContentID) = (Field:'Headline'));
						// (Content_Body) += '</p>\n';
					/Records;
				/If;
			/Inline;
		/Iterate;
	
		// TESTING OVERRIDE
		// $ResponseFilepathEval = '/Custom Development';
		// $ResponseFilepathEval = '/Custom Development/USBank';
	
		// (Content_Body) += '<p class="debug"><strong>urlhandler.inc LINE 253</strong><br>\n';
		// (Content_Body) += '<b>ResponseFilepathEval</b> = "' ($ResponseFilepathEval) '"<br>\n';
		// (Content_Body) += '<b>ContentIDMap</b> = ' ($ContentIDMap) '<br>\n';
		// (Content_Body) += '<b>ContentPathMap</b> = ' ($ContentPathMap) '<br>\n';
		// (Content_Body) += '<b>ContentHeirIDMap</b> = ' ($ContentHeirIDMap) '<br>\n';
		// (Content_Body) += '<b>ContentHeadMap</b> = ' ($ContentHeadMap) '</p>\n';
	
		// FIND ID from the Path
		// (Content_Body) += '<h3>FIND IDs from the Path</h3>\n';
		Var:'vID' = ($ContentIDMap->(find:$ResponseFilepathEval));
		// (Content_Body) += '<p class="debug"><strong>urlhandler.inc LINE 275</strong><br>\n';
		// (Content_Body) += '273: vID from ContentIDMap = ' ($vID) '<br>\n';
	
		// Now look up the Heirarchy ID associated with that Content record
		(Var:'vHeirarchyID') = (LI_GetHeirarchyID: -ID=$vID);
		// (Content_Body) += '277: vHeirarchyID = ' (Var:'vHeirarchyID') '<br>\n';
	
		// If vID is empty, it is not a content page, so look up the Heirarchy page
		// This is passed to the content page to look up the default content page for that heirarchy level
		If: $vID == '';
			// (Content_Body) += '<i>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;282: vID BLANK, look up HeirarchyIDKey</i><br>\n';
			Var:'HeirarchyIDKey' = ($URLLabelMap->(findkeys:$ResponseFilepathEval));
			// Protect from "Get" error
			Protect;
				Var:'vHeirarchyID' = ($HeirarchyIDKey->Get:1);
			/Protect;
	
			// If there was none, define it to be zero
			If: $vHeirarchyID == '';
				$vHeirarchyID = 0;
				// (Content_Body) += '<i><font color="red">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;280: HeirarchyIDKey NOT defined, setting $vHeirarchyID to zero</font></i><br>\n';
			/If;
	
		Else;
			// (Content_Body) += '<i>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;282: vID is defined</i><br>\n';
		/If;
	
		// (Content_Body) += '296: vHeirarchyID = ' (Var:'vHeirarchyID') '</p>\n';
	
		// Finally look up the RootID, which is the highest level in this heirarchy
		Var:'RootIDMap' = (xs_cat->getParent: -cattable=$svHeirarchyTable, -ID=$vHeirarchyID);
		// FIND RootID in RootIDMap
		Var:'vRootID' = ($RootIDMap->(find:'ID'));
		Var:'IsRoot' = (var:'vRootID') == '' ? true | false;
		// (Content_Body) += '<p class="debug"><strong>urlhandler.inc LINE 302</strong><br>\n';
		// (Content_Body) += '302: RootIDMap = '($RootIDMap)'<br>\n';
		// (Content_Body) += '302: vRootID = '($vRootID)'<br>\n';
		// (Content_Body) += '302: IsRoot = '($IsRoot)'</p>\n';
	
		// TESTING
		// Find Path from the ID
		// (Content_Body) += '<h3>FIND Path from the ID</h3>\n';
		// Var:'vID' = 89;
		// (Content_Body) += '<b>299: vID SET MANUALLY (testing)</b> = ' ($vID) '<br>\n';
		// Var:'vID_ContentPathMap' = ($ContentPathMap->(find:$vID));
		// (Content_Body) += '<b>299: vID_ContentPathMap</b> = ' ($vID_ContentPathMap) '</p>\n';
		// Log Request
		// Log_Critical: 'urlhandler: END Response_Filepath = ' (Response_Filepath);
		// (Content_Body) += include:($svLibsPath)'vardumpalpha.lasso';

/Output_None;

// (Content_Body) += '<b>END build_heirmaps</b><br>\n';
'\n<!-- END build_heirmaps -->\n';

?>
