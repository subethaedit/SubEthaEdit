<?Lassoscript
// Last modified 11/27/07 by ECL, Landmann InterActive

// FUNCTIONALITY
// This file is included in the add pages to process action_params

// Copying Action_Params to vars
// Remove leading and trailing spaces

// CHANGE NOTES
// 11/27/07
// First implementation

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

Var:'vTestimonial_Comment'=(Action_Param:'Testimonial_Comment');
	$vTestimonial_Comment->trim;
Var:'vActive'=(Action_Param:'Active');
	$vActive->trim;

// If required is missing, output error 1003 "Required Missing"
// but ONLY if the page has been submit
If: $vNew != 'Y';
	If: ($vTestimonial_Comment == '') || ($vActive == '');
		Var:'vError' = '1003';
		Var:'vOption' = 'Testimonial Text';
	/If;
/If;

// OPTIONAL FIELDS
Var:'vTestimonial_Head'=(Action_Param:'Testimonial_Head');
	$vTestimonial_Head->trim;
Var:'vTestimonial_Name'=(Action_Param:'Testimonial_Name');
	$vTestimonial_Name->trim;
Var:'vTestimonial_Thumb'=(Action_Param:'Testimonial_Thumb');
	$vTestimonial_Thumb->trim;

// Create name to display
// Since only the comment is required, we will pass the ID
?>