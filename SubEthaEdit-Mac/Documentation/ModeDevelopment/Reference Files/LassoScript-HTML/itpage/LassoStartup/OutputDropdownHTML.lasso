<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputDropdownHTML }
	{Description=		Outputs the already-built $DropdownHTML }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				1/14/09 }
	{Usage=				OutputDropdownHTML }
	{ExpectedResults=	Outputs the HTML in $DropdownHTML }
	{Dependencies=		$DropdownHTML must be defined, otherwise there will be no output }
	{DevelNotes=		$DropdownHTML is created in build_dropdownJS.inc
						This tag is merely a convenience to make it less awkward for a designer }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputDropdownHTML');
	Define_Tag:'OutputDropdownHTML',
		-Description='Outputs $DropdownHTML, which contains a secondary dropdown. Necessary header Javascript is generated in $DropdownJS, created in build_dropdownJSinc.';

		Local('Result') = null;

		// Check if $DropdownHTML is defined
		If: (Var_Defined:'DropdownHTML');

			$DropdownHTML += '<!-- OutputDropdownHTML -->\n';
			Return: (Encode_Smart:($DropdownHTML));

		Else;

			// Output a comment that variable is not defined
			#Result = '<!-- OutputDropdownHTML: $DropdownHTML is undefined -->\n';

			If: $svDebug == 'Y';
				#Result += '<strong>OutputDropdownHTML: </strong>$DropdownHTML is undefined<br>\n';
			/If;

			Return: (Encode_Smart:(#Result));

		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputDropdownHTML';

/If;
?>