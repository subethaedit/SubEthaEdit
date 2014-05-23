<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputTestimonial }
	{Description=		Outputs either all or one randomly-selected testimonial }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				1/11/08 }
	{Usage=				OutputTestimonial }
	{ExpectedResults=	If $vTestimonial = all, it outputs all the testimonials in one block
						If $vTestimonial = random, it outputs one randomly-selected testimonial }
	{Dependencies=		$vTestimonial must be defined, otherwise there will be no output }
	{DevelNotes=		$vTestimonial is created in detail.inc. 
						This tag outputs the testimonial in ***one large block***, there is no pagination available.
						This tag checks the value of $vTestimonial, which comes from the Testimonial field on the content table }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputTestimonial');
	Define_Tag:'OutputTestimonial',
		-Description='Outputs either all or one randomly-selected testimonial';

		Local:'Result' = null;

		// Check if $vTestimonial is defined
		If: (Var:'vTestimonial') != '';

			If: $svDebug == 'Y';
				#Result += '<p class="debugCT">\n';
				#Result += '60: vTestimonial = ' ($vTestimonial) '</p>\n';
			/If;

			// Get all the testimonial records
			If: $vTestimonial == 'All';
				Var:'SQLSearchTestimonials' = 'SELECT ID, Testimonial_Head, Testimonial_Comment, Testimonial_Name, Testimonial_Thumb
				FROM ' $svTestimonialsTable ' WHERE Active = "Y" ORDER BY ID DESC';
			// Get a random testimonial record
			Else: $vTestimonial == 'Random';
				Var:'SQLSearchTestimonials' = 'SELECT ID, Testimonial_Head, Testimonial_Comment, Testimonial_Name, Testimonial_Thumb 				FROM ' $svTestimonialsTable ' WHERE Active = "Y" ORDER BY RAND() LIMIT 1';
			// Not defined, get a random record
			Else: $vTestimonial == '';
				Var:'SQLSearchTestimonials' = 'SELECT ID, Testimonial_Head, Testimonial_Comment, Testimonial_Name, Testimonial_Thumb 				FROM ' $svTestimonialsTable ' WHERE Active = "Y" ORDER BY RAND() LIMIT 1';
			/If;

			#Result +='<div class="TestimonialContainer">\n';

			Inline: $IV_Testimonials, -Table=$svTestimonialsTable, -SQL=$SQLSearchTestimonials;

				Records;
	
					Var:'vTestimonial_Head' = (Field:'Testimonial_Head');
					Var:'vTestimonial_Comment' = (Field:'Testimonial_Comment');
					Var:'vTestimonial_Name' = (Field:'Testimonial_Name');
					Var:'vTestimonial_Thumb' = (Field:'Testimonial_Thumb');
					#Result +='\t<table width="100%" class="TestimonialContainer">\n';
					#Result +='\t\t<tr>\n';
					If: $vTestimonial_Thumb != '';
//						#Result +='\t\t\t<td width="140">\n';
						#Result +='\t\t\t<td width="100">\n';
						#Result +='\t\t\t\t<p class="testimonial">\n';
						#Result +='\t\t\t\t\t<img src="'($svImagesThmbPath)($vTestimonial_Thumb)'" alt="'($vTestimonial_Thumb)'">\n';
					Else;
						#Result +='\t\t\t<td>\n';
						#Result +='\t\t\t\t<p class="testimonial">\n';
					/If;
					#Result +='\t\t\t</p></td>\n';
	
					#Result +='\t\t\t<td>\n';
					#Result +='\t\t\t\t<p class="testimonial">\n';
					If: ($vTestimonial_Head != '');
						#Result +='\t\t\t\t\t<strong>'($vTestimonial_Head)'</strong><br>\n';
					/If;
					#Result +='\t\t\t\t\t'($vTestimonial_Comment)'<br>\n';
					If: ($vTestimonial_Name != '');
						#Result +='\t\t\t\t\t<strong>'($vTestimonial_Name)'</strong><br>\n';
					/If;
	
					#Result +='\t\t\t</p></td>\n';
					#Result +='\t\t</tr>\n';
					#Result +='\t</table>\n';
	
				/Records;

			/Inline;

			#Result += '</div>\n';

			Else;

			If: $svDebug == 'Y';
				#Result += 'Testimonial content is undefined<br>\n';
			/If;

		/If;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputTestimonial';

/If;
?>