/*
 * Name: WildcardController.m
 * Project: OgreKit
 *
 * Creation Date: Oct 07 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */
 
#import "WildcardController.h"

//#define DEBUG_OGRE_WILDCARD

#define MIN_NUM_OF_ITEMS_TO_DISPLAY		3
#define Min(a, b)						(((a) < (b))? (a) : (b))

static NSCharacterSet	*gDoubleQuotationCharSet;
static NSAppleScript	*gActivateFinderAppleScript;

static NSString	* const WildcardFindNameKey         = @"Find String";
static NSString	* const WildcardReplaceNameKey      = @"Replace String";
static NSString	* const WildcardIgnoreCaseOptionKey = @"Ignore Case";
static NSString	* const WildcardRegexOptionKey      = @"Use Regular Expressions";
static NSString	* const WildcardShowFinderKey       = @"Show Finder after Done";
static NSString	* const WildcardDesktopKey          = @"Find on the Desktop";
static NSString	* const WildcardFindInCommentKey    = @"Find in Comments";

@implementation WildcardController

/* initialize */
+ (void)initialize
{
	/* FinderをActivateするAppleScript */
	gActivateFinderAppleScript = [[NSAppleScript alloc] initWithSource:
@"tell application \"Finder\"\n\
	activate\n\
end tell"];
	
	/* backslashとdouble quotationを退避するときに使用する */
	gDoubleQuotationCharSet = [[NSCharacterSet characterSetWithCharactersInString:[OgreBackslashCharacter stringByAppendingString:@"\""]] retain];
	
	/* OgreKitの初期設定 */
	[OGRegularExpression setDefaultEscapeCharacter:OgreBackslashCharacter];
}

- (void)awakeFromNib
{
	/* 前回のWindowの位置を再現 */
    [wildcardWindow setFrameAutosaveName: @"Wildcard Window"];
    [wildcardWindow setFrameUsingName: @"Wildcard Window"];
	
	// 設定の復帰
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	id	anObject = [defaults objectForKey:WildcardFindNameKey];
	if (anObject != nil) [findNameTextField setStringValue:anObject];
	
	anObject = [defaults objectForKey:WildcardReplaceNameKey];
	if (anObject != nil) [replaceNameTextField setStringValue:anObject];

	anObject = [defaults objectForKey:WildcardIgnoreCaseOptionKey];
	if (anObject != nil) [ignoreCaseCheckBox setState:[anObject intValue]];
	
	anObject = [defaults objectForKey:WildcardRegexOptionKey];
	if (anObject != nil) [regexCheckBox setState:[anObject intValue]];
	
	anObject = [defaults objectForKey:WildcardShowFinderKey];
	if (anObject != nil) [showFinderCheckBox setState:[anObject intValue]];
	
	anObject = [defaults objectForKey:WildcardDesktopKey];
	if (anObject != nil) [desktopCheckBox setState:[anObject intValue]];
	
	anObject = [defaults objectForKey:WildcardFindInCommentKey];
	if (anObject != nil) {
		if ([anObject boolValue]) {
			[findPopUp selectItemAtIndex:1];
			_findInComment = YES;
		} else {
			[findPopUp selectItemAtIndex:0];
			_findInComment = NO;
		}
		[self updateButtonTitle];
	} else {
		[findPopUp selectItemAtIndex:0];
		_findInComment = NO;
	}
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)aApp
{
	return YES;	// 全てのウィンドウを閉じたら終了する。
}

// 終了処理
- (void)applicationWillTerminate:(NSNotification*)aNotification
{
	// 設定の保存
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[findNameTextField stringValue] forKey:WildcardFindNameKey];
	[defaults setObject:[replaceNameTextField stringValue] forKey:WildcardReplaceNameKey];
	[defaults setObject:[NSNumber numberWithInt:[ignoreCaseCheckBox state]] forKey:WildcardIgnoreCaseOptionKey];
	[defaults setObject:[NSNumber numberWithInt:[regexCheckBox state]] forKey:WildcardRegexOptionKey];
	[defaults setObject:[NSNumber numberWithInt:[showFinderCheckBox state]] forKey:WildcardShowFinderKey];
	[defaults setObject:[NSNumber numberWithInt:[desktopCheckBox state]] forKey:WildcardDesktopKey];
	[defaults setObject:[NSNumber numberWithBool:_findInComment] forKey:WildcardFindInCommentKey];
}

/* setter, getter */
- (unsigned)options
// ignore case
// delimt by whitespace (simple matching syntax使用時)
{
	unsigned	options = OgreCaptureGroupOption;	// デフォルトでキャプチャ
	if (!_findInComment) options |= OgreFindNotEmptyOption;	// コメントを検索する場合以外は空マッチを許さない。
	if ([ignoreCaseCheckBox state] == NSOnState) options |= OgreIgnoreCaseOption;
	if ([self syntax] == OgreSimpleMatchingSyntax) options |= OgreDelimitByWhitespaceOption;
	
	return options;
}

- (OgreSyntax)syntax
{
	return (([regexCheckBox state] == NSOnState)? OgreRubySyntax : OgreSimpleMatchingSyntax);
}

- (NSString*)escapeCharacter
{
	return OgreBackslashCharacter;
}



/* IB actions */
- (IBAction)copy:(id)sender
{
	/* UNDER CONSTRUCTION */
	/* FinderのAppleScript対応待ち */
}

- (IBAction)rename:(id)sender
{
	OGRegularExpression	*regex = [self regex];	// (エラーチェック)
	if (regex == nil) return; 
	
	OGRegularExpressionMatch	*match;
	
	int						i, numberOfAllItems, numberOfMatchedItems;
	NSArray					*allItems = nil, *comments = nil, *targetContents;
	NSString				*targetName, *replaceString, *itemName, *kindName, *replacedName;
	NSMutableString			*scriptString, *selectItems, *oldNames, *newNames, *alertMessage;
	BOOL					nowFindInComment;
	
	nowFindInComment = _findInComment;
	// 対象Window中の項目・コメント一覧を得る。
	if (nowFindInComment) {
		// コメントでマッチングする
		[self getAllItemsInTargetWindow:&allItems comments:&comments];
		targetContents = comments;
		kindName = @"comment";
	} else {
		// 項目でマッチングする
		[self getAllItemsInTargetWindow:&allItems comments:nil];
		targetContents = allItems;
		kindName = @"name";
	}
	if (allItems == nil) return;	// エラー発生
	numberOfAllItems = [allItems count];
	
	// パターンにマッチしたファイルを選択・リネームするAppleScriptを書く
	numberOfMatchedItems = 0;
	alertMessage = [NSMutableString stringWithString:@""];
	replaceString = [replaceNameTextField stringValue];
	if (_targetWindowID == -1) {
		scriptString = [NSMutableString stringWithString:
@"tell application \"Finder\"\n\
	set t to the desktop\n\
	"];
	} else {
		scriptString = [NSMutableString stringWithFormat:
@"tell application \"Finder\"\n\
	set t to the Finder window id %d\n\
	", _targetWindowID];
	}
	selectItems = [NSMutableString stringWithString:@"select {"];
	oldNames = [NSMutableString stringWithString:@"set {"];
	newNames = [NSMutableString stringWithString:@"{"];
	
	for (i = 0; i < numberOfAllItems; i++) {
		targetName = [targetContents objectAtIndex:i];
		if ((match = [regex matchInString:targetName]) != nil) {
			numberOfMatchedItems++;
			if (numberOfMatchedItems > 1) {
				[selectItems appendString:@", "];
				[oldNames appendString:@", "];
				[newNames appendString:@", "];
			}
			itemName = [[self class] escapeUnsafeCharacters:[allItems objectAtIndex:i]];
			replacedName = [regex replaceAllMatchesInString:targetName withString:replaceString];
			[selectItems appendFormat:@"item \"%@\"", itemName];
			[oldNames appendFormat:@"%@ of item \"%@\" in t", kindName, itemName];
			[newNames appendFormat:@"\"%@\"", [[self class] escapeUnsafeCharacters:replacedName]];
			// 警告文表示用
			if (numberOfMatchedItems <= MIN_NUM_OF_ITEMS_TO_DISPLAY) {
				[alertMessage appendFormat:@"\"%@\" -> \"%@\"\n", targetName, replacedName];
			}
		}
	}
	[selectItems appendString:@"} in t\n\
end tell"];
	[newNames appendString:@"}\n\
end tell"];
	[oldNames appendString:@"} to "];
	[oldNames appendString:newNames];
	
#ifdef DEBUG_OGRE_WILDCARD
	NSLog(@"Script: %@", scriptString);
#endif
	if (numberOfMatchedItems == 0) {
		// 全くマッチしなかった場合
		NSBeep();
		[statusTextField setStringValue:@"Not found."];
		return;
	}
	
	// ファイルを選択する
	[statusTextField setStringValue:[NSString stringWithFormat:@"Selecting %d item%@...", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")]];
	[self doAppleScriptString:[scriptString stringByAppendingString:selectItems] 
		trimLine:[NSString stringWithFormat:@"", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")] activateFinder:NO];
	
	// 本当にリネームしていいのかどうか確認する。
	//  警告文の作成
	[alertMessage insertString:[NSString stringWithFormat:@"THIS OPERATION IS NOT UNDOABLE!\nDo you really want to %@ %d item%@?\n\n", ((nowFindInComment)? @"revise the comment of" : @"rename"), numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")] atIndex:0];
	if (numberOfMatchedItems > MIN_NUM_OF_ITEMS_TO_DISPLAY) [alertMessage appendString:@"..."];
	
	[self confirmDecisionToRename: alertMessage
		contextInfo:[[NSArray alloc] initWithObjects:
			[scriptString stringByAppendingString:oldNames], 
			[NSNumber numberWithInt:numberOfMatchedItems], 
			[NSNumber numberWithBool:nowFindInComment], nil] /* confirmSheetDidDEndの中でreleaseする */
		findInComment:nowFindInComment];
}

- (IBAction)select:(id)sender
{
	OGRegularExpression	*regex = [self regex];	// (エラーチェック)
	if (regex == nil) return; 
	
	OGRegularExpressionMatch	*match;
	
	int						i, numberOfAllItems, numberOfMatchedItems;
	NSArray					*allItems = nil, *comments = nil, *targetContents = nil;
	NSMutableString			*scriptString;
	
	// 対象Window中の項目・コメント一覧を得る。
	if (_findInComment) {
		// コメントでマッチングする
		[self getAllItemsInTargetWindow:&allItems comments:&comments];
		targetContents = comments;
	} else {
		// 項目でマッチングする
		[self getAllItemsInTargetWindow:&allItems comments:nil];
		targetContents = allItems;
	}
	if (targetContents == nil) return;	// エラー発生
	numberOfAllItems = [allItems count];
	
	// パターンにマッチしたファイルを選択・削除するAppleScriptを書く
	numberOfMatchedItems = 0;
	scriptString = [NSMutableString stringWithString:
@"tell application \"Finder\"\n\
	select {"];
	for (i = 0; i < numberOfAllItems; i++) {
		if ((match = [regex matchInString:[targetContents objectAtIndex:i]]) != nil) {
			numberOfMatchedItems++;
			if (numberOfMatchedItems > 1) [scriptString appendString:@", "];
			[scriptString appendFormat:@"item \"%@\"", [[self class] escapeUnsafeCharacters:[allItems objectAtIndex:i]]];
		}
	}
	if (_targetWindowID == -1) {
		[scriptString appendString:
@"} in the desktop\n\
end tell"];
	} else {
		[scriptString appendFormat:
@"} in the Finder window id %d\n\
end tell", _targetWindowID];
	}
#ifdef DEBUG_OGRE_WILDCARD
	NSLog(@"Script: %@", scriptString);
#endif
	if (numberOfMatchedItems == 0) {
		// 全くマッチしなかった場合
		NSBeep();
		[statusTextField setStringValue:@"Not found."];
		return;
	}
	
	// ファイルを選択する
	[statusTextField setStringValue:[NSString stringWithFormat:@"Selecting %d item%@...", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")]];
	[self doAppleScriptString:scriptString trimLine:[NSString stringWithFormat:@"%d item%@ selected.", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")] activateFinder:([showFinderCheckBox state] == NSOnState)];
}

- (IBAction)trash:(id)sender
{
	OGRegularExpression	*regex = [self regex];	// (エラーチェック)
	if (regex == nil) return; 
	
	OGRegularExpressionMatch	*match;
	
	int						i, numberOfAllItems, numberOfMatchedItems;
	NSArray					*allItems = nil, *comments = nil, *targetContents = nil;
	NSMutableString			*scriptString, *alertMessage;
	
	// 対象Window中の項目・コメント一覧を得る。
	if (_findInComment) {
		// コメントでマッチングする
		[self getAllItemsInTargetWindow:&allItems comments:&comments];
		targetContents = comments;
	} else {
		// 項目でマッチングする
		[self getAllItemsInTargetWindow:&allItems comments:nil];
		targetContents = allItems;
	}
	if (allItems == nil) return;	// エラー発生
	numberOfAllItems = [allItems count];
	
	// パターンにマッチしたファイルを選択するAppleScriptを書く
	numberOfMatchedItems = 0;
	scriptString = [NSMutableString stringWithString:@""];
	alertMessage = [NSMutableString stringWithString:@""];
	for (i = 0; i < numberOfAllItems; i++) {
		if ((match = [regex matchInString:[targetContents objectAtIndex:i]]) != nil) {
			numberOfMatchedItems++;
			if (numberOfMatchedItems > 1) [scriptString appendString:@", "];
			[scriptString appendFormat:@"item \"%@\"", [[self class] escapeUnsafeCharacters:[allItems objectAtIndex:i]]];
			// 警告文表示用
			if (numberOfMatchedItems<= MIN_NUM_OF_ITEMS_TO_DISPLAY) {
				[alertMessage appendFormat:@"%@\n", [allItems objectAtIndex:i]];
			}
		}
	}
	if (_targetWindowID == -1) {
		[scriptString appendString:
@"} in the desktop\n\
end tell"];
	} else {
		[scriptString appendFormat:
@"} in the Finder window id %d\n\
end tell", _targetWindowID];
	}
#ifdef DEBUG_OGRE_WILDCARD
	NSLog(@"Script: %@", scriptString);
#endif
	if (numberOfMatchedItems == 0) {
		// 全くマッチしなかった場合
		NSBeep();
		[statusTextField setStringValue:@"Not found."];
		return;
	}
	// ファイルを選択する
	[statusTextField setStringValue:[NSString stringWithFormat:@"Selecting %d item%@...", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")]];
	[self doAppleScriptString:[
@"tell application \"Finder\"\n\
	select {" stringByAppendingString:scriptString] 
		trimLine:[NSString stringWithFormat:@"Really delete %d item%@?", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")] activateFinder:NO];
	
	// 本当に削除していいのかどうか確認する。
	[scriptString insertString:
@"tell application \"Finder\"\n\
	delete {" atIndex:0];
	//  警告文の作成
	[alertMessage insertString:[NSString stringWithFormat:@"Do you really want to delete %d item%@?\n\n", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")] atIndex:0];
	if (numberOfMatchedItems > MIN_NUM_OF_ITEMS_TO_DISPLAY) [alertMessage appendString:@"..."];
	
	[self confirmDecisionToTrash:alertMessage 
		contextInfo:[[NSArray alloc] initWithObjects:scriptString, [NSNumber numberWithInt:numberOfMatchedItems], nil] /* confirmSheetDidDEndの中でreleaseする */];
}

// 検索種類の変更
- (IBAction)changePopUp:(id)sender
{
	if ([[findPopUp selectedCell] tag] == 0) {
		// Find by Name
		_findInComment = NO;
	} else {
		// Find by Comment
		_findInComment = YES;
	}
	[self updateButtonTitle];
}

- (void)updateButtonTitle
{
	if (_findInComment) {
		// Find by Comment
		[replaceTitle setStringValue:@"New Comment:"];
		[renameButton setTitle:@"Revise"];
	} else {
		// Find by Name
		[replaceTitle setStringValue:@"New Name:"];
		[renameButton setTitle:@"Rename"];
	}
}

/* get target items Finder */
- (void)getAllItemsInTargetWindow:(NSArray**)allItems comments:(NSArray**)comments
{
	int						i, numberOfAllItems;
	
	NSAppleScript			*script;
	NSDictionary			*error;
	NSAppleEventDescriptor	*results;
	
	// Finderを2番目にする予定。
	//[self activateFinder];
	
	// 対象WindowのIDを取得する。
	if ([desktopCheckBox state] == NSOnState) {
		_targetWindowID = -1;
	} else {
		script = [[NSAppleScript alloc] initWithSource:
@"tell application \"Finder\"\n\
	try\n\
		set windowID to id of the Finder window 1\n\
	on error\n\
		set windowID to -1\n\
	end\n\
	return (windowID as string)\n\
end tell"];
		results = [script executeAndReturnError:&error];
		[script release];
		if (results == nil) {
			// error occurred
			NSBeep();
			[self showErrorAlert:@"Error!" message:[NSString stringWithFormat:@"%@", error]];
			*allItems = nil;
			if (comments) *comments = nil;
			return;
		}
		_targetWindowID = [[results stringValue] intValue];
#ifdef DEBUG_OGRE_WILDCARD
		NSLog(@"Window ID: %d", _targetWindowID);
#endif
	}
	
	// 対象Window中の項目名一覧を得る。(ただし、_targetWindowID == -1の場合はDesktopを対象にする)
	if (_targetWindowID == -1) {
		script = [[NSAppleScript alloc] initWithSource:
@"tell application \"Finder\"\n\
	get the name of the every item in the desktop\n\
end tell"];
	} else {
		script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:
@"tell application \"Finder\"\n\
	get the name of the every item in the Finder window id %d\n\
end tell", _targetWindowID]];
	}
	results = [script executeAndReturnError:&error];
	[script release];
	if (results == nil) {
		// error occurred
		NSBeep();
		[self showErrorAlert:@"Error!" message:[NSString stringWithFormat:@"%@", error]];
		*allItems = nil;
		if (comments) *comments = nil;
		return;
	}
	
	numberOfAllItems = [results numberOfItems];
	*allItems = [NSMutableArray arrayWithCapacity:numberOfAllItems];
	for (i = 1 /* 注意! 0からではない */; i <= numberOfAllItems; i++) {
		[(NSMutableArray*)*allItems addObject:[[results descriptorAtIndex:i] stringValue]];
	}
#ifdef DEBUG_OGRE_WILDCARD
	NSLog(@"All Items: %@", [*allItems description]);
#endif
	
	// 対象Window中のコメント一覧を得る。(ただし、_targetWindowID == -1の場合はDesktopを対象にする)
	if (comments) {
		if (_targetWindowID == -1) {
			script = [[NSAppleScript alloc] initWithSource:
	@"tell application \"Finder\"\n\
		get the comment of the every item in the desktop\n\
	end tell"];
		} else {
			script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:
	@"tell application \"Finder\"\n\
		get the comment of the every item in the Finder window id %d\n\
	end tell", _targetWindowID]];
		}
		results = [script executeAndReturnError:&error];
		[script release];
		if (results == nil) {
			// error occurred
			NSBeep();
			[self showErrorAlert:@"Error!" message:[NSString stringWithFormat:@"%@", error]];
			*allItems = nil;
			if (comments) *comments = nil;
			return;
		}
		
		numberOfAllItems = [results numberOfItems];
		*comments = [NSMutableArray arrayWithCapacity:numberOfAllItems];
		for (i = 1 /* 注意! 0からではない */; i <= numberOfAllItems; i++) {
			[(NSMutableArray*)*comments addObject:[[results descriptorAtIndex:i] stringValue]];
		}
	#ifdef DEBUG_OGRE_WILDCARD
		NSLog(@"All Comments: %@", [*comments description]);
	#endif
	}
}

- (void)doAppleScriptString:(NSString*)aSctiptString trimLine:(NSString*)aMessage activateFinder:(BOOL)isActivate
{
	NSAppleScript			*script;
	NSDictionary			*error;
	NSAppleEventDescriptor	*results;
	
	script = [[NSAppleScript alloc] initWithSource:aSctiptString];
	results = [script executeAndReturnError:&error];
	[script release];
	if (results == nil) {
		// error occurred
		[self showErrorAlert:@"Error!" message:[NSString stringWithFormat:@"%@", error]];
	} else {
		[statusTextField setStringValue:aMessage];
		if (isActivate) [self activateFinder];
	}
}

/* 正しい正規表現かどうかチェックする */
- (OGRegularExpression*)regex
{
	OGRegularExpression	*regex = nil;
	NS_DURING
		regex = [OGRegularExpression regularExpressionWithString: [findNameTextField stringValue] 
			options: [self options] 
			syntax: [self syntax] 
			escapeCharacter:[self escapeCharacter]];
	NS_HANDLER
		// 例外処理
		if ([[localException name] isEqualToString:OgreException]) {
			[self showErrorAlert:@"Invalid Pattern" message:[localException reason]];
		} else {
			[localException raise];
		}
		return nil;
	NS_ENDHANDLER
	
	return regex;
}

- (void)showErrorAlert:(NSString*)aTitle message:(NSString*)aMessage
{
	NSBeep();
	NSBeginAlertSheet(aTitle, @"OK", nil, nil, wildcardWindow, self, nil, @selector(sheetDidDismiss:returnCode:contextInfo:), nil, aMessage);
}

- (void)sheetDidDismiss:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	[wildcardWindow makeKeyAndOrderFront:self];
}

- (void)confirmDecisionToTrash:(NSString*)aMessage contextInfo:(void*)contextInfo
{
	NSBeginAlertSheet(@"Trash", @"Yes", @"No", nil, wildcardWindow, self, @selector(confirmTrashSheetDidDEnd:returnCode:contextInfo:), @selector(sheetDidDismiss:returnCode:contextInfo:), contextInfo, aMessage);
}

- (void)confirmTrashSheetDidDEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	NSString	*scriptString = [(NSArray*)contextInfo objectAtIndex:0];
	int	numberOfMatchedItems = [[(NSArray*)contextInfo objectAtIndex:1] intValue];
	[(NSArray*)contextInfo autorelease];
	if (returnCode == NSAlertDefaultReturn) {
		// ファイルを削除する
		[statusTextField setStringValue:[NSString stringWithFormat:@"Putting %d item%@ in the trash can...", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")]];
		[self doAppleScriptString:scriptString trimLine:[NSString stringWithFormat:@"%d item%@ thrown into the trash can.", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")] activateFinder:([showFinderCheckBox state] == NSOnState)];
	} else {
		[statusTextField setStringValue:@"Trash cancelled."];
	}
}

- (void)confirmDecisionToRename:(NSString*)aMessage contextInfo:(void*)contextInfo findInComment:(BOOL)findInComment
{
	NSBeginAlertSheet(((findInComment)? @"Revise" : @"Rename"), @"Yes", @"No", nil, wildcardWindow, self, @selector(confirmRenameSheetDidDEnd:returnCode:contextInfo:), @selector(sheetDidDismiss:returnCode:contextInfo:), contextInfo, aMessage);
}

- (void)confirmRenameSheetDidDEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	NSString	*scriptString = [(NSArray*)contextInfo objectAtIndex:0];
	int			numberOfMatchedItems = [[(NSArray*)contextInfo objectAtIndex:1] intValue];
	BOOL		nowFindInComment = [[(NSArray*)contextInfo objectAtIndex:2] boolValue];
	[(NSArray*)contextInfo autorelease];
	NSString	*indNam;	//	(k)inNam(e) 手抜き
	if (nowFindInComment) {
		indNam = @"evis";
	} else {
		indNam = @"enam";
	}
	if (returnCode == NSAlertDefaultReturn) {
		// ファイルをリネームする
		[statusTextField setStringValue:[NSString stringWithFormat:@"R%@ing %d item%@...", indNam, numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @"")]];
		[self doAppleScriptString:scriptString trimLine:[NSString stringWithFormat:@"%d item%@ r%@ed.", numberOfMatchedItems, ((numberOfMatchedItems > 1)? @"s" : @""), indNam] activateFinder:([showFinderCheckBox state] == NSOnState)];
	} else {
		[statusTextField setStringValue:[NSString stringWithFormat:@"R%@e cancelled.", indNam]];
	}
}



/* backslashとdouble quotationを退避する */
+ (NSString*)escapeUnsafeCharacters:(NSString*)aString
{
	if (aString == nil) return nil;

	NSMutableString	*escapedString = [NSMutableString stringWithString:aString];
	
	/* backslashとdouble quotationを退避する */
	unsigned			counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	unsigned	strlen = [aString length];
	NSRange 	searchRange = NSMakeRange(0, strlen), matchRange;
	while ( matchRange = [escapedString rangeOfCharacterFromSet:gDoubleQuotationCharSet options:0 range:searchRange], 
			matchRange.length > 0 ) {
		[escapedString insertString:OgreBackslashCharacter atIndex:matchRange.location];
		strlen += 1;
		searchRange.location = matchRange.location + 2;
		searchRange.length   = strlen - searchRange.location;
		
		/* autorelease poolを解放 */
		counterOfAutorelease++;
		if (counterOfAutorelease % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	
	[pool release];
	
	return escapedString;
}

// Finderを最前面に持ってくる。
- (void)activateFinder
{
	NSDictionary	*error;
	
	if ([gActivateFinderAppleScript executeAndReturnError:&error] == nil) {
		// error occurred
		[self showErrorAlert:@"Error!" message:[NSString stringWithFormat:@"%@", error]];
	}
}

@end
