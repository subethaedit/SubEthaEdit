/*
 * Name: OgreTextFinder.m
 * Project: OgreKit
 *
 * Creation Date: Sep 20 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreFindPanelController.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTextFindProgressSheet.h>


// singleton
static OgreTextFinder	*_sharedTextFinder = nil;

// 例外名
NSString	*OgreTextFinderException = @"OgreTextFinderException";

// encode/decodeに使用するKey
static NSString	*OgreTextFinderHistoryKey         = @"Find Controller History";
static NSString	*OgreTextFinderSyntaxKey          = @"Syntax";
static NSString	*OgreTextFinderEscapeCharacterKey = @"Escape Character";

@implementation OgreTextFinder

+ (NSBundle*)ogreKitBundle
{
	static NSBundle *theBundle = nil;
	
	if (theBundle == nil) {
		/* OgreKit.framework bundle instanceを探す */
		NSArray			*allFrameworks = [NSBundle allFrameworks];  // リンクされている全フレームワーク
		NSEnumerator	*enumerator = [allFrameworks reverseObjectEnumerator];  // OgreKitは後ろにある可能性が高い
		NSBundle		*aBundle;
		while ((aBundle = [enumerator nextObject]) != nil) {
			if ([[[aBundle bundlePath] lastPathComponent] isEqualToString:@"OgreKit.framework"]) {
#ifdef DEBUG_OGRE_FIND_PANEL
				NSLog(@"Find out OgreKit: %@", [aBundle bundlePath]);
#endif
				theBundle = [aBundle retain];
				break;
			}
		}
	}
	
	return theBundle;
}

+ (id)sharedTextFinder
{
	if (_sharedTextFinder == nil) {
		_sharedTextFinder = [[[self class] alloc] init];
	}
	
	return _sharedTextFinder;
}

- (id)init
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-init of OgreTextFinder");
#endif
	if (_sharedTextFinder != nil) {
		[super release];
		return _sharedTextFinder;
	}
	
    self = [super init];
    if (self != nil) {
		[self createThreadCenter];
		_busyTargetArray = [[NSMutableArray alloc] initWithCapacity:0];	// 使用中ターゲット
		
		NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary	*fullHistory = [defaults dictionaryForKey:@"OgreTextFinder"];	// 履歴等
		
		if (fullHistory != nil) {
			_history = [[fullHistory objectForKey: OgreTextFinderHistoryKey] retain];

			id		anObject = [fullHistory objectForKey: OgreTextFinderSyntaxKey];
			if(anObject == nil) {
				[self setSyntax:[OGRegularExpression defaultSyntax]];
			} else {
				_syntax = [OGRegularExpression syntaxForIntValue:[anObject intValue]];
			}
				
			_escapeCharacter = [[fullHistory objectForKey: OgreTextFinderEscapeCharacterKey] retain];
			if(_escapeCharacter == nil) {
				[self setEscapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
			}
		} else {
			_history = nil;
			[self setSyntax:[OGRegularExpression defaultSyntax]];
			[self setEscapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
		}
		
		_saved = NO;
		// Applicationのterminationを拾う (履歴保存のタイミング)
		[[NSNotificationCenter defaultCenter] addObserver: self 
				selector: @selector(appWillTerminate:) 
				name: NSApplicationWillTerminateNotification
				object: NSApp];
		// Applicationのlaunchを拾う (Findメニューの設定のタイミング)
		[[NSNotificationCenter defaultCenter] addObserver: self 
				selector: @selector(appDidFinishLaunching:) 
				name: NSApplicationDidFinishLaunchingNotification
				object: NSApp];
		
		[NSBundle loadNibNamed:[self findPanelNibName] owner:self];
		
		_sharedTextFinder = self;
	}
	
    return self;
}

/* Thread Center */
- (void)createThreadCenter
{
	_threadCenter = [[OgreTextFindThreadCenter alloc] initWithTextFinder:self];
}

- (void)appDidFinishLaunching:(NSNotification*)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-appDidFinishLaunching: of OgreTextFinder");
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name: NSApplicationDidFinishLaunchingNotification 
		object: NSApp];

	/* Checking the Mac OS X version */
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_0) {
		/* On a 10.0.x or earlier system */
		return; // use the default Find Panel
	} else if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1) {
		/* On a 10.1 - 10.1.x system */
		return; // use the default Find Panel
	} else if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2) {
		/* On a 10.2 - 10.2.x system */
		return; // use the default Find Panel
	} else {
		/* 10.3 or later system */
		
		/* Findメニューの設定 */
		if (findMenu == nil) {
			// findPanelNibの中にFindメニューが見つからなかったとき
			NSLog(@"Find Menu not found in %@.nib", [self findPanelNibName]);
		} else {
			// Findメニューのタイトル
			NSString	*titleOfFindPanel = OgreTextFinderLocalizedString(@"Find");
			
			// Findメニューの初期化
			[findMenu setTitle:titleOfFindPanel];
			id <NSMenuItem> newFindMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
			[newFindMenuItem setTitle:titleOfFindPanel];
			[newFindMenuItem setSubmenu:findMenu];
			
			NSMenu		*mainMenu = [NSApp mainMenu];
			
			id <NSMenuItem> oldFindMenuItem = [self findMenuItemNamed:titleOfFindPanel startAt:mainMenu];
			// Findメニューが既にある場合はそこをfindMenuに入れ替える
			// なければ左から4番目にFindメニューを作り、そこにfindMenuをセットする。
			if (oldFindMenuItem != nil) {
				//NSLog(@"Find found");
				NSMenu		*supermenu = [oldFindMenuItem menu];
				[supermenu insertItem:newFindMenuItem atIndex:[supermenu indexOfItem:oldFindMenuItem]];
				[supermenu removeItem:oldFindMenuItem];
			} else {
				//NSLog(@"Find not found");
				[mainMenu insertItem:newFindMenuItem atIndex:3];
			}
			[mainMenu update];
		}
	}
}

// currentを起点に名前がnameのmenu itemを探す。
- (NSMenuItem*)findMenuItemNamed:(NSString*)name startAt:(NSMenu*)current
{
	id <NSMenuItem>	foundMenuItem = nil;
	if (current == nil) return nil;
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	int i, n;
	NSMutableArray	*menuArray = [NSMutableArray arrayWithObject:current];
	while ([menuArray count] > 0) {
		NSMenu			*aMenu = [menuArray objectAtIndex:0];
		id <NSMenuItem> aMenuItem = [aMenu itemWithTitle:name];
		if (aMenuItem != nil) {
			// 見つかった場合
			foundMenuItem = [aMenuItem retain];
			break;
		}
		
		// 見つからなかった場合
		n = [aMenu numberOfItems];
		for (i=0; i<n; i++) {
			aMenuItem = [aMenu itemAtIndex:i];
			//NSLog(@"%@", [aMenuItem title]);
			if ([aMenuItem hasSubmenu]) [menuArray addObject:[aMenuItem submenu]];
		}
		[menuArray removeObjectAtIndex:0];
	}
	
	[pool release];
	
	return [foundMenuItem autorelease];
}

- (void)appWillTerminate:(NSNotification*)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-appWillTerminate: of OgreTextFinder");
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name: NSApplicationWillTerminateNotification 
		object: NSApp];
	
	// 検索履歴等の保存
	NSDictionary	*fullHistory = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: 
			[findPanelController history],
			[NSNumber numberWithInt:[OGRegularExpression intValueForSyntax:_syntax]], 
			_escapeCharacter, 
			nil]
		forKeys:[NSArray arrayWithObjects: 
			OgreTextFinderHistoryKey, 
			OgreTextFinderSyntaxKey,
			OgreTextFinderEscapeCharacterKey,
			nil]];
	
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:fullHistory forKey:@"OgreTextFinder"];
	[defaults synchronize];
	
	_saved = YES;
}

- (NSDictionary*)history	// 非公開メソッド
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-history of OgreTextFinder");
#endif
	NSDictionary	*history = _history;
	_history = nil;
	
	return [history autorelease];
}

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"CAUTION! -dealloc of OgreTextFinder");
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (_saved == NO) [self appWillTerminate:nil];	// 履歴の保存がまだならば保存する。
	
	[_threadCenter release];
	[findPanelController release];
	[_history release];
	[_escapeCharacter release];
	[_busyTargetArray release];
	_sharedTextFinder = nil;
	
	[super dealloc];
}

- (IBAction)showFindPanel:(id)sender
{
	[findPanelController showFindPanel:self];
}

- (NSString *)findPanelNibName
{
	return @"OgreAdvancedFindPanel";
}

/* accessors */

- (void)setFindPanelController:(OgreFindPanelController*)aFindPanelController
{
	[findPanelController autorelease];
	findPanelController = [aFindPanelController retain];
}

- (OgreFindPanelController*)findPanelController
{
	return findPanelController;
}

- (void)setEscapeCharacter:(NSString*)character
{
	[character retain];
	[_escapeCharacter release];
	_escapeCharacter = character;
}

- (NSString*)escapeCharacter
{
	return _escapeCharacter;
}

- (void)setSyntax:(OgreSyntax)syntax
{
	//NSLog(@"%d", [OGRegularExpression intValueForSyntax:syntax]);
	_syntax = syntax;
}

- (OgreSyntax)syntax
{
	return _syntax;
}

/* 検索対象 */
- (void)setTargetToFindIn:(id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-setTargetToFindIn:\"%@\" of OgreTextFinder", [target className]);
#endif
	_targetToFindIn = target;
}

- (id)targetToFindIn
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-targetToFindIn of OgreTextFinder");
#endif
	id	target = nil;
	[self setTargetToFindIn:nil];
	
	/* responder chainにtellMeTargetToFindIn:を投げる */
	if ([NSApp sendAction:@selector(tellMeTargetToFindIn:) to:nil from:self]) {
		// tellMeTargetToFindIn:に応答があった場合、
		//NSLog(@"succeed to perform tellMeTargetToFindIn:");
		target = _targetToFindIn;
	} else {
		// 応答がない場合、main windowのfirst responderがNSTextViewならばそれを採用する。
		//NSLog(@"failed to perform tellMeTargetToFindIn:");
		id	anObject = [[NSApp mainWindow] firstResponder];
		if ((anObject != nil) && [anObject isKindOfClass:[NSTextView class]]) target = anObject;
	}
	
	return target;
}

- (BOOL)isBusyTarget:(id)target
{
	return [_busyTargetArray containsObject:target];
}

- (void)makeTargetBusy:(id)target
{
	if (target != nil) [_busyTargetArray addObject:target];
}

- (void)makeTargetFree:(id)target
{
	if (target != nil) [_busyTargetArray removeObject:target];
}

/* Find/Replace/Highlight... */

- (BOOL)find:(NSString*)expressionString 
	options:(unsigned)options
	fromTop:(BOOL)isFromTop
	forward:(BOOL)forward
	wrap:(BOOL)isWrap
{
	BOOL	isMatch = NO;
	
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return NO;
	[self makeTargetBusy:target];
	
	OGRegularExpression	*regex;
	regex = [OGRegularExpression regularExpressionWithString: expressionString 
		options: options 
		syntax: [self syntax] 
		escapeCharacter: [self escapeCharacter]];
	
	NSString					*text = [target string];
	NSRange						selectedRange = [target selectedRange];
	NSEnumerator				*enumerator;
	OGRegularExpressionMatch	*match;
	NSArray						*matchArray;
	
	if (isFromTop) selectedRange = NSMakeRange(0, 0);
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if (forward) {
		/* 前方検索 */
		enumerator = [regex matchEnumeratorInString:text 
			options:options 
			range:NSMakeRange(NSMaxRange(selectedRange), [text length] - NSMaxRange(selectedRange))];
		// 最初のマッチ結果を得る。
		match = [enumerator nextObject];
		if (match != nil) {
			// マッチした場合
			isMatch = YES;
			NSRange	aRange = [match rangeOfMatchedString];
			[target setSelectedRange:aRange];
			[target scrollRangeToVisible:aRange];
		} else if (isWrap) {
			// マッチしなかった場合でもwrapする場合は検索範囲を変えてもう一度試みる
			enumerator = [regex matchEnumeratorInString:text 
				options:options 
				range:NSMakeRange(0, selectedRange.location)];
			match = [enumerator nextObject];
			if (match != nil) {
				// マッチした場合
				isMatch = YES;
				NSRange	aRange = [match rangeOfMatchedString];
				[target setSelectedRange:aRange];
				[target scrollRangeToVisible:aRange];
			}		
		}
	} else {
		/* 後方検索 */
		// 最後のマッチ結果を得る
		match = nil;
		matchArray = [regex allMatchesInString:text 
			options:options 
			range:NSMakeRange(0, selectedRange.location)];
		if ([matchArray count] > 0) match = [matchArray objectAtIndex:([matchArray count] - 1)];
		if (match != nil) {
			// マッチした場合
			isMatch = YES;
			NSRange	aRange = [match rangeOfMatchedString];
			[target setSelectedRange:aRange];
			[target scrollRangeToVisible:aRange];
		} else if (isWrap) {
			// マッチしなかった場合でもwrapする場合は検索範囲を変えてもう一度試みる
			// 最後のマッチ結果を得る
			match = nil;
			matchArray = [regex allMatchesInString:text 
				options:options 
				range: NSMakeRange(NSMaxRange(selectedRange), [text length] - NSMaxRange(selectedRange))];
			if ([matchArray count] > 0) match = [matchArray objectAtIndex: ([matchArray count] - 1)];
			if (match != nil) {
				// マッチした場合
				isMatch = YES;
				NSRange	aRange = [match rangeOfMatchedString];
				[target setSelectedRange:aRange];
				[target scrollRangeToVisible:aRange];
			}
		}
	}
	
	[pool release];
	
	if (isMatch) [target display];
	[self makeTargetFree:target];
	
	return isMatch;
}

- (BOOL)findAll:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(unsigned)options
	inSelection:(BOOL)inSelection
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return NO;
	[self makeTargetBusy:target];

	OgreTextFindThread			*newThread;
	OgreTextFindProgressSheet	*sheet = nil;
	
	/* 処理状況表示用シートの生成 */
	sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window] 
		title:OgreTextFinderLocalizedString(@"Find All") 
		didEndSelector: @selector(makeTargetFree:) 
		toTarget: self 
		withObject: target];
	
	OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:expressionString
		options: options
		syntax:[self syntax] 
		escapeCharacter:[self escapeCharacter]];
	
	/* スレッドの生成 */
	newThread = [[[OgreTextFindThread alloc] initWithCenter:_threadCenter] autorelease];
	[newThread start: OgreFindAllThread 
		target: target 
		regularExpression: regex 
		options: options 
		replaceString: nil 
		color: highlightColor 
		inSelection: inSelection 
		progressSheet: sheet];
	
	return YES;
}

- (BOOL)replace:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options
{
	BOOL	isReplaced = NO;
	
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target] || ![target isEditable]) return NO;
	[self makeTargetBusy:target];
	
	NSString			*replacedString;
	OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:expressionString 
		options:options 
		syntax:[self syntax] 
		escapeCharacter:[self escapeCharacter]];
	
	NSString	*text = [target string];
	unsigned	textLength = [text length];
	NSRange		selectedRange = [target selectedRange];
	BOOL		locked = NO;
		
	OGRegularExpressionMatch	*match = [regex matchInString:text options:options range:selectedRange];
	
	if (match) {
		isReplaced = YES;
		OGReplaceExpression	*repex = [[OGReplaceExpression alloc] initWithString:replaceString 
			escapeCharacter:[regex escapeCharacter]];
		
		NSTextStorage	*textStorage = [target textStorage];
		locked = [target lockFocusIfCanDraw];
		[textStorage beginEditing];
		
		NSRange		matchRange = [match rangeOfMatchedString];
		[target setSelectedRange:matchRange];
		unsigned	attrIndex = matchRange.location;
		// 文字属性のコピー元。置換前の1文字目の文字属性をコピーする
		if (matchRange.location < textLength) {
			attrIndex = matchRange.location;
		} else {
			// matchRange.location == textLength (> 1) の場合は1文字前にずらす。
			// @"abc" -> attributesAtIndex:3 -> exception
			attrIndex = textLength - 1;
		}
		
		replacedString = [repex replaceMatchedStringOf:match];
		NSRange	newRange = NSMakeRange(matchRange.location, [replacedString length]);
		// Undo操作の登録
		if ([target allowsUndo]) {
			NSUndoManager	*undoManager = [target undoManager];
			[undoManager beginUndoGrouping];
			[[undoManager prepareWithInvocationTarget:self] 
				undoableReplaceCharactersInRange:newRange 
				withAttributedString:[[[NSAttributedString alloc] initWithAttributedString:[textStorage attributedSubstringFromRange:matchRange]] autorelease] 
				inTarget:target 
				jumpToSelection:YES];
			[undoManager setActionName:OgreTextFinderLocalizedString(@"Replace")];
			[undoManager endUndoGrouping];
		}
		
		// 置換	
		if (textLength > 0) {
			[textStorage replaceCharactersInRange:matchRange withAttributedString: [[[NSAttributedString alloc] 
				initWithString: replacedString
				attributes: [textStorage attributesAtIndex:attrIndex effectiveRange:nil]] autorelease]];
		} else {
			// textLength == 0の場合は属性なしで置換
			[target setString:replacedString];
		}
				
		[textStorage endEditing];
		[target setSelectedRange:newRange];
		[target scrollRangeToVisible:newRange];
		if (locked) [target unlockFocus];
		[target display];
		[repex release];
	}
	
	[self makeTargetFree:target];
	return isReplaced;
}

- (BOOL)replaceAll:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options
	inSelection:(BOOL)inSelection
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target] || ![target isEditable]) return NO;
	[self makeTargetBusy:target];
	
	OgreTextFindThread			*newThread;
	OgreTextFindProgressSheet	*sheet = nil;
	
	/* 処理状況表示用シートの生成 */
	sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window] 
		title:OgreTextFinderLocalizedString(@"Replace All") 
		didEndSelector: @selector(makeTargetFree:) 
		toTarget: self 
		withObject: target];
		
	OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:expressionString
		options: options
		syntax:[self syntax] 
		escapeCharacter:[self escapeCharacter]];
	
	/* スレッドの生成 */
	newThread = [[[OgreTextFindThread alloc] initWithCenter:_threadCenter] autorelease];
	[newThread start: OgreReplaceAllThread 
		target: target 
		regularExpression: regex 
		options: options 
		replaceString: replaceString 
		color: nil 
		inSelection: inSelection 
		progressSheet: sheet];
	
	return YES;
}


- (BOOL)unhightlight
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return NO;
	
	NSString		*text = [target string];

	if ([target lockFocusIfCanDraw]) {
		[[target layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [text length])];
		[target unlockFocus];
	}
	
	return YES;
}

- (BOOL)hightlight:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(unsigned)options
	inSelection:(BOOL)inSelection
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return NO;
	[self makeTargetBusy:target];
	
	OgreTextFindThread			*newThread;
	OgreTextFindProgressSheet	*sheet = nil;
	
	/* 処理状況表示用シートの生成 */
	sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window] 
		title:OgreTextFinderLocalizedString(@"Highlight") 
		didEndSelector: @selector(makeTargetFree:) 
		toTarget: self 
		withObject: target];
	
	OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:expressionString
		options: options
		syntax:[self syntax] 
		escapeCharacter:[self escapeCharacter]];
	
	/* スレッドの生成 */
	newThread = [[[OgreTextFindThread alloc] initWithCenter:_threadCenter] autorelease];
	[newThread start: OgreHighlightThread 
		target: target 
		regularExpression: regex 
		options: options 
		replaceString: nil 
		color: highlightColor 
		inSelection: inSelection 
		progressSheet: sheet];
	
	return YES;
}

/* selection */
- (NSString*)selectedString
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return nil;
	
	return [[target string] substringWithRange:[target selectedRange]];
}

- (BOOL)isSelectionEmpty
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return NO;
	NSRange selectedRange = [target selectedRange];
	if (selectedRange.length > 0) return NO;
	
	return YES;
}

- (BOOL)jumpToSelection
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return NO;
	
	[[target window] makeKeyAndOrderFront:self];
	[target scrollRangeToVisible:[target selectedRange]];
	return YES;
}

/* notify from Thread Center */
- (oneway void)didEndThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didEndThread of OgreTextFinder");
#endif
	id	result, target;
	OgreTextFindProgressSheet	*sheet;
	OgreTextFindThreadType		command;
	
	[_threadCenter getResult:&result command:&command target:&target progressSheet:&sheet];
	[target display];
	//NSLog(@"%@", result);
	
	BOOL	closeProgressSheetWhenDone = NO;
	if (command == OgreFindAllThread) {
		closeProgressSheetWhenDone = [(id <OgreTextFindThreadClient>)findPanelController didEndFindAll:result];
	} else if (command == OgreReplaceAllThread) {
		closeProgressSheetWhenDone = [(id <OgreTextFindThreadClient>)findPanelController didEndReplaceAll:result];
	} else if (command == OgreHighlightThread) {
		closeProgressSheetWhenDone = [(id <OgreTextFindThreadClient>)findPanelController didEndHighlight:result];
	}
	
	if (closeProgressSheetWhenDone) {
		// 自動的に閉じる。OKボタンではreleaseしないようにする。
		[sheet setReleaseWhenOKButtonClicked:NO];
		[sheet performSelector:@selector(close:) withObject:self afterDelay:0.0];
	}
	[sheet release];
}

/* Undo/Redo Replace */
- (void)undoableReplaceCharactersInRange:(NSRange)aRange withAttributedString:(NSAttributedString*)aString inTarget:(id)aTarget jumpToSelection:(BOOL)jumpToSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-undoableReplaceCharactersInRange of OgreTextFinder");
#endif
	NSTextStorage	*textStorage = [aTarget textStorage];
	// register redo
	NSRange	newRange = NSMakeRange(aRange.location, [aString length]);
	[[[aTarget undoManager] prepareWithInvocationTarget:self] 
		undoableReplaceCharactersInRange:newRange 
		withAttributedString:[[[NSAttributedString alloc] initWithAttributedString:[textStorage attributedSubstringFromRange:aRange]] autorelease] 
		inTarget:aTarget 
		jumpToSelection:jumpToSelection];
	// undo
	[aTarget setSelectedRange:aRange];
	[textStorage replaceCharactersInRange:aRange withAttributedString:aString];
	[aTarget setSelectedRange:newRange];
	if (jumpToSelection) [aTarget scrollRangeToVisible:newRange];
}

@end

