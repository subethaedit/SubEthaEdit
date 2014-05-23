<?Lassoscript
// Last modified 5/29/08 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_FileStream }
	{Description=		Stream a file to the browser }
	{Author=			Adam Randall }
	{AuthorEmail=		}
	{ModifiedBy=		Eric Landmann }
	{ModifiedByEmail=	support@iterate.ws }
	{Date=				9/10/2004 }
	{Usage=				LI_FileStream: -File='filename' }
	{ExpectedResults=	A file streamed to the browser }
	{Dependencies=		}
	{DevelNotes=		}
	{ChangeNotes=		* Author: Adam Randall
						* Company: Xaren Consulting
						* Date: 1/14/2004
						* Modified: 9/10/2004
						* Version: 1.1
						*
						* This tag will allow you to stream a very large
						* file, while utilizing a very small amount of
						* resources. Load on the server should be minimal.
						* Usage: FileStream: -File='filename'
						5/29/08 ECL
						Added notes about buffer }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI';

If: !(Lasso_TagExists: 'LI_FileStream');

	Define_Tag: 'FileStream',
		-required = 'File',
		-optional = 'Name',
		-optional = 'Type',
		-optional = 'Buffer',
		-priority = 'Replace',
		-Namespace = $svCTNamespace;

		If: (lasso_tagexists: 'lasso_executiontimelimit');
			lasso_executiontimelimit: 0;
		/If;

		If: (Local_defined: 'buffer');
			Local: '_buffer' = (integer: #buffer);
		Else;

			// Eric's Notes:
			// buffer set to 30000 will yield these download times:
			// About 6 minutes for 48Mb Photoshop file
			// About 6 seconds for 1.6Mb Illustrator file
			Local: '_buffer' = 30000;
		/If;

		Local:
			'file_size' = (file_getsize: #file);

		If: !(Local_defined: 'type');
			Local: 'type' = 'application/octet-stream';
		/If;

		If: !(Local_defined: 'name');
			Local: 'safename' = #file->(split: '/')->last;
		Else;
			Local: 'safename' = #name;
		/If;
		#safename->(replace: '"', '\\"');

		If: (file_currenterror) == 'No error';

			$__http_header__ = 'HTTP/1.0 200 OK\r\n';
			$__http_header__ += 'Server: Lasso/' (lasso_version: -lassoversion)->(get: 1) '\r\n';
			$__http_header__ += 'MIME-Version: 1.0\r\n';
			$__http_header__ += 'Content-Type: ' #type '\r\n';
			$__http_header__ += 'Content-Disposition: attachment; filename="' #safename '"\r\n';
			$__http_header__ += 'Content-Length: ' #file_size '\r\n';

		Loop:
			-Loopfrom = 0,
			-Loopto = ((math_ceil: #file_size / (decimal: #_buffer)) - 1),
			-Loopincrement = 1;

				Local: 'start' = (Loop_count) * #_buffer;
				Local: 'end' = #start #_buffer;

				If: #end > #file_size;
					#end = #file_size;
				/If;

				$__html_reply__ = (file_read:
					#file,
					-filestartpos = #start,
					-fileendpos = #end);

				server_push;

			/Loop;

			server_push; // just in case
			abort;

		Else;
			fail: -1, 'No permission to file';
		/If;

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_FileStream';

/If;


?>