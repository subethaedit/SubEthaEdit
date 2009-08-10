(*
Eudora

Copyright © 2002-2006 Apple Computer, Inc.

You may incorporate this Apple sample code into your program(s) without
restriction.  This Apple sample code has been provided "AS IS" and the
responsibility for its operation is yours.  You are not permitted to
redistribute this Apple sample code as "Apple sample code" after having
made changes.  If you're going to redistribute the code, we require
that you make it clear that the code was descended from Apple sample
code, but that you've made changes.
*)

(*
This script is used in conjunction with the Import Addresses script. It
implements address importing from Qualcomm Eudora through the
importToAddressBook handler.
*)

on importToAddressBook(unused)
	-- (anything)
	-- returns integer
	
	
end importToAddressBook

on importFromEudora(totalRecordsImported)
	set scriptFolderLocation to my getScriptFolderLocation()
	set theScript to load script alias (scriptFolderLocation & "Import Helper.scpt")
	tell application "Finder"
		set homeDir to home as string
		set pathname to homeDir & "Documents:Eudora Folder:Eudora Nicknames"
		try
			set eudoraFile to alias pathname
		on error
			try
				set pathname to homeDir & "Documents:Eudora Folder:Nicknames Folder:Eudora Nicknames"
				set eudoraFile to alias pathname
			on error
				activate
				set theNicknamesFile to choose file with prompt "Locate your Eudora Nicknames file, usually located in your Eudora Folder:"
				set pathname to (theNicknamesFile as string)
				set eudoraFile to alias pathname
			end try
		end try
	end tell
	set theFile to open for access eudoraFile as file specification
	try
		set theContents to read theFile from 1 to eof
		close access eudoraFile as file specification
		set scriptFolderLocation to my getScriptFolderLocation()
		set theScript to load script alias (scriptFolderLocation & "Import Helper.scpt")
		set AppleScript's text item delimiters to theScript's sniffLineDelimiter(theContents)
		set everyLineItem to every text item of theContents
		tell application "Address Book" to activate
		set lineItemsToProcessAtEnd to {}
		repeat with eachLineItem in everyLineItem
			set theNickname to my findNickname(eachLineItem)
			if (theNickname is not equal to "") then
				if eachLineItem begins with "alias" then
					set lineItemsToProcessAtEnd to lineItemsToProcessAtEnd & eachLineItem
				else if eachLineItem begins with "note" then
					set appendToNotes to ""
					tell application "Address Book" to set newEntry to make new person with properties {first name:theNickname, nickname:theNickname}
					set theOffset to offset of theNickname in eachLineItem
					set eachLineItem to characters (theOffset + (length of theNickname) + 1) thru -1 of eachLineItem as string
					set processedFields to {}
					if eachLineItem begins with "<" then
						set AppleScript's text item delimiters to "<"
						set everyField to every text item of eachLineItem
						set AppleScript's text item delimiters to ""
						repeat with theCounter from 2 to count of everyField
							set thisItem to item theCounter of everyField
							if (last character of thisItem is equal to ">") then
								set thisItem to (characters 1 thru -2 of thisItem) as string
								set processedFields to processedFields & {thisItem}
							else if (thisItem does not contain ">") then
								set appendToNotes to appendToNotes & everyField as string
							else
								set theOffset to offset of ">" in thisItem
								set originalString to thisItem
								set thisItem to (characters 1 thru (theOffset - 1) of originalString) as string
								set appendToNotes to (appendToNotes & (characters (theOffset + 1) thru -1 of originalString) as string) & return & return
								set processedFields to processedFields & {thisItem}
							end if
						end repeat
					else
						set appendToNotes to appendToNotes & eachLineItem
					end if
					repeat with eachField in processedFields
						set AppleScript's text item delimiters to ":"
						try
							set theField to text item 1 of eachField
							set theValue to my fixAscii3(text item 2 of eachField)
							
							if theField is equal to "first" then
								theScript's setFirstName(newEntry, theValue)
							else if theField is equal to "last" then
								theScript's setLastName(newEntry, theValue)
							else if theField is equal to "address" then
								theScript's setStreetAddress(newEntry, "home", theValue)
							else if theField is equal to "address2" then
								theScript's setStreetAddress(newEntry, "work", theValue)
							else if theField is equal to "title" then
								theScript's setTitle(newEntry, theValue)
							else if theField is equal to "city" then
								theScript's setCity(newEntry, "home", theValue)
							else if theField is equal to "zip" then
								theScript's setZip(newEntry, "home", theValue)
							else if theField is equal to "state" then
								theScript's setState(newEntry, "home", theValue)
							else if theField is equal to "state2" then
								theScript's setState(newEntry, "work", theValue)
							else if theField is equal to "country" then
								theScript's setCountry(newEntry, "home", theValue)
							else if theField is equal to "city2" then
								theScript's setCity(newEntry, "work", theValue)
							else if theField is equal to "zip2" then
								theScript's setZip(newEntry, "work", theValue)
							else if theField is equal to "country2" then
								theScript's setCountry(newEntry, "work", theValue)
							else if theField is equal to "company" then
								theScript's setCompany(newEntry, theValue)
							else if theField is equal to "phone" then
								theScript's setPhone(newEntry, "home", theValue)
							else if theField is equal to "fax" then
								theScript's setPhone(newEntry, "home fax", theValue)
							else if theField is equal to "mobile" then
								theScript's setPhone(newEntry, "mobile", theValue)
							else if theField is equal to "phone2" then
								theScript's setPhone(newEntry, "work", theValue)
							else if theField is equal to "fax2" then
								theScript's setPhone(newEntry, "work fax", theValue)
							else if theField is equal to "mobile2" then
								theScript's setPhone(newEntry, "work mobile", theValue)
							else if theField is equal to "name" then
								-- skip it
							else
								if theValue is not equal to "" then
									set appendToNotes to appendToNotes & theField & ": " & theValue & return
								end if
							end if
						on error
							set appendToNotes to appendToNotes & eachField
						end try
					end repeat
					theScript's setNotes(newEntry, appendToNotes)
					set totalRecordsImported to totalRecordsImported + 1
					if (totalRecordsImported mod 10 is equal to 0) then
						tell application "Address Book" to save addressbook
					end if
				end if
			end if
		end repeat
		-- for better performance
		set everyEmailAddress to {}
		tell application "Address Book"
			set everyPerson to every person
			repeat with eachPerson in everyPerson
				set everyAddress to every email of eachPerson
				repeat with eachAddress in everyAddress
					if value of eachAddress is not equal to "" then
						set everyEmailAddress to everyEmailAddress & {eachAddress}
					end if
				end repeat
			end repeat
		end tell
		set everyLineItemToDeferToTheBitterEnd to {}
		repeat with eachLineItemToProcessAtEnd in lineItemsToProcessAtEnd
			set deferredItems to {}
			set thisNickname to my findNickname(eachLineItemToProcessAtEnd)
			set everyAddress to my extractAddresses(eachLineItemToProcessAtEnd, thisNickname)
			tell application "Address Book"
				set theResult to (every person whose nickname is thisNickname)
				if ((count of theResult) is greater than 0) then
					set existingPerson to item 1 of theResult
					repeat with eachAddress in everyAddress
						set {theFirstName, theLastName, theEmailAddress} to my parseStringForEmailAndName(eachAddress)
						if theEmailAddress is not equal to "" then
							theScript's setEmail(existingPerson, "home", theEmailAddress)
						end if
					end repeat
				else
					set addressCounter to 0
					repeat with eachAddress in everyAddress
						if length of eachAddress is greater than 1 then
							set addressCounter to addressCounter + 1
						end if
					end repeat
					if (addressCounter) is greater than 1 then
						set everyGroup to (every group whose name is thisNickname)
						if (count of everyGroup) is equal to 0 then
							set newGroup to make new group with properties {name:thisNickname}
						else
							set newGroup to item 1 of everyGroup
						end if
						repeat with eachAddress in everyAddress
							set matchedPerson to ""
							if (count of eachAddress) is not equal to 0 then
								set {extractedFirstName, extractedLastName, extractedEmailAddress} to my parseStringForEmailAndName(eachAddress)
								if extractedEmailAddress contains "@" then
									if extractedEmailAddress is in everyEmailAddress then
										set everyPerson to every person
										repeat with eachPerson in everyPerson
											set everyEmail to every email of eachPerson
											repeat with eachEmail in everyEmail
												if value of eachEmail is equal to extractedEmailAddress then
													set matchedPerson to eachPerson
													exit repeat
												end if
											end repeat
											if matchedPerson is not equal to "" then
												exit repeat
											end if
										end repeat
									else
										set matchedPerson to make new person with properties {nickname:extractedFirstName, first name:extractedFirstName, last name:extractedLastName}
										theScript's setEmail(matchedPerson, "home", extractedEmailAddress)
									end if
								else
									set theResult to (every person whose nickname is equal to eachAddress)
									if (count of theResult) is greater than 0 then
										set matchedPerson to item 1 of theResult
									end if
								end if
								if matchedPerson is equal to "" then
									if extractedEmailAddress is equal to "" then
										set deferredItems to deferredItems & {extractedFirstName}
									else
										set newPerson to make new person with properties {first name:extractedFirstName, nickname:extractedFirstName, last name:extractedLastName}
										theScript's setEmail(newPerson, "other", extractedEmailAddress)
										add newPerson to newGroup
									end if
								else
									add matchedPerson to newGroup
								end if
							end if
						end repeat
					else if (addressCounter is equal to 1) then
						set {theFirstName, theLastName, theEmailAddress} to my parseStringForEmailAndName(item 1 of everyAddress)
						tell application "Address Book" to set newEntry to make new person with properties {nickname:thisNickname, first name:theFirstName, last name:theLastName}
						theScript's setEmail(newEntry, "home", theEmailAddress)
					end if
					set totalRecordsImported to totalRecordsImported + 1
					if (totalRecordsImported mod 5 is equal to 0) then
						tell application "Address Book" to save addressbook
					end if
				end if
			end tell
			if deferredItems is not equal to {} then
				set everyLineItemToDeferToTheBitterEnd to everyLineItemToDeferToTheBitterEnd & {{thisNickname, deferredItems}}
			end if
		end repeat
		repeat with eachLineItemToDeferToTheBitterEnd in everyLineItemToDeferToTheBitterEnd
			set theGroupName to item 1 of eachLineItemToDeferToTheBitterEnd
			set listOfPeople to item 2 of eachLineItemToDeferToTheBitterEnd
			tell application "Address Book"
				set everyGroup to (every group whose name is theGroupName)
				if (count of everyGroup) is greater than 0 then
					set theGroup to item 1 of everyGroup
					repeat with eachPerson in listOfPeople
						set everyPerson to (every person whose nickname is eachPerson)
						if (count of everyPerson) is greater than 0 then
							set thePerson to item 1 of everyPerson
							add thePerson to theGroup
						end if
					end repeat
				end if
			end tell
		end repeat
		tell application "Address Book" to save addressbook
	on error errText number errNum
		try
			close access eudoraFile as file specification
		end try
		if errNum is not equal to -1711 then
			display dialog "No Eudora contacts were found in this file! " & return & return & errText buttons {"OK"} default button 1
		end if
	end try
	return totalRecordsImported
end importFromEudora

on findNickname(eachLineItem)
	set theNickname to ""
	set AppleScript's text item delimiters to " "
	set everyTextItem to every text item of eachLineItem
	if (count of everyTextItem) is greater than 1 then
		if item 2 of everyTextItem begins with "\"" then
			set AppleScript's text item delimiters to "\""
			set everyTextItem to every text item of eachLineItem
			set AppleScript's text item delimiters to ""
			try
				set theNickname to text item 2 of everyTextItem as string
			end try
		else
			set AppleScript's text item delimiters to " "
			try
				set theNickname to text item 2 of eachLineItem as string
			end try
		end if
	end if
	set AppleScript's text item delimiters to ""
	(*
	set AppleScript's text item delimiters to "\""
	set everyTextItem to every text item of eachLineItem
	set AppleScript's text item delimiters to ""
	if ((count of everyTextItem) is greater than 1) then
		set theNickname to (text item 2 of everyTextItem) as string
	else
		set AppleScript's text item delimiters to " "
		try
			set theNickname to text item 2 of eachLineItem as string
		end try
		set AppleScript's text item delimiters to ""
	end if
	*)
	return theNickname
end findNickname

on extractAddresses(eachLineItem, theNickname)
	set theOffset to offset of theNickname in eachLineItem
	if (theNickname contains " ") then
		set theSpaceOffset to 2
	else
		set theSpaceOffset to 1
	end if
	set theRemainingString to (characters (theOffset + (length of theNickname) + theSpaceOffset) thru -1 of eachLineItem) as string
	set AppleScript's text item delimiters to ","
	set everyAddress to every text item in theRemainingString
	
	set AppleScript's text item delimiters to ""
	return everyAddress
end extractAddresses

on fixAscii3(theData)
	set returnValue to theData
	set AppleScript's text item delimiters to ASCII character 3
	set everyTextItem to every text item of theData
	set theCount to count of everyTextItem
	if theCount is greater than 1 then
		set AppleScript's text item delimiters to ASCII character 10
		set returnValue to everyTextItem as string
	end if
	return returnValue
end fixAscii3

on parseStringForEmailAndName(theString)
	log "theString: " & theString
	set theString to my stripCharacter(theString, "(")
	set theString to my stripCharacter(theString, ")")
	set theString to my stripCharacter(theString, "<")
	set theString to my stripCharacter(theString, ">")
	set theString to my stripCharacter(theString, "\"")
	set AppleScript's text item delimiters to " "
	set everyTextItem to every text item of theString
	set nameString to ""
	set emailString to ""
	set firstNameString to ""
	set lastNameString to ""
	repeat with eachItem in everyTextItem
		if eachItem contains "@" then
			set emailString to eachItem
		else
			if nameString is not equal to "" then
				set nameString to nameString & " "
			end if
			set nameString to nameString & eachItem
		end if
	end repeat
	if nameString is not equal to "" then
		set everyTextItem to every text item of nameString
		if (count of everyTextItem) is equal to 1 then
			set firstNameString to item 1 of everyTextItem as string
		else
			set firstNameString to items 1 thru -2 of everyTextItem as string
			set lastNameString to last item of everyTextItem as string
		end if
	end if
	set AppleScript's text item delimiters to ""
	log "firstNameString: " & firstNameString
	log "lastNameString: " & lastNameString
	log "emailString: " & emailString
	return {firstNameString, lastNameString, emailString}
end parseStringForEmailAndName

on stripCharacter(theString, theCharacter)
	set AppleScript's text item delimiters to theCharacter
	set everyTextItem to every text item of theString
	set AppleScript's text item delimiters to ""
	set theString to everyTextItem as string
	return theString
end stripCharacter

on getScriptFolderLocation()
	tell application "Finder" to set bootVolume to startup disk as string
	set basePathToLibraryScripts to bootVolume & "Library:Scripts:Mail Scripts:Helper Scripts:"
	return basePathToLibraryScripts
end getScriptFolderLocation

on run
	display alert "Address Importer Script" message "This script is an address importer script to be used with the Import Addresses script. It supports importing nicknames from Qualcomm Eudora."
end run