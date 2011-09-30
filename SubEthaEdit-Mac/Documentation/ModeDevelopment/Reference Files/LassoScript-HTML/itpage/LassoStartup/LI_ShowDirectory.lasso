<?Lassoscript
// Last modified 9/17/07 by ECL
/*
Tagdocs;
	{Tagname=			LI_ShowDirectory }
	{Description=		Show Directory Tag }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				9/17/07 }
	{Usage=				LI_ShowDirectory: -Directory='/help/', -AsLinks=true; }
	{ExpectedResults=	A formatted directory display of any directory passed to it. }
	{Dependencies=		 }
	{DevelNotes=		If #AsLinks is true, will display each document as a link }
	{ChangeNotes=		 }
/Tagdocs;
*/

If: !(Lasso_TagExists: 'LI_ShowDirectory');

	Define_Tag: 'ShowDirectory',
		-Namespace=$svCTNamespace,
		-Required = 'Directory',
		-Optional = 'AsLinks';

		// Get Folders from the /help folder
		Inline: -Nothing, -Username=$svSiteUsername, -Password=$svSitePassword;

			Local:'Result' = string;
			Local:'WhichDir' = #Directory;
			Local:'File_Listing' = #Directory;
			Local:'x' = integer;
		
			// List the directory recursively
			Local:'x' = 0;

			Inline: -Nothing, -Username=$svSiteUsername, -Password=$svSitePassword;
				#File_Listing = (File_ListDirectory: (#WhichDir));
				If: $svDebug == 'Y';
					#Result += '<p class="debugCT"><strong>LI_ShowDirectory</strong><br> ' #File_Listing' <br>\n';
					#Result += '30: File_Listing = ' #File_Listing ' <br>\n';
				/If;
			/Inline;
		
			// Display files in the directory
			Loop: (#File_Listing->Size);
				If: $svDebug == 'Y';
					#Result += '44: Loop_Count = ' (Loop_Count) '<br>\n';
				/If;
				If:(Loop_Count) != #x;
					// This gets the filename
					Local:'ThisFile' = (#File_Listing)->(get:(Loop_Count));
						// Display file if not starting with a period
						If: !((#ThisFile)->BeginsWith('.'));
							Local('DirectoryName_Clean' = (#ThisFile));
							#DirectoryName_Clean->RemoveTrailing('/');
							// Build the link
							'\t\t\t\t';
							If: #AsLinks == true;
								#Result += '\t\t\t\t<a href="/help/'(#DirectoryName_Clean)'" class="menuBoxContentLink"><b>' (#DirectoryName_Clean) '</b></a>\n';
							Else;
								#Result += '\t\t\t\t'(#DirectoryName_Clean)'\n';
							/If;

							If: ((Loop_Count) >> 1) && ((Loop_Count) != #x);
								#Result += '\t\t\t\t<br>\n';
							/If;
						/If;
				/If;
			/Loop;

		If: $svDebug == 'Y';
			#Result += '</p>\n';
		/If;

		Return: (Encode_Smart:#Result); 
	
		/Inline;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_ShowDirectory';

/If;

?>