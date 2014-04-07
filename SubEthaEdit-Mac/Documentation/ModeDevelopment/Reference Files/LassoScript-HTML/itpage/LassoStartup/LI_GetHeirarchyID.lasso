<?Lassoscript 
// Last modified 2/15/08 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_GetHeirarchyID }
	{Description=		Gets the Heirarchy ID for a given content page }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				2/15/08 }
	{Usage=				LI_GetHeirarchyID: -ID='24' }
	{ExpectedResults=	The ID of the Heirarchy assigned to that content page
						If no content ID is provided, no output will occur }
	{Dependencies=		Needs to be fed a ContentID }
	{DevelNotes=		If no content ID is provided, no output will occur }
	{ChangeNotes=		2/15/08
						First implementation }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI_';

If:!(Lasso_TagExists:'LI_GetHeirarchyID');
	Define_Tag: 'GetHeirarchyID',
		-Required='ID',
		-Priority='replace',
		-Description='Gets HeirarchyID for a given content page',
		-namespace=$svCTNamespace;

		Local('Result') = null;

		Var:'SQLGetHeirarchyID' = '/* LI_GetHeirarchyID */ SELECT HeirarchyID FROM '$svSiteDatabase'.'$svContentTable' WHERE ID = "' (#ID) '"';
		Inline: $IV_Content, -Table=$svContentTable, -SQL=$SQLGetHeirarchyID;
			Records;		
//				If: $svDebug == 'Y';
//					#Result += ('<p class="debugCT"><strong>LI_GetHeirarchyID</strong><br>\n');
//					#Result += ('HeirarchyID = '(Field:'HeirarchyID')'<br>');
//					#Result += ('Error_CurrentError = ' (Error_CurrentError) '</p>\n');
//				Else;
					#Result = (Field:'HeirarchyID');
//				/If;
			/Records;
		/Inline;

		If: $svDebug == 'Y';
			Return: (Encode_Smart:(#Result));
		Else;
			Return: (#Result);
		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_GetHeirarchyID';

/If;
?>
