//
//  LayoutManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

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
    u_00b6,
    u_2014,
    u_2024,
    u_2038,
    u_204b,
    u_2192,
    u_21ab,
    u_21cb,
	u_25A1, //WHITE SQUARE, &squ
    u_2761,
    u_fffd,
    u_00b6_red,
    u_2014_red,
    u_204b_red,
    u_21ab_red,
    u_2761_red
};

static NSString *S_specialGlyphs[17];

@implementation LayoutManager

+ (void)initialize {
	if (self == [LayoutManager class]) {
		S_specialGlyphs[u_00b6]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x00b6];
		S_specialGlyphs[u_00b6_red]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x00b6];
		S_specialGlyphs[u_2014]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x2014];
		S_specialGlyphs[u_2014_red]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x2014];
		S_specialGlyphs[u_2024]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x2024];
		S_specialGlyphs[u_2038]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x2038];
		S_specialGlyphs[u_204b]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x204b];
		S_specialGlyphs[u_204b_red]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x204b];
		S_specialGlyphs[u_2192]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x2192];
		S_specialGlyphs[u_21ab]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x21ab];
		S_specialGlyphs[u_21ab_red]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x21ab];
		S_specialGlyphs[u_21cb]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x21cb];
		S_specialGlyphs[u_2761]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x2761];
		S_specialGlyphs[u_2761_red]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x2761];
		S_specialGlyphs[u_fffd]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0xfffd];
	}
	S_specialGlyphs[u_25A1]=[[NSString alloc] initWithFormat:@"%C",(unsigned short)0x25A1]; //WHITE SQUARE, &squ
}

- (id)init {
    if ((self=[super init])) {
        I_flags.showsChangeMarks=NO;
        I_invisiblesTextStorage =   [NSTextStorage new];
        I_invisiblesLayoutManager = [NSLayoutManager new];
        [I_invisiblesLayoutManager addTextContainer:[[NSTextContainer new] autorelease]];
        [I_invisiblesTextStorage addLayoutManager:I_invisiblesLayoutManager];
    
		[self setInvisibleCharacterColor:[NSColor grayColor]];
		
        NSMutableString *string = [I_invisiblesTextStorage mutableString];
        [string appendString:@"0"]; // just for offset
        int i=0;
        for (i=1;i<=u_2761_red;i++) {
            [string appendString:S_specialGlyphs[i]];
        }
    }
    return self;
}

- (void)dealloc {
    [I_invisiblesLayoutManager release];
    [I_invisiblesTextStorage release];
	[I_invisibleCharacterColor release];
	[I_inactiveSelectionColor release];
    [super dealloc];
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
    [markPath release];
}


- (BOOL)showsChangeMarks {
    return I_flags.showsChangeMarks;
}

- (void)setShowsChangeMarks:(BOOL)showsChangeMarks {
    if (showsChangeMarks != I_flags.showsChangeMarks) {
        I_flags.showsChangeMarks=showsChangeMarks;
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

- (BOOL)showsInvisibles {
    return I_flags.showsInvisibles;
}
- (void)setShowsInvisibles:(BOOL)showsInvisibles {
    if (showsInvisibles != I_flags.showsInvisibles) {
        I_flags.showsInvisibles=showsInvisibles;
        [self invalidateLayoutForCharacterRange:NSMakeRange(0,[[self textStorage] length]) actualCharacterRange:NULL];
    }
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
    if (I_flags.showsChangeMarks) {
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
			fillColor = I_inactiveSelectionColor;
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

- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)containerOrigin
{
    FoldableTextStorage *textStorage = (FoldableTextStorage *)[self textStorage];
    BOOL hasMixedLineEndings = [textStorage hasMixedLineEndings];
    LineEnding    lineEnding = [textStorage lineEnding];
    if ([self showsInvisibles] || hasMixedLineEndings) {
        NSRect lineFragmentRect=NSZeroRect; //gets initialized lazily
        NSMutableDictionary *attributes=nil;
        // figure out what invisibles to draw
        NSRange charRange = [self characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
        NSString *characters = [[self textStorage] string];
        unsigned i;
        unichar previousChar=0;
        unichar charBuffer[CHARBUFFERSIZE];
        while (charRange.length>0) {
            int loopLength = MIN(charRange.length,CHARBUFFERSIZE);
            [characters getCharacters:charBuffer range:NSMakeRange(charRange.location,loopLength)];
            for (i=0;i<loopLength;i++) {
                unichar c = charBuffer[i];
                unichar next_c = (i+1 < loopLength)?charBuffer[i+1]:
                    (NSMaxRange(charRange)>charRange.location+loopLength?[characters characterAtIndex:charRange.location+loopLength]:0);
                int draw = u_false;
                if ([self showsInvisibles]) {
                    if (c == ' ') {		// "real" space
                        draw = u_2024; // one dot leader 0x00b7; // "middle dot" 0x22c5; // "Dot centered"
                    } else if (c == '\t') {	// "correct" indentation
                        draw = u_2192; // "Arrow right"
                    } else if (c == 0x21e4 || c == 0x21e5) {	// not "correct" indentation (leftward tab, rightward tab)
                        draw = u_2192; // "Arrow right"
                    } else if (c == '\r') {	// mac line feed
                        draw = u_204b; // "reversed Pilcrow"
                    } else if (c == 0x0a) {	// unix line feed
                        if (previousChar == '\r') {
                            draw = u_2014; // m-dash 
                        } else {
                            draw = u_00b6; // "Pilcrow sign"
                        }
                    } else if (c == 0x2028) { // unicode line separator
                        draw = u_2761;
                    } else if (c == 0x2029) { // unicode paragraph separator
                        draw = u_21ab;
                    } else if (c == 0x00a0) { // nbsp
                        draw = u_2038;
                    } else if (c == 0x0c) {	// page break
                        draw = u_21cb; // leftwards harpoon over rightwards harpoon
                    } else if ( c == 0x3000 ) {  // JPN full width spaces
						draw = u_25A1;
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
                        draw = u_204b_red; // "reversed Pilcrow"
                    } else if (c == 0x0a) {	// unix line feed
                        if (previousChar == '\r') {
                            if (lineEnding != LineEndingCRLF) {
                                draw = u_2014_red; // m-dash 
                            }
                        } else if (lineEnding != LineEndingLF){
                            draw = u_00b6_red; // "Pilcrow sign"
                        }
                    } else if (c == 0x2028 && lineEnding != LineEndingUnicodeLineSeparator) { // unicode line separator
                        draw = u_2761_red;
                    } else if (c == 0x2029 && lineEnding != LineEndingUnicodeParagraphSeparator) { // unicode paragraph separator
                        draw = u_21ab_red;
                    }
                }
                if (draw!=u_false) {
                    // where is that one?
                    if (!attributes) {
                        attributes = [[[self textStorage] attributesAtIndex:i effectiveRange:NULL] mutableCopy];
						if (  I_invisibleCharacterColor != nil )
							[attributes setObject:I_invisibleCharacterColor forKey:NSForegroundColorAttributeName];
                        [I_invisiblesTextStorage addAttributes:attributes range:NSMakeRange(0,[I_invisiblesTextStorage length])];
                        [attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
                        [I_invisiblesTextStorage addAttributes:attributes range:NSMakeRange([I_invisiblesTextStorage length]-6,6)];
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
        if (attributes) {
            [attributes release];
            attributes=nil;
        }
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

- (void)setInvisibleCharacterColor:(NSColor*)aColor
{
	// forcing a redraw is the responsibility of the caller
	
	[I_invisibleCharacterColor autorelease];
	I_invisibleCharacterColor = [aColor retain];
}

- (void)setInactiveSelectionColor:(NSColor *)aColor {
	[I_inactiveSelectionColor autorelease];
	I_inactiveSelectionColor = [aColor retain];
}

- (NSColor *)inactiveSelectionColor {
	return I_inactiveSelectionColor;
}

- (NSColor*)invisibleCharacterColor
{
	return I_invisibleCharacterColor;
}

@end
