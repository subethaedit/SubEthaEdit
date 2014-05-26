<?Lassoscript 
// Last modified 6/6/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_GetContentLink }
	{Description=		Gets content pages based upon HeirarchyID }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				1/24/08 }
	{Usage=				LI_GetContentLink: -ID='24', -css_id='18'; }
	{ExpectedResults=	A link to a content page }
	{Dependencies=		Needs to be fed a HeirarchyID }
	{DevelNotes=		If no Heirarchy ID is provided, no output will occur
						STATUS: Currently unused }
	{ChangeNotes=		1/23/08
						First implementation
						6/6/09
						Modifying this to pass a CSS id }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI_';

If:!(Lasso_TagExists:'LI_GetContentLink');
	Define_Tag: 'GetContentLink',
		-Required='ID',
		-Required='css_class',  -type='string',
		-Priority='replace',
		-Description='Gets pages of content based upon HeirarchyID',
		-namespace=$svCTNamespace;

		Local('Result') = null;

		Var:'SQLGetContent' = 'SELECT ID, Headline FROM '$svSiteDatabase'.'$svContentTable' WHERE HeirarchyID = "' (#ID) '" AND Active="Y"';
		Inline: $IV_Content,  -Table=$svContentTable, -SQL=$SQLGetContent;
			If: (Found_Count) > 0;
				Records;		
					If: $svDebug == 'Y';
						#Result += ('<span class="ghost">'(Field:'id')'&nbsp;</span>');
					/If;
					// If a root link, call style "indent0off"
					If: $ThisFieldDepth == 0;
						Var('IndentStyle' = '0off');
					Else;
						Var('IndentStyle' = $ThisFieldDepth);
					/If;
					#Result += ('<a href id="'(Field:'id')'">'(Field:'Headline')'</a>');
				/Records;
			/If;
		/Inline;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_GetContentLink';

/If;
?>
