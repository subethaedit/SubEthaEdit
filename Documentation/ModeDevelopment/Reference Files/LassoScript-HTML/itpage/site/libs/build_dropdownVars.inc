<?Lassoscript
// Last modified 6/15/09 by ECL, Landmann InterActive

// CHANGE NOTES
// 1/27/09
// Added check for User Privileges to build menus for specific privilege levels
// This makes it possible to build a dropdown for the secure area
// See http://devcms.steepnbrew.com/devel/Heirarchy/nestedset_viewHeirarchyPrivs.lasso for a heirarchy
// DATA NOTE: Privileges must be set manually in the cms_heirarchy table. Use the privs values from cms_userprivs.
// 6/15/09
// Removed privilege check from query

// FUNCTIONALITY
// This file creates $DropdownJS (header Javascript) and $DropdownHTML (HTML menu) for dropdowns - DOES NOT OUTPUT ANYTHING.
// The variables $ContentPathMap and $ContentIDMap are established by urlhandler.inc
// and should already exist. If they don't, you've got a bigger problem!
// TO OUTPUT
// $DropdownJS is output by the atend handler in LI_CMSatend.lasso
// You must select a template for the content page that calls the dropdown, such as SB_pf5_TestBot_Dropdown.html
// TESTING
// You can use the CT OutputDropdownJS to output the header JS
// Use OutputDropdownHTML to output the menu HTML

// SAMPLE CODE: See /DEVEL/Dropdowns/Chalmers Source/ChalmersMenusPOC.html
// The page header must call mm_menu.js for this to work.

// SAMPLE HEADER JS
/*	<script language="JavaScript">
	<!--
	function mmLoadMenus() {

	if (window.mm_menu_84) return;
	window.mm_menu_84 = new Menu("root",200,16,"Verdana, Arial, Helvetica, sans-serif",10,"#000000","#ffffcc","#f6ffca","#333333","left","middle",3,0,1000,-5,7,true,true,true,0,true,true);
	mm_menu_84.addMenuItem("<!-- ContentID 22 -->Cafe Business","location='/coffee-cafe-owners/steep-&-brew-cafes/cafe-business'");
	mm_menu_84.addMenuItem("<!-- ContentID 33 -->Licensee Cafes","location='/coffee-cafe-owners/steep-&-brew-cafes/licensee-cafes'");
	mm_menu_84.hideOnMouseOut=true;
		mm_menu_84.menuBorder=1;
		mm_menu_84.menuLiteBgColor='#ffffff';
		mm_menu_84.menuBorderBgColor='#555555';
		mm_menu_84.bgColor='#555555';

	if (window.mm_menu_83) return;
	window.mm_menu_83 = new Menu("root",200,16,"Verdana, Arial, Helvetica, sans-serif",10,"#000000","#ffffcc","#f6ffca","#333333","left","middle",3,0,1000,-5,7,true,true,true,0,true,true);
	mm_menu_83.addMenuItem("<!-- ContentID 30 -->From Cafe Owners","location='/coffee-cafe-owners/customer-referrals/from-cafe-owners'");
	mm_menu_83.hideOnMouseOut=true;
		mm_menu_83.menuBorder=1;
		mm_menu_83.menuLiteBgColor='#ffffff';
		mm_menu_83.menuBorderBgColor='#555555';
		mm_menu_83.bgColor='#555555';

	if (window.mm_menu_76) return;
	window.mm_menu_76 = new Menu("root",200,16,"Verdana, Arial, Helvetica, sans-serif",10,"#000000","#ffffcc","#f6ffca","#333333","left","middle",3,0,1000,-5,7,true,true,true,0,true,true);
	mm_menu_76.addMenuItem("<!-- ContentID 36 -->Cafe Owners","location='/coffee-cafe-owners/independent-cafes/cafe-owners'");
	mm_menu_76.hideOnMouseOut=true;
		mm_menu_76.menuBorder=1;
		mm_menu_76.menuLiteBgColor='#ffffff';
		mm_menu_76.menuBorderBgColor='#555555';
		mm_menu_76.bgColor='#555555';

	mm_menu_76.writeMenus();
	} // mmLoadMenus()
	//-->
	</script> */

// SAMPLE HTML
/* <!-- START build_dropdown HTML -->
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td width="150"><div id="84"><a href="/LINK" onMouseOut="MM_swapImgRestore();" onMouseOver="MM_showMenu(window.mm_menu_84,4,14,null,'84');" class="dropdown">steep & brew cafes</a></div></td>
		<td width="150"><div id="83"><a href="/LINK" onMouseOut="MM_swapImgRestore();" onMouseOver="MM_showMenu(window.mm_menu_83,4,14,null,'83');" class="dropdown">customer referrals</a></div></td>
		<td width="150"><div id="76"><a href="/LINK" onMouseOut="MM_swapImgRestore();" onMouseOver="MM_showMenu(window.mm_menu_76,4,14,null,'76');" class="dropdown">independent cafes</a></div></td>
	</tr>
</table>
<!-- END build_dropdown HTML -->
*/


// Debugging
// Var:'svDebug' = 'Y';

// Used to hold the dropdown Javascript
Var:'DropdownJS' = string;

// Used to hold the dropdown HTML
Var:'DropdownHTML' = string;

// Used to store the ID of the Heirarchy record
Var:'mmID' = (Field:'ID');

// TESTING
// COPIED FROM urlhandler.inc
// Create a map for the full URL and ContentID, key is the ID
// SAMPLE DATA
/* Var:'ContentPathMap' = map;
$ContentPathMap = map(
	'1' = '/home/welcome to steep & brew',
	'2' = '/our coffees/steep & brew/steep & brew coffees',
	'4' = '/company directory/company directory',
	'7' = '/about us/our story',
	'9' = '/our coffees/cafe fair/cafe fair coffees',
	'10' = '/coffee for business/steep & brew can help you move your business forward',
	'14' = '/our coffees/coffees for every occasion',
	'15' = '/community involvement/coffee done right',
	'22' = '/coffee cafe owners/steep & brew cafes/cafe business',
	'18' = '/coffee cafe owners/independent cafes/sales directors/assorted sales materials',
	'24' = '/coffee cafe owners/independent cafes/cafe owners/pricing info and biz forms',
	'19' = '/coffee cafe owners/we inspire cafe owners to achieve success',
	'30' = '/coffee cafe owners/customer referrals/from cafe owners',
	'31' = '/coffee cafe owners/independent cafes/cafe owners/coffee grinders',
	'32' = '/coffee cafe owners/independent cafes/cafe owners/coffee brewers',
	'33' = '/coffee cafe owners/steep & brew cafes/licensee cafes',
	'34' = '/coffee cafe owners/independent cafes/cafe owners/coffee bins',
	'29' = '/home/holiday coffee drink recipes/recipes and video link',
	'36' = '/coffee cafe owners/independent cafes/cafe owners');

Var:'ContentIDMap' = map;
$ContentIDMap = map(
	'/our coffees/steep & brew/steep & brew coffees' = '2',
	'/coffee cafe owners/steep & brew cafes/licensee cafes' = '33',
	'/about us/our story' = '7',
	'/coffee cafe owners/independent cafes/cafe owners' = '36',
	'/coffee cafe owners/independent cafes/sales directors/assorted sales materials' = '18',
	'/coffee cafe owners/steep & brew cafes/cafe business' = '22',
	'/coffee for business/steep & brew can help you move your business forward' = '10',
	'/community involvement/coffee done right' = '15',
	'/coffee cafe owners/we inspire cafe owners to achieve success' = '19',
	'/coffee cafe owners/independent cafes/cafe owners/coffee grinders' = '31',
	'/coffee cafe owners/independent cafes/cafe owners/pricing info and biz forms' = '24',
	'/company directory/company directory' = '4',
	'/home/holiday coffee drink recipes/recipes and video link' = '29',
	'/coffee cafe owners/customer referrals/from cafe owners' = '30',
	'/coffee cafe owners/independent cafes/cafe owners/coffee brewers' = '32',
	'/home/welcome to steep & brew' = '1',
	'/our coffees/cafe fair/cafe fair coffees' = '9',
	'/our coffees/coffees for every occasion' = '14',
	'/coffee cafe owners/independent cafes/cafe owners/coffee bins' = '34');

*/
// START the JS	
$DropdownJS += ('\n\t<script language="JavaScript">
	<!--
	function mmLoadMenus() {\n');

// Start the HTML
// CUSTOMIZE THIS AS NECESSARY
$DropdownHTML += '<!-- START build_dropdown HTML -->\n';
$DropdownHTML += '<br>\n';
$DropdownHTML += '<table border="0" cellpadding="0" cellspacing="0">\n\t<tr>\n';

// Used to indicate how many levels to go down in heirarchy
Var:'ShowDepths' = 0;

// Key to Heirarchy IDs
// Heirarchy ID		Node Name
//		84			/Coffee Cafe Owners/Steep & Brew Cafes
//		83			/Coffee Cafe Owners/Customer Referrals
//		76			/Coffee Cafe Owners/Independent Cafes

// Contains an array of Heirarchy IDs to start with, then display the lower heirarchy and links
Var:'SecondaryMenuIDArray' = array;
// TESTING
// $SecondaryMenuIDArray = array('84', '83', '76');
// $SecondaryMenuIDArray = $vHeirarchyID;
// WORKS
// $SecondaryMenuIDArray = array('73');
$SecondaryMenuIDArray = array($vHeirarchyID);
Var:'ShowDepths' = 1;

// Iterate through the Heirarchy IDs. Each ID will create an entry to which is attached a dropdown menu.
// The LOWER items in the dropdown are content pages that fall under this heirarchy entry.
Iterate: $SecondaryMenuIDArray, Local('myItem');
	Local('StartID') = #myItem;

	// TESTING - Change this to indicate which Heirarchy ID to use
	// Local('StartID' = 84);
	
	// Construct query to order by node.lft
	Var:'SQLSelectPartialNode' = '/* SELECT Partial Node */
	SELECT node.id, node.name, node.lft, node.rgt, node.HeirarchySlug, (COUNT(parent.id) - (sub_tree.depth + 1)) AS depth FROM ' $svHeirarchyTable ' AS node, ' $svHeirarchyTable ' AS parent, ' $svHeirarchyTable ' AS sub_parent,
			(
					SELECT node.id, node.name, (COUNT(parent.id) - 1) AS depth
					FROM ' $svHeirarchyTable ' AS node,
					' $svHeirarchyTable ' AS parent
					WHERE node.lft BETWEEN parent.lft AND parent.rgt
					AND node.id = ' #StartID '
					GROUP BY node.name
					ORDER BY node.lft
			) AS sub_tree
	WHERE
		(
			node.lft BETWEEN parent.lft AND parent.rgt
			AND node.lft BETWEEN sub_parent.lft AND sub_parent.rgt
			AND sub_parent.id = sub_tree.id 
		)
	GROUP BY node.id
	HAVING depth <= ' $ShowDepths '
	ORDER BY node.lft';
	
	Inline: $IV_Heirarchy, -SQL=$SQLSelectPartialNode, -Table=$svHeirarchyTable;
	
		If: $svDebug == 'Y';
			$DropdownJS += '<p class="debug">\n';
			$DropdownJS += '107: <strong>Get Heirarchy</strong><br>\n';
			$DropdownJS += '107: Found_Count = ' (Found_Count) '<br>\n';
			$DropdownJS += '107: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
			$DropdownJS += '107: SQLSelectPartialNode = ' ($SQLSelectPartialNode) '<br>\n';
			$DropdownJS += '107: <strong>Records_Array</strong> = ' (Records_Array) '</p>\n';
		/If;

		Records;
	
			// Using the field ID to uniquely name the mm_menu
			$mmID = (Field:'ID');
	
			If: $svDebug == 'Y';
				$DropdownJS += '<p class="debug">\n';
				$DropdownJS += ('56: <strong>Loop_Count = ' (Loop_Count) '</strong><br>\n');
				$DropdownJS += ('56: ID = ' (Field:'id') '<br>\n');
				$DropdownJS += ('56: HeirarchySlug = ' (Field:'HeirarchySlug') '<br>\n');
				$DropdownJS += ('56: ThisNodeDepth = ' ($ThisNodeDepth) '</p>\n');
			/If;
	
			$DropdownJS += ('\n\tif (window.mm_menu_'($mmID)') return;\n');
			$DropdownJS += ('\twindow.mm_menu_'($mmID)' = new Menu("root",240,16,"Verdana, Arial, Helvetica, sans-serif",10,"#000000","#ffffcc","#f6ffca","#333333","left","middle",3,0,1000,-5,7,true,true,true,0,true,true);\n');

			$DropdownHTML += '\t\t<td width="150"><div id="Menu'($mmID)'"><a href="'(Field:'name')'" onMouseOut="MM_swapImgRestore();" onMouseOver="MM_showMenu(window.mm_menu_'($mmID)',4,14,null,\'Menu'($mmID)'\');" class="dropdown">'(Field:'Name')'</a></div></td>\n';

			Local:'CurrentDepth' = 0;
			Var:'IndentLevel' = 0;
	
			If: (Integer(Field:'Depth')) > $IndentLevel;
				$IndentLevel = $IndentLevel + 1;
			Else:  (Integer(Field:'Depth')) < $IndentLevel;
				$IndentLevel = $IndentLevel - 1;
			Else:  (Integer(Field:'Depth')) == $IndentLevel;
				// No change to level
			/If;
	//		$DropdownJS += ((Field:'ID') ' || ');
	//		Loop: $IndentLevel;
	//			$DropdownJS += '&diams;';
	//		/Loop;
	//		$DropdownJS += ((Field:'name') ' || ' (Field:'HeirarchySlug') '<br>\n');
	
	
			// *********************************************
			// Find Content for this Heirarchy ID
			// *********************************************
			Var:'SQLQueryContent' = 'SELECT ID, HeirarchyID, Headline, Active
			FROM ' $svSiteDatabase '.' $svContentTable ' WHERE HeirarchyID = "' (Field:'ID') '" AND Active = "Y"';
	
			Inline: $IV_Content, -SQL=$SQLQueryContent;
	
	//			If: $svDebug == 'Y';
	//				$DropdownJS += '<p class="debug">\n';
	//				$DropdownJS += ('162: <strong>Get Content</strong><br>\n');
	//				$DropdownJS += ('162: Records_Array = ' (Records_Array) '</p>\n');
	//			/If;
	
				Records;
	
					Var:'ContentIDLink' = (Field:'ID');
					// Clean the URLSlug - Replace spaces with dashes
					Local:'out' = ($ContentPathMap->(Find:($ContentIDLink)));
					#out->replace(' ','-');
					Var:'ThisContentPath' = (String_LowerCase:(#out));
	
	//			If: $svDebug == 'Y';
	//				$DropdownJS += '<p class="debug">\n';
	//				$DropdownJS += ('162: ContentIDLink = '($ContentIDLink) '</p>\n');
	//			/If;
	
	//				$DropdownJS += ((Field:'id') ' || ' (Field:'Headline') '<br>\n');
					$DropdownJS += ('\tmm_menu_'($mmID)'.addMenuItem("<!-- ContentID '(Field:'id')' -->'(Field:'Headline')'","location=\''($ThisContentPath)'\'");\n'); 

				/Records;
	
			/Inline;
	
			$DropdownJS += ('\tmm_menu_'($mmID)'.hideOnMouseOut=true;
		mm_menu_'($mmID)'.menuBorder=1;
		mm_menu_'($mmID)'.menuLiteBgColor=\'#ffffff\';
		mm_menu_'($mmID)'.menuBorderBgColor=\'#555555\';
		mm_menu_'($mmID)'.bgColor=\'#555555\';\n');
	
		/Records;
	
	/Inline;

/Iterate; // $SecondaryMenuIDArray

// Close the JS
$DropdownJS += '\n\tmm_menu_'($mmID)'.writeMenus();
	} // mmLoadMenus()
	//-->
	</script>\n';

// Close the HTML
$DropdownHTML += '	</tr>
</table>
<br>
<!-- END build_dropdown HTML -->\n';

// Debugging
// Var:'svDebug' = 'Y';

?>
