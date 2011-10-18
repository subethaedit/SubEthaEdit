<?Lassoscript
// Last modified: 6/9/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Building Google links for File Grid
// Creates the HTML for five links, like this:
//  1  |  2  |  3  |  4  |  5  |  NEXT

// CHANGE NOTES
// 10/30/07
// First implementation
// 2/19/08
// Changing link to pass NewQuery = N
// 6/9/08
// Fixing NEXT link not appearing correctly.

'<!-- START Nav Control Grid -->\n';
// '<div align="center">\n';

// Display Found_Count
If: ($ImageCount) > 0;
	'Displaying <strong>' ($LoopFrom) '</strong> through <strong>'; If: ($ImageCount) <= ($LoopTo); ($ImageCount); Else; ($LoopTo); /If; '</strong> of <strong><font color="red">' ($ImageCount) '</font></strong> records.<br>\n';
/If;

// PREV link
If: $This_Group > 0;
	'<a href="http://'($svDomain)(Response_Filepath)'?DataType='($vDataType)'&skip='(math_sub: $LoopFrom, $Group_Size, 1)'&group='(Math_Sub: $This_Group, 1)'&NewQuery=N&Action=Browse"> PREVIOUS GROUP</a><span class="ghost">&nbsp;|&nbsp;</span>';
/If;

// MIDDLE links
$SkipCount = (Math_Mult:$This_Group,$Group_Size);
$Records_Found = $ImageCount;

If: $Records_Found > $Records_Per_Page;
	Loop: 5;
		If: $SkipCount >= $Records_Found;
			Loop_Abort;
		/If;
		$SkipCount = (Math_Add: $SkipCount, $Records_Per_Page);
		If: $Records_Skipped == (Math_Sub: $SkipCount, $Records_Per_Page);
			'<font color="#000000"><strong>' (Math_Div: $SkipCount, $Records_Per_Page) '</strong></font>\n';
		Else;
			'<a href="http://'($svDomain)(Response_Filepath)'?DataType='($vDataType)'&skip='(Math_Sub: $SkipCount, $Records_Per_Page)'&group='($This_Group)'&NewQuery=N&Action=Browse">'(Math_Div: $SkipCount, $Records_Per_Page)'</a>';
		/If;
		If: ((Loop_Count) < 5) && ($SkipCount < $Records_Found);
			'<span class="ghost">&nbsp;|&nbsp;</span>';
		/If;
	/Loop;

// NEXT link
	If: ($ImageCount) > $SkipCount;
		$This_Group = (Math_Add:$This_Group,1);
		'<span class="ghost">&nbsp;|&nbsp;</span><a href="http://'($svDomain)(Response_Filepath)'?DataType='($vDataType)'&skip='(math_mult: $Group_Size, $This_Group)'&group='($This_Group)'&NewQuery=N&Action=Browse">NEXT GROUP</a>\n';
	/If;
/If;

// '</div>\n';
'<!-- END Nav Control Grid -->\n';
?>