<?Lassoscript
// Last modified 11/11/07 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_ShowError3 }
	{Description=		Show Error version 3.0.1 }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				6/19/06 }
	{Usage=				LI_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption'); }
	{ExpectedResults=	Fully-formatted HTML error box }
	{Dependencies=		Error messages are in $svErrorsTable }
	{DevelNotes=		CSS VERSION uses colors coded into the style sheet
						See style sheet for styles named "ErrorBoxPos" and "ErrorBoxNeg" }
	{ChangeNotes=		11/11/07
						Recoded for itPage v 3.0 }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI_';

If: !(Lasso_TagExists:'LI_ShowError3');
	Define_Tag: 'ShowError3',
		-Namespace = $svCTNamespace,
		-Required = 'ErrNum',
		-Optional = 'Option';

		Local:'Result' = '';

		If: #ErrNum != '';
			Inline: -Database=$svSiteDatabase, -Table=$svErrorsTable,
				-UserName=$svSiteUsername,-Password=$svSitePassword,
				-SQL="/* LI_ShowError3 */
					SELECT Code, Message, Title, Attrib FROM " $svErrorsTable "
					WHERE Code = '" (#ErrNum) "' LIMIT 1";
					Local:'vErr' = (Error_CurrentError) ' -- ' (Error_CurrentError: -ErrorCode);
					Local:'vErrNo' = (Error_CurrentError: -ErrorCode);

				If: #vErrNo == 0;
					If: (Found_Count)== 0;
						#Result += '<div ID="ErrorBoxHeadNeg">\n'
							'\t<div class="ErrorHeadNeg">No Error Message Found</div>\n'
							'</div>\n';
					Else;

						// Get Attribute from database and output Title
						If: (Field:'Attrib') == 'Pos';
							#Result = '<div ID="ErrorBoxHeadPos">\n'
							'\t<div class="ErrorHeadPos">'(Field:'Title')'</div>\n'
							'</div>\n';
						Else;
							#Result = '<div ID="ErrorBoxHeadNeg">\n'
							'\t<div class="ErrorHeadNeg">'(Field:'Title')'</div>\n'
							'</div>\n';
						/If;

						// Output the message div
						If: (Field:'Attrib') == 'Pos';
							#Result += '<div ID="ErrorBoxMessagePos">\n'
							'\t<div class="ErrorMessagePos">';
						Else;
							#Result += '<div ID="ErrorBoxMessageNeg">\n'
							'\t<div class="ErrorMessageNeg">';
						/If;

						// Output the Message
						If: #Option != '';
							#Result += (String_Replace: (Field:'Message'), -Find='<form_input>', -Replace=#Option);
						Else;
							#Result += (Field:'Message');
						/If;

						// Output closing divs
						#Result += '</div>\n';
						#Result += '</div>\n';

					/If;
				Else;
					#Result += #vErr;
				/If;
			/Inline;
		Else;
			// Output top of table
			#Result = '<div ID="ErrorBoxHeadNeg">\n'
				'\t<div class="ErrorHeadNeg">UNKNOWN ERROR</div>\n'
				'</div>\n'
				'<div ID="ErrorBoxMessageNeg">\n'
				'\t<div class="ErrorMessageNeg">EXCEPTION: An Unknown Error was Generated</div>\n'
				'</div>\n';
		/If;

		Return: Encode_Smart:(#Result);

	 /Define_Tag; 

	Log_Critical: 'Custom Tag Loaded - LI_ShowError3';

/If;

?>