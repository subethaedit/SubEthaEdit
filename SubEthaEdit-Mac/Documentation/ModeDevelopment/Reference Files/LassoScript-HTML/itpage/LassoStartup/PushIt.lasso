<?Lassoscript
// Last modified 11/11/07 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			PushIt }
	{Description=		Pushes content from the server to the browser. }
	{Author=			Unknown }
	{AuthorEmail=		}
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				}
	{Usage=				PushIt: 'output this string' }
	{ExpectedResults=	HTML content pushed to a browser }
	{Dependencies=		None }
	{DevelNotes=		This tag is used when you have a large, long-running page that you want to push content incrementally to the browser. Works only with Apache 1.3. }
	{ChangeNotes=		 }
/Tagdocs;
*/
If: !(Lasso_TagExists: 'PushIt');
	Define_Tag:'PushReply',-priority='replace',-required='reply';
		$__html_reply__ += string: #reply;
	/Define_Tag;
	
	Define_Tag:'PushIt',-priority='replace',-required='reply';
		PushReply: #reply;
		Server_Push;
	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - PushIt';

/If;
?>