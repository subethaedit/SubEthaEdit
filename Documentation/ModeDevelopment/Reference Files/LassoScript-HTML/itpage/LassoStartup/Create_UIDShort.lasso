<?Lassoscript
// Last modified 11/11/07 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			Create_UIDShort }
	{Description=		Create a Unique ID - only 3 digits long }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				 }
	{Usage=				Create_UIDShort }
	{ExpectedResults=	Outputs a random ID of 3 digits }
	{Dependencies=		None }
	{DevelNotes=		Used by upload system to append a random ID of only 3 digits to the uploaded images/files }
	{ChangeNotes=		 }
/Tagdocs;
*/
If: !(Lasso_TagExists: 'Create_UIDShort');
	Define_Tag: 'Create_UIDShort';
		Local: 'UID_Characters' = 'AaBb9CcDd8EeFf7GgHh6iJj5KkLm4NnoPp3QqRr2SsTt1UuVv9WwXx8YyZz';
		Local: 'UID_StringLength' = 3;
		Local: 'newUID' = (String);
		Loop: #UID_StringLength;
			Local: 'a_Character' = #UID_Characters->(Get:(Math_Random: -Min=1, -Max=(#UID_Characters->Size)));
			#newUID += #a_Character;
		/Loop;
		Return: #newUID;
	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - Create_UIDShort';

/If;
?>
