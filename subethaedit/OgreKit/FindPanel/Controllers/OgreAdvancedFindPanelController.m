/*
 * Name: OgreAdvancedFindPanelController.m
 * Project: OgreKit
 *
 * Creation Date: Sep 14 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreAdvancedFindPanelController.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreAFPCEscapeCharacterFormatter.h>
#import <OgreKit/OgreTextFindProgressSheet.h>
#import <OgreKit/OgreFindResultWindowController.h>
#import <OgreKit/OgreAttachableWindowMediator.h>

// 諸設定
static const int  OgreAFPCMaximumLeftMargin = 30;   // 検索結果の左側の最大文字数 (マッチ結果が隠れてしまうことを防ぐ)
static const int  OgreAFPCMaximumMatchedStringLength = 250; // 検索結果の最大文字数

// OgreAPFCLocalizable.stringsを使用したローカライズ
#define OgreAPFCLocalizedString(key)	[[OgreTextFinder ogreKitBundle] localizedStringForKey:(key) value:(key) table:@"OgreAPFCLocalizable"]

// 例外名
NSString	*OgreAFPCException = @"OgreAdvancedFindPanelControllerException";

// historyのencode/decodeに使用するKey
static NSString	*OgreAFPCFindHistoryKey            = @"AFPC Find History";
static NSString	*OgreAFPCReplaceHistoryKey         = @"AFPC Replace History";
static NSString	*OgreAFPCOptionsKey                = @"AFPC Options";
static NSString	*OgreAFPCSyntaxKey                 = @"AFPC Syntax";
static NSString	*OgreAFPCEscapeCharacterKey        = @"AFPC Escape Character Tag";
static NSString	*OgreAFPCHighlightColorKey         = @"AFPC Highlight Color";
static NSString	*OgreAFPCOriginKey                 = @"AFPC Origin";
static NSString	*OgreAFPCScopeKey                  = @"AFPC Scope";
static NSString	*OgreAFPCWrapKey                   = @"AFPC Wrap";
static NSString	*OgreAFPCCloseWhenDoneKey          = @"AFPC Close Process Sheet When Done";
static NSString	*OgreAFPCMaxNumOfFindHistoryKey    = @"AFPC Maximum Number of Find History";
static NSString	*OgreAFPCMaxNumOfReplaceHistoryKey = @"AFPC Maximum Number of Replace History";


@implementation OgreAdvancedFindPanelController

- (OgreSyntax)syntaxForIndex:(unsigned)index
{
	if (index == 0) return OgreSimpleMatchingSyntax;
	if (index == 1) return OgrePOSIXBasicSyntax;
	if (index == 2) return OgrePOSIXExtendedSyntax;
	if (index == 3) return OgreEmacsSyntax;
	if (index == 4) return OgreGrepSyntax;
	if (index == 5) return OgreGNURegexSyntax;
	if (index == 6) return OgreJavaSyntax;
	if (index == 7) return OgrePerlSyntax;
	if (index == 8) return OgreRubySyntax;
	
	[NSException raise:OgreException format:@"unknown syntax."];
	return NULL;
}

- (int)indexForSyntax:(OgreSyntax)syntax
{
	if (syntax == OgreSimpleMatchingSyntax) return 0;
	if (syntax == OgrePOSIXBasicSyntax) return 1;
	if (syntax == OgrePOSIXExtendedSyntax) return 2;
	if (syntax == OgreEmacsSyntax) return 3;
	if (syntax == OgreGrepSyntax) return 4;
	if (syntax == OgreGNURegexSyntax) return 5;
	if (syntax == OgreJavaSyntax) return 6;
	if (syntax == OgrePerlSyntax) return 7;
	if (syntax == OgreRubySyntax) return 8;
	
	[NSException raise:OgreException format:@"unknown syntax."];
	return -1;	// dummy
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	// GUIの初期化
	// syntaxを見分けるtagを設定
	int i;
	for (i=0; i<=8; i++) {
		[[syntaxPopUpButton itemAtIndex:i] setTag:[OGRegularExpression intValueForSyntax:[self syntaxForIndex:i]]];
	}
	
	_findComboBoxCell    = [findComboBox cell];
	_replaceComboBoxCell = [replaceComboBox cell];
	
	// 初期値設定
	_delimitChackBoxState = [optionDelimitCheckBox state];
	_findHistory = [[NSMutableArray alloc] initWithCapacity:0];
	_replaceHistory = [[NSMutableArray alloc] initWithCapacity:0];
	_isAlertSheetOpen = NO;
	_findResultWindowController = nil;
	
	// 履歴の復元
	[self restoreHistory:[textFinder history]];
	[textFinder setEscapeCharacter:[self escapeCharacter]];
	[textFinder setSyntax:[self syntax]];
	// optionDelimitCheckBoxの表示をsyntaxに合わせる。
	if ([self syntax] == OgreSimpleMatchingSyntax) {
		[self enableDelimitCheckBox:YES];
	} else {
		[self enableDelimitCheckBox:NO];
	}
	
	// escape characterのformatter
	_escapeCharacterFormatter = [[[OgreAFPCEscapeCharacterFormatter alloc] init] autorelease];
	[_escapeCharacterFormatter setDelegate:self];
	[_findComboBoxCell setFormatter:_escapeCharacterFormatter];
	[_replaceComboBoxCell setFormatter:_escapeCharacterFormatter];
	
	// max # of find/replace historyの変更を拾う
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(updateMaxNumOfFindHistory:) 
		name: NSControlTextDidEndEditingNotification
		object: maxNumOfFindHistoryTextField];
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(updateMaxNumOfReplaceHistory:) 
		name: NSControlTextDidEndEditingNotification
		object: maxNumOfReplaceHistoryTextField];
}

/*- (void)notified:(NSNotification*)aNotification
{
	NSLog(@"%@", [aNotification name]);
}*/

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_replaceHistory release];
	[_findHistory release];
	[_escapeCharacterFormatter release];
	
	[super dealloc];
}


/* (re)store history */

- (void)restoreHistory:(NSDictionary*)history
{
	if (history == nil) return;
	
	NSMutableArray	*findHistory = [NSMutableArray arrayWithArray:[history objectForKey:OgreAFPCFindHistoryKey]];
	if ((findHistory != nil) && ([findHistory count] > 0)) {
		[_findHistory release];
		_findHistory = [findHistory retain];
		[_findComboBoxCell setStringValue:[_findHistory objectAtIndex:0]];
		[findComboBox reloadData];
	} else {
		[_findComboBoxCell setStringValue:@""];
	}
	
	NSMutableArray	*replaceHistory = [[NSMutableArray arrayWithArray:[history objectForKey:OgreAFPCReplaceHistoryKey]] retain];
	if ((replaceHistory != nil) && ([replaceHistory count] > 0)) {
		[_replaceHistory release];
		_replaceHistory = [replaceHistory retain];
		[_replaceComboBoxCell setStringValue:[_replaceHistory objectAtIndex:0]];
		[replaceComboBox reloadData];
	} else {
		[_replaceComboBoxCell setStringValue:@""];
	}
	
	int	i;
	id	anObject = [history objectForKey:OgreAFPCOptionsKey];
	if (anObject != nil) {
		for (i=0; i<=12; i++) [[moreOptionsMatrix cellAtRow:i column:0] setState:NSOffState];
		[optionIgnoreCaseCheckBox setState:NSOffState];
		[optionDelimitCheckBox setState:NSOffState];
		
		unsigned	options = [anObject unsignedIntValue];
		if ((options & OgreSingleLineOption) != 0) [[moreOptionsMatrix cellAtRow:0 column:0] setState:NSOnState];
		if ((options & OgreMultilineOption) != 0) [[moreOptionsMatrix cellAtRow:1 column:0] setState:NSOnState];
		if ((options & OgreIgnoreCaseOption) != 0) {
			[[moreOptionsMatrix cellAtRow:2 column:0] setState:NSOnState];
			[optionIgnoreCaseCheckBox setState:NSOnState];
		}
		if ((options & OgreExtendOption) != 0) [[moreOptionsMatrix cellAtRow:3 column:0] setState:NSOnState];
		if ((options & OgreFindLongestOption) != 0) [[moreOptionsMatrix cellAtRow:4 column:0] setState:NSOnState];
		if ((options & OgreFindNotEmptyOption) != 0) [[moreOptionsMatrix cellAtRow:5 column:0] setState:NSOnState];
		if ((options & OgreFindEmptyOption) != 0) [[moreOptionsMatrix cellAtRow:6 column:0] setState:NSOnState];
		if ((options & OgreNegateSingleLineOption) != 0) [[moreOptionsMatrix cellAtRow:7 column:0] setState:NSOnState];
		if ((options & OgreCaptureGroupOption) != 0) [[moreOptionsMatrix cellAtRow:8 column:0] setState:NSOnState];
		if ((options & OgreDontCaptureGroupOption) != 0) [[moreOptionsMatrix cellAtRow:9 column:0] setState:NSOnState];
		if ((options & OgreDelimitByWhitespaceOption) != 0) {
			[[moreOptionsMatrix cellAtRow:10 column:0] setState:NSOnState];
			[optionDelimitCheckBox setState:NSOnState];
			_delimitChackBoxState = NSOnState;
		} else {
			_delimitChackBoxState = NSOffState;
		}
		if ((options & OgreNotBOLOption) != 0) [[moreOptionsMatrix cellAtRow:11 column:0] setState:NSOnState];
		if ((options & OgreNotEOLOption) != 0) [[moreOptionsMatrix cellAtRow:12 column:0] setState:NSOnState];
	}
	
	anObject = [history objectForKey:OgreAFPCSyntaxKey];
	if (anObject != nil) {
		OgreSyntax	syntax = [OGRegularExpression syntaxForIntValue:[anObject intValue]];
		
		[syntaxPopUpButton selectItemAtIndex:[self indexForSyntax:syntax]];
		
		if (syntax == OgreSimpleMatchingSyntax) {
			[optionRegexCheckBox setState:NSOffState];
		} else {
			[optionRegexCheckBox setState:NSOnState];
		}
		
		int	i, syntaxValue = [OGRegularExpression intValueForSyntax:syntax];
		for (i = 0; i <= 8; i++) {
			if ([[syntaxPopUpButton itemAtIndex:i] tag] == syntaxValue) {
				[syntaxPopUpButton selectItemAtIndex:i];
				break;
			}
		}
	}
	
	anObject = [history objectForKey:OgreAFPCEscapeCharacterKey];
	if (anObject != nil) {
		[escapeCharacterPopUpButton selectItemAtIndex:[anObject intValue]];
	}
	
	anObject = [history objectForKey:OgreAFPCHighlightColorKey];
	if (anObject != nil) {
		[highlightColorWell setColor:[NSUnarchiver unarchiveObjectWithData:anObject]];
	}
	
	anObject = [history objectForKey:OgreAFPCOriginKey];
	if (anObject != nil) {
		for (i=0; i<=1; i++) [[originMatrix cellAtRow:i column:0] setState:NSOffState];
		unsigned	origin = [anObject unsignedIntValue];
		[[originMatrix cellAtRow:origin column:0] setState:NSOnState];
	}
	
	anObject = [history objectForKey:OgreAFPCScopeKey];
	if (anObject != nil) {
		for (i=0; i<=1; i++) [[scopeMatrix cellAtRow:i column:0] setState:NSOffState];
		unsigned	scope = [anObject unsignedIntValue];
		[[scopeMatrix cellAtRow:scope column:0] setState:NSOnState];
	}
	
	anObject = [history objectForKey:OgreAFPCWrapKey];
	if (anObject != nil) {
		if ([anObject intValue] == NSOnState) {
			[optionWrapCheckBox setState:NSOnState];
		} else {
			[optionWrapCheckBox setState:NSOffState];
		}
	}
	
	anObject = [history objectForKey:OgreAFPCCloseWhenDoneKey];
	if (anObject != nil) {
		[closeWhenDoneCheckBox setState:[anObject intValue]];
	}
	
	anObject = [history objectForKey:OgreAFPCMaxNumOfFindHistoryKey];
	if (anObject != nil) {
		[maxNumOfFindHistoryTextField setIntValue:[anObject intValue]];
	}
	
	anObject = [history objectForKey:OgreAFPCMaxNumOfReplaceHistoryKey];
	if (anObject != nil) {
		[maxNumOfReplaceHistoryTextField setIntValue:[anObject intValue]];
	}
}

- (NSDictionary*)history
{
	/* 検索履歴等の情報を残したい場合はこのメソッドを上書きする。 */
	return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
			_findHistory, 
			_replaceHistory, 
			[NSNumber numberWithUnsignedInt:([self options] | ((_delimitChackBoxState == NSOnState)? OgreDelimitByWhitespaceOption : 0))], 
			[NSNumber numberWithInt:[[syntaxPopUpButton selectedItem] tag]], 
			[NSNumber numberWithInt:[[escapeCharacterPopUpButton selectedItem] tag]], 
			[NSArchiver archivedDataWithRootObject:[highlightColorWell color]], 
			[NSNumber numberWithUnsignedInt:[[originMatrix selectedCell] tag]], 
			[NSNumber numberWithUnsignedInt:[[scopeMatrix selectedCell] tag]], 
			[NSNumber numberWithInt:[optionWrapCheckBox state]], 
			[NSNumber numberWithInt:[closeWhenDoneCheckBox state]], 
			[NSNumber numberWithInt:[maxNumOfFindHistoryTextField intValue]], 
			[NSNumber numberWithInt:[maxNumOfReplaceHistoryTextField intValue]], 
			nil]
		forKeys:[NSArray arrayWithObjects:
			OgreAFPCFindHistoryKey, 
			OgreAFPCReplaceHistoryKey, 
			OgreAFPCOptionsKey, 
			OgreAFPCSyntaxKey, 
			OgreAFPCEscapeCharacterKey, 
			OgreAFPCHighlightColorKey, 
			OgreAFPCOriginKey, 
			OgreAFPCScopeKey, 
			OgreAFPCWrapKey, 
			OgreAFPCCloseWhenDoneKey, 
			OgreAFPCMaxNumOfFindHistoryKey, 
			OgreAFPCMaxNumOfReplaceHistoryKey, 
			nil]];
}


/* combo box data source methods */

- (int)numberOfItemsInComboBox:(NSComboBox*)aComboBox
{
	if (aComboBox == replaceComboBox) {
		return [_replaceHistory count];
	}
	return [_findHistory count];
}

- (id)comboBox:(NSComboBox*)aComboBox objectValueForItemAtIndex:(int)index
{
	if (aComboBox == replaceComboBox) {
		return [_replaceHistory objectAtIndex:index];
	}
	return [_findHistory objectAtIndex:index];
}

- (unsigned)comboBox:(NSComboBox*)aComboBox indexOfItemWithStringValue:(NSString*)string
{
	if (aComboBox == replaceComboBox) {
		return [_replaceHistory indexOfObject:string];
	}
	return [_findHistory indexOfObject:string];
}

/* find/replace history */

- (void)addFindHistory:(NSString*)string
{
	[self loadFindStringToPasteboard];	// load to Paseteboad
	
	int	i, n = [_findHistory count];
	for (i = 0; i < n; i++) {
		if ([[_escapeCharacterFormatter stringForObjectValue:[_findHistory objectAtIndex:i]] isEqualToString:string]) {
			[_findHistory removeObjectAtIndex:i];
			break;
		}
	}
	
	[_findHistory insertObject:string atIndex:0];
	
	while ([_findHistory count] > [maxNumOfFindHistoryTextField intValue]) {
		[_findHistory removeObjectAtIndex:[maxNumOfFindHistoryTextField intValue]];
	}

	[findComboBox reloadData];
}

- (void)addReplaceHistory:(NSString*)string
{
	int	i, n = [_replaceHistory count];
	for (i = 0; i < n; i++) {
		if ([[_escapeCharacterFormatter stringForObjectValue:[_replaceHistory objectAtIndex:i]] isEqualToString:string]) {
			[_replaceHistory removeObjectAtIndex:i];
			break;
		}
	}
	
	[_replaceHistory insertObject:string atIndex:0];
	
	int	maxNumOfHistory = [maxNumOfReplaceHistoryTextField intValue];
	while ([_replaceHistory count] > maxNumOfHistory) {
		[_replaceHistory removeObjectAtIndex:maxNumOfHistory];
	}

	[replaceComboBox reloadData];
}

- (IBAction)clearFindReplaceHistories:(id)sender
{
	[findPanel makeKeyAndOrderFront:self];
	NSBeginAlertSheet(OgreAPFCLocalizedString(@"Clear"), 
		OgreAPFCLocalizedString(@"Yes"), 
		OgreAPFCLocalizedString(@"No"), 
		nil, findPanel, self, 
		@selector(clearFindPeplaceHistoriesSheetDidEnd:returnCode:contextInfo:), 
		@selector(sheetDidDismiss:returnCode:contextInfo:), nil, 
		OgreAPFCLocalizedString(@"Do you really want to clear find/replace histories?"));
	_isAlertSheetOpen = YES;
}

- (void)clearFindPeplaceHistoriesSheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo{
	if (returnCode == NSAlertDefaultReturn) {
		[_findHistory release];
		[_replaceHistory release];
		_findHistory = [[NSMutableArray alloc] initWithCapacity:0];
		_replaceHistory = [[NSMutableArray alloc] initWithCapacity:0];
		[_findComboBoxCell setStringValue:@""];
		[_replaceComboBoxCell setStringValue:@""];
	}
}


/* accessors */

- (NSString*)escapeCharacter
{
	int tag = [[escapeCharacterPopUpButton selectedItem] tag];
	// 0: ＼
	// 1: ￥
	// 2: ＼ (Convert ￥ to ＼)
	// 3: ￥ (Convert ＼ to ￥)
	
	if ((tag == 0) || (tag == 2)) {
		return OgreBackslashCharacter;
	} else {
		return OgreGUIYenCharacter;
	}
}

- (BOOL)shouldEquateYenWithBackslash
{
	int tag = [[escapeCharacterPopUpButton selectedItem] tag];
	// 0: ＼
	// 1: ￥
	// 2: ＼ (Convert ￥ to ＼)
	// 3: ￥ (Convert ＼ to ￥)
	
	if ((tag == 0) || (tag == 1)) {
		return NO;
	} else {
		return YES;
	}
}

- (unsigned)options
{
	unsigned	options = OgreNoneOption;
	
	if ([[moreOptionsMatrix cellAtRow:0 column:0] state] == NSOnState) options |= OgreSingleLineOption;
	if ([[moreOptionsMatrix cellAtRow:1 column:0] state] == NSOnState) options |= OgreMultilineOption;
	if ([[moreOptionsMatrix cellAtRow:2 column:0] state] == NSOnState) options |= OgreIgnoreCaseOption;
	if ([[moreOptionsMatrix cellAtRow:3 column:0] state] == NSOnState) options |= OgreExtendOption;
	if ([[moreOptionsMatrix cellAtRow:4 column:0] state] == NSOnState) options |= OgreFindLongestOption;
	if ([[moreOptionsMatrix cellAtRow:5 column:0] state] == NSOnState) options |= OgreFindNotEmptyOption;
	if ([[moreOptionsMatrix cellAtRow:6 column:0] state] == NSOnState) options |= OgreFindEmptyOption;
	if ([[moreOptionsMatrix cellAtRow:7 column:0] state] == NSOnState) options |= OgreNegateSingleLineOption;
	if ([[moreOptionsMatrix cellAtRow:8 column:0] state] == NSOnState) options |= OgreCaptureGroupOption;
	if ([[moreOptionsMatrix cellAtRow:9 column:0] state] == NSOnState) options |= OgreDontCaptureGroupOption;
	if ([[moreOptionsMatrix cellAtRow:10 column:0] state] == NSOnState) options |= OgreDelimitByWhitespaceOption;
	if ([[moreOptionsMatrix cellAtRow:11 column:0] state] == NSOnState) options |= OgreNotBOLOption;
	if ([[moreOptionsMatrix cellAtRow:12 column:0] state] == NSOnState) options |= OgreNotEOLOption;
	
	return options;
}

- (OgreSyntax)syntax
{
	//NSLog(@"%d", [[syntaxMatrix selectedCell] tag]);
	return [OGRegularExpression syntaxForIntValue:[[syntaxPopUpButton selectedItem] tag]];
}

- (BOOL)isEntire
{
	if ([[scopeMatrix cellAtRow:0 column:0] state] == NSOnState) return YES;
	
	return NO;
}

- (void)setIsEntire:(BOOL)isEntire
{
    [[scopeMatrix cellAtRow:0 column:0] setState:(isEntire? NSOnState : NSOffState)];
    [[scopeMatrix cellAtRow:1 column:0] setState:(!isEntire? NSOnState : NSOffState)];
}

- (void)avoidEmptySelection
{
	if ([[self textFinder] isSelectionEmpty]) {
		// 空範囲選択の場合、強制的に検索範囲を全体にする。
		[[scopeMatrix cellAtRow:0 column:0] setState:NSOnState];
		[[scopeMatrix cellAtRow:1 column:0] setState:NSOffState];
	}
}

- (BOOL)isStartFromTop
{
	if ([[originMatrix cellAtRow:0 column:0] state] == NSOnState) return YES;
	
	return NO;
}

- (void)setStartFromCursor
{
	[[originMatrix cellAtRow:0 column:0] setState:NSOffState];	// At Top
	[[originMatrix cellAtRow:1 column:0] setState:NSOnState];	// From Cursor
}

- (BOOL)isWrap
{
	if ([optionWrapCheckBox state] == NSOnState) return YES;
	
	return NO;
}

- (IBAction)showFindPanel:(id)sender
{
    if (![findPanel isVisible]) [self loadFindStringFromPasteboard];
    
	[findPanel makeFirstResponder:findComboBox];
	[super showFindPanel:self];
}

/* update settings */

- (IBAction)updateEscapeCharacter:(id)sender
{
	[textFinder setEscapeCharacter:[self escapeCharacter]];
	[_findComboBoxCell setObjectValue:[_findComboBoxCell stringValue]];	// update display
	[_replaceComboBoxCell setObjectValue:[_replaceComboBoxCell stringValue]];	// update display
}

- (IBAction)updateOptions:(id)sender
{
	//NSLog(@"update options");
	
	if (sender == moreOptionsMatrix) {
		[optionIgnoreCaseCheckBox setState: [[moreOptionsMatrix cellAtRow:2 column:0] state]];
		[optionDelimitCheckBox setState: [[moreOptionsMatrix cellAtRow:10 column:0] state]];
	} else {
		[[moreOptionsMatrix cellAtRow:2 column:0] setState: [optionIgnoreCaseCheckBox state]];
		[[moreOptionsMatrix cellAtRow:10 column:0] setState: [optionDelimitCheckBox state]];
	}
	
	//NSLog(@"check %d", [[sender selectedCell] tag]);
	if ([[sender selectedCell] tag] == 9) _delimitChackBoxState = [optionDelimitCheckBox state];
}

- (IBAction)updateSyntax:(id)sender
{
	//NSLog(@"update syntax");
	
	if (sender == syntaxPopUpButton) {
		if ([[syntaxPopUpButton selectedItem] tag] == [OGRegularExpression intValueForSyntax:OgreSimpleMatchingSyntax]) {
			[optionRegexCheckBox setState: NSOffState];
			[self enableDelimitCheckBox:YES];
		} else {
			[optionRegexCheckBox setState: NSOnState]; 
			[self enableDelimitCheckBox:NO];
		}
	} else {
		if ([optionRegexCheckBox state] == NSOnState) {
			int	i, syntaxValue = [OGRegularExpression intValueForSyntax:OgreRubySyntax];
			for (i = 0; i <= 8; i++) {
				if ([[syntaxPopUpButton itemAtIndex:i] tag] == syntaxValue) {
					[syntaxPopUpButton selectItemAtIndex:i];
					break;
				}
			}
			[self enableDelimitCheckBox:NO];
		} else {
			int	i, syntaxValue = [OGRegularExpression intValueForSyntax:OgreSimpleMatchingSyntax];
			for (i = 0; i <= 8; i++) {
				if ([[syntaxPopUpButton itemAtIndex:i] tag] == syntaxValue) {
					[syntaxPopUpButton selectItemAtIndex:i];
					break;
				}
			}
			[self enableDelimitCheckBox:YES];
		}
	}
	
	OgreSyntax	syntax = [self syntax];
	[textFinder setSyntax:syntax];
}

- (void)enableDelimitCheckBox:(BOOL)changeToEnable
{
	if (changeToEnable) {
		[[moreOptionsMatrix cellAtRow:10 column:0] setAllowsMixedState:NO];
		[optionDelimitCheckBox setAllowsMixedState:NO];
		
		[[moreOptionsMatrix cellAtRow:10 column:0] setState:_delimitChackBoxState];
		[optionDelimitCheckBox setState:_delimitChackBoxState];
		
		[[moreOptionsMatrix cellAtRow:10 column:0] setEnabled:YES];
		[optionDelimitCheckBox setEnabled:YES];
	} else {
		//_delimitChackBoxState = [optionDelimitCheckBox state];
		
		[[moreOptionsMatrix cellAtRow:10 column:0] setAllowsMixedState:YES];
		[optionDelimitCheckBox setAllowsMixedState:YES];
		
		if (_delimitChackBoxState == NSOnState) {
			[[moreOptionsMatrix cellAtRow:10 column:0] setState:NSMixedState];
			[optionDelimitCheckBox setState:NSMixedState];
		} else {
			[[moreOptionsMatrix cellAtRow:10 column:0] setState:NSOffState];
			[optionDelimitCheckBox setState:NSOffState];
		}
		
		[[moreOptionsMatrix cellAtRow:10 column:0] setEnabled:NO];
		[optionDelimitCheckBox setEnabled:NO];
	}
}

- (void)updateMaxNumOfFindHistory:(NSNotification*)aNotification
{
	int	maxNumOfHistory = [maxNumOfFindHistoryTextField intValue];
	while ([_findHistory count] > maxNumOfHistory) {
		[_findHistory removeObjectAtIndex:maxNumOfHistory];
	}

	[findComboBox reloadData];
}

- (void)updateMaxNumOfReplaceHistory:(NSNotification*)aNotification
{
	int	maxNumOfHistory = [maxNumOfReplaceHistoryTextField intValue];
	while ([_replaceHistory count] > maxNumOfHistory) {
		[_replaceHistory removeObjectAtIndex:maxNumOfHistory];
	}

	[replaceComboBox reloadData];
}


/* show alert */
- (BOOL)alertIfInvalidRegex
{
	NS_DURING
		[OGRegularExpression regularExpressionWithString: [_findComboBoxCell stringValue] 
			options: [self options] 
			syntax: [self syntax] 
			escapeCharacter:[self escapeCharacter]];
	NS_HANDLER
		// 例外処理
		if ([[localException name] isEqualToString:OgreException]) {
			[self showErrorAlert:OgreAPFCLocalizedString(@"Invalid Regular Expression") message:[localException reason]];
		} else {
			[localException raise];
		}
		return NO;
	NS_ENDHANDLER
	
	return YES;
}

- (void)showErrorAlert:(NSString*)title message:(NSString*)message
{
	NSBeep();
	[findPanel makeKeyAndOrderFront:self];
	NSBeginAlertSheet(title, OgreAPFCLocalizedString(@"OK"), nil, nil, findPanel, self, nil, @selector(sheetDidDismiss:returnCode:contextInfo:), nil, message);
	_isAlertSheetOpen = YES;
}

- (void)sheetDidDismiss:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	//NSLog(@"sheetDidDismiss");
	[findPanel makeKeyAndOrderFront:self];
	_isAlertSheetOpen = NO;
}

/* actions */

- (IBAction)findNext:(id)sender
{
	[self findNextStrategy];
}

- (IBAction)findNextAndOrderOut:(id)sender
{
	OgreTextFindResult	*result = [self findNextStrategy];
	if ([result isSuccess]) [findPanel orderOut:self];
}

- (OgreTextFindResult*)findNextStrategy
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return [OgreTextFindResult textFindResultWithTarget:nil thread:nil];   // failure
	}
    
	if (![self alertIfInvalidRegex]) {
        return [OgreTextFindResult textFindResultWithTarget:nil thread:nil];   // failure
    }
	
	[self addFindHistory:[_findComboBoxCell stringValue]];
	
	OgreTextFindResult	*result = [[self textFinder] find:[_findComboBoxCell stringValue] 
		options:[self options]	
		fromTop:[self isStartFromTop]
		forward:YES
		wrap:[self isWrap]];
	
	if (![result alertIfErrorOccurred]) {
		if ([result isSuccess]) {
			[self setStartFromCursor];
		} else {
			NSBeep();
		}
	}
    
	return result;
}

- (IBAction)findPrevious:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[_findComboBoxCell stringValue]];
	
	OgreTextFindResult	*result = [[self textFinder] find:[_findComboBoxCell stringValue] 
		options:[self options] 
		fromTop:[self isStartFromTop]
		forward:NO
		wrap:[self isWrap]];
		
	if (![result alertIfErrorOccurred]) {
		if ([result isSuccess]) {
			[self setStartFromCursor];
		} else {
			NSBeep();
		}
	}
}

- (IBAction)replace:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[_findComboBoxCell stringValue]];
	[self addReplaceHistory:[_replaceComboBoxCell stringValue]];
	
	OgreTextFindResult	*result = [[self textFinder] replaceAndFind:[_findComboBoxCell stringValue] 
			withString:[_replaceComboBoxCell stringValue] 
			options:[self options] 
            replacingOnly:YES 
            wrap:NO];
			
	if (![result alertIfErrorOccurred]) {
		if ([result isSuccess]) {
			[self setStartFromCursor];
		} else {
			NSBeep();
		}
	}
}

- (IBAction)replaceAndFind:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[_findComboBoxCell stringValue]];
	[self addReplaceHistory:[_replaceComboBoxCell stringValue]];
	
	OgreTextFindResult	*result = [[self textFinder] replaceAndFind:[_findComboBoxCell stringValue] 
			withString:[_replaceComboBoxCell stringValue] 
			options:[self options] 
            replacingOnly:NO 
            wrap:[self isWrap]];
			
	if (![result alertIfErrorOccurred]) {
		if ([result isSuccess]) {
			[self setStartFromCursor];
		} else {
			NSBeep();
		}
	}
}


- (IBAction)replaceAll:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[_findComboBoxCell stringValue]];
	[self addReplaceHistory:[_replaceComboBoxCell stringValue]];
	
	//[self avoidEmptySelection];
	OgreTextFindResult	*result = [[self textFinder] replaceAll: [_findComboBoxCell stringValue] 
		withString: [_replaceComboBoxCell stringValue]
		options: [self options] 
		inSelection: ![self isEntire]];
		
	if ([result alertIfErrorOccurred]) return;  // error
	if (![result isSuccess]) NSBeep();
}

- (BOOL)didEndReplaceAll:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didEndReplaceAll: of %@", [self className]);
#endif
	BOOL	closeProgressWindow;
	OgreTextFindResult	*textFindResult = (OgreTextFindResult*)anObject;
	
	if ([textFindResult alertIfErrorOccurred]) {
		// error
		closeProgressWindow = NO;
	} else {
		// success or failure
		//int	numOfReplace = [[textFindResult resultInfo] intValue];
		//NSLog(@"didEndReplaceAll: %d", numOfReplace);
		closeProgressWindow =  (([closeWhenDoneCheckBox state] == NSOnState)? YES : NO);
	}
	
	return closeProgressWindow;
}


- (IBAction)highlight:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[_findComboBoxCell stringValue]];
	
	//[self avoidEmptySelection];
	OgreTextFindResult	*result = [[self textFinder] hightlight: [_findComboBoxCell stringValue] 
		color: [highlightColorWell color] 
		options: [self options] 
		inSelection: ![self isEntire]];
	
	if ([result alertIfErrorOccurred]) return;  // error
	if (![result isSuccess]) NSBeep();
}

- (BOOL)didEndHighlight:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didEndHighlight: of %@", [self className]);
#endif
	BOOL	closeProgressWindow;
	OgreTextFindResult	*textFindResult = (OgreTextFindResult*)anObject;
	
	if ([textFindResult alertIfErrorOccurred]) {
		// error
		closeProgressWindow = NO;
	} else {
		// success or failure
		//int	numberOfMatch = [[textFindResult resultInfo] intValue];
		//NSLog(@"didEndHighlight: %d", numberOfMatch);
		closeProgressWindow =  (([closeWhenDoneCheckBox state] == NSOnState)? YES : NO);
	}
	
	return closeProgressWindow;
}

- (IBAction)unhighlight:(id)sender
{
	OgreTextFindResult	*result = [[self textFinder] unhightlight];
	
	if (![result alertIfErrorOccurred]) {
		if (![result isSuccess]) NSBeep();
	}
}

- (IBAction)findAll:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	if (![self alertIfInvalidRegex]) return;
	
	[self addFindHistory:[_findComboBoxCell stringValue]];
	
	//[self avoidEmptySelection];
	OgreTextFindResult	*result = [[self textFinder] findAll: [_findComboBoxCell stringValue] 
		color: [highlightColorWell color] 
		options: [self options] 
		inSelection: ![self isEntire]];
		
	if ([result alertIfErrorOccurred]) return;  // error
	if (![result isSuccess]) NSBeep();
}

- (BOOL)didEndFindAll:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didEndFindAll: of %@", [self className]);
#endif
	
	BOOL	closeProgressWindow = YES;	// 発見できた場合は常に閉じる
	OgreTextFindResult	*textFindResult = (OgreTextFindResult*)anObject;
	
	if ([textFindResult alertIfErrorOccurred]) {
		// error
		closeProgressWindow = NO;
	} else {
		if ([textFindResult isSuccess]) {
			// success
			[textFindResult setMaximumLeftMargin:OgreAFPCMaximumLeftMargin];  // 検索結果の左側の最大文字数
			[textFindResult setMaximumMatchedStringLength:OgreAFPCMaximumMatchedStringLength];  // 検索結果の最大文字数
			if (_findResultWindowController == nil) {
				_findResultWindowController = [[OgreFindResultWindowController alloc] initWithTextFindResult:textFindResult liveUpdate:NO];
				NSWindow	*findResultWindow = [_findResultWindowController window];
				NSRect		frame = [findResultWindow frame];
				frame.origin.x = [findPanel frame].origin.x;
				frame.origin.y = [findPanel frame].origin.y - frame.size.height;
				frame.size.width = [findPanel frame].size.width;
				[findResultWindow setFrame:frame display:NO animate:NO];
				[findPanel addChildWindow:findResultWindow ordered:NSWindowAbove];
				//[[OgreAttachableWindowMediator sharedMediator] attachAcceptee:findResultWindow toAcceptor:findPanel withAccepteeEdge:NSMaxYEdge];
            } else {
				[_findResultWindowController setTextFindResult:textFindResult];
			}
			
			[self showFindPanel:self];
            [_findResultWindowController show];
		} else {
			// failure
			closeProgressWindow = (([closeWhenDoneCheckBox state] == NSOnState)? YES : NO);
		}
	}
	
	return closeProgressWindow;
}

- (IBAction)findSelectedText:(id)sender
{
	[self useSelectionForFind:self];
	[self findNext:self];
}

- (IBAction)jumpToSelection:(id)sender
{
	if (![textFinder jumpToSelection]) NSBeep();
}

- (IBAction)useSelectionForFind:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	NSString	*selectedString = [textFinder selectedString];
	if (selectedString != nil) {
		[_findComboBoxCell setStringValue:selectedString];
		//if (sender != self) [self showFindPanel:sender];
	} else {
		NSBeep();
	}
}

- (IBAction)useSelectionForReplace:(id)sender
{
	if (_isAlertSheetOpen) {
		NSBeep();
		[self showFindPanel:self];
		return;
	}
	NSString	*selectedString = [textFinder selectedString];
	if (selectedString != nil) {
		[_replaceComboBoxCell setStringValue:selectedString];
		//if (sender != self) [self showFindPanel:sender];
	} else {
		NSBeep();
	}
}


/* delegate method of drawers */
- (void)drawerWillClose:(NSNotification*)notification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-drawerDidClose: of %@", [self className]);
#endif
	id	sender = [notification object];
	if (sender == moreOptionsDrawer) {
		[moreOptionsButton setTitle:OgreAPFCLocalizedString(@"More Options")];
	}
}

- (void)drawerWillOpen:(NSNotification*)notification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-drawerWillOpen: of %@", [self className]);
#endif
	id	sender = [notification object];
	if (sender == moreOptionsDrawer) {
		[moreOptionsButton setTitle:OgreAPFCLocalizedString(@"Less Options")];
	}
}

/* load find string from/to pasteboard */
- (void)loadFindStringFromPasteboard
{
	NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
	NSString *findString = [pasteboard stringForType:NSStringPboardType];
	if ((findString != nil) && ([findString length] > 0)) [_findComboBoxCell setStringValue:findString];
}

- (void)loadFindStringToPasteboard
{
	NSString *findString = [_findComboBoxCell stringValue];
	if ((findString != nil) && ([findString length] > 0)) {
		NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
		[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		[pasteboard setString:findString forType:NSStringPboardType];
	}
}

/* delegate method of NSCombobox (Find TextField, Replace TextField) */
- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)command
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-control:textView:doCommandBySelector:%@", NSStringFromSelector(command));
#endif
	
	if (command == @selector(insertNewline:)) {
		[findNextButton setAction:@selector(findNextAndOrderOut:)];
		[findNextButton performClick:self]; // Find Next
		[findNextButton setAction:@selector(findNext:)];
		//[self findNextAndOrderOut:self];
		return YES;
	}
	
	if (command == @selector(moveUp:)) {
		[textView moveUp:self];
		return YES;
	}
	if (command == @selector(moveDown:)) {
		[textView moveDown:self];
		return YES;
	}
	if (command == @selector(moveLeft:)) {
		[textView moveLeft:self];
		return YES;
	}
	if (command == @selector(moveRight:)) {
		[textView moveRight:self];
		return YES;
	}
	
	return NO;
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
    [self findPanelFlagsChanged:0]; // release key
}

/* delegate method of OgreAdvancedFindPanel */
- (void)findPanelFlagsChanged:(unsigned)modifierFlags  
{
    if (modifierFlags & NSAlternateKeyMask) {
        // alt key pressed
        if (!_altKeyDown) {
            _altKeyDown = YES;
            _tmpIsEntire = [self isEntire];
            [self setIsEntire:NO];
        }
    } else {
        // alt key released
        if (_altKeyDown) {
            _altKeyDown = NO;
            [self setIsEntire:_tmpIsEntire];
        }
    }
}

- (void)findPanelDidAddChildWindow:(NSWindow*)childWindow
{
	_findResultWindowController = [childWindow delegate];
}

- (void)findPanelDidRemoveChildWindow:(NSWindow*)childWindow
{
	_findResultWindowController = nil;
}

@end
