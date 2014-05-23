<?Lassoscript
// Last modified 11/24/09 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file processes action_params

// CHANGE NOTES
// 10/12/07
// Recoded for Clean URLs
// 11/15/07
// Switched fields CategoriesID to HeirarchyID
// 4/2/08
// Added code for URL Fix (Issue #547)
// 1/15/09
// Added Story field
// 6/22/09
// Added gallery feature
// 8/25/09
// Adding page stylesheet
// 11/23/09
// Added SortOrder
// 11/24/09
// Add ShowInNav field


// Copying Action_Params to vars
// Remove leading and trailing spaces
// If required is missing, output an error
// If multiple errors, they will step on each other, but not worried about it

If: (Action_Param:'Error') != '';
	Var:'vError' = (Action_Param:'Error');
/If;
If: (Action_Param:'Option') != '';
	Var:'vOption' = (Action_Param:'Option');
/If;
Var:'vID' = (Action_Param:'ID');

// Pass a param "New" through the URL to indicate it is a new page
Var:'vNew' = (Action_Param:'New');

Var:'vProcess' = (Action_Param:'Process');

Var:'vHeirarchyID' = (Action_Param:'HeirarchyID');
	$vHeirarchyID->trim;
Var:'vHeadline' = (Action_Param:'Headline');
	$vHeadline->trim;
Var:'vSubhead' = (Action_Param:'Subhead');
	$vSubhead->trim;
Var:'vAuthor' = (Action_Param:'Author');
	$vAuthor->trim;
Var:'vText_1' = (Action_Param:'Text_1');
	$vText_1->trim;
Var:'vText_2' = (Action_Param:'Text_2');
	$vText_2->trim;
Var:'vImage_thumb' = (Action_Param:'Image_thumb');
	$vImage_thumb->trim;
Var:'vImage_med' = (Action_Param:'Image_med');
	$vImage_med->trim;
Var:'vImage_large' = (Action_Param:'Image_large');
	$vImage_large->trim;
Var:'vImage_title' = (Action_Param:'Image_title');
	$vImage_title->trim;
Var:'vImage_caption' = (Action_Param:'Image_caption');
	$vImage_caption->trim;
Var:'vMedia_FIle' = (Action_Param:'Media_File');
	$vMedia_File->trim;
Var:'vPrice_1' = (Action_Param:'Price_1');
	$vPrice_1->trim;
Var:'vPrice_2' = (Action_Param:'Price_2');
	$vPrice_2->trim;
Var:'vURL' = (Action_Param:'URL');
	$vURL->trim;
Var:'vPageKeywords' = (Action_Param:'PageKeywords');
	$vPageKeywords->trim;
Var:'vPageAuthor' = (Action_Param:'PageAuthor');
	$vPageAuthor->trim;
Var:'vPageDescription' = (Action_Param:'PageDescription');
	$vPageDescription->trim;
Var:'vPageCopyright' = (Action_Param:'PageCopyright');
	$vPageCopyright->trim;
Var:'vPageTitle' = (Action_Param:'PageTitle');
	$vPageTitle->trim;
Var:'vPageTemplate'=(Action_Param:'PageTemplate');
	$vPageTemplate->trim;
Var:'vPageStylesheet'=(Action_Param:'PageStylesheet');
	$vPageStylesheet->trim;
Var:'vPortfolioGroupID'=(Action_Param:'PortfolioGroupID');
	$vPortfolioGroupID->trim;
Var:'vGalleryGroupID'=(Action_Param:'GalleryGroupID');
	$vGalleryGroupID->trim;
Var:'vTestimonial'=(Action_Param:'Testimonial');
	$vTestimonial->trim;
Var:'vStory'=(Action_Param:'Story');
	$vStory->trim;
Var:'vActive'=(Action_Param:'Active');
	$vActive->trim;
Var:'vActiveFrom'=(Action_Param:'ActiveFrom');
	$vActiveFrom->trim;
Var:'vActiveTo'=(Action_Param:'ActiveTo');
	$vActiveTo->trim;
// SET vActiveTo if not defined
If($vActiveTo == '');
	$vActiveTo = '2100-01-01';
/If;
Var:'vSortOrder'=(Action_Param:'SortOrder');
	$vSortOrder->trim;
Var:'vShowInNav'=(Action_Param:'ShowInNav');
	$vShowInNav->trim;
Var:'vAttachPopup'=(Action_Param:'AttachPopup');
	$vAttachPopup->trim;

// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit
If: $vNew != 'Y';
	If: ($vHeirarchyID == '') || ($vHeadline == '') || ($vActive == '');
		Var:'vError' = '1003';
		Var:'vOption' = 'Heirarchy or Headline';
	/If;
/If;

// Create name to display
Var:'vDisplayName' = $vHeadline;

// Process the Headline to produce the URLSlug
Var:'vURLSlug' = (LI_CleanSlug: -NodeName=$vHeadline);

?>