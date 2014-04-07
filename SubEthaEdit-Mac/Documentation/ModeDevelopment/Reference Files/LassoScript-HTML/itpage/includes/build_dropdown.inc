<?Lassoscript
// Last modified 9/21/10 by ECL, Landmann InterActive

// FUNCTIONALITY
// This is the jQuery version of dropdown
// SITE-SPECIFIC CHANGE
// Load different jqueryslidemenu.css for normal pages

// SPECIAL DEBUGGING VERSION WITH LOTS OF TRACKING CODE
// NOTE: The removetrailing </li> does NOT work due to the debugging code, so
//     *** look for the message "Removed trailing /li" *** in the output
//
// For use with Dynamic Drive-style jQuery slider (a.k.a. "css flyout") menus
// This file creates $DropdownJS (header Javascript) and $DropdownHTML (HTML menu) for dropdowns -
//     DOES NOT OUTPUT ANYTHING.
// The variables $ContentPathMap and $ContentIDMap are established by urlhandler.inc
// and should already exist. If they don't, you've got a bigger problem!
// TO OUTPUT
// $DropdownJS SHOULD BE output by the atend handler in LI_CMSatend.lasso, but due some bizarreness is
// instead output in page_header.inc
// You must select a template for the content page that calls the dropdown, such as SB_pf5_TestBot_Dropdown.html
// TESTING
// Use the CT OutputDropdownJS to output the header JS
// Use OutputDropdownHTML to output the menu HTML

// DEPENDENCIES
// xs_cat
// jQuery SliderMenus stuff (see notes)

// NOTES
// From: <http://www.dynamicdrive.com/style/csslibrary/item/jquery_multi_level_css_menu_2/P120/>

// CHANGE NOTES
// 9/12/09 ECL
// Reworked to fix problem with secondary heiararchy levels not displaying correctly
// 9/21/09 ECL
// Added check for jqueryslidemenu2.css (client-specific stylesheet)
// 3/14/10 ECL
// Commented out unnecessary debugging code
// 6/25/10 ECL
// Adding code for contact_popup to links
// 9/21/10 ECL
// Adding check for gallery to set alternate Javascript jqueryslidemenu2.js used for different arrows.
// Also styled the link with the class "linkcurrentpage"

// Debugging
// Var:'svDebug' = 'Y';

// Used to hold the dropdown Javascript
Var:'DropdownJS' = string;

// Used to hold the dropdown HTML
Var:'DropdownHTML' = string;

// Control var used to remove trailing </li>
// Var:'InsideLI' = false;

// Control var used to determine whether we are inside of a <ul>
Var:'InsideUL' = false;

// Used for the final link in the URL
Var:'LinkContentPath' = string;

// Used to hold the previous heirarchy path, used to build the URL
Var:'PrevLevel' = string;

// Used to hold the depth that was just set previously. This will be used to check whether we are existing a /ul
Var:'PrevDepth' = 0;

// Check to see if client-specific stylesheet exists named jqueryslidemenu2.css. If it does not, use jqueryslidemenu.css.
Var:'ClientStylesheetExists' = (File_Exists:($svCSSPath+'jqueryslidemenu2.css'));

// Use this code for Dynamic Drive-style jQuery slider ("css flyout") menus
$DropdownJS = ('\t<link rel="stylesheet" type="text/css" href="'+($svCSSPath));

// Include stock jqueryslidemenu.css if $GalleryContent is defined to load the default Gallery stylesheet.
// Otherwise include jqueryslidemenu2.css as that is the client-specific stylesheet.
// Checking for a value of 0 because that is the default
If ((Var:'vGalleryGroupID') != 0);
	$DropdownJS += 'jqueryslidemenu.css';
Else;
	If: $ClientStylesheetExists == true;
		Var('UseThisStylesheet' = 'jqueryslidemenu2.css');
	Else;
		Var('UseThisStylesheet' = 'jqueryslidemenu.css');
	/If;
	$DropdownJS += $UseThisStylesheet;
/If;
$DropdownJS += ('">
	<!--[if lte IE 7]>
		<style type="text/css">
			html .jqueryslidemenu{height: 1%;} /*Holly Hack for IE7 and below*/
		</style>
	<![endif]-->\n');

// Include alternate JS if $GalleryContent is defined.
// This is done solely for the purpose of controlling the down and right arrows.
If((Var:'vGalleryGroupID') != 0);
	$DropdownJS += ('\t<script type="text/javascript" src="'+($svJSPath)+'jqueryslidemenu2.js"></script>\n');
Else;
	$DropdownJS += ('\t<script type="text/javascript" src="'+($svJSPath)+'jqueryslidemenu.js"></script>\n');
/If;

// START container for left navbar
$DropdownHTML += '<!-- START build_dropdown -->\n';
$DropdownHTML += ('<!-- vGalleryGroupID = '+(Var:'vGalleryGroupID')+'-->\n');
$DropdownHTML += '<div id="myslidemenu" class="jqueryslidemenu">\n';
$DropdownHTML += '\t<ul>\n';

// Get the entire navigation heirarchy (Active nodes only)
Var:'SQLSelectFullNode' = ('/* Select full node */
	SELECT node.id, node.name, node.HeirarchySlug,
	(COUNT(parent.name) - 1) AS depth, node.lft, node.rgt
	FROM '+($svHeirarchyTable)+' AS node, '+($svHeirarchyTable)+' AS parent
	WHERE node.lft BETWEEN parent.lft AND parent.rgt
	AND node.Active = "Y"
	GROUP BY node.id
	ORDER BY node.lft');

Inline: $IV_Heirarchy, -SQL=$SQLSelectFullNode, -Table=$svHeirarchyTable;

	If: $svDebug == 'Y';
		$DropdownHTML += '<p class="debug">\n';
		$DropdownHTML += ('Found_Count = '+(Found_Count)+'<br>\n');
		$DropdownHTML += ('Error_CurrentError = '+(Error_CurrentError)+'<br>\n');
		$DropdownHTML += ('SQLSelectFullNode = '+($SQLSelectFullNode)+'<br>\n');
		$DropdownHTML += ('Records_Array = '+(Records_Array)+'</p>\n');
	/If;

	Var('ThisDepth' = (Integer(Field:'depth')));

	Records;

		Var('c_depth'= (Integer(Field:'depth'))); 

		Var:'ThisHeirarchyID' = (Field:'id');
		Var:'ThisDepth' = (Integer(Field:'depth'));
		Var:'ThisHeirarchyName' = (Field:'name');
		Var:'ThisNodeNameSlug' = (Field:'HeirarchySlug');
		Var:'MyItemLink' = string;
		Var:'MyItemURLPath' = string;

/* NOT USING - It actually doesn't look ahead properly
// Looking ahead to see if THIS heirarchy record has any lower levels (children)
Var('ThisLoopCount' = Loop_Count);
Protect;
	Var:'ThisLoopCountChildren' = (Records_Array->Get:$ThisLoopCount);
/Protect;
Var:'ThisLoopCountChildrenSize' = $ThisLoopCountChildren->size;
If: $ThisLoopCountChildrenSize == 0;
	Var('OutputCloseDiv' = true);
/If;

$DropdownHTML += ('<!-- 0 CHECKING DEPTHS $ThisLoopCount = '+($ThisLoopCount)+' -->\n');
$DropdownHTML += ('<!-- 0 CHECKING DEPTHS $ThisLoopCountChildren = '+($ThisLoopCountChildren)+' -->\n');
$DropdownHTML += ('<!-- 0 CHECKING DEPTHS $ThisLoopCountChildrenSize = '+($ThisLoopCountChildrenSize)+' -->\n');
$DropdownHTML += ('<!-- 0 CHECKING DEPTHS $OutputCloseDiv = '+($OutputCloseDiv)+' -->\n');
If: $ThisLoopCountChildrenSize > 1;
	$DropdownHTML += ('<!-- 0 LOOKING AHEAD: This node has more than 1 record, OUTPUT ul = '+($ThisLoopCountChildren)+' -->\n');
Else;
	$DropdownHTML += ('<!-- 0 LOOKING AHEAD: This node has 1 record, do NOT output ul = '+($ThisLoopCountChildren)+' -->\n');
/If;
*/
		// LOOK AHEAD for content pages
		// Set to true when ths Heirarchy level has content pages
		Local('HasContent' = boolean);
		
		Var:'MyItemID' = ($ContentHeirIDMap->(find($ThisHeirarchyID)));
		// This will contain the number of content pages for this heirarchy level
		Var:'MyItemSize' = $MyItemID->size;
		
		// $DropdownHTML += ('\n<!-- 83: ThisHeirarchyID = '+$ThisHeirarchyID+' -->\n');
		// $DropdownHTML += ('<!-- 83: MyItemSize = '+$MyItemSize+' -->\n');

		If: ($MyItemID != '');
			#HasContent = true;
		Else;
			#HasContent = false;
		/If;
		
		// Manufacture the links
		If(#HasContent == true);

			If: $ThisDepth == 0;
				$PrevLevel = '';
			/If;

			// Always make the link the Heirarchy Name for Depth 0 menu items
			If: $MyItemSize == 1 && $ThisDepth == 0;

				// Clean the URLSlug - Replace spaces with dashes
				// Note: Path has been modified by prefixing tthe heirarchy name
				If: $PrevLevel == $ThisNodeNameSlug;
					If: (Loop_Count) == 1;
						Local:'out' = ($ThisNodeNameSlug);
					Else;
						Local:'out' = (($PrevLevel)'/'($ThisNodeNameSlug));
					/If;
				Else;
					Local:'out' = ($ThisNodeNameSlug);
				/If;
				#out->replace(' ','-');
				$LinkContentPath = (String_LowerCase:(#out));

/*				// Output closing </ul>
				If(($InsideUL == true) && ($ThisDepth != $PrevDepth));
					$MyItemLink += '\t\t</ul><!-- xAA -->\n';
					// Flag that we are NOT inside a <ul>
					$InsideUL = false;
				/If;
*/
				// Output closing </ul>
//				If(($InsideUL == true) && ($ThisDepth != $PrevDepth));
				If(($InsideUL == true) && ($ThisDepth != $PrevDepth));
					$MyItemLink += '\t\t</ul><!-- xAA -->\n';
					// Flag that we are NOT inside a <ul>
					$InsideUL = false;
				/If;

				If: Integer(Field('Depth')) == $ThisDepth;
					$MyItemLink += ('<!-- x -->\n');
//					$MyItemLink += ('<!-- 140 $PrevDepth = '+($PrevDepth)+' -->\n');
//					$MyItemLink += ('<!-- 140 $ThisDepth = '+($ThisDepth)+' -->\n');
//					$MyItemLink += ('<!-- 140 $InsideUL = '+($InsideUL)+' -->\n');
//					$MyItemLink += ('\t<li><!-- 0 --><a href="/'+($LinkContentPath)+'">'+($ThisHeirarchyName)+'</a></li><!-- K -->\n');
					$MyItemLink += ('\t<li><!-- 0 --><a href="/'+($LinkContentPath)+'">');
						If($ThisHeirarchyID == $vHeirarchyID); $MyItemLink += ('<span class="linkcurrentpage">'); /If;
					$MyItemLink += ($ThisHeirarchyName);
						If($ThisHeirarchyID == $vHeirarchyID); $MyItemLink += ('</span>'); /If;
					$MyItemLink += ('</a></li><!-- K -->\n');

				Else: Integer(Field('Depth')) > $ThisDepth;
					// Remove trailing </li>
					// $DropdownHTML->(RemoveTrailing('</li>\n\n'));
					$DropdownHTML = (String_Replace: $DropdownHTML, -Find='</li><!-- K -->', -Replace='<!-- y Removed trailing /li -->\n');
//					$MyItemLink += ('<!-- y Removed trailing /li -->\n');
//					$MyItemLink += ('<!-- y -->\n');
//					$MyItemLink += ('<!-- 150 $ThisDepth = '+($ThisDepth)+' -->\n');
					$MyItemLink += ('\t<ul>\n\t\t<li><a href="/'+($LinkContentPath)+'">'+($ThisHeirarchyName)+'</a></li>\n');
					// Flag that we are inside a <ul>
					$InsideUL = true;
					
				// Not sure we actually ever hit this condition
				Else: Integer(Field('Depth')) < $ThisDepth; 
//					$MyItemLink += ('<!-- z -->\n');
//					$MyItemLink += ('<!-- 160 $ThisDepth = '+($ThisDepth)+' -->\n');
					$MyItemLink += (('\t' * ($ThisDepth ))('</ul>\n' * ($ThisDepth))+'</ul>\n<ul>\n'+('\t' * ($ThisDepth))+'<li class="li_'+($c_depth)+'">'+($ThisHeirarchyName)+'</li>\n');
					// Flag that we are inside a <ul>
					$InsideUL = true;
				/If;
		
				// Set the previous level
				$PrevLevel = $ThisHeirarchyName;

			Else;

				// Clean the URLSlug - Replace spaces with dashes
				// Note: Path has been modified by prefixing the heirarchy name
				If($ThisDepth > 0);
					If: (Loop_Count) == 1;
						Local:'out' = ($ThisNodeNameSlug);
					Else;
						Local:'out' = (($PrevLevel)'/'($ThisNodeNameSlug));
					/If;
				Else;
					Local:'out' = ($ThisNodeNameSlug);
				/If;
				#out->replace(' ','-');
				$LinkContentPath = (String_LowerCase:(#out));
				If: Integer(Field('Depth')) == $ThisDepth;
//					$MyItemLink += ('<!-- xx -->\n');
//					$MyItemLink += ('<!-- 190 $PrevDepth = '+($PrevDepth)+' -->\n');
//					$MyItemLink += ('<!-- 190 $ThisDepth = '+($ThisDepth)+' -->\n');
//					$MyItemLink += ('<!-- 190 $InsideUL = '+($InsideUL)+' -->\n');

					// DELETE TRAILING /LI
					If: $PrevDepth == $ThisDepth;
						// Do nothing
					Else;
						$DropdownHTML = (String_Replace: $DropdownHTML, -Find='</li><!-- K -->', -Replace='<!-- xx Removed trailing /li -->\n');
						$MyItemLink += ('<!-- xx Removed trailing /li -->\n');
						$MyItemLink += '\t\t<ul><!-- AA -->\n';
						// Flag that we are inside a <ul>
						$InsideUL = true;
					/If;

					// Add linkcurrentpage
//					$MyItemLink += ('<!-- gah000 -->');
//					$MyItemLink += ('<!-- 252 MyItemID = '+($MyItemID)+' -->\n');
//					$MyItemLink += ('<!-- 252 ThisHeirarchyID = '+($ThisHeirarchyID)+' -->\n');
//					$MyItemLink += ('<!-- 252 vHeirarchyID = '+($vHeirarchyID)+' -->\n');

					$MyItemLink += ('\t<li><!-- 000 --><a href="/'+($LinkContentPath)+'">');
						If($ThisHeirarchyID == $vHeirarchyID); $MyItemLink += ('<span class="linkcurrentpage">'); /If;
					$MyItemLink += ($ThisHeirarchyName);
						If($ThisHeirarchyID == $vHeirarchyID); $MyItemLink += ('</span>'); /If;
					$MyItemLink += ('</a>\n');

					If: $PrevDepth == $ThisDepth;
						$MyItemLink += '\t\t<ul><!-- AAAA -->\n';
						// Flag that we are inside a <ul>
						$InsideUL = true;
					Else: $PrevDepth < $ThisDepth;
						$MyItemLink += '\t\t<ul><!-- AAAB-->\n';
						// Flag that we are inside a <ul>
						$InsideUL = true;
					/If;

					Iterate: $MyItemID, (Local:'i');
						Var:'MyItemLabel' = ($ContentHeadMap->(find:(#i)));
						Var:'MyItemURLPath' = ($ContentPathMap->(find:(#i)));
						// Clean the URLSlug - Replace spaces with dashes
						Local:'out' = $MyItemURLPath;
						#out->replace(' ','-');
						$LinkContentPath = (String_LowerCase:(#out));
						// Decorate the link with the thickbox class to create the popup
						If($LinkContentPath >> 'popup');
							$MyItemLink += ('\t\t\t<li><!-- x0 --><a href="'($LinkContentPath)'" class="thickbox">'($MyItemLabel)'</a></li>\n');
						Else;
							$MyItemLink += ('\t\t\t<li><!-- x0 --><a href="'($LinkContentPath)'">'($MyItemLabel)'</a></li>\n');
						/If;
					/Iterate;
					$MyItemLink += '\t\t</ul><!-- BB -->\n';
					$MyItemLink += '\t</li><!-- BB -->\n';

				Else: Integer(Field('Depth')) > $ThisDepth;
//					$MyItemLink += ('<!-- yy -->\n');
					Iterate: $MyItemID, (Local:'i');
						Var:'MyItemLabel' = ($ContentHeadMap->(find:(#i)));
						Var:'MyItemURLPath' = ($ContentPathMap->(find:(#i)));
						// Clean the URLSlug - Replace spaces with dashes
						Local:'out' = $MyItemURLPath;
						#out->replace(' ','-');
						$LinkContentPath = (String_LowerCase:(#out));
						$MyItemLink += ('\t\t\t<li><!-- y0 --><a href="'($LinkContentPath)'">'($MyItemLabel)'</a></li>\n');
					/Iterate;

				Else: Integer(Field('Depth')) < $ThisDepth; 
					$MyItemLink += ('<!-- zz -->\n'); 
					$MyItemLink += (('\t' * ($ThisDepth ))('</ul>\n' * ($ThisDepth))+'</ul>\n<ul>\n'+('\t' * ($ThisDepth))+'<li class="li_'+($c_depth)+'">'+($ThisHeirarchyName)+'</li>\n');
					// Flag that we are inside a <ul>
					$InsideUL = true;

				/If;

				// Set the current Depth
		 		$ThisDepth = (Integer(Field('Depth')));

			/If;

		/If;

		$PrevDepth = $ThisDepth;

		$DropdownHTML += (($MyItemLink)'\n');

	/Records;

/Inline;

// END container for left navbar
$DropdownHTML += '</ul>
	<br style="clear: left">
</div>\n';
$DropdownHTML += '<!-- END build_dropdown -->\n';

?>
