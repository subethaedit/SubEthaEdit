<?Lassoscript
// Last modified 11/11/07 by ECL, Landmann InterActive

/*
Tagdocs;
	{Tagname=			LI_BuildContentSelectList }
	{Description=		Builds a <select> list of Content IDs }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				9/19/07 }
	{Usage=				LI_BuildContentSelectList }
	{ExpectedResults=	A fully-formatted <select> list }
	{Dependencies=		Calls data from $svContentTable; will only select records with Field:'Active'="Y". $ContentIDSelect is defined in the manage_heirarchy page and is the ID of the content record. }
	{DevelNotes=		Upon first usage, it creates the variable $ContentIDRecordsArray. Subsequent usages use the existing variable. }
	{ChangeNotes=		 }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI_';

If:!(Lasso_TagExists:'LI_BuildContentSelectList');
	Define_Tag: 'BuildContentSelectList',
		-Description='Builds a select list of Content IDs',
		-namespace=$svCTNamespace;

		Local('Result') = null;

		// Set $ContentIDQueryRun = true when it is run. That avoids running the query more than once.
		Var:'ContentIDQueryRun' = boolean;
		
		// If $ContentIDQueryRun is not true, run the query
		If: $ContentIDQueryRun != true;
		
			Var:'SQLGetContentIDs' = '/* LI_BuildContentSelectList */
			SELECT ID, headline FROM ' $svContentTable '
				WHERE Active = "Y" ORDER BY headline';
			
					Inline: $IV_Content, -Table=$svContentTable, -SQL=$SQLGetContentIDs;
						Records;
							Var:'ContentIDRecordsArray' = (Records_Array);
						/Records;
					/Inline;
			
			// Set ContentIDQueryRun to true so it won't run again
			$ContentIDQueryRun = true;
		
		/If;
		
		If: (Var:'ContentIDRecordsArray') != '';
		
			#Result += '\t\t\t<select name="Content_ID">\n';
			#Result += '\t\t\t\t<option value=""';
		
			If: $ContentIDSelect == '';
				#Result += ' selected';
			/If;
			// NOTE: There is no default select message
			#Result += '></option>\n';
		
			Loop: ($ContentIDRecordsArray->size);
		
				// Get the first item of the array, which is the ID
				// Get the second item of the array, which is the name
				Local:'ThisContentID' = ($ContentIDRecordsArray->(Get:Loop_Count)->(Get:1));
				Local:'ThisContentHeadline' = ($ContentIDRecordsArray->(Get:Loop_Count)->(Get:2));
		
				#Result += '\t\t\t\t\t<option value="'(#ThisContentID) '"';
				If: $ContentIDSelect == #ThisContentID;
					#Result += ' selected';
				/If;
				#Result += '>';
				// If debug is on, add ID to select menu to show the ID
				If: $svDebug == 'Y';
					#Result += 'ID #'(#ThisContentID)' - ';
				/If;
				#Result += (#ThisContentHeadline)'</option>\n';
		
			/Loop;
		
			#Result += '\t\t\t\t</select>\n';

		/If;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_BuildContentSelectList';

/If;
?>