<?Lassoscript
// Last modified: 7/13/09 by ECL, Landmann InterActive

// FUNCTIONALITY
/* DELETE/MODIFY DATABASE ENTRIES

VALID INPUT to this routine is an Image_Med filename (e.g. "SupportDesk_Lt5.jpg") and NOT an ID.
This routine uses $vID which is passed from the AJAX page check_imageusage.lasso

This code will do the following:

	Content Table: UPDATE all records by erasing the Image_ fields. All other data is unchanged.
	Gallery Table: DELETE all gallery entries using the image.
	Gallery-to-Gallery Groups Table: DELETE all g2g entries with this image.
	Portfolio Table: DELETE All portfolio entries using the image.
	Portfolio-to-Portfolio Groups Table: DELETE all p2g entries with this image.
	Stories Table: UPDATE all records by erasing the Story_Thumb field. All other data is unchanged.
	Testimonials Table: UPDATE all records by erasing the Testimonial_Thumb field. All other data is unchanged.

Error Checking/Reporting: not doing any here, codes are returned from other areas.

*/

// 7/13/09
// First implementation

// Debugging
// Var:'svDebug' = 'Y';

// Convert action_params
Var:'vID' = (Action_Param:'id');

// TESTING
// Var:'vID' = 'SupportDesk_Lt5.jpg';
// Var:'vID' = '1CuzcoSquare_d8e.jpg';
// Var:'vID' = 'WTIHome5_09_3TK.jpg';

If: $svDebug == 'Y';
	'<p class="debug"><strong>library_moddata.inc</strong></p>\n';
/If;

// CONTENT Table ------------------------------------------------------------------------
Var('SQLModContent' = '/* library_moddata - $SQLModContent */
UPDATE ' ($svSiteDatabase) '.' ($svContentTable) ' SET
	Image_Large="", Image_Med="", Image_Thumb=""
WHERE Image_Med="'($vID)'"');
Inline: $IV_Content, -Table=$svContentTable, -SQL=$SQLModContent;
	Debug;
		'30: SQLModContent = ' ($SQLModContent) '<br>\n';
		'30: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

// GALLERY - Done in 3 steps ------------------------------------------------------------
// 1. Grab the ID of the Gallery Entry. Use this to delete records in gg2g.
Var('SQLQueryGallery' = '/* library_moddata - $SQLQueryGallery */
SELECT gallery_id FROM ' ($svSiteDatabase) '.' ($svGalleryTable) ' WHERE gallery_thumb="'($vID)'"');
Inline: $IV_Galleries, -Table=$svGalleryTable, -SQL=$SQLQueryGallery;
	Var:'ThisGalleryID' = (Field:'gallery_id');
	Debug;
		'40: SQLQueryGallery = ' ($SQLQueryGallery) '<br>\n';
		'40: ThisGalleryID = ' ($ThisGalleryID) '<br>\n';
		'40: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

// 2. DELETE the Gallery Entry record. 
Var('SQLModGallery' = '/* library_moddata - $SQLModGallery */
DELETE FROM ' ($svSiteDatabase) '.' ($svGalleryTable) ' WHERE gallery_thumb="'($vID)'"');
Inline: $IV_Galleries, -Table=$svGalleryTable, -SQL=$SQLModGallery;
	Debug;
		'50: SQLModGallery = ' ($SQLModGallery) '<br>\n';
		'50: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

// 3. DELETE the gg2g records.
Var('SQLModGallery2' = '/* library_moddata - $SQLModGallery2 */
DELETE FROM ' ($svSiteDatabase) '.' ($svGG2GalleryTable) ' WHERE gallery_id="'($ThisGalleryID)'"');
Inline: $IV_Galleries, -Table=$svGG2GalleryTable, -SQL=$SQLModGallery2;
	Debug;
		'60: SQLModGallery2 = ' ($SQLModGallery2) '<br>\n';
		'60: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

// PORTFOLIO - Done in 3 steps ---------------------------------------------------------
// 1. Grab the ID of the Portfolio Entry. Use this to delete records in pg2p.
Var('SQLQueryPortfolio' = '/* library_moddata - $SQLQueryPortfolio */
SELECT portfolio_id FROM ' ($svSiteDatabase) '.' ($svPortfolioTable) ' WHERE portfolio_thumb="'($vID)'"');
Inline: $IV_Portfolios, -Table=$svPortfolioTable, -SQL=$SQLQueryPortfolio;
	Var:'ThisPortfolioID' = (Field:'portfolio_id');
	Debug;
		'70: SQLQueryPortfolio = ' ($SQLQueryPortfolio) '<br>\n';
		'70: ThisPortfolioID = ' ($ThisPortfolioID) '<br>\n';
		'70: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

// 2. DELETE the Portfolio Entry record. 
Var('SQLModPortfolio' = '/* library_moddata - $SQLModPortfolio */
DELETE FROM ' ($svSiteDatabase) '.' ($svPortfolioTable) ' WHERE portfolio_thumb="'($vID)'"');
Inline: $IV_Portfolios, -Table=$svPortfolioTable, -SQL=$SQLModPortfolio;
	Debug;
		'80: SQLModPortfolio = ' ($SQLModPortfolio) '<br>\n';
		'80: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

// 3. DELETE the pg2p records.
Var('SQLModPortfolio2' = '/* library_moddata - $SQLModPortfolio2 */
DELETE FROM ' ($svSiteDatabase) '.' ($svPG2PortfolioTable) ' WHERE portfolio_id="'($ThisPortfolioID)'"');
Inline: $IV_Portfolios, -Table=$svPG2PortfolioTable, -SQL=$SQLModPortfolio2;
	Debug;
		'90: SQLModPortfolio2 = ' ($SQLModPortfolio2) '<br>\n';
		'90: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

// Story Table ------------------------------------------------------------------------
Var('SQLModStory' = '/* library_moddata - $SQLModStory */
UPDATE ' ($svSiteDatabase) '.' ($svStoriesTable) ' SET Story_Thumb=""
WHERE Story_Thumb="'($vID)'"');
Inline: $IV_Stories, -Table=$svStoriesTable, -SQL=$SQLModStory;
	Debug;
		'30: SQLModStory = ' ($SQLModStory) '<br>\n';
		'30: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

// Testimonial Table ------------------------------------------------------------------------
Var('SQLModTestimonial' = '/* library_moddata - $SQLModTestimonial */
UPDATE ' ($svSiteDatabase) '.' ($svTestimonialsTable) ' SET Testimonial_Thumb=""
WHERE Testimonial_Thumb="'($vID)'"');
Inline: $IV_Testimonials, -Table=$svTestimonialsTable, -SQL=$SQLModTestimonial;
	Debug;
		'30: SQLModTestimonial = ' ($SQLModTestimonial) '<br>\n';
		'30: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
	/Debug;
/Inline;

?>
