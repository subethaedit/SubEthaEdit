<?Lassoscript
// Last modified 6/9/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Building Google links for search response pages
// Creates the HTML for five links, like this:
//  1  |  2  |  3  |  4  |  5  |  NEXT

// CHANGE NOTES
// 11/30/07
// Getting rid of $show in link
// 6/9/08
// Minor syntax changes to code to make it look more like nav_control_grid

'<!-- START Nav Control -->\n';
'<div align="center">\n';

// Display Found_Count
If: (Found_Count) > 0;
	'Displaying <strong>' (Shown_First) '</strong> through <strong>' (Shown_Last) '</strong> of <strong><font color="red">' (Found_Count) '</font></strong> records.<br>\n';
/If;

// PREV link
If: $This_Group > 0;
	'<a href="http://'($svDomain)(Response_Filepath)'?DataType='($vDataType)'&skip='(math_sub: (shown_first) ,$Group_Size, 1)'&group='(Math_Sub: $This_Group, 1)'"> PREVIOUS GROUP</a><span class="ghost">&nbsp;|&nbsp;</span>';
/If;

// MIDDLE links
$SkipCount = (Math_Mult:$This_Group,$Group_Size);
$Records_Found = (Found_Count);

If: $Records_Found > $Records_Per_Page;
	Loop: 5;
		If: $SkipCount >= $Records_Found;
			Loop_Abort;
		/If;
		$SkipCount = (Math_Add: $SkipCount, $Records_Per_Page);
		If: $Records_Skipped == (Math_Sub: $SkipCount, $Records_Per_Page);
			'<font color="#000000"><strong>' (Math_Div: $SkipCount, $Records_Per_Page) '</strong></font>\n';
		Else;
			'<a href="http://'($svDomain)(Response_Filepath)'?DataType='($vDataType)'&skip='(Math_Sub: $SkipCount, $Records_Per_Page)'&group='($This_Group)'&NewQuery=N">'(Math_Div: $SkipCount, $Records_Per_Page)'</a>';
		/If;
		If: ((Loop_Count) < 5) && ($SkipCount < $Records_Found);
			'<span class="ghost">&nbsp;|&nbsp;</span>';
		/If;
	/Loop;

// NEXT link
	If: (Found_Count) > $SkipCount;
		$This_Group = (Math_Add:$This_Group,1);
		'<span class="ghost">&nbsp;|&nbsp;</span><a href="http://'($svDomain)(Response_Filepath)'?DataType='($vDataType)'&skip='(math_mult: $Group_Size, $This_Group)'&group='($This_Group)'&NewQuery=N">NEXT GROUP</a>\n';
	/If;
/If;

'</div>\n';
'<!-- END Nav Control -->\n';
?>