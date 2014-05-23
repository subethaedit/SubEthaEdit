<?Lassoscript
// Last modified 9/28/08 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			Debug }
	{Description=		Creates a debug container }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				6/23/08 }
	{Usage=				Debug;
							'SomeVar = ' $SomeVar '<br>\n';
						/Debug; }
	{ExpectedResults=	If $svDebug = Y, contents of debug container will be output
						If $svDebug != Y, nothing will output }
	{Dependencies=		$svDebug must be set. It is set in siteconfig.lasso, but can also be set anywhere upstream of where Debug is called. }
	{DevelNotes=		Optional parameter "Quiet" is not finished. }
	{ChangeNotes=		4/2/08
						First implementation
						}
/Tagdocs;
*/
If: !(Lasso_TagExists:'Debug');
	Define_Tag: 'Debug',
		-Optional='Quiet',
		-Container;

		Local('Output') = string;

		Local('Start') = ('<p class="debug"><strong>' + (Response_Filepath) + '</strong><br>\n');
		Local('End' = '</p>\n');
		If: (Var:'svDebug') == 'Y';
			#Output = ((#Start) + (Run_Children) + (#End));
		Else;
			// Output nothing
		/If;
		Return(Encode_Smart(#Output));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - Debug';

/If;

/*
// Testing
Var:'svDebug' = 'Y';
Var:'SomeVar' = 'booha';

Debug;
	'SomeVar = ' $SomeVar '<br>\n';
/Debug;
*/
?>
