/*
 * Name: OgreTextFindResult.m
 * Project: OgreKit
 *
 * Creation Date: Sep 18 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OGRegularExpressionMatch.h>

static const unsigned   OgreTextFindResultInitialCapacity = 30;

@implementation OgreTextFindResult

- (id)initWithString:(NSString*)text syntax:(OgreSyntax)syntax color:(NSColor*)highlightColor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-initWithString: of OgreTextFindResult");
#endif	
	self = [super init];
	if (self) {
		/* 1行目の範囲を得る */
		_text = [text retain];
		_textLength = [_text length];
		_lineRange = [_text lineRangeForRange:NSMakeRange(0, 0)];
		_searchLineRangeLocation = _lineRange.location + _lineRange.length;
		
		[[highlightColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
			getHue: &_hue 
			saturation: &_saturation 
			brightness: &_brightness 
			alpha: &_alpha];
			
		_simple = (syntax == OgreSimpleMatchingSyntax);
		_lineOfMatchedStrings = [[NSMutableArray alloc] initWithCapacity:OgreTextFindResultInitialCapacity];
		[_lineOfMatchedStrings addObject:[NSNumber numberWithUnsignedInt:0]];
		_matchRangeArray = [[NSMutableArray alloc] initWithCapacity:OgreTextFindResultInitialCapacity];
		[_matchRangeArray addObject:[NSArray arrayWithObject:[NSValue valueWithRange:NSMakeRange(0, 0)]]];
		_count = 0;
		
		_line = 1;
		_cacheAbsoluteLocation = 0;
		
		_maxLeftMargin = -1;			// 無制限
		_maxMatchedStringLength = -1;   // 無制限
	}
	
	return self;
}

- (void)finishToFindInTarget:(id)target
{
	if ([self count] == 0) return;	// マッチしなかった場合
	
	_targetToFindIn = target;
	//targetのあるwindowのcloseを検出する。
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(windowWillClose:) 
		name: NSWindowWillCloseNotification
		object: [_targetToFindIn window]];
	
	//text storageの変更を検出する。
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(textStorageWillProcessEditing:) 
		name: NSTextStorageWillProcessEditingNotification
		object: [_targetToFindIn textStorage]];
	
	// 絶対位置のキャッシュ
	_cacheIndex = 0;
	_cacheAbsoluteLocation = 0;
	
	// 更新用絶対位置のキャッシュ
	_updateCacheIndex = 0;
	_updateCacheAbsoluteLocation = 0;
}

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-dealloc of OgreTextFindResult");
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_lineOfMatchedStrings release];
	[_matchRangeArray release];
	[_text release];
}

/* addMatch */
- (void)addMatch:(OGRegularExpressionMatch*)match
{
	NSRange			range = [match rangeOfMatchedString];
	unsigned		newAbsoluteLocation = range.location;
	
	_count++;
	
	// マッチの相対位置
	// 0番目の部分文字列は前のマッチとの相対位置
	// 1番目以降の部分文字列は0番目の部分文字列との相対位置
	int				i, n = [match count];
	NSMutableArray	*rangeArray = [NSMutableArray arrayWithCapacity:n];
	range = [match rangeOfSubstringAtIndex:0];
	[rangeArray addObject:[NSValue valueWithRange:NSMakeRange(range.location - _cacheAbsoluteLocation, range.length)]];
	for (i = 1; i < n; i++) {
		range = [match rangeOfSubstringAtIndex:i];
		[rangeArray addObject:[NSValue valueWithRange:NSMakeRange(range.location - newAbsoluteLocation, range.length)]];
	}
	_cacheAbsoluteLocation = newAbsoluteLocation;
	
	// マッチした文字列が何行目にあるのか探す
	while (newAbsoluteLocation >= _searchLineRangeLocation) {
		_lineRange = [_text lineRangeForRange:NSMakeRange(_searchLineRangeLocation, 0)];
		_searchLineRangeLocation = _lineRange.location + _lineRange.length;
		_line++;
		if (_searchLineRangeLocation == _textLength) {
			if (_textLength == 0) _line--;
			break;
		}
	}
	
	// マッチした文字列の先頭が_line行目にある場合
	[_lineOfMatchedStrings addObject:[NSNumber numberWithUnsignedInt:_line]];
	[_matchRangeArray addObject:rangeArray];
}

- (NSNumber*)lineOfMatchedStringAtIndex:(unsigned)index
{
	return [_lineOfMatchedStrings objectAtIndex:(index + 1)];   // 0番目はダミー
}

- (NSAttributedString*)matchedStringAtIndex:(unsigned)index
{
	if (_targetToFindIn == nil) return [[[NSAttributedString alloc] initWithString:OgreTextFinderLocalizedString(@"Missing.") attributes:[NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName]] autorelease];
	
	NSArray						*matchArray = [_matchRangeArray objectAtIndex:(index + 1)];   // 0番目はダミー
	int							i, n = [matchArray count];
	NSRange						lineRange, intersectionRange, matchRange, range;
	NSMutableAttributedString	*lineString;
	NSString					*text = [_targetToFindIn string];
	unsigned					matchLocation = 0, delta = 0;
	
	// キャッシュを更新
	if (index > _cacheIndex) {
		while (_cacheIndex != index) {
			_cacheIndex++;
			range = [[[_matchRangeArray objectAtIndex:_cacheIndex] objectAtIndex:0] rangeValue];
			_cacheAbsoluteLocation += range.location;
		}
	} else if (index < _cacheIndex) {
		while (_cacheIndex != index) {
			range = [[[_matchRangeArray objectAtIndex:_cacheIndex] objectAtIndex:0] rangeValue];
			_cacheAbsoluteLocation -= range.location;
			_cacheIndex--;
		}
	}
	
	// index番目にマッチした文字列の先頭のある行の範囲・内容
	range = [[matchArray objectAtIndex:0] rangeValue];
	matchRange = NSMakeRange(range.location + _cacheAbsoluteLocation, range.length);
	if ([text length] < (matchRange.location + matchRange.length)) {
		// matchRangeの範囲の文字列が存在しない場合
		return [[[NSAttributedString alloc] initWithString:OgreTextFinderLocalizedString(@"Missing.") attributes:[NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName]] autorelease];
	}
	lineRange = [text lineRangeForRange:NSMakeRange(matchRange.location, 0)];

	lineString = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
	if ((_maxLeftMargin >= 0) && (matchRange.location > lineRange.location + _maxLeftMargin)) {
		// MatchedStringの左側の文字数を制限する
		delta = matchRange.location - (lineRange.location + _maxLeftMargin);
		lineRange.location += delta;
		lineRange.length   -= delta;
		[lineString appendAttributedString:[[[NSAttributedString alloc] 
			initWithString:@"..." 
			attributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName]] autorelease]];
	}
	if ((_maxMatchedStringLength >= 0) && (lineRange.length > _maxMatchedStringLength)) {
		// 全文字数を制限する
		lineRange.length = _maxMatchedStringLength;
		[lineString appendAttributedString:[[[NSAttributedString alloc] 
			initWithString:[text substringWithRange:lineRange]] autorelease]];
		[lineString appendAttributedString:[[[NSAttributedString alloc] 
			initWithString:@"..." 
			attributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName]] autorelease]];
	} else {
		[lineString appendAttributedString:[[[NSAttributedString alloc] 
			initWithString:[text substringWithRange:lineRange]] autorelease]];
	}
	
	// 色付け
	[lineString beginEditing];
	for(i = 0; i < n; i++) {
		range = [[matchArray objectAtIndex:i] rangeValue];
		if (i == 0) {
			// 0番目の部分文字列は前のマッチとの相対位置
			matchLocation = range.location + _cacheAbsoluteLocation;
			matchRange = NSMakeRange(matchLocation, range.length);
		} else {
			// 1番目以降の部分文字列は0番目の部分文字列との相対位置
			matchRange = NSMakeRange(range.location + matchLocation, range.length);
		}
		intersectionRange = NSIntersectionRange(lineRange, matchRange);
		double	dummy;
		
		if (intersectionRange.length > 0) {
			[lineString setAttributes:
				[NSDictionary dictionaryWithObject:
					[NSColor colorWithCalibratedHue: 
						modf(_hue + ((_simple)? ((float)(i-1)) : ((float)i)) / ((_simple)? ((float)(n-1)) : ((float)n)), &dummy) 
						saturation: _saturation 
						brightness: _brightness 
						alpha: _alpha] forKey:NSBackgroundColorAttributeName] 
				range:NSMakeRange(intersectionRange.location - lineRange.location + ((delta == 0)? 0 : 3), intersectionRange.length)];
		}
	}
	[lineString endEditing];

	return lineString;
}

- (BOOL)showMatchedStringAtIndex:(unsigned)index
{
	if (_targetToFindIn == nil) return NO;
	
	[[_targetToFindIn window] makeKeyAndOrderFront:self];
	return [self selectMatchedStringAtIndex:index];
}

- (BOOL)selectMatchedStringAtIndex:(unsigned)index
{
	if (_targetToFindIn == nil) return NO;
	
	NSRange	range, matchRange;
	// キャッシュを更新
	if (index > _cacheIndex) {
		while (_cacheIndex != index) {
			_cacheIndex++;
			range = [[[_matchRangeArray objectAtIndex:_cacheIndex] objectAtIndex:0] rangeValue];
			_cacheAbsoluteLocation += range.location;
		}
	} else if (index < _cacheIndex) {
		while (_cacheIndex != index) {
			range = [[[_matchRangeArray objectAtIndex:_cacheIndex] objectAtIndex:0] rangeValue];
			_cacheAbsoluteLocation -= range.location;
			_cacheIndex--;
		}
	}
	
	// index番目にマッチした文字列の先頭のある行の範囲・内容
	range = [[[_matchRangeArray objectAtIndex:(index + 1)] objectAtIndex:0] rangeValue];
	matchRange = NSMakeRange(range.location + _cacheAbsoluteLocation, range.length);
	if ([[_targetToFindIn string] length] < (matchRange.location + matchRange.length)) return NO;
	
	[_targetToFindIn setSelectedRange:matchRange];
	[_targetToFindIn scrollRangeToVisible:matchRange];
	
	return YES;
}

- (unsigned)count
{
	return _count;
}

// [_targetToFindIn window] will close
- (void)windowWillClose:(NSNotification*)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-windowWillClose: of OgreTextFindResult");
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_targetToFindIn = nil;
}

- (NSString*)description
{
	return [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
			_lineOfMatchedStrings, 
			_matchRangeArray, 
			[NSArray arrayWithObjects:[NSNumber numberWithFloat:_hue], 
				[NSNumber numberWithFloat:_saturation], 
				[NSNumber numberWithFloat:_brightness], 
				[NSNumber numberWithFloat:_alpha], nil], 
			[NSNumber numberWithBool:_simple], 
			[NSNumber numberWithUnsignedInt:_line], 
			[NSNumber numberWithUnsignedInt:_count], 
		nil] forKeys:[NSArray arrayWithObjects:
			@"Match Line", 
			@"Match Range", 
			@"Highlight Color", 
			@"Simple", 
			@"Line", 
			@"Count", 
		nil]] description];
}

- (void)textStorageWillProcessEditing:(NSNotification*)aNotification
{
	NSTextStorage   *textStorage = [aNotification object];
	NSRange			editedRange = [textStorage editedRange];
	int				changeInLength = [textStorage changeInLength];
	
	if ([textStorage editedMask] & NSTextStorageEditedCharacters) {
		// 文字の変更の場合
		/*NSLog(@"w: (%d, %d) -> (%d, %d)", 
			editedRange.location, editedRange.length - changeInLength, 
			editedRange.location, editedRange.length);*/
		// 表示の更新
		[self updateOldRange:NSMakeRange(editedRange.location, editedRange.length - changeInLength) newRange:NSMakeRange(editedRange.location, editedRange.length)];
	}
}

// 表示を更新
- (void)updateOldRange:(NSRange)oldRange newRange:(NSRange)newRange
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-updateOldRange: of OgreTextFindResult");
#endif
	// Notation
	//  (a b) : changed range
	//  [c d] : range of matched string
	// Possible configurations of these ranges "(), []"
	//  0. [ ] ( )
	//  1. ( ) [ ]
	//  2. ( [ ) ]
	//  3. ( [ ] )
	//  4. [ ( ) ]
	//  5. [ ( ] )
	
	NSMutableArray *target;
	NSRange		range, updatedRange;
	unsigned	a, b, c, d, b2;
	unsigned	i, j, 
				count = [self count], 
				numberOfSubranges = [[_matchRangeArray objectAtIndex:1] count];
	
	a = oldRange.location;
	b = NSMaxRange(oldRange);
	b2 = NSMaxRange(newRange);
	
	// 更新用絶対位置キャッシュの更新 (影響を受けない("[ ] ( )"となる)最大のindexを求める。)
	range = [[[_matchRangeArray objectAtIndex:_updateCacheIndex] objectAtIndex:0] rangeValue];
	d = _updateCacheAbsoluteLocation + range.length;
	if (a < d) {
		// ( ... ] ... の場合。
		do {
			// 一つ左の[]に行く。
			range = [[[_matchRangeArray objectAtIndex:_updateCacheIndex] objectAtIndex:0] rangeValue];
			_updateCacheAbsoluteLocation -= range.location;
			_updateCacheIndex--;
			range = [[[_matchRangeArray objectAtIndex:_updateCacheIndex] objectAtIndex:0] rangeValue];
			d = _updateCacheAbsoluteLocation + range.length;
		} while (a < d);
	} else if (d < a) {
		// [ ] ( ) の場合
		do {
			if (_updateCacheIndex == count) {
				// これ以上右の[]がない場合
				range.location = 0;		// _updateCacheAbsoluteLocation -= range.location;の相殺項
				_updateCacheIndex++;	// _updateCacheIndex--;の相殺項
				break;
			}
			// 一つ右の[]に行く。
			_updateCacheIndex++;
			range = [[[_matchRangeArray objectAtIndex:_updateCacheIndex] objectAtIndex:0] rangeValue];
			_updateCacheAbsoluteLocation += range.location;
			d = _updateCacheAbsoluteLocation + range.length;
		} while (d < a);
		// 行き過ぎた分戻す。
		_updateCacheAbsoluteLocation -= range.location;
		_updateCacheIndex--;
	}
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"the maximal index of undisturbed matched string: %d", _updateCacheIndex);
#endif
	
	// 表示用絶対位置キャッシュの更新
	if (_updateCacheIndex < _cacheIndex) {
		_cacheIndex = _updateCacheIndex;
		_cacheAbsoluteLocation = _updateCacheAbsoluteLocation;
	}
	
	c = _updateCacheAbsoluteLocation;   // _updateCacheIndex番目の絶対位置
	for (i = _updateCacheIndex + 1; i <= count; i++) {
		target = [_matchRangeArray objectAtIndex:i];
		range = [[target objectAtIndex:0] rangeValue];
		c += range.location;
		d = c + range.length;
		
		if (d <= a) {
			// 0. [ ] ( )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"0. [ ] ( )");
#endif
		} else if ((a <= b) && (b <= c) && (c <= d)) {
			// 1. ( ) [ ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"1. ( ) [ ]");
#endif
			updatedRange = NSMakeRange(range.location + b2 - b, range.length);  // ( ) [ ]
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			break;
		} else if ((c < a) && (a <= b) && (b < d)) {
			// 4. [ ( ) ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"4. [ ( ) ]");
#endif
			updatedRange = NSMakeRange(range.location, range.length + b2 - b);  // [ ( ) ]
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			[self updateSubranges:target 
				count:numberOfSubranges 
				oldRange:oldRange 
				newRange:NSMakeRange(a, b2 - a) 
				origin:c 
				leftAlign:NO];
		} else if ((a <= c) && (c <= d) && (d <= b)) {
			// 3. ( [ ] )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"3. ( [ ] )");
#endif
			updatedRange = NSMakeRange(range.location + b2 - c, 0);		// (   )[]
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			b2 = c;
			// 部分文字列の範囲を更新
			for (j = 1; j < numberOfSubranges; j++) {
				[target replaceObjectAtIndex:j withObject:[NSValue valueWithRange:NSMakeRange(0, 0)]];
			}
		} else if ((a <= c) && (c < b) && (b < d)) {
			// 2. ( [ ) ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"2. ( [ ) ]");
#endif
			updatedRange = NSMakeRange(range.location + b2 - c, range.length - (b - c));	// (   )[ ]
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			b2 = c;
			[self updateSubranges:target 
				count:numberOfSubranges 
				oldRange:oldRange 
				newRange:NSMakeRange(a, b2 - a) 
				origin:c 
				leftAlign:NO];
		} else if ((c < a) && (a < d) && (d <= b)) {
			// 5. [ ( ] )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"5. [ ( ] )");
#endif
			updatedRange = NSMakeRange(range.location, range.length - (d - a));		// [ ](   )
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			[self updateSubranges:target 
				count:numberOfSubranges 
				oldRange:oldRange 
				newRange:NSMakeRange(a, b2 - a) 
				origin:c 
				leftAlign:YES];
		} else {
			// その他
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"others");
#endif
		}
	}
	
	[(id <OgreTextFindResultDelegateProtocol>)_delegate didUpdateTextFindResult:self];
}

- (void)updateSubranges:(NSMutableArray*)target count:(unsigned)numberOfSubranges oldRange:(NSRange)oldRange newRange:(NSRange)newRange origin:(unsigned)origin leftAlign:(BOOL)leftAlign
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-updateSubranges: of OgreTextFindResult");
#endif
	unsigned	i, a, b, b2, c, d;
	NSRange		range, updatedRange;
	a = oldRange.location;
	b = NSMaxRange(oldRange);
	b2 = NSMaxRange(newRange);
	
	for (i = 1; i < numberOfSubranges; i++) {
		range = [[target objectAtIndex:i] rangeValue];
		c = origin + range.location;
		d = c + range.length;
		
		if (d <= a) {
			// 0. [ ] ( )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"0. [ ] ( )");
#endif
		} else if ((a <= b) && (b <= c) && (c <= d)) {
			// 1. ( ) [ ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"1. ( ) [ ]");
#endif
			updatedRange = NSMakeRange(range.location + b2 - b, range.length);
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else if ((c < a) && (a <= b) && (b < d)) {
			// 4. [ ( ) ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"4. [ ( ) ]");
#endif
			updatedRange = NSMakeRange(range.location, range.length + b2 - b);
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else if ((a <= c) && (c <= d) && (d <= b)) {
			// 3. ( [ ] )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"3. ( [ ] )");
#endif
			if (leftAlign) {
				updatedRange = NSMakeRange(range.location - (c - a), 0);	// []( )
			} else {
				updatedRange = NSMakeRange(range.location + b2 - c, 0);		// ( )[]
			}
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else if ((a <= c) && (c < b) && (b < d)) {
			// 2. ( [ ) ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"2. ( [ ) ]");
#endif
			updatedRange = NSMakeRange(range.location + b2 - c, range.length - (b - c));
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else if ((c < a) && (a < d) && (d <= b)) {
			// 5. [ ( ] )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"5. [ ( ] )");
#endif
			updatedRange = NSMakeRange(range.location, range.length - (d - a));
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else {
			// その他
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"others");
#endif
		}
	}
}

// -matchedStringAtIndex:にて、マッチした文字列の左側の最大文字数 (-1: 無制限)
- (void)setMaximumLeftMargin:(int)leftMargin
{
	_maxLeftMargin = leftMargin;
}

// -matchedStringAtIndex:の返す最大文字数 (-1: 無制限)
- (void)setMaximumMatchedStringLength:(int)aLength
{
	_maxMatchedStringLength = aLength;
}


// delegate
- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;
}

@end
