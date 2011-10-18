<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputDropdownJS }
	{Description=		Outputs the already-built $DropdownJS }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				1/14/09 }
	{Usage=				OutputDropdownJS }
	{ExpectedResults=	Outputs the HTML in $DropdownJS }
	{Dependencies=		$DropdownJS must be defined, otherwise there will be no output }
	{DevelNotes=		$DropdownJS is created in build_dropdownJS.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputDropdownJS');
	Define_Tag:'OutputDropdownJS',
		-Description='Outputs $DropdownJS, which contains the header Javascript to be used with $DropdownHTML';

		Local('Result') = null;

		// Check if $DropdownJS is defined
		If: (Var_Defined:'DropdownJS');

			Return: (Encode_Smart:($DropdownJS));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputDropdownJS: $DropdownJS is undefined -->\n';

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputDropdownJS';

/If;
?>
