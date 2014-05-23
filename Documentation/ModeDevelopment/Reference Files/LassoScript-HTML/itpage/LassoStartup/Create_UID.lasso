<?Lassoscript
// Last modified 11/11/07 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			Create_UID }
	{Description=		Create a Unique ID }
	{Author=			Pier Kuipers? or Chris Corwin? }
	{AuthorEmail=		 }
	{ModifiedBy=		Eric Landmann }
	{ModifiedByEmail=	support@iterate.ws }
	{Date=				 }
	{Usage=				Create_UID }
	{ExpectedResults=	Outputs a random ID of 12 digits }
	{Dependencies=		None }
	{DevelNotes=		 }
	{ChangeNotes=		 }
/Tagdocs;
*/
If: !(Lasso_TagExists: 'Create_UID');
	Define_Tag: 'Create_UID';
		Local: 'UID_Characters' = 'AaBb9CcDd8EeFf7GgHh6iJj5KkLm4NnoPp3QqRr2SsTt1UuVv9WwXx8YyZz';
		Local: 'UID_StringLength' = 12;
		Local: 'newUID' = (String);
		Loop: #UID_StringLength;
			Local: 'a_Character' = #UID_Characters->(Get:(Math_Random: -Min=1, -Max=(#UID_Characters->Size)));
			#newUID += #a_Character;
		/Loop;
		Return: #newUID;
	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - Create_UID';

/If;
?>
