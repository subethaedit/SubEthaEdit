<?Lassoscript
// Last modified 8/30/09 by ECL

?><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<title>CT Scanner</title> 
	<link type="text/css" rel="stylesheet" href="admin.css">
</head>
<body>
<?Lassoscript
/*
Tagdocs;
	{Tagname=			CTDump }
	{Description=		Dumps all custom tags in the /LassoStartup folder }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				8/31/09 }
	{Usage=				CTDump }
	{ExpectedResults=	A nicely-formatted tag dump }
	{Dependencies=		For security reasons, does NOT dump tags in the Lasso Professional folder, but instead dumps the files in the /LassoStartup folder of the site virtual host. If there's nothing in that folder, you won't get any output. }
	{DevelNotes=		For CTDump to work, the header information must be in "TagDocs" format. See the wiki for information on that definition. }
	{ChangeNotes=		8/31/09
						First implementation }
/Tagdocs;
*/

Define_Tag:'CTDump', -autooutput, -priority='replace';

	// #TagElements are the individual tag "elements" that we extract to display
	Local(
		'Folder' = '/LassoStartup/',
		'CTFileArray' = (array),
		'Filename' = (string),
		'Result' = (string),
		'TagElements' = array('TagName', 'Author', 'AuthorEmail', 'ModifiedBy', 'ModifiedByEmail', 'Date', 'Description', 'DevelNotes', 'ChangeNotes', 'Usage',  'ExpectedResults', 'Dependencies'));

	// Look in #Folder for all CTs, iterate through each one individually
	#CTFileArray = (File_ListDirectory(#Folder));
	If: $svDebug == 'Y';
		#Result += '<p class="debugCT">\n';
		#Result += ('37: CTFileArray = ' + (#CTFileArray) + '<\p>\n');
	/If;

	// Output number of custom tag files
	#Result += ('<p>Found: ' (#CTFileArray->size) ' custom tag files</p>\n');

	Iterate: #CTFileArray, #Filename;

	// #TagElements are the individual tag "elements" that we extract to display
	Local(
		'ThisElement' = (string),
		'ThisTagname' = (string),
		'ThisTagnameOutput' = (string),
		'ThisTagnameOutSplit' = (string),
		'FileContents' = (null),
		'TagHeader' = (null),
		'ThisTagnameOutSplit' = (null));

		If: $svDebug == 'Y';
			#Result += '<p class="debugCT">\n';
			#Result += ('<strong>CTScanner.lasso</strong></br>\n');
			#Result += ('54: Filename = ' + (#Filename) + '</p>\n');
		/If;

		If( (#Filename->(BeginsWith('.')) == false) && (File_IsDirectory(#Filename) == false));

			#FileContents = (Include_Raw((#Folder)+(#Filename)));
			If: $svDebug == 'Y';
				#Result += '<p class="debugCT">\n';
				#Result += ('64: FileContents = ' + (#FileContents) + '</p>\n');
			/If;

// From PB 	#comments=(string_findRegExp: #fileText, -find='/\\*.+?\\*/', -ignorecase);
			Protect;
				#TagHeader = (String_FindRegExp(#FileContents, -Find='(?is)tagdocs;(.*)/tagdocs;')->get(2));
			/Protect;

			If: $svDebug == 'Y';
				#Result += '<p class="debugCT">\n';
				#Result += ('54: TagHeader = ' + (#TagHeader) + '<br>\n');
			/If;

			// Output starting container and filename
			#Result += ('<div class="TagContainer">\n');
			#Result += ('<h2 class="TagFilename">' + (#Filename) + '</h2>\n');

			If(#TagHeader->size == 0);
				#Result += ('<p><strong>Error:</strong> No Tagdocs defined.</p>\n');

			// Extract individual elements
			Else;

				// Iterate through the TagElements array
				Iterate: #TagElements, Local('i');

// Works for tags with ONE LINE, but NOT multiple lines
//					#ThisTagnameOutput=(String_FindRegExp(#TagHeader, -Find=('\\{'(#i)'=(.+?)\\}'), -IgnoreCase));
// WORKS - but not all found, stops at } or end of one line
//					#ThisTagnameOutput=(String_FindRegExp(#TagHeader, -Find=('(?i)'(#i)'=(.*)}*?'), -IgnoreCase));
// From PB			#rsrcType=(string_findRegExp: #thisComment, -find='\\{rsrcType=(.+?)\\}', -ignorecase);
//					#ThisTagnameOutput=(String_FindRegExp(#TagHeader, -Find=('\\{'(#i)'=(.+?)\\}'), -IgnoreCase));
// WORKS - All found, multiple lines after search string
//					#ThisTagnameOutput=(String_FindRegExp(#TagHeader, -Find=('(?is){'(#i)'=(.*)}'), -IgnoreCase));
// WORKS - All found, multiple lines after search string, LEAVES trailing {
// Using this for now
	 				#ThisTagnameOutput=(String_FindRegExp(#TagHeader, -Find=('(?is){'(#i)'=(.*)}*?'), -IgnoreCase));

					// Split the string, grab the second part
					If(#ThisTagnameOutput->size > 0);
						#ThisTagnameOutput = (#ThisTagnameOutput->get:2);
						#ThisTagnameOutput->trim;
					/If;

					// Output the tag element only if there is some value
					If(#ThisTagnameOutput != '');

						If: $svDebug == 'Y';
							#Result += '<p class="debugCT">\n';
							#Result += ('<br>89: <strong>' #i + '</strong> = ' + (#ThisTagnameOutput) + '</p>\n');
						/If;

						// MESSY but necessary because can't get the second regex to do what we need
						// Split on the first }
						// Need to protect this block because there may be nothing in #ThisTagnameOutput
						Protect;
							#ThisTagnameOutSplit = (#ThisTagnameOutput->Split('}')->First);
	
							If: $svDebug == 'Y';
								#Result += '<p class="debugCT">\n';
								#Result += ('95: <strong>ThisTagnameOutSplit</strong> = ' + (#ThisTagnameOutSplit) + '</p>\n');
							/If;
	
							If(#ThisTagnameOutput != '');
								#Result += ('<div class="TagName">' + #i + '\n');
								#Result += ('<div class="TagValue">' + (Output:#ThisTagnameOutSplit, -EncodeBreak) + '</div>\n');
								#Result += ('</div>\n');
							/If;
	
						/Protect;

					/If;

				/Iterate;
			/If;
		/If;

		#Result += ('</div>\n');

	/Iterate;

	Return: (Encode_Smart:#Result);

/Define_Tag;

Log_Critical: 'Custom Tag Loaded - CTDump';

?>
