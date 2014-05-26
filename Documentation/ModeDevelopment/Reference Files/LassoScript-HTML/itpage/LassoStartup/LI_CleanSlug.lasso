<?Lassoscript
// Last modified 4/2/08 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_CleanSlug }
	{Description=		Cleans the input to make it suitable for use as an URL slug. }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				4/2/08 }
	{Usage=				LI_CleanSlug: -NodeName=$URLSlug }
	{ExpectedResults=	Input: ¿Por qué es esta código?
						Output: por que es esta codigo }
	{Dependencies=		A number of tags from the Lasso Pro library:
						lp_string_extendedtoplain
						lp_string_CP1252toUTF8.lasso
						lp_logical_in.lasso
						lp_logical_between.lasso
						lp_string_zap.lasso }
	{DevelNotes=		Strips question marks, periods, commas, quotes, dashes, exclam, percent, dollar.
						Converts UTF8 characters to plain ASCII. }
	{ChangeNotes=		4/2/08
						First implementation }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI_';

If: !(Lasso_TagExists:'CleanSlug');
	Define_Tag: 'CleanSlug',
		-Required='NodeName',
		-Priority='replace',
		-Description='Cleans the input to make it suitable for use as an URL slug',
		-namespace=$svCTNamespace;

		Local('Result') = null;

		// Process the Headline to produce the URLSlug
		#Result = (String_LowerCase:(lp_string_extendedtoplain: #NodeName));
		// Strip question marks, periods, commas, quotes, dashes, exclam, percent, dollar
		#Result = (String_Replace: #Result, -Find='?', -Replace=' ');
		#Result = (String_Replace: #Result, -Find='.', -Replace=' ');
		#Result = (String_Replace: #Result, -Find=',', -Replace=' ');
		#Result = (String_Replace: #Result, -Find='"', -Replace=' ');
		#Result = (String_Replace: #Result, -Find='\'', -Replace=' ');
		#Result = (String_Replace: #Result, -Find='-', -Replace=' ');
		#Result = (String_Replace: #Result, -Find='!', -Replace=' ');
		#Result = (String_Replace: #Result, -Find='%', -Replace=' ');
		#Result = (String_Replace: #Result, -Find='$', -Replace=' ');
		// Compress multiple spaces down to one
		#Result = (String_ReplaceRegExp:#Result, -Find='\\s+', -Replace=' ');
		#Result->Trim;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_CleanSlug';

/If;

?>