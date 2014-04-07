<?Lassoscript
// Last modified 7/28/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file builds a Google sitemap

// Debugging
Var('svDebug' = 'N');

Output_None;
// TESTING ONLY
//	Include:'/urlhandlerTEST.inc';
	Include:'/urlhandler.inc';
/Output_None;

// Include: '/site/libs/page_header_devel.inc';
	
// Used to hold the HTML
Var('SitemapHTML' = string);

// Used to hold the final Google sitemap
Var('mySiteMap' = null);

// Used to hold an array of all the links in the site
// The array consists of an indention level used for building unordered lists, a delimiter (|||), and the URL path
// Level 0 = root level
// SAMPLE DATA
/* SitemapArray = array: (0|||home), (0|||features), (1|||/features/features-overview), (1|||/features/gallery-demo), (1|||features/front-end), (2|||/features/front-end/front-end-features), (1|||features/back-end), (2|||/features/back-end/back-end-features), (0|||documentation), (0|||license), (0|||about) */
Var('SitemapArray' = array);

// Control var used to determine whether we are in a root level
Var('InsideUL' = false);

// Used for the final link in the URL
Var('LinkContentPath' = string);

// Used to hold the previous heirarchy path, used to build the URL
Var('PrevLevel' = string);

// Used to determine the level of indention in the navigation
// This will be processed to create the unordered list
Var('ThisNavDepth' = integer);

// Get the entire navigation heirarchy (Active nodes only)
Var('SQLSelectFullNode' = '/* Select full node */
	SELECT node.id, node.name, node.HeirarchySlug,
	(COUNT(parent.name) - 1) AS depth
	FROM ' ($svHeirarchyTable) ' AS node, ' ($svHeirarchyTable) ' AS parent
	WHERE node.lft BETWEEN parent.lft AND parent.rgt
	AND node.Active = "Y"
	GROUP BY node.id
	ORDER BY node.lft');

Inline: $IV_Heirarchy, -SQL=$SQLSelectFullNode, -Table=$svHeirarchyTable;

Var('mySiteMap' = google_sitemap);

	If: $svDebug == 'Y';
		$SitemapHTML += '<-- START $SitemapHTML -->\n';
		$SitemapHTML += '<p class="debug">\n';
		$SitemapHTML += 'ProcessCleanURLs = ' ($ProcessCleanURLs) '<br>\n';
		$SitemapHTML += 'Found_Count = ' (Found_Count) '<br>\n';
		$SitemapHTML += 'Error_CurrentError = ' (Error_CurrentError) '<br>\n';
		$SitemapHTML += 'SQLSelectFullNode = ' ($SQLSelectFullNode) '<br>\n';
		$SitemapHTML += 'URLLabelMap = ' ($URLLabelMap) '<br>\n';
		$SitemapHTML += 'Records_Array = ' (Records_Array) '</p>\n';
		$SitemapHTML += 'ContentHeirIDMap = ' ($ContentHeirIDMap) '</p>\n';
	/If;

	Var('IndentLevel' = 0);

	Records;

		Var('ThisHeirarchyID' = (Field:'id'));
		Var('ThisDepth' = (Integer(Field:'depth')));
		Var('ThisHeirarchyName' = (Field:'name'));
		Var('ThisNodeNameSlug' = (Field:'HeirarchySlug'));
		Var('MyItemURLPath' = string);

		// LOOK AHEAD for content pages
		// Set to true when ths Heirarchy level has content pages
		Local('HasContent' = boolean);
		Var('MyItemID' = ($ContentHeirIDMap->(find($ThisHeirarchyID))));
		// Used to see if there is more than one content page for this Heirarchy ID
		// If there is more than one page, the array size will be > 1
		Var('MyItemSize' = $MyItemID->size);

		// Set #HasContent to true if this Hierarchy ID has content
		Local('HasContent' = (Var('MyItemID') != '') ? true | false);

		// Manufacture the links
		If(#HasContent == true);

			// Assign ThisDepth to ThisNavDepth
			$ThisNavDepth = $ThisDepth;

			// Always make the link the Heirarchy Name for Depth 0 menu items
			If: $MyItemSize == 1 && $ThisDepth == 0;
				// Clean the URLSlug - Replace spaces with dashes
				// Note: Path has been modified by prefixing tthe heirarchy name
				If: $PrevLevel == $ThisNodeNameSlug;
					If: (Loop_Count) == 1;
						Local('out' = ($ThisNodeNameSlug));
					Else;
						Local('out' = (($PrevLevel)+'/'+($ThisNodeNameSlug)));
					/If;
				Else;
					Local('out' = ($ThisNodeNameSlug));
				/If;
				#out->replace(' ','-');
				$LinkContentPath = (String_LowerCase:(#out));

				// Add leading slash for root level links
				// WATCH IT - Modifies $LinkContentPath IN PLACE
				If: !($LinkContentPath->BeginsWith('/'));
					Var('LinkContentPath' = (('/')+$LinkContentPath));
				/If;
				// Used to look up the Content ID
				Var('LookupThisLink' = $LinkContentPath);
				
				// Insert the page into the array
				$SitemapHTML += '<!-- 114: LinkContentPath = ' $LinkContentPath ' -->\n';
				Var('ContentLinkID' = ($ContentIDMap->(find:$LookupThisLink)));
				$SitemapArray->insert(($ThisNavDepth)+'|||'+($LinkContentPath));

				$InsideUL = false;

				// Set the previous level
				Var('PrevLevel' =  ($ThisHeirarchyName));

				$SitemapHTML += '<!-- 128: Error_CurrentError = '+(Error_CurrentError)+' -->\n';
				$SitemapHTML += '<!-- 128: SitemapArray = '+($SitemapArray)+' -->\n';

			Else;
		
				// Clean the URLSlug - Replace spaces with dashes
				// Note: Path has been modified by prefixing the heirarchy name
				If($ThisDepth > 0);
					If: (Loop_Count) == 1;
						Local('out' = ($ThisNodeNameSlug));
					Else;
						Local('out' = (($PrevLevel)+'/'+($ThisNodeNameSlug)));
					/If;
				Else;
					Local('out' = ($ThisNodeNameSlug));
				/If;
				#out->replace(' ','-');
				$LinkContentPath = (String_LowerCase:(#out));

				// Add leading slash for root level links
				// WATCH IT - Modifies $LinkContentPath IN PLACE
				If: !($LinkContentPath->BeginsWith('/'));
					Var('LinkContentPath' = (('/')+$LinkContentPath));
				/If;
				// Used to look up the Content ID
				Var('LookupThisLink' = $LinkContentPath);
				
				// Insert the page into the array
				// Add leading slash for root level links
				If: !($LinkContentPath->BeginsWith('/'));
					Var('LookupThisLink' = (('/')+$LinkContentPath));
				Else;
					Var('LookupThisLink' = $LinkContentPath);
				/If;
				$SitemapHTML += '<!-- 160: LinkContentPath = ' $LinkContentPath ' -->\n';
				Var('ContentLinkID' = ($ContentIDMap->(find:$LookupThisLink)));
				$SitemapArray->insert(($ThisNavDepth)+'|||'+($LinkContentPath));

				$InsideUL = true;
		
				// Increment ThisNavDepth because now we're going deeper
				$ThisNavDepth = (Math_Add: $ThisNavDepth, 1);

				Iterate: $MyItemID, (Local:'i');
					Var('MyItemLabel' = ($ContentHeadMap->(find:(#i))));
					Var('MyItemURLPath' = ($ContentPathMap->(find:(#i))));
					// Used to look up the Content ID
					Var('LookupThisLink' = $MyItemURLPath);
					// Clean the URLSlug - Replace spaces with dashes
					Local('out' = $MyItemURLPath);
					#out->replace(' ','-');
					$LinkContentPath = (String_LowerCase:(#out));

					// Insert the page into the array
					$SitemapHTML += '<!-- 185: LinkContentPath = ' $LinkContentPath ' -->\n';
					Var('ContentLinkID' = ($ContentIDMap->(find:$LookupThisLink)));
					$SitemapArray->insert(($ThisNavDepth)+'|||'+($LinkContentPath));

					// Reset the previous level head - DO NOT MOVE
					If: (Loop_Count) != 1;
						Var('PrevLevel' =  ($ThisHeirarchyName));
					/If;

					$SitemapHTML += '<!-- 188: Error_CurrentError = '+(Error_CurrentError)+' -->\n';
					$SitemapHTML += '<!-- 188: SitemapArray = '+($SitemapArray)+' -->\n';

				/Iterate;

			/If;
		
		/If;

/*		If: $svDebug == 'Y';
			$SitemapHTML += '<!-- $InsideUL = ' ($InsideUL) ' -->\n';
			$SitemapHTML += '<!-- #HasContent = ' (#HasContent) ' -->\n';
		/If;		
*/
		// Reset $InsideUL
		If: ($ThisDepth != 0) && ($InsideUL == true);
			$InsideUL = false;
		/If;

		// Display only if this node has content -- REMOVED

		$InsideUL = false;

		If: $ThisDepth > $IndentLevel;
			$IndentLevel = $IndentLevel + 1;
		Else: $ThisDepth < $IndentLevel;
			$IndentLevel = $IndentLevel - 1;
		Else: $ThisDepth == $IndentLevel;
			// No change to level
		/If;

	/Records;

/Inline;

Iterate: $SitemapArray, (Local('i'));

	Local('ThisElement' = ((#i)->(split('|||'))->Get('2')));
	Local('ThisElementFullURL' = ('http://'+($svDomain)+(#ThisElement)));

	$mySiteMap->addurl(
		-loc=(#ThisElementFullURL),
		-lastmod=date,
		-changefreq='always',
		-priority=1.0);

	$SitemapHTML += '<!-- 230: Error_CurrentError = '+(Error_CurrentError)+' -->\n';
	$mySiteMap->save:(response_path);

/Iterate;

Debug;
	'<strong>230 SitemapArray</strong> = ' ($SitemapArray) '<br>\n';
	'<strong>230 SitemapHTML</strong> = ' ($SitemapHTML) '<br>\n';
/Debug;

If: $svDebug == 'Y';
	Debug;
	'<br><b>$mySiteMap</b> = '+($mySiteMap)+'<br>\n';
	/Debug;
// Output the Sitemap
Else;
	$mySiteMap;
/If;

?>
