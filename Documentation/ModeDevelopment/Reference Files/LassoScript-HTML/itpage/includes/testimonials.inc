<?Lassoscript
// Last modified 10/12/07 by ECL, Landmann InterActive

// CHANGE NOTES
// 10/12/07
// Recoded for Clean URLs
// Getting rid of the table

If: $svDebug == 'Y';
	'<p class="debug"><strong>/includes/testimonials.inc</strong><br>\n';
/If;

Var:'SQLQueryPortfolioRandom' = 'SELECT id,CategoryID,SectionID,Text_1,Image_Thumb,Image_Title FROM ' $svSiteDatabase '.' $svContentTable ' WHERE SectionID="14" AND CategoryID="34" AND Active="Y" ORDER BY RAND() LIMIT 1';

If:	$svDebug == 'Y';
	'3: SQLQueryPortfolioRandom = ' (Var:'SQLQueryPortfolioRandom') '</p>\n'; 
/if;

Inline: $IV_Content, -SQL=$SQLQueryPortfolioRandom;

	$FinalContent += '<div class="containeryellow">';
	
	$FinalContent += '\t<p class="Testimonial">'(Field:'Text_1',-EncodeNone)'</p>
	<p align="center" class="Testimonial"><a href="detail.lasso?SectionID=14&CategoryID=33&New=Y">View more Testimonials</a></p>\n';
	$FinalContent += '</div>\n';

/Inline;
?>