<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputStory }
	{Description=		Outputs either all or one randomly-selected story }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				1/15/09 }
	{Usage=				OutputStory }
	{ExpectedResults=	If $vStory = all, it outputs all the stories in one block
						If $vStory = random, it outputs one randomly-selected story }
	{Dependencies=		$vStory must be defined, otherwise there will be no output }
	{DevelNotes=		$vStory is created in detail.inc. 
						This tag outputs the story in ***one large block***, there is no pagination available.
						This tag checks the value of $vStory, which comes from the Story field on the content }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputStory');
	Define_Tag:'OutputStory',
		-Description='Outputs either all or one randomly-selected story';

		Local:'Result' = null;

		// Check if $vStory is defined
		If: (Var:'vStory') != '';

			If: $svDebug == 'Y';
				#Result += '<p class="debugCT">\n';
				#Result += '60: vStory = ' ($vStory) '</p>\n';
			/If;

			// Get all the story records
			If: $vStory == 'All';
				Var:'SQLSearchStories' = 'SELECT ID, Story_Head, Story_Comment, Story_Name, Story_Thumb FROM ' $svStoriesTable ' WHERE Active = "Y"';
			// Get a random story record
			Else: $vStory == 'Random';
				Var:'SQLSearchStories' = 'SELECT ID, Story_Head, Story_Comment, Story_Name, Story_Thumb FROM ' $svStoriesTable ' WHERE Active = "Y" ORDER BY RAND() LIMIT 1';
			// Not defined, get a random record
			Else: $vStory == '';
				Var:'SQLSearchStories' = 'SELECT ID, Story_Head, Story_Comment, Story_Name, Story_Thumb FROM ' $svStoriesTable ' WHERE Active = "Y" ORDER BY RAND() LIMIT 1';
			/If;

			#Result +='<div class="StoryContainer">\n';

			Inline: $IV_Stories, -Table=$svStoriesTable, -SQL=$SQLSearchStories;

				Records;
	
					Var:'vStory_Head' = (Field:'Story_Head');
					Var:'vStory_Comment' = (Field:'Story_Comment');
					Var:'vStory_Name' = (Field:'Story_Name');
					Var:'vStory_Thumb' = (Field:'Story_Thumb');
					#Result +='\t<table width="100%" class="StoryContainer">\n';
					#Result +='\t\t<tr>\n';
					If: $vStory_Thumb != '';
						#Result +='\t\t\t<td width="140" valign="top">\n';
						#Result +='\t\t\t\t<p class="StoryImage">\n';
						#Result +='\t\t\t\t\t<img src="'($svImagesThmbPath)($vStory_Thumb)'" alt="'($vStory_Thumb)'">\n';
					Else;
						#Result +='\t\t\t<td valign="top">\n';
						#Result +='\t\t\t\t<p class="StoryImage">\n';
					/If;
					#Result +='\t\t\t</p></td>\n';
	
					#Result +='\t\t\t<td>\n';

					If: ($vStory_Head != '');
						#Result +='\t\t\t\t<p class="StoryHead">\n';
						#Result +='\t\t\t\t\t'($vStory_Head)'<br>\n';
						#Result +='\t\t\t\t</p>\n';
					/If;

					If: ($vStory_Name != '');
						#Result +='\t\t\t\t<p class="StoryName">\n';
						#Result +='\t\t\t\t\t'($vStory_Name)'<br>\n';
						#Result +='\t\t\t\t</p>\n';
					/If;

					// Story_Comment is required field, so don't need a conditional
					#Result +='\t\t\t\t<p class="StoryContent">\n';
					#Result +='\t\t\t\t\t'($vStory_Comment)'<br>\n';
					#Result +='\t\t\t\t</p>\n';
	
					#Result +='\t\t\t</td>\n';
					#Result +='\t\t</tr>\n';
					#Result +='\t</table>\n';
	
				/Records;

			/Inline;

			#Result += '</div>\n';

			Else;

			If: $svDebug == 'Y';
				#Result += 'Story content is undefined<br>\n';
			/If;

		/If;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputStory';

/If;
?>
