<?Lassoscript
// Last modified: 5/20/08 by ECL, Landmann InterActive

/*
Tagdocs;
	{Tagname=			LI_CloakEmail }
	{Description=		Creates a Javascript that cloaks the e-mail }
	{Author=			Greg Willits }
	{AuthorEmail=		 }
	{ModifiedBy=		Eric Landmann }
	{ModifiedByEmail=	support@iterate.ws }
	{Date=				5/20/08 }
	{Usage=				LI_CloakEmail: -Address='you@yourdomain.com', -DisplayName='Me' }
	{ExpectedResults=	<script language=javascript>
<!-- Output from LI_CloakEmail -->
<!--
var username = "you";
var server = "yourdomain";
var tld =  "com";
var display = "My Email";
document.write("<a href=" + "mail" + "to:" + username + "@" + server + "." + tld + ">" + display + "</a>")
//-->
</script>
}
	{Dependencies=		None }
	{DevelNotes=		Original idea for this tag came from Greg Willits }
	{ChangeNotes=		}
/Tagdocs;
*/

Var:'svCTNamespace' = 'LI_';

If: !(Lasso_TagExists:'LI_CloakEmail');

	Define_Tag:'CloakEmail',
		-Required = 'Address',
		-Required = 'DisplayName',
		-Namespace = $svCTNamespace;
	
		Local:'Result' = (string);
		Local:'username' = (string);
		Local:'domain' = (string);
		Local:'server' = (string);
		Local:'tld' = (string);
		
		Local('username') = (#Address->Split('@')->First);
		Local('domain') = (#Address->Split('@')->Last);
		Local('server') = (#domain->Split('.')->First);
		Local('tld') = (#domain->Split('.')->Last);

		#Result += '<script type="text/javascript" language="JavaScript">\n';
		#Result += '<!-- Output from LI_CloakEmail -->\n';
		#Result += '<!--\n';
		#Result += 'var username = "'(#username)'";\n';
		#Result += 'var server = "'(#server)'";\n';
		#Result += 'var tld =  "'(#tld)'";\n';
		#Result += 'var display = "'(#DisplayName)'";\n';
		#Result += 'document.write("<a href=" + "mail" + "to:" + username + "@" + server + "." + tld + ">" + display + "<\/a>")\n';
		#Result += '//-->\n';
		#Result += '</script>\n';

		Return: Encode_Smart(#Result);

	/Define_Tag;

 /If;

?>