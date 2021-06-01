//  LayoutManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.

#import "LayoutManager.h"
#import "PlainTextDocument.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMSession.h"
#import "GeneralPreferences.h"
#import "FoldableTextStorage.h"
#import "SelectionOperation.h"
#import "SEETextView.h"
#import "PlainTextEditor.h"

enum {
    u_false=0,
    u_00ac, // NOT sign ( nice NL symbol ) ¬
    u_00b6, // pilcrow sign ¶
    u_2014, // em dash —
    u_2023, // TRIANGULAR BULLET (nice tab variant) ‣
    u_2024, // one dot leader ․
    u_2038, // bottom caret ‸
    u_204b, // reverse pilcrow ⁋
    u_2319, // turned not sign ⌙
    u_240d, // SYMBOL FOR CARRIAGE RETURN ␍
    u_2192, // rightwards arrow →
    u_21ab, // leftwards arrow with loop ↫
    u_21cb, // LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON ⇋
	u_25a1, // WHITE SQUARE □
    u_2761, // CURVED STEM PARAGRAPH SIGN ORNAMENT ❡
    u_fffd, // REPLACEMENT CHARACTER �
    u_00ac_red,
    u_00b6_red,
    u_2014_red,
    u_204b_red,
    u_21ab_red,
    u_2319_red,
    u_240d_red,
    u_2761_red
};

static NSString *S_specialGlyphs[u_2761_red+1];

@interface SEELineHeightTypesetter : NSATSTypesetter
@end

@implementation SEELineHeightTypesetter
- (void)willSetLineFragmentRect:(NSRect *)lineFragmentRect forGlyphRange:(NSRange)glyphRange
        usedRect:(NSRect *)usedRect baselineOffset:(CGFloat *)baselineOffset {
    NSParagraphStyle *style = [self.layoutManager.textStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
    if (style) {
        CGFloat lineHeightMulitple = style.lineHeightMultiple;
        if (lineHeightMulitple > 0) {
            // adjust baselineoffset
            CGFloat additionalBaselineOffset = ((*lineFragmentRect).size.height / lineHeightMulitple) * (lineHeightMulitple - 1.0) / 2.0;
            //        NSLog(@"would have adjusted: %f %f -> %f %@", _lineHeightMultiplier, additionalBaselineOffset, *baselineOffset, NSStringFromRect(*lineFragmentRect));
            *baselineOffset = *baselineOffset - additionalBaselineOffset;
        }
    }
}
@end

@interface LayoutManager ()
@end

@implementation LayoutManager

+ (void)initialize {
	if (self == [LayoutManager class]) {
        S_specialGlyphs[u_00ac]     = @"\u00ac";
        S_specialGlyphs[u_00ac_red] = @"\u00ac";
		S_specialGlyphs[u_00b6]     = @"\u00b6";
		S_specialGlyphs[u_00b6_red] = @"\u00b6";
		S_specialGlyphs[u_2014]     = @"\u2014";
		S_specialGlyphs[u_2014_red] = @"\u2014";
        S_specialGlyphs[u_2023]     = @"\u2023";
		S_specialGlyphs[u_2024]     = @"\u2024";
		S_specialGlyphs[u_2038]     = @"\u2038";
		S_specialGlyphs[u_204b]     = @"\u204b";
		S_specialGlyphs[u_204b_red] = @"\u204b";
		S_specialGlyphs[u_2192]     = @"\u2192";
		S_specialGlyphs[u_21ab]     = @"\u21ab";
		S_specialGlyphs[u_21ab_red] = @"\u21ab";
		S_specialGlyphs[u_21cb]     = @"\u21cb";
        S_specialGlyphs[u_2319]     = @"\u2319";
        S_specialGlyphs[u_2319_red] = @"\u2319";
        S_specialGlyphs[u_240d]     = @"\u240d";
        S_specialGlyphs[u_240d_red] = @"\u240d";
		S_specialGlyphs[u_2761]     = @"\u2761";
		S_specialGlyphs[u_2761_red] = @"\u2761";
		S_specialGlyphs[u_fffd]     = @"\ufffd";
        S_specialGlyphs[u_25a1]     = @"\u25a1";
	}
}

- (instancetype)init {
    if ((self=[super init])) {
        _showsChangeMarks = NO;
        I_invisiblesTextStorage =   [NSTextStorage new];
        I_invisiblesLayoutManager = [NSLayoutManager new];
        [I_invisiblesLayoutManager addTextContainer:[NSTextContainer new]];
        [I_invisiblesTextStorage addLayoutManager:I_invisiblesLayoutManager];
    
		[self setInvisibleCharacterColor:[NSColor grayColor]];
		
        [self setTypesetter:[SEELineHeightTypesetter new]];
        
        NSMutableString *string = [I_invisiblesTextStorage mutableString];
        [string appendString:@"0"]; // just for offset
        int i=0;
        for (i=1;i<=u_2761_red;i++) {
            [string appendString:S_specialGlyphs[i]];
        }
    }
    return self;
}

- (void)drawBorderedMarksWithColor:(NSColor *)aColor atRects:(NSRectArray)aRectArray rectCount:(NSUInteger)rectCount {

    if (rectCount == 0) return;
    NSBezierPath *markPath = [NSBezierPath new];
    NSRect topRect = aRectArray[0];
    float left;
    float x;
    float y;
    unsigned i = 0;
    if ((rectCount > 1) && topRect.origin.x != aRectArray[1].origin.x) {
        if (topRect.origin.x >= aRectArray[1].origin.x + aRectArray[1].size.width) {
            [markPath appendBezierPathWithRect:NSMakeRect(topRect.origin.x+1, topRect.origin.y, topRect.size.width-1, topRect.size.height-1)];
            x = aRectArray[1].origin.x + 1;
            y = aRectArray[1].origin.y;
            [markPath moveToPoint:NSMakePoint(x, y)];
            i = 1;
            left = aRectArray[1].origin.x + 1;
        } else {
            left = aRectArray[1].origin.x + 1;
            x = left;
            y = topRect.origin.y + topRect.size.height;
            [markPath moveToPoint:NSMakePoint(x, y)];
            x = topRect.origin.x + 1;
            [markPath lineToPoint:NSMakePoint(x, y)];
            y = topRect.origin.y;
            [markPath lineToPoint:NSMakePoint(x, y)];
        }
    } else {
        left = topRect.origin.x + 1;
        x = topRect.origin.x + 1;
        y = topRect.origin.y;
        [markPath moveToPoint:NSMakePoint(x, y)];
    }

    for (; i < rectCount; i++) {
        NSRect rect = aRectArray[i];


        x = rect.origin.x + rect.size.width;

        float nextX = (i < rectCount)?aRectArray[i+1].origin.x + aRectArray[i+1].size.width:left;

        [markPath lineToPoint:NSMakePoint(x, y)];
        if (x < nextX && (i != 0)) {
            y = rect.origin.y + rect.size.height;
            [markPath lineToPoint:NSMakePoint(x, y)];
        } else {
            y = rect.origin.y + rect.size.height - 1;
            [markPath lineToPoint:NSMakePoint(x, y)];
        }
    }

    x = left;
    [markPath lineToPoint:NSMakePoint(x, y)];

    [markPath closePath];

    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:-0.5 yBy:0.5];
    [markPath transformUsingAffineTransform: transform];

    //[markPath addClip];

    [aColor set];
    [markPath fill];

    NSColor *borderColor = [aColor shadowWithLevel:0.3];
    [borderColor set];
    [markPath stroke];
}


- (void)setShowsChangeMarks:(BOOL)showsChangeMarks {
    if (showsChangeMarks != _showsChangeMarks) {
        _showsChangeMarks = !!showsChangeMarks;
        FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
        NSRange wholeRange=NSMakeRange(0,[textStorage length]);
        NSRange searchRange;
        unsigned position=wholeRange.location;
        while (position < NSMaxRange(wholeRange)) {
            NSString *userID=[textStorage attribute:ChangedByUserIDAttributeName 
                                atIndex:position longestEffectiveRange:&searchRange inRange:wholeRange];
            if (userID) {
                [self invalidateLayoutForCharacterRange:searchRange actualCharacterRange:NULL];
            }
            position=NSMaxRange(searchRange);
        }
    }
}

- (void)setShowsInvisibles:(BOOL)showsInvisibles {
    if (showsInvisibles != _showsInvisibles) {
        _showsInvisibles = !!showsInvisibles;
        [self invalidateLayout];
    }
}

- (void)setShowsInconsistentIndentation:(BOOL)showsInconsistentIndentation {
    if (showsInconsistentIndentation != _showsInconsistentIndentation) {
        _showsInconsistentIndentation = !!showsInconsistentIndentation;
        [self invalidateLayout];
    }
}

-(void)setUsesTabs:(BOOL)usesTabs {
    if (usesTabs != _usesTabs) {
        _usesTabs = !!usesTabs;
        [self invalidateLayout];
    }
}

- (void)setTabWidth:(int)tabWidth {
    if (tabWidth != _tabWidth) {
        _tabWidth = tabWidth;
        [self invalidateLayout];
    }
}

- (void)invalidateLayout {
    [self invalidateLayoutForCharacterRange:NSMakeRange(0,[[self textStorage] length]) actualCharacterRange:NULL];
}

- (void)invalidateLayoutForCharacterRange:(NSRange)charRange actualCharacterRange:(NSRangePointer)actualCharRange {
    [super invalidateLayoutForCharacterRange:charRange actualCharacterRange:actualCharRange];
}

- (void)invalidateDisplayForCharacterRange:(NSRange)charRange {
    [super invalidateDisplayForCharacterRange:charRange];
}

// - (void)textStorage:(NSTextStorage *)aTextStorage edited:(NSUInteger)mask range:(NSRange)newCharRange changeInLength:(NSInteger)delta invalidatedRange:(NSRange)invalidatedCharRange {
// 	NSLog(@"%s %@ %d %@",__FUNCTION__,NSStringFromRange(newCharRange),delta,NSStringFromRange(invalidatedCharRange));
// 	[super textStorage:aTextStorage edited:mask range:newCharRange changeInLength:delta invalidatedRange:invalidatedCharRange];
// }


- (void)drawBackgroundForGlyphRange:(NSRange)aGlyphRange atPoint:(NSPoint)anOrigin {
    NSTextContainer *container = [self textContainerForGlyphAtIndex:aGlyphRange.location effectiveRange:nil];
    NSRange charRange = [self characterRangeForGlyphRange:aGlyphRange actualGlyphRange:nil];
    NSColor *backgroundColor = [[container textView] backgroundColor];
    NSPoint containerOrigin = [[container textView] textContainerOrigin];
	NSTextStorage *textStorage = [self textStorage];
	NSString *textStorageString=[textStorage string];
    if (_showsChangeMarks) {
        NSUInteger position = charRange.location;
        NSRange attributeRange;
        while (position < NSMaxRange(charRange)) {
            NSString *userID=[textStorage attribute:ChangedByUserIDAttributeName atIndex:position longestEffectiveRange:&attributeRange inRange:charRange];
            if (userID) {
                NSColor *changeColor=[[[TCMMMUserManager sharedInstance] userForUserID:userID] changeColor];
                NSColor *userBackgroundColor=[backgroundColor blendedColorWithFraction:
                                    [[NSUserDefaults standardUserDefaults] floatForKey:ChangesSaturationPreferenceKey]/100.
                                 ofColor:changeColor];
                [userBackgroundColor set];
                
                NSUInteger startIndex, lineEndIndex, contentsEndIndex;
                NSUInteger innerPosition = attributeRange.location;
                while (innerPosition < NSMaxRange(attributeRange)) {
                    [textStorageString getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(innerPosition,0)];
                    innerPosition=lineEndIndex;
                    if (startIndex<attributeRange.location) startIndex=attributeRange.location;
                    if (contentsEndIndex>NSMaxRange(attributeRange)) contentsEndIndex=NSMaxRange(attributeRange);
                    NSUInteger rectCount;
                    NSRectArray rectArray = [self rectArrayForCharacterRange:NSMakeRange(startIndex,contentsEndIndex-startIndex) withinSelectedCharacterRange:NSMakeRange(NSNotFound,0) inTextContainer:container rectCount:&rectCount];
                    if (!NSEqualPoints(containerOrigin,NSZeroPoint)) {
                        unsigned rectIndex = rectCount;
                        while (rectIndex--) {
                            rectArray[rectIndex]=NSOffsetRect(rectArray[rectIndex],containerOrigin.x,containerOrigin.y);
                        }
                    }
                    NSRectFillList(rectArray,rectCount);
                }
            }
            position=NSMaxRange(attributeRange);
        }
    }

    // selections
    PlainTextDocument *document = (PlainTextDocument *)[[[[container textView] window] windowController] document];
    TCMMMSession *session=[document session];
    NSString *sessionID=[session sessionID];
    NSDictionary *sessionParticipants=[session participants];
    NSEnumerator *participants = [[sessionParticipants objectForKey:TCMMMSessionReadWriteGroupName] objectEnumerator];
    TCMMMUser *user = nil;
//    float saturation=[[[NSUserDefaults standardUserDefaults] objectForKey:SelectionSaturationPreferenceKey] floatValue];
	FoldableTextStorage *ts = (FoldableTextStorage *)[self textStorage];
    while ((user = [participants nextObject])) {
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            NSRange selectionRange = NSIntersectionRange(charRange, [ts foldedRangeForFullRange:[selectionOperation selectedRange]]);
            if (selectionRange.length !=0) {
                NSColor *changeColor=[user changeColor];
                NSColor *selectionColor=[backgroundColor blendedColorWithFraction:
                                    [[NSUserDefaults standardUserDefaults] floatForKey:SelectionSaturationPreferenceKey]/100.
                                 ofColor:changeColor];
                NSUInteger rectCount;
                NSRectArray selectionRectArray = [self rectArrayForCharacterRange:selectionRange withinSelectedCharacterRange:selectionRange inTextContainer:container rectCount:&rectCount];
				
				// transform the selection rects by the textcontainerorigin
				for (NSUInteger index = 0; index < rectCount; index++) {
					selectionRectArray[index].origin.x += containerOrigin.x;
					selectionRectArray[index].origin.y += containerOrigin.y;
				}
				
                [self drawBorderedMarksWithColor:selectionColor atRects:selectionRectArray rectCount:rectCount];
            }
        }
    }

	// search scope if any
	PlainTextEditor *editor = [[container textView] isKindOfClass:[SEETextView class]] ?
		[(SEETextView *)[container textView] editor] :
		nil;
	NSValue *searchScopeValue = editor.searchScopeValue;
	BOOL shouldShowSearchScope = [(PlainTextWindowController *)editor.textView.window.windowController isShowingFindAndReplaceInterface];
	if (searchScopeValue && shouldShowSearchScope) {
        NSUInteger position = charRange.location;
        NSRange attributeRange;
        while (position < NSMaxRange(charRange)) {
            id foundSearchScopeValue = [textStorage attribute:SEESearchScopeAttributeName atIndex:position longestEffectiveRange:&attributeRange inRange:charRange];
            if (foundSearchScopeValue && [foundSearchScopeValue containsObject:searchScopeValue]) {
                NSColor *searchScopeColor = [NSColor searchScopeBaseColor];
                NSColor *searchScopeBackgroundColor = [backgroundColor blendedColorWithFraction:30./100.
																			   ofColor:searchScopeColor];
                [searchScopeBackgroundColor set];
                
                NSUInteger startIndex, lineEndIndex, contentsEndIndex;
                NSUInteger innerPosition = attributeRange.location;
                while (innerPosition < NSMaxRange(attributeRange)) {
                    [textStorageString getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange(innerPosition,0)];
                    innerPosition=lineEndIndex;
                    if (startIndex<attributeRange.location) startIndex=attributeRange.location;
                    if (contentsEndIndex>NSMaxRange(attributeRange)) contentsEndIndex=NSMaxRange(attributeRange);
                    NSUInteger rectCount;
                    NSRectArray rectArray = [self rectArrayForCharacterRange:NSMakeRange(startIndex,contentsEndIndex-startIndex) withinSelectedCharacterRange:NSMakeRange(NSNotFound,0) inTextContainer:container rectCount:&rectCount];
                    if (!NSEqualPoints(containerOrigin,NSZeroPoint)) {
                        unsigned rectIndex = rectCount;
                        while (rectIndex--) {
                            rectArray[rectIndex]=NSOffsetRect(rectArray[rectIndex],containerOrigin.x,containerOrigin.y);
                        }
                    }
                    NSRectFillList(rectArray,rectCount);
                }
            }
            position=NSMaxRange(attributeRange);
		}
	}

    [super drawBackgroundForGlyphRange:aGlyphRange atPoint:anOrigin];
}

- (void)fillBackgroundRectArray:(const NSRect *)rectArray count:(NSUInteger)rectCount forCharacterRange:(NSRange)charRange color:(NSColor *)color {
	NSColor *fillColor = color;
	BOOL wasModified = NO;
	if ([color.colorSpaceName isEqualToString:NSNamedColorSpace]) {
		if ([color.colorNameComponent isEqual:@"secondarySelectedControlColor"]) { // inactive selection color
			fillColor = _inactiveSelectionColor;
			[fillColor setFill];
			wasModified = YES;
		}
	}
	[super fillBackgroundRectArray:rectArray count:rectCount forCharacterRange:charRange color:fillColor];
	if (wasModified) {
		[color set];
		// steht alles in den headern - frag nicht
	}
}

#define CHARBUFFERSIZE 200

- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)containerOrigin {
    FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
    BOOL hasMixedLineEndings = [textStorage hasMixedLineEndings];
    LineEnding    lineEnding = [textStorage lineEnding];
    if ([self showsInvisibles] || hasMixedLineEndings || self.showsInconsistentIndentation) {
        NSRect lineFragmentRect = NSZeroRect; //gets initialized lazily
        NSMutableDictionary *attributes;
        // figure out what invisibles to draw
        NSRange charRange = [self characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
        
        NSString *characters = [[self textStorage] string];
        NSUInteger start;
        [characters getLineStart:&start end:nil contentsEnd:nil forRange:charRange];
        int tabWidth = self.tabWidth;
        if (tabWidth < 0) {
            tabWidth = 0;
        }
        NSUInteger lookahead = MIN(1, MIN(CHARBUFFERSIZE - 1, tabWidth));
        
        NSUInteger i;
        unichar previousChar = 0;
        unichar charBuffer[CHARBUFFERSIZE];
        BOOL withinIndentation = YES;
        while (charRange.length>0) {
            NSUInteger bufSize = MIN(charRange.length, CHARBUFFERSIZE);
            NSUInteger loopLength = MIN(charRange.length,CHARBUFFERSIZE - lookahead);
            [characters getCharacters:charBuffer
                                range:NSMakeRange(charRange.location,bufSize)];
            
            for (i=0;i<loopLength;i++) {
                unichar c = charBuffer[i];
                unichar next_c = (i+1 < bufSize) ? charBuffer[i+1] : 0;
                int draw = u_false;
                
                
                withinIndentation = (withinIndentation ||
                                     previousChar == '\r' ||
                                     previousChar == '\n' ||
                                     previousChar == 0x0a ||
                                     previousChar == 0x2028 ||
                                     previousChar == 0x2029) && (c == ' ' || c == '\t');
                
                
                if ([self showsInvisibles]) {
                    if (c == ' ') {		// "real" space
                        draw = u_2024; // one dot leader 0x00b7; // "middle dot" 0x22c5; // "Dot centered"
                    } else if (c == '\t') {	// "correct" indentation
//                        draw = u_2192; // "Arrow right"
                        draw = u_2023; // triangle right
                    } else if (c == 0x21e4 || c == 0x21e5) {	// not "correct" indentation (leftward tab, rightward tab)
//                        draw = u_2192; // "Arrow right"
                        draw = u_2023; // triangle right
                    } else if (c == '\r') {	// mac line feed
//                        draw = u_204b; // "reversed Pilcrow"
                        draw = u_2319;
                    } else if (c == 0x0a) {	// unix line feed
//                        if (previousChar == '\r') {
//                            draw = u_2014; // m-dash
//                        } else {
//                            draw = u_00b6; // "Pilcrow sign"
                            draw = u_00ac; // not
//                        }
                    } else if (c == 0x2028) { // unicode line separator
                        draw = u_2761;
                    } else if (c == 0x2029) { // unicode paragraph separator
                        draw = u_21ab;
                    } else if (c == 0x00a0) { // nbsp
                        draw = u_2038;
                    } else if (c == 0x0c) {	// page break
                        draw = u_21cb; // leftwards harpoon over rightwards harpoon
                    } else if ( c == 0x3000 ) {  // JPN full width spaces
						draw = u_25a1;
                    } else if (c < 0x20 || (0x007f <= c && c <= 0x009f) || [[NSCharacterSet illegalCharacterSet] characterIsMember: c]) {	// some other mystery control character
                        draw = u_fffd; // replacement character for controls that don't belong there
                    } else {
                        NSRange glyphRange = [self glyphRangeForCharacterRange:NSMakeRange(charRange.location+i,1) actualCharacterRange:NULL];
                        if (glyphRange.length == 0) {
                            // something that doesn't show up as a glpyh
                            draw = u_fffd; // replacement character
                        }
                    }
                }
                if (hasMixedLineEndings) {
                    if (c == '\r' && ((lineEnding != LineEndingCR && next_c!='\n')|| (next_c=='\n' && lineEnding!=LineEndingCRLF)) ) {	// mac line feed
//                        draw = u_204b_red; // "reversed Pilcrow"
                        draw = u_2319_red;
                    } else if (c == 0x0a) {	// unix line feed
                        if (previousChar == '\r') {
                            if (lineEnding != LineEndingCRLF) {
//                                draw = u_2014_red; // m-dash
                                draw = u_00ac_red;
                            }
                        } else if (lineEnding != LineEndingLF){
//                            draw = u_00b6_red; // "Pilcrow sign"
                            draw = u_00ac_red; // not red
                        }
                    } else if (c == 0x2028 && lineEnding != LineEndingUnicodeLineSeparator) { // unicode line separator
                        draw = u_2761_red;
                    } else if (c == 0x2029 && lineEnding != LineEndingUnicodeParagraphSeparator) { // unicode paragraph separator
                        draw = u_21ab_red;
                    }
                }
                
                if (self.showsInconsistentIndentation) {
                    if (self.usesTabs && withinIndentation) {
                        // Using spaces to indent by less than a tab with is legitimate
                        // Therefor 'withinIndentation' will be set to NO if at least one
                        // of the next tabWidth characters is neither a space nor a tab
                        if (c == ' ' && previousChar != ' ') {
                            for (NSUInteger index = i; index < tabWidth + i && index < bufSize; index++) {
                                if (charBuffer[index] != ' ' && charBuffer[index] != '\t') {
                                    withinIndentation = NO;
                                }
                            }
                        }
                        
                        if (withinIndentation && c == ' ') {
                            draw = u_2024;
                        }
                    } else {
                        // Spaces are used for indentation
                        if (c == '\t') {
//                            draw = u_2192;
                            draw = u_2023; // triangle right
                        }
                    }
                }
                
                
                
                if (draw!=u_false) {
                    // where is that one?
                    if (!attributes) {
                        attributes = [[[self textStorage] attributesAtIndex:i effectiveRange:NULL] mutableCopy];
                        if ( _invisibleCharacterColor ) {
							[attributes setObject:_invisibleCharacterColor forKey:NSForegroundColorAttributeName];
                        }
                        [I_invisiblesTextStorage addAttributes:attributes range:NSMakeRange(0,[I_invisiblesTextStorage length])];
                        [attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
                        [I_invisiblesTextStorage addAttributes:attributes range:NSMakeRange([I_invisiblesTextStorage length]-9,9)];
                        lineFragmentRect = [I_invisiblesLayoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL];
                    }
                    NSPoint layoutLocation = [I_invisiblesLayoutManager locationForGlyphAtIndex:draw];
                    layoutLocation.x += lineFragmentRect.origin.x;
                    layoutLocation.y += lineFragmentRect.origin.y;

                    NSRange glyphRange = [self glyphRangeForCharacterRange:NSMakeRange(charRange.location+i,1) actualCharacterRange:NULL];
                    NSPoint where = [self locationForGlyphAtIndex:glyphRange.location];
                    NSRect fragment = [self lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:NULL];
                    where.x += containerOrigin.x + fragment.origin.x;
                    where.y += containerOrigin.y + fragment.origin.y;
                    [I_invisiblesLayoutManager drawGlyphsForGlyphRange:NSMakeRange(draw, 1) atPoint:NSMakePoint(where.x-layoutLocation.x,where.y-layoutLocation.y)];
                }
                previousChar=c;
            }
            charRange.location += loopLength;
            charRange.length   -= loopLength;
        }
        attributes = nil;
    }

    // draw the real glyphs
    [super drawGlyphsForGlyphRange: glyphRange atPoint: containerOrigin];
}

- (void)removeTemporaryAttributes:(id)anObjectEnumerable forCharacterRange:(NSRange)aRange {
    NSEnumerator *attributeNames=[anObjectEnumerable objectEnumerator];
    id attributeName=nil;
    while ((attributeName=[attributeNames nextObject])) {
        [self removeTemporaryAttribute:attributeName
                     forCharacterRange:aRange];
    }
}

- (void)forceTextViewGeometryUpdate {
	if (self.textStorage.length > 0) {
		NSRange lastCharRange = NSMakeRange(self.textStorage.length-1, 1);
		[self.textStorage edited:NSTextStorageEditedAttributes range:lastCharRange changeInLength:0];
	}
}

@end
