<?Lassoscript
// Last modified 3/6/08 by ECL, Landmann InterActive

/*
Tagdocs;
	{Tagname=			LI_BuildPortfolioMultiSelect }
	{Description=		Builds a <select> list of Content IDs }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		}
	{ModifiedByEmail=	}
	{Date=				3/6/08 }
	{Usage=				LI_BuildPortfolioMultiSelect: -ID=$vPortfolioGroupID }
	{ExpectedResults=	A fully-formatted multiple <select> list }
	{Dependencies=		Calls data from $svPortfolioTable; will only select Field:'Active'='Y' records.
Requires a $vPortfolioGroupID to be passed to it which is the Portfolio Group ID. }
	{DevelNotes=		See proof of concept "filter_arrays_multiselect.lasso".
Filters from a Records_Array to another array.
Looking for whether a Portfolio ID is in the array and whether the group_id for that Portfolio ID is the value we are looking for.
Arrays must be built manually because the first element (Portfolio_ID) has to be an integer for sort to work correctly. }
	{ChangeNotes=		3/6/08
						First implementation }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI_';

If:!(Lasso_TagExists:'LI_BuildPortfolioMultiSelect');
	Define_Tag: 'BuildPortfolioMultiSelect',
		-Description='Builds a multiple select list of Portfolio Entries',
		-Required='ID',
		-namespace=$svCTNamespace;

		Local('Result') = null;

		// Initialize variables
		// Used to store the records_array from the search
		Local:'AllPFEntriesArray' = array;
		Local:'AssignedPFEntriesArray' = array;
		
		// THREE-STEP PROCESS
		// STEP 1 - Grab all portfolio entries
		// STEP 2 - Grab the portfolio entries assigned to the current portfolio group
		// STEP 3 - Combine the two arrays into a single array. Make sure the ID is unique.
		// RESULT of this process is that #AllPFEntriesArray will contain an array containing
		// unique Portfolio Entry IDs, with appropriate ones selected. The array will be sorted by ID.
		
		// STEP 1
		// Get ALL of the Portfolio Entries - Create the first array
		// Sorting the array is not necessary as it is already in order by portfolio_id
		Var:'SQLBuildPortfolio' = '/* Get ALL Portfolio Entries */
		SELECT pf.portfolio_id, pf.portfolio_thumb,
		/* This line adds a column called pg_groupID with a value of zero */
		Concat(0) AS pg_groupID
		FROM cms_portfolio AS pf WHERE pf.Active = "Y" ORDER BY pf.portfolio_id';
		Inline: $IV_Portfolios, -Table=$svPortfolioTable, -SQL=$SQLBuildPortfolio;
			Records;
				#AllPFEntriesArray->insert: (Array: (Integer:(Field:'portfolio_id')),(Field:'portfolio_thumb'),(Field:'pg_groupID'));
			/Records;
		/Inline;
		
		// STEP 2
		// Get the assigned Portfolio Entries - Create the second array
		Var:'SQLBuildPortfolio' = '/* Get Portfolio Entries ONLY for this group */
		SELECT pf.portfolio_id, pf.portfolio_thumb, pg2p.pg_groupid
		FROM cms_portfolio AS pf
		LEFT JOIN cms_pg2portfolio AS pg2p USING (portfolio_id)
		WHERE pf.Active = "Y" AND pg_groupID = ' $vPortfolioGroupID ' ORDER BY pf.portfolio_id';
		Inline: $IV_Portfolios, -Table=$svPortfolioTable, -SQL=$SQLBuildPortfolio;
			#AssignedPFEntriesArray = (Records_Array);
		/Inline;
		
		If: $svDebug == 'Y';
			#Result += '<p class="debugCT">\n';
			#Result += '58: <b>AllPFEntriesArray</b> is <b> ' (#AllPFEntriesArray->Size) '</b> elements<br>\n';
			#Result += '58: <b>AllPFEntriesArray</b> = ' (#AllPFEntriesArray) '<br>\n';
			#Result += '58: <b>AssignedPFEntriesArray</b> is <b> ' (#AssignedPFEntriesArray->Size) '</b> elements<br>\n';
			#Result += '58: <b>AssignedPFEntriesArray</b> = ' (#AssignedPFEntriesArray) '</p>\n';
		/If;
		
		// STEP 3
		// Loop through the AssignedPFEntriesArray. Find the loop_count in the AllPFEntriesArray.
		// Delete the AllPFEntriesArray element, and insert the AssignedPFEntriesArray element
		// This results in that entry having a value in pg_groupid
		Loop:(#AssignedPFEntriesArray)->Size;
		
			Local:'DeleteThisElement' = integer;
			Local:'ThisAssignedElementID' = (Integer:(#AssignedPFEntriesArray->(Get:(Loop_Count))->(Get:1)));
			Local:'ThisAssignedElementThumb' = #AssignedPFEntriesArray->(Get:(Loop_Count))->(Get:2);
			// Put element into an array for searching. Note appended '0' on the end so the array matches Step 1
			Local:'FindThisElement' = (Array: (#ThisAssignedElementID), (#ThisAssignedElementThumb), '0');
			// Put the FINAL array element into #ReplaceThisElement. This will be used to replace. It contains the correct $vPortfolioGroupID
			Local:'ReplaceThisElement' = (Array: (#ThisAssignedElementID), (#ThisAssignedElementThumb), ($vPortfolioGroupID));
		
			If: $svDebug == 'Y';
				#Result += '<p class="debugCT">\n';
				#Result += '76: <b>Loop_Count</b> = ' (Loop_Count) '<br>\n';
				// #Result += '76: <b>FindThisElement</b> = ' (#FindThisElement) '<br>\n';
				// #Result += '76: <b>ReplaceThisElement</b> = ' (#ReplaceThisElement) '<br>\n';
				#Result += '76: <b>ThisAssignedElementID</b> = ' (#ThisAssignedElementID) '<br>\n';
			/If;
			// Get the index (position) in the array of the element in AllPFEntriesArray
			// If it exists (which it always should), replace it with the element from AssignedPFEntriesArray
			If: (#AllPFEntriesArray->(find:(#FindThisElement)));
				Local:'DeleteThisElement' = #AllPFEntriesArray->(FindIndex:(#FindThisElement));
				If: $svDebug == 'Y';
					#Result += '104: Found the Element<br>\n';
					#Result += '104: The Index is: <b>DeleteThisElement</b> = ' (#DeleteThisElement) '<br>\n';
				/If;
				#AllPFEntriesArray->remove:(#DeleteThisElement->Get:1);
				#AllPFEntriesArray->insert:(#ReplaceThisElement);
			Else;
				Local:'DeleteThisElement' = integer;
				If: $svDebug == 'Y';
					#Result += '104: Did NOT find the Element</p>\n';
				/If;
			/If;
		
		/Loop;
		
		// Sort the array. This will now work because the ID is an integer. Yay!
		#AllPFEntriesArray->(Sort:True);
		
		If: $svDebug == 'Y';
			#Result += '<p class="debugCT">\n';
			#Result += '100: <b>AllPFEntriesArray</b> is <b> ' (#AllPFEntriesArray->Size) '</b> elements<br>\n';
			#Result += '100: <b>AllPFEntriesArray</b> = ' #AllPFEntriesArray ' </p>\n';
		/If;
		
		// NOW - Build the Select box
		Loop: (#AllPFEntriesArray->size);

			// Used to display whether an ID is selected in the select list
			Local:'IsSelected' = string;

			// Get the first item of the array, which is the ID
			// Get the second item of the array, which is the thumb
			// Get the third item of the array, which is the Portfolio Group ID
			Local:'ThisEntryID' = (#AllPFEntriesArray->(Get:Loop_Count)->(Get:1));
			Local:'ThisEntryThumb' = (#AllPFEntriesArray->(Get:Loop_Count)->(Get:2));
			Local:'ThisEntryGroupID' = (#AllPFEntriesArray->(Get:Loop_Count)->(Get:3));

			// Compare the record's pg_groupid to the PortfolioGroupID. If a match, select it in list
			If: (#ThisEntryGroupID) == $vPortfolioGroupID;
				#IsSelected = ' selected';
			/If;

			#Result += '\t\t<option value="'(#ThisEntryID)'"'(#IsSelected)'>ID '(#ThisEntryID)' - '(#ThisEntryThumb)'</option>\n';

		/Loop;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_BuildPortfolioMultiSelect';

/If;
?>