<?Lassoscript
// Last modified 1/16/07 by ECL
/*
Tagdocs;
	{Tagname=			LI_StringRemoveHTML }
	{Description=		Strips HTML tags from the given string. Attempts to preserve some formatting. }
	{Author=			Jason Huck }
	{AuthorEmail=		1/16/07 }
	{ModifiedBy=		Eric Landmann }
	{ModifiedByEmail=	support@iterate.ws }
	{Date=				 }
	{Usage=				LI_StringRemoveHTML }
	{ExpectedResults=	Strips all HTML tags from the given string. Attempts to preserve some formatting. }
	{Dependencies=		None }
	{DevelNotes=		 }
	{ChangeNotes=		1/16/07
						Renamed this tag from original string_removehtml to LI_StringRemoveHTML for ease of management on itPage.
						Downloaded from tagSwap.net on Dec. 17, 2007.
						Latest version available from <http://tagSwap.net/string_removehtml>. }
/Tagdocs;
*/
define_tag(
	'StringRemoveHTML',
	-namespace='LI_',
	-priority='replace',
	-required='text',
	-type='string',
	-optional='linebreak',
	-type='string',
	-description='Strips HTML tags from the given string. Attempts to preserve some formatting.'
);	
	local('out') = params->first;
	!local_defined('linebreak') ? local('linebreak' = '\n');

	#out = string_replaceregexp(
		#out,
		-find='\\s+',
		-replace=' ',
		-ignorecase
	);

	#out = string_replaceregexp(
		#out,
		-find='(?s)<br.+?>',
		-replace=#linebreak,
		-ignorecase
	);

	#out = string_replaceregexp(
		#out,
		-find='(?s)<p.+?>',
		-replace=(#linebreak * 2),
		-ignorecase
	);

	#out = string_replaceregexp(
		#out,
		-find='(?s)<.+?>',
		-replace='',
		-ignorecase
	);

	#out = decode_html(#out);

	return(@#out);

	Log_Critical: 'Custom Tag Loaded - LI_StringRemoveHTML';

/define_tag;

?>
