/*
 * Name: OgreTextFindThread.m
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindThread.h>
#import <OgreKit/OgreTextFindThreadCenter.h>
#import <OgreKit/OgreTextFindProgressSheet.h>
#import <OgreKit/OgreTextFindResult.h>


@implementation OgreTextFindThread

- (id)initWithCenter:(OgreTextFindThreadCenter*)aCenter
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithCenter: of OgreTextFindThread");
#endif
	self = [super init];
	if (self) {
		_threadCenter = aCenter;
		_cancelled = NO;
		_target = nil;
		_regex = nil;
		_replaceString = nil;
		_color = nil;
	}
	
	return self;
}

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -dealloc of OgreTextFindThread");
#endif
	[_target release];
	[_regex release];
	[_replaceString release];
	[_color release];

	[super dealloc];
}


- (void)start:(OgreTextFindThreadType)command 
	target:(id)target 
	regularExpression:(OGRegularExpression*)regularExpression 
	options:(unsigned)options 
	replaceString:(NSString*)replaceString 
	color:(NSColor*)highlightColor 
	inSelection:(BOOL)inSelection 
	progressSheet:(OgreTextFindProgressSheet*)progressSheet;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -start: of OgreTextFindThread");
#endif
	
	// arguments
	_command = command;
	_target = [target retain];
	_text = [_target string];
	_regex = [regularExpression retain];
	_options = options;
	_replaceString = [replaceString retain];
	_color = [highlightColor retain];
	_inSelection = inSelection;
	
	_progressSheet = progressSheet;
	[_progressSheet setCancelSelector:@selector(cancel:) 
		toTarget:self /* retainされる */
		withObject:nil];
	
	if (_command == OgreFindAllThread) {
		[NSApplication detachDrawingThread:@selector(findAll:) 
			toTarget:self 
			withObject:nil];
			// (注意) detachNewThreadSelectorと微妙に動作が異なる。
			// -[NSThread exit]で抜けた場合はtoTargetはreleaseされない。 -> exitで抜けてはならない。
	} else if (_command == OgreReplaceAllThread) {
		[NSApplication detachDrawingThread:@selector(replaceAll:) 
			toTarget:self 
			withObject:nil];
	} else if (_command == OgreHighlightThread) {
		[NSApplication detachDrawingThread:@selector(highlight:) 
			toTarget:self 
			withObject:nil];
	}
}

- (void)findAll:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" begin -findAll: of OgreTextFindThread");
#endif
	
	NSDate		*processTime = [NSDate date];
	unsigned	textLength = [_text length];
	BOOL		cancelled = NO;
	NSRange		matchRange = NSMakeRange(0, 0);
	int			matches = 0;
	double		donePerTotal;
	OgreTextFindResult	*result = nil;
	
	NSString	*progressMessage, *progressMessagePlural;
	progressMessage = OgreTextFinderLocalizedString(@"%d string found. (%dsec remaining)");
	progressMessagePlural = OgreTextFinderLocalizedString(@"%d strings found. (%dsec remaining)");
	
	NSRange		selectedRange = [_target selectedRange];
	
	/* 前方検索 */
	if (!_inSelection) {
		selectedRange = NSMakeRange(0, textLength);
	}
	NSEnumerator	*enumerator = [_regex matchEnumeratorInString: _text 
		options: _options 
		range: selectedRange];
	//NSLog(@"%@", [enumerator description]);
	
	result = [[[OgreTextFindResult alloc] initWithString:_text syntax:[_regex syntax] color:_color] autorelease];
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSDate	*periodicTimer = [[NSDate alloc] init];	// 経過時間
	OGRegularExpressionMatch	*match;
	while ((match = [enumerator nextObject]) != nil) {
		//NSLog(@"%@", [match description]);
		/* cancelled? */
		if (_cancelled) {
			cancelled = YES;
			break;
		}
		
		matches++;
		
		// resultに追加
		[result addMatch:match];
		
		/* show progress (by 1sec) */
		if ([periodicTimer timeIntervalSinceNow] <= -1.0) {
			matchRange = [match rangeOfMatchedString];
			donePerTotal = (double)(matchRange.location + matchRange.length + 1)/(double)(textLength + 1);
			[(OgreTextFindProgressSheet*)_progressSheet setProgress:donePerTotal 
				message:[NSString stringWithFormat:((matches > 1)? progressMessagePlural : progressMessage), 
				matches, 
				(int)ceil(-[processTime timeIntervalSinceNow] * (1.0 - donePerTotal)/donePerTotal)]];
			[periodicTimer release];
			periodicTimer = [[NSDate alloc] init];
		}
		
		/* release autorelease pool */
		if (matches % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	[periodicTimer release];
	[pool release];
	[result finishToFindInTarget:_target];
	
	/* 完了 */
	[self showDone:(double)(matchRange.location + matchRange.length + 1)/(double)(textLength + 1) count:matches time:(-[processTime timeIntervalSinceNow]) cancelled:cancelled];
	
	/* 結果をOgreTextFindThreadCenterに送る */
	[_threadCenter putResult:result command:OgreFindAllThread target:_target progressSheet:_progressSheet];
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" end -findAll: of OgreTextFindThread");
#endif
}

- (void)replaceAll:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" begin -replaceAll: of OgreTextFindThread");
#endif
	
	NSDate		*processTime = [NSDate date];
	int			replaces = 0, matches = 0;
	unsigned	textLength = [_text length];
	NSRange		matchRange = NSMakeRange(textLength, 0), replacedRange;
	BOOL		errorOccurred = NO, cancelled = NO, locked = NO;
	NSString	*replacedString;
	double		donePerTotal;
		
	NSString	*progressMessage, *progressMessagePlural;
	progressMessage = OgreTextFinderLocalizedString(@"%d string replaced. (%dsec remaining)");
	progressMessagePlural = OgreTextFinderLocalizedString(@"%d strings replaced. (%dsec remaining)");
	
	if (![_target isEditable]) {
		replaces = -1;
		errorOccurred = YES;	// 編集不可の場合
		
	} else {
		OGReplaceExpression	*repex = [[OGReplaceExpression alloc] initWithString:_replaceString 
			escapeCharacter:[_regex escapeCharacter]];
#ifdef DEBUG_OGRE_FIND_PANEL
		NSLog(@"%@", [repex description]);
#endif
		
		NSTextStorage	*textStorage = [_target textStorage];
		NSRange			selectedRange = [_target selectedRange];
		if (!_inSelection) {
			selectedRange = NSMakeRange(0, textLength);
		}
		
		NSArray	*matchArray = [_regex allMatchesInString:_text options:_options range:selectedRange];
		matches = [matchArray count];
		OGRegularExpressionMatch	*match;
		unsigned	attrIndex;
		
		// Undo操作の登録開始
		BOOL	allowsUndo = [_target allowsUndo];
		NSUndoManager	*undoManager = nil;
		if (allowsUndo) undoManager = [_target undoManager];
		if (allowsUndo) [undoManager beginUndoGrouping];

		NSDate	*periodicTimer = [[NSDate alloc] init];	// 経過時間
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
		locked = [_target lockFocusIfCanDraw];
		//[textStorage beginEditing];
		
		while (replaces < matches) {
			/* cancelled? */
			if (_cancelled) {
				cancelled = YES;
				break;
			}
			
			replaces++;
			
			/* replace */
			// 後ろから置換する
			match = [matchArray objectAtIndex: (matches - replaces)];
			matchRange = [match rangeOfMatchedString];
			// 文字属性のコピー元。置換前の1文字目の文字属性をコピーする
			if (matchRange.location < textLength) {
				attrIndex = matchRange.location;
			} else {
				// matchRange.location == textLength (> 1) の場合は1文字前にずらす。
				// @"abc" -> attributesAtIndex:3 -> exception
				attrIndex = textLength - 1;
			}
			
			replacedString = [repex replaceMatchedStringOf:match];
			// Undo操作の登録
			if (allowsUndo) {
				[_target setSelectedRange:matchRange];
				replacedRange = NSMakeRange(matchRange.location, [replacedString length]);
				[[undoManager prepareWithInvocationTarget:[OgreTextFinder sharedTextFinder]] 
				undoableReplaceCharactersInRange: replacedRange
				withAttributedString:[[[NSAttributedString alloc] initWithAttributedString:[textStorage attributedSubstringFromRange:matchRange]] autorelease] 
				inTarget:_target
				jumpToSelection:NO];
			}
			
			// 置換
			if (textLength > 0) {
				[textStorage replaceCharactersInRange:matchRange withAttributedString: [[[NSAttributedString alloc] 
					initWithString: replacedString
					attributes: [textStorage attributesAtIndex:attrIndex effectiveRange:nil]] autorelease]];
			} else {
				// textLength == 0の場合は属性なしでコピー。
				[_target setString:replacedString];
			}
			if (allowsUndo) [_target setSelectedRange:replacedRange];
					
			/* show progress (by 1sec)*/
			if ([periodicTimer timeIntervalSinceNow] <= -1.0) {
				donePerTotal = (double)replaces/(double)matches;
				[(OgreTextFindProgressSheet*)_progressSheet setProgress:donePerTotal 
					message:[NSString stringWithFormat:((replaces > 1)? progressMessagePlural : progressMessage), 
					replaces, 
					(int)ceil(-[processTime timeIntervalSinceNow] * (1.0 - donePerTotal)/donePerTotal)]];
				[periodicTimer release];
				periodicTimer = [[NSDate alloc] init];
				
				/* upadate screen */
				//[textStorage endEditing];
				if (locked) [_target unlockFocus];
				locked = [_target lockFocusIfCanDraw];
				//[textStorage beginEditing];
			}
			
			/* release autorelease pool */
			if (replaces % 100 == 0) {
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
			}
			
		}
		
		/* 完了 */
		[self showDone:((double)replaces/(double)matches) count:replaces time:(-[processTime timeIntervalSinceNow]) cancelled:cancelled];
		//[textStorage endEditing];
		if (locked) [_target unlockFocus];
		
		[pool release];
		[periodicTimer release];
		[repex release];
		
		// Undo操作の登録完了
		if (allowsUndo) [undoManager setActionName:OgreTextFinderLocalizedString(@"Replace All")];
		if (allowsUndo) [undoManager endUndoGrouping];
	}
	
	if (errorOccurred) {
		NSBeep();
		[(OgreTextFindProgressSheet*)_progressSheet done:0.0 message:OgreTextFinderLocalizedString(@"Error! Uneditable.")];
	}
	
	/* 結果をOgreTextFindThreadCenterに送る */
	[self sendResult:[NSNumber numberWithInt:replaces]];
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" end -replaceAll: of OgreTextFindThread");
#endif
}

- (void)highlight:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" begin -highlight: of OgreTextFindThread");
#endif
	
	NSDate		*processTime = [NSDate date];
	BOOL		cancelled = NO, locked = NO;
	int			matches = 0;
	unsigned	textLength = [_text length];
	double		donePerTotal;
	
	NSString	*progressMessage, *progressMessagePlural;
	progressMessage = OgreTextFinderLocalizedString(@"%d string highlighted. (%dsec remaining)");
	progressMessagePlural = OgreTextFinderLocalizedString(@"%d strings highlighted. (%dsec remaining)");
	
	NSRange		matchRange = NSMakeRange(0, 0), searchRange, aRange;
	if (_inSelection) {
		searchRange = [_target selectedRange];
	} else {
		searchRange = NSMakeRange(0, textLength);
	}
	
	NSEnumerator	*enumerator = [_regex matchEnumeratorInString: _text 
		options: _options
		range: searchRange];
	
	/* 色付け */
	float	hue, saturation, brightness, alpha;
	[[_color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
		getHue: &hue 
		saturation: &saturation 
		brightness: &brightness 
		alpha: &alpha];
		
	BOOL	simple = ([_regex syntax] == OgreSimpleMatchingSyntax);
	int		i, n;
	
	id		layoutManager = [_target layoutManager];
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];	// autorelease pool
	NSDate	*periodicTimer = [[NSDate alloc] init];	// 経過時間
	
	// remove temporary background color attribute
	locked = [_target lockFocusIfCanDraw];
	[layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, textLength)];
	
	OGRegularExpressionMatch	*match;
	match = [enumerator nextObject];
	if (match != nil) {
		n = [match count];	// 部分文字列の数はどのマッチでも同じ
		do {
			/* cancelled? */
			if (_cancelled) {
				cancelled = YES;
				break;
			}
			
			matches++;
			
			/* 部分文字列ごとに違う色で色付けする */
			for(i = 0; i < n; i++) {
				aRange = [match rangeOfSubstringAtIndex:i];
				double	dummy;
				
				if (aRange.length > 0) {
					[layoutManager setTemporaryAttributes:[NSDictionary dictionaryWithObject:
						[NSColor colorWithCalibratedHue: 
							modf(hue + ((simple)? ((float)(i-1)) : ((float)i)) / ((simple)? ((float)(n-1)) : ((float)n)), &dummy)
							saturation: saturation 
							brightness: brightness 
							alpha: alpha] forKey:NSBackgroundColorAttributeName] forCharacterRange: aRange];
				}
			}
			
			/* show progress (by 1sec)*/
			if ([periodicTimer timeIntervalSinceNow] <= -1.0) {
				matchRange = [match rangeOfMatchedString];
				donePerTotal = (double)(matchRange.location + matchRange.length + 1)/(double)(textLength + 1);
				[(OgreTextFindProgressSheet*)_progressSheet setProgress:donePerTotal 
					message:[NSString stringWithFormat:((matches > 1)? progressMessagePlural : progressMessage), 
					matches, 
					(int)ceil(-[processTime timeIntervalSinceNow] * (1.0 - donePerTotal)/donePerTotal)]];
				[periodicTimer release];
				periodicTimer = [[NSDate alloc] init];
				
				/* upadate screen */
				if (locked) [_target unlockFocus];
				locked = [_target lockFocusIfCanDraw];
			}
			
			/* release autorrelease pool */ 
			if (matches % 100 == 0) {
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
			}
		} while ( (match = [enumerator nextObject]) != nil );
	}
	
	/* 完了 */
	[self showDone:(double)(matchRange.location + matchRange.length + 1)/(double)(textLength + 1) count:matches time:(-[processTime timeIntervalSinceNow]) cancelled:cancelled];

	if (locked) [_target unlockFocus];
	[periodicTimer release];
	[pool release];
	
	/* 結果をOgreTextFindThreadCenterに送る */
	[self sendResult:[NSNumber numberWithInt:matches]];
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" end -highlight: of OgreTextFindThread");
#endif
}

/* キャンセル (two-phase termination) */
- (void)cancel:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -cancel: of OgreTextFindThread");
#endif
	_cancelled = YES;
}

/* 完了したことをシートに表示する */
- (void)showDone:(double)progression count:(int)count time:(NSTimeInterval)processTime cancelled:(BOOL)cancelled
{
	/* コマンド文字列を得る */
	NSString	*finishedMessage = nil, *finishedMessagePlural = nil,
				*cancelledMessage = nil, *cancelledMessagePlural = nil, 
				*notFoundMessage, *cancelledNotFoundMessage;
	
	notFoundMessage				= OgreTextFinderLocalizedString(@"Not found. (%.3fsec)");
	cancelledNotFoundMessage	= OgreTextFinderLocalizedString(@"Not found. (canceled, %.3fsec)");
	
	if (_command == OgreFindAllThread) {
		finishedMessage			= OgreTextFinderLocalizedString(@"%d string found. (%.3fsec)");
		finishedMessagePlural   = OgreTextFinderLocalizedString(@"%d strings found. (%.3fsec)");
		cancelledMessage		= OgreTextFinderLocalizedString(@"%d string found. (canceled, %.3fsec)");
		cancelledMessagePlural  = OgreTextFinderLocalizedString(@"%d strings found. (canceled, %.3fsec)");
	} else if (_command == OgreReplaceAllThread) {
		finishedMessage			= OgreTextFinderLocalizedString(@"%d string replaced. (%.3fsec)");
		finishedMessagePlural   = OgreTextFinderLocalizedString(@"%d strings replaced. (%.3fsec)");
		cancelledMessage		= OgreTextFinderLocalizedString(@"%d string replaced. (canceled, %.3fsec)");
		cancelledMessagePlural  = OgreTextFinderLocalizedString(@"%d strings replaced. (canceled, %.3fsec)");
	} else if (_command == OgreHighlightThread) {
		finishedMessage			= OgreTextFinderLocalizedString(@"%d string highlighted. (%.3fsec)");
		finishedMessagePlural   = OgreTextFinderLocalizedString(@"%d strings highlighted. (%.3fsec)");
		cancelledMessage		= OgreTextFinderLocalizedString(@"%d string highlighted. (canceled, %.3fsec)");
		cancelledMessagePlural  = OgreTextFinderLocalizedString(@"%d strings highlighted. (canceled, %.3fsec)");
	}
	
	if (cancelled) {
		if (count == 0) {
			NSBeep();
			[(OgreTextFindProgressSheet*)_progressSheet done:0.0 
				message:[NSString stringWithFormat:cancelledNotFoundMessage, 
				processTime + 0.0005 /* 四捨五入 */]];
		} else {
			[(OgreTextFindProgressSheet*)_progressSheet done:progression 
				message:[NSString stringWithFormat:((count > 1)? cancelledMessagePlural : cancelledMessage), 
				count, 
				processTime + 0.0005 /* 四捨五入 */]];
		}
	} else {
		if (count == 0) {
			NSBeep();
			[(OgreTextFindProgressSheet*)_progressSheet done:0.0 
				message:[NSString stringWithFormat:notFoundMessage, 
				processTime + 0.0005 /* 四捨五入 */]];
		} else {
			[(OgreTextFindProgressSheet*)_progressSheet done:1.0 
				message:[NSString stringWithFormat:((count > 1)? finishedMessagePlural : finishedMessage), 
				count, 
				processTime + 0.0005 /* 四捨五入 */]];
		}
	}
}

/* 完了 */
- (void)sendResult:(id)result
{
	[_threadCenter putResult:result command:_command target:_target progressSheet:_progressSheet];
}

@end
