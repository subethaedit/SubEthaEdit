<?Lassoscript
// Last modified 6/19/09 by ECL, Landmann InterActive

/*
Tagdocs;
	{Tagname=			LI_BuildGalleryMultiSelect }
	{Description=		Builds a <select> list of Content IDs }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				6/19/08 }
	{Usage=				LI_BuildGalleryMultiSelect: -ID=$vGalleryGroupID }
	{ExpectedResults=	A fully-formatted multiple <select> list }
	{Dependencies=		Calls data from $svGalleryTable; will only select Field:'Active'='Y' records
					Requires a $vGalleryGroupID to be passed to it which is the Gallery ID. }
	{DevelNotes=		See proof of concept "filter_arrays_multiselect.lasso".
Filters from a Records_Array to another array.
Looking for whether a Gallery ID is in the array and whether the group_id for that Gallery ID is the value we are looking for.
Arrays must be built manually because the first element (Gallery_ID) has to be an integer for sort to work correctly. }
	{ChangeNotes=		6/19/09
						First implementation }
/Tagdocs;
*/

// Define the namespace
Var:'svCTNamespace' = 'LI_';

If:!(Lasso_TagExists:'LI_BuildGalleryMultiSelect');
	Define_Tag: 'BuildGalleryMultiSelect',
		-Description='Builds a multiple select list of Gallery Entries',
		-Required='ID',
		-namespace=$svCTNamespace;

		Local('Result') = null;

		// Initialize variables
		// Used to store the records_array from the search
		Local:'AllGalleryEntriesArray' = array;
		Local:'AssignedGalleryEntriesArray' = array;
		
		// THREE-STEP PROCESS
		// STEP 1 - Grab all gallery entries
		// STEP 2 - Grab the gallery entries assigned to the current gallery
		// STEP 3 - Combine the two arrays into a single array. Make sure the ID is unique.
		// RESULT of this process is that #AllGalleryEntriesArray will contain an array containing
		// unique Gallery Entry IDs, with appropriate ones selected. The array will be sorted by ID.
		
		// STEP 1
		// Get ALL of the Gallery Entries - Create the first array
		// Sorting the array is not necessary as it is already in order by gallery_id
		Var:'SQLBuildGallery' = '/* Get ALL Gallery Entries */
		SELECT g.gallery_id, g.gallery_thumb,
		/* This line adds a column called gg_groupID with a value of zero */
		Concat(0) AS gg_groupID
		FROM ' $svGalleryTable ' AS g WHERE g.Active = "Y" ORDER BY g.gallery_id';
		Inline: $IV_Galleries, -Table=$svGalleryTable, -SQL=$SQLBuildGallery;
			Records;
				#AllGalleryEntriesArray->insert: (Array: (Integer:(Field:'gallery_id')),(Field:'gallery_thumb'),(Field:'gg_groupID'));
			/Records;
		/Inline;
		
		// STEP 2
		// Get the assigned Gallery Entries - Create the second array
		Var:'SQLBuildGallery' = '/* Get Gallery Entries ONLY for this group */
		SELECT g.gallery_id, g.gallery_thumb, gg2g.gg_groupid
		FROM ' $svGalleryTable ' AS g
		LEFT JOIN ' $svGG2GalleryTable ' AS gg2g USING (gallery_id)
		WHERE g.Active = "Y" AND gg_groupID = ' $vGalleryGroupID ' ORDER BY g.gallery_id';
		Inline: $IV_Galleries, -Table=$svGalleryTable, -SQL=$SQLBuildGallery;
			#AssignedGalleryEntriesArray = (Records_Array);
		/Inline;
		
		If: $svDebug == 'Y';
			#Result += '<p class="debugCT">\n';
			#Result += '58: <b>AllGalleryEntriesArray</b> is <b> ' (#AllGalleryEntriesArray->Size) '</b> elements<br>\n';
			#Result += '58: <b>AllGalleryEntriesArray</b> = ' (#AllGalleryEntriesArray) '<br>\n';
			#Result += '58: <b>AssignedGalleryEntriesArray</b> is <b> ' (#AssignedGalleryEntriesArray->Size) '</b> elements<br>\n';
			#Result += '58: <b>AssignedGalleryEntriesArray</b> = ' (#AssignedGalleryEntriesArray) '</p>\n';
		/If;
		
		// STEP 3
		// Loop through the AssignedGalleryEntriesArray. Find the loop_count in the AllGalleryEntriesArray.
		// Delete the AllGalleryEntriesArray element, and insert the AssignedGalleryEntriesArray element
		// This results in that entry having a value in gg_groupid
		Loop:(#AssignedGalleryEntriesArray)->Size;
		
			Local:'DeleteThisElement' = integer;
			Local:'ThisAssignedElementID' = (Integer:(#AssignedGalleryEntriesArray->(Get:(Loop_Count))->(Get:1)));
			Local:'ThisAssignedElementThumb' = #AssignedGalleryEntriesArray->(Get:(Loop_Count))->(Get:2);
			// Put element into an array for searching. Note appended '0' on the end so the array matches Step 1
			Local:'FindThisElement' = (Array: (#ThisAssignedElementID), (#ThisAssignedElementThumb), '0');
			// Put the FINAL array element into #ReplaceThisElement. This will be used to replace. It contains the correct $vGalleryGroupID
			Local:'ReplaceThisElement' = (Array: (#ThisAssignedElementID), (#ThisAssignedElementThumb), ($vGalleryGroupID));
		
			If: $svDebug == 'Y';
				#Result += '<p class="debugCT">\n';
				#Result += '76: <b>Loop_Count</b> = ' (Loop_Count) '<br>\n';
				// #Result += '76: <b>FindThisElement</b> = ' (#FindThisElement) '<br>\n';
				// #Result += '76: <b>ReplaceThisElement</b> = ' (#ReplaceThisElement) '<br>\n';
				#Result += '76: <b>ThisAssignedElementID</b> = ' (#ThisAssignedElementID) '<br>\n';
			/If;
			// Get the index (position) in the array of the element in AllGalleryEntriesArray
			// If it exists (which it always should), replace it with the element from AssignedGalleryEntriesArray
			If: (#AllGalleryEntriesArray->(find:(#FindThisElement)));
				Local:'DeleteThisElement' = #AllGalleryEntriesArray->(FindIndex:(#FindThisElement));
				If: $svDebug == 'Y';
					#Result += '104: Found the Element<br>\n';
					#Result += '104: The Index is: <b>DeleteThisElement</b> = ' (#DeleteThisElement) '<br>\n';
				/If;
				#AllGalleryEntriesArray->remove:(#DeleteThisElement->Get:1);
				#AllGalleryEntriesArray->insert:(#ReplaceThisElement);
			Else;
				Local:'DeleteThisElement' = integer;
				If: $svDebug == 'Y';
					#Result += '104: Did NOT find the Element</p>\n';
				/If;
			/If;
		
		/Loop;
		
		// Sort the array. This will now work because the ID is an integer. Yay!
		#AllGalleryEntriesArray->(Sort:True);
		
		If: $svDebug == 'Y';
			#Result += '<p class="debugCT">\n';
			#Result += '100: <b>AllGalleryEntriesArray</b> is <b> ' (#AllGalleryEntriesArray->Size) '</b> elements<br>\n';
			#Result += '100: <b>AllGalleryEntriesArray</b> = ' #AllGalleryEntriesArray ' </p>\n';
		/If;
		
		// NOW - Build the Select box
		Loop: (#AllGalleryEntriesArray->size);

			// Used to display whether an ID is selected in the select list
			Local:'IsSelected' = string;

			// Get the first item of the array, which is the ID
			// Get the second item of the array, which is the thumb
			// Get the third item of the array, which is the Gallery ID
			Local:'ThisEntryID' = (#AllGalleryEntriesArray->(Get:Loop_Count)->(Get:1));
			Local:'ThisEntryThumb' = (#AllGalleryEntriesArray->(Get:Loop_Count)->(Get:2));
			Local:'ThisEntryGroupID' = (#AllGalleryEntriesArray->(Get:Loop_Count)->(Get:3));

			// Compare the record's gg_groupid to the GalleryID. If a match, select it in list
			If: (#ThisEntryGroupID) == $vGalleryGroupID;
				#IsSelected = ' selected';
			/If;

			#Result += '\t\t<option value="'(#ThisEntryID)'"'(#IsSelected)'>ID '(#ThisEntryID)' - '(#ThisEntryThumb)'</option>\n';

		/Loop;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - LI_BuildGalleryMultiSelect';

/If;
?>