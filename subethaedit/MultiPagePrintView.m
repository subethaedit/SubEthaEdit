//
//  MultiPagePrintView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.08.04.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "MultiPagePrintView.h"
#import "PrintTypesetter.h"
#import "PrintTextView.h"
#import "SyntaxHighlighter.h"
#import "DocumentMode.h"
#import "PlainTextDocument.h"
#import "TCMMMUserManager.h"
#import "TCMMMUserSeeAdditions.h"
#import "PlainTextDocument.h"
#import "GeneralPreferences.h"

@implementation MultiPagePrintView

- (id)initWithFrame:(NSRect)frame document:(PlainTextDocument *)aDocument {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        I_textStorage=[[aDocument textStorage] retain];
        I_document=[aDocument retain];
    }
    return self;
}

- (void)dealloc {
    [I_textStorage removeLayoutManager:I_layoutManager];
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
    [I_document release];
    [I_layoutManager release];
    [I_textStorage release];
    [I_headerAttributes release];
    [I_headerFormatString release];
    [super dealloc];
}

#pragma mark -
#pragma mark ### Accessors ###

- (void)setHeaderFormatString:(NSString *)aString {
    [I_headerFormatString autorelease];
    I_headerFormatString=[aString copy];
}

- (NSString *)headerFormatString {
    return I_headerFormatString;
}
- (void)setHeaderAttributes:(NSDictionary *)aHeaderAttributes {
    [I_headerAttributes autorelease];
    I_headerAttributes=[aHeaderAttributes copy];
}

- (NSDictionary *)headerAttributes {
    return I_headerAttributes;
}


- (NSString *)printJobTitle {
    return [I_document displayName];
}

#pragma mark -

// Return the number of pages available for printing
- (BOOL)knowsPageRange:(NSRangePointer)range {

    // happy paginating:
    I_pageCount=0;
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    NSDictionary *printInfoDictionary = [printInfo dictionary];
    NSLog(@"PrintInfo: %@",[[[[printInfo dictionary] mutableCopy] autorelease] description]);

    BOOL copyFirst=([[printInfoDictionary objectForKey:@"SEEColorizeSyntax"] boolValue] != [I_document highlightsSyntax]);
    
    int i=0;
    for (i=0;i<2;i++) {
        if (copyFirst) {
            I_textStorage = [[NSTextStorage alloc] initWithAttributedString:[I_textStorage autorelease]];
        } else {
            if ([[printInfoDictionary objectForKey:@"SEEHighlightSyntax"] boolValue]) {
                SyntaxHighlighter *highlighter=[[I_document documentMode] syntaxHighlighter];
                    if (highlighter)
                        while (![highlighter colorizeDirtyRanges:I_textStorage ofDocument:I_document]);
            }
        }
        copyFirst=!copyFirst;
    }

    if (![[printInfoDictionary objectForKey:@"SEEHighlightSyntax"] boolValue]) {
        [I_textStorage addAttribute:NSForegroundColorAttributeName value:[I_document documentForegroundColor] range:NSMakeRange(0,[I_textStorage length])];
        [I_textStorage addAttribute:NSFontAttributeName value:[I_document fontWithTrait:0] 
            range:NSMakeRange(0,[I_textStorage length])];
    }

    float lineNumberSize=8.;

    if (![[printInfoDictionary objectForKey:@"SEEUseCustomFont"] boolValue]) {
        if ([[printInfoDictionary objectForKey:@"SEEResizeDocumentFont"] boolValue]) {
            NSFontManager *fontManager=[NSFontManager sharedFontManager];
            float newSize=[[printInfoDictionary objectForKey:@"SEEResizeDocumentFontTo"] floatValue];
            if (newSize<=0.) newSize=4.;
            if (lineNumberSize > newSize) lineNumberSize=newSize;
            NSRange wholeRange=NSMakeRange(0,[I_textStorage length]);
            if (NSMaxRange(wholeRange)>0) {
                NSRange foundRange=NSMakeRange(0,0);
                while (NSMaxRange(wholeRange)>NSMaxRange(foundRange)) {
                    NSFont *font=[I_textStorage attribute:NSFontAttributeName atIndex:NSMaxRange(foundRange) longestEffectiveRange:&foundRange inRange:wholeRange];
                    font=[fontManager convertFont:font toSize:newSize];
                    [I_textStorage addAttribute:NSFontAttributeName value:font range:foundRange];
                }
            }
        }
    } else {
        NSFontManager *fontManager=[NSFontManager sharedFontManager];
        NSDictionary *fontAttributes=[printInfoDictionary objectForKey:@"SEEFontAttributes"];
        NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
        if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
        if (lineNumberSize > [newFont pointSize]) lineNumberSize=[newFont pointSize];
        NSRange wholeRange=NSMakeRange(0,[I_textStorage length]);
        if (NSMaxRange(wholeRange)>0) {
            NSRange foundRange=NSMakeRange(0,0);
            while (NSMaxRange(wholeRange)>NSMaxRange(foundRange)) {
                NSFont *font=[I_textStorage attribute:NSFontAttributeName atIndex:NSMaxRange(foundRange) longestEffectiveRange:&foundRange inRange:wholeRange];
                font=[fontManager convertFont:newFont toHaveTrait:[fontManager traitsOfFont:font]];
                [I_textStorage addAttribute:NSFontAttributeName value:font range:foundRange];
            }
        }
    }

    I_layoutManager=[NSLayoutManager new];
    [I_textStorage addLayoutManager:I_layoutManager];
    NSTypesetter *typesetter = [PrintTypesetter new];
    [I_layoutManager setTypesetter:typesetter];
    [typesetter release];
    
    I_pageSize=[printInfo paperSize];
    I_textContainerSize=I_pageSize;
    // NSLog(@"left:%f, top:%f, right:%f, bottom:%f",[printInfo leftMargin],[printInfo topMargin],[printInfo rightMargin],[printInfo bottomMargin]);
    I_textContainerSize.width  -= [printInfo leftMargin] + [printInfo rightMargin];
    I_textContainerSize.height -= [printInfo topMargin] + [printInfo bottomMargin];

    I_textContainerOrigin.x=[printInfo leftMargin];
    I_textContainerOrigin.y=[printInfo topMargin];

    
    NSUserDefaults *standardUserDefaults=[NSUserDefaults standardUserDefaults];

    if ([[printInfoDictionary objectForKey:@"SEEPageHeader"] boolValue]) {
        I_headerTextView =[[NSTextView alloc] initWithFrame:NSMakeRect([printInfo leftMargin],[printInfo rightMargin],I_textContainerSize.width,I_textContainerSize.height)];
        [[I_headerTextView textContainer] setLineFragmentPadding:0.];
        [I_headerTextView setTextContainerInset:NSMakeSize(0.,0.)];

        NSFont *headerFont=[NSFont fontWithName:@"Helvetica" size:10.];
        if (!headerFont) headerFont=[NSFont systemFontOfSize:10.];
        NSMutableDictionary *headerAttributes=[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor],NSForegroundColorAttributeName,headerFont,NSFontAttributeName,nil];
        NSMutableParagraphStyle *paragraphStyle=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setTabStops:[NSArray array]];
        NSTextTab *tab=[[NSTextTab alloc] initWithType:NSRightTabStopType location:I_textContainerSize.width-1.];
        [paragraphStyle addTabStop:tab];
        [tab release];
        [headerAttributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
        [paragraphStyle release];
        [self setHeaderAttributes:headerAttributes];

        NSString *date=[NSString stringWithFormat:NSLocalizedString(@"PrintDate: %@",@"Date Information in Print Header"),
                    [[NSCalendarDate calendarDate] 
                            descriptionWithCalendarFormat:[standardUserDefaults objectForKey:NSDateFormatString] 
                            locale:(id)standardUserDefaults] ];
        if ([[printInfoDictionary objectForKey:@"SEEPageHeaderFilename"] boolValue] &&
            [[printInfoDictionary objectForKey:@"SEEPageHeaderCurrentDate"] boolValue]) {
            [self setHeaderFormatString:[NSString stringWithFormat:@"%1$@\t%2$@\n%3$@",[self printJobTitle],@"%1$@",date]];
        } else if ([[printInfoDictionary objectForKey:@"SEEPageHeaderFilename"] boolValue]) {
            [self setHeaderFormatString:[NSString stringWithFormat:@"%1$@\t%2$@",[self printJobTitle],@"%1$@"]];
        } else if ([[printInfoDictionary objectForKey:@"SEEPageHeaderCurrentDate"] boolValue]) {
            [self setHeaderFormatString:[NSString stringWithFormat:@"%1$@\t%2$@",date,@"%1$@"]];
        } else {
            [self setHeaderFormatString:@"\t%1$@"];
        }

        NSTextStorage *textStorage=[I_headerTextView textStorage];
        [textStorage replaceCharactersInRange:NSMakeRange(0,0) withString:
            [NSString stringWithFormat:[self headerFormatString],
                NSLocalizedString(@"PrintPage %d of %d",@"Page Information in Print Header")]];
        [textStorage addAttributes:[self headerAttributes] range:NSMakeRange(0,[textStorage length])];

        // determine the space we need
        NSLayoutManager *layoutManager=[I_headerTextView layoutManager];
        NSRect boundingRect=
            [layoutManager boundingRectForGlyphRange:
                [layoutManager glyphRangeForCharacterRange:NSMakeRange(0,[textStorage length]) actualCharacterRange:NULL]
             inTextContainer:[[layoutManager textContainers] objectAtIndex:0]];
        [I_headerTextView setFrameSize:NSMakeSize(I_textContainerSize.width,boundingRect.size.height+4.)];
        I_textContainerOrigin.y   +=boundingRect.size.height+8.;
        I_textContainerSize.height-=boundingRect.size.height+8.;
        
        [self addSubview:I_headerTextView];
    }    
    
    // setup Paragraph Style and add line Numbers
    BOOL lineNumbers=[[printInfoDictionary objectForKey:@"SEELineNumbers"] boolValue];
    
    NSRange lastGlyphRange=NSMakeRange(NSNotFound,0);
    if ([I_textStorage length]>0) {

        NSMutableParagraphStyle *paragraphStyle=[[I_textStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL] mutableCopy];

        [paragraphStyle setTabStops:[NSArray array]];
        float tabStart=0.;
        if (lineNumbers) {
            [paragraphStyle setHeadIndent:30.];
            [paragraphStyle setFirstLineHeadIndent:0.];
            NSTextTab *tab=[[NSTextTab alloc] initWithType:NSRightTabStopType location:25.];
            [paragraphStyle addTabStop:tab];
            [tab release];
            tab=[[NSTextTab alloc] initWithType:NSLeftTabStopType location:30.];
            [paragraphStyle addTabStop:tab];
            [tab release];
            tabStart=30.;
        }
        
        
        // Create correct tabstops for tab users
        NSFont *font=[I_textStorage attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
        float charWidth = [font widthOfString:@" "];
        if (charWidth<=0) {
            charWidth=[font maximumAdvancement].width;
        }
        float tabWidth=charWidth*[I_document tabWidth];
        while (tabStart+tabWidth < I_textContainerSize.width) {
            tabStart+=tabWidth;
            NSTextTab *tab=[[NSTextTab alloc] initWithType:NSLeftTabStopType location:tabStart];
            [paragraphStyle addTabStop:tab];
            [tab release];
        }

        // to provide the space four our annotations if needed
        [paragraphStyle setLineSpacing:12.];


        // NSLog(@"TabStops: %@",[[paragraphStyle tabStops] description]);

        if (lineNumbers) {
            NSMutableDictionary *attributes=[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,[NSFont userFixedPitchFontOfSize:lineNumberSize],NSFontAttributeName,nil];
            
            [I_textStorage beginEditing];
            int lineNumber=1;
            NSString *lineNumberString=nil;
            NSRange lineRange=NSMakeRange(0,0);
            do {
                lineRange.location=NSMaxRange(lineRange);
                lineRange.length=0;
                lineNumberString=[[NSString alloc] initWithFormat:@"\t%d:\t",lineNumber];
                [I_textStorage replaceCharactersInRange:lineRange withString:lineNumberString];
                lineRange.length=[lineNumberString length];
                [I_textStorage setAttributes:attributes range:lineRange];
                lineRange=[[I_textStorage string] lineRangeForRange:lineRange];
                [lineNumberString release];
                lineNumber++;
            } while (NSMaxRange(lineRange)<[I_textStorage length]);
        }
        
        [I_textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[I_textStorage length])];
        [paragraphStyle release];
        [I_textStorage endEditing];

        // prepare for Annotation and Background
        TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
        if ([[printInfoDictionary objectForKey:@"SEEColorizeChangeMarks"] boolValue] ||
            [[printInfoDictionary objectForKey:@"SEEAnnotateChangeMarks"] boolValue]) {
            NSRange foundRange=NSMakeRange(0,0);
            NSRange wholeRange=NSMakeRange(0,[I_textStorage length]);
            while (NSMaxRange(wholeRange)>NSMaxRange(foundRange)) {
                NSString *userID=[I_textStorage attribute:ChangedByUserIDAttributeName atIndex:NSMaxRange(foundRange) longestEffectiveRange:&foundRange inRange:wholeRange];
                if (userID) {
                    if ([[printInfoDictionary objectForKey:@"SEEAnnotateChangeMarks"] boolValue]) {
                        [I_textStorage addAttribute:@"AnnotateID" value:userID range:foundRange];
                    }
                    if ([[printInfoDictionary objectForKey:@"SEEColorizeChangeMarks"] boolValue]) {
                        TCMMMUser *user=[userManager userForUserID:userID];
                        NSColor *changeColor=[user changeColor];
                        NSColor *userBackgroundColor=[[I_document documentBackgroundColor] blendedColorWithFraction:
                                            [standardUserDefaults floatForKey:ChangesSaturationPreferenceKey]/100.
                                         ofColor:changeColor];
                        [I_textStorage addAttribute:@"PrintBackgroundColour" value:userBackgroundColor range:foundRange];
                    }
                }
            }
        }

        if ([[printInfoDictionary objectForKey:@"SEEColorizeWrittenBy"] boolValue] ||
            [[printInfoDictionary objectForKey:@"SEEAnnotateWrittenBy"] boolValue]) {
            NSRange foundRange=NSMakeRange(0,0);
            NSRange wholeRange=NSMakeRange(0,[I_textStorage length]);
            while (NSMaxRange(wholeRange)>NSMaxRange(foundRange)) {
                NSString *userID=[I_textStorage attribute:WrittenByUserIDAttributeName 
                                                atIndex:NSMaxRange(foundRange) 
                                                longestEffectiveRange:&foundRange inRange:wholeRange];
                if (userID) {
                    if ([[printInfoDictionary objectForKey:@"SEEAnnotateWrittenBy"] boolValue]) {
                        [I_textStorage addAttribute:@"AnnotateID" value:userID range:foundRange];
                    }
                    if ([[printInfoDictionary objectForKey:@"SEEColorizeWrittenBy"] boolValue]) {
                        TCMMMUser *user=[userManager userForUserID:userID];
                        NSColor *changeColor=[user changeColor];
                        NSColor *userBackgroundColor=[[I_document documentBackgroundColor] blendedColorWithFraction:
                                            [standardUserDefaults floatForKey:ChangesSaturationPreferenceKey]/100.
                                         ofColor:changeColor];
                        [I_textStorage addAttribute:@"PrintBackgroundColour" value:userBackgroundColor range:foundRange];
                    }
                }
            }
        }

        // ensure last line has a linebreak, for annotations to be typeset correctly
        unsigned startIndex, lineEndIndex, contentsEndIndex;
        [[I_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:NSMakeRange([I_textStorage length]-1,0)];
        if (contentsEndIndex==lineEndIndex) {
            [I_textStorage replaceCharactersInRange:NSMakeRange([I_textStorage length],0) withString:@"\n"];
        }


        lastGlyphRange=[I_layoutManager glyphRangeForCharacterRange:NSMakeRange([I_textStorage length]-1,1) actualCharacterRange:0];
    }

    
    BOOL overflew=NO;
    [self setFrame:NSMakeRect(0.,0.,I_pageSize.width,0.)];
    NSPoint origin=I_textContainerOrigin;
    do {
        BOOL leftPage=I_pageCount%2 && [[printInfoDictionary objectForKey:@"SEEFacingPages"] boolValue];
        overflew=NO;
        NSTextContainer *textContainer=[[NSTextContainer alloc] initWithContainerSize:I_textContainerSize];
        NSTextView *textview= [[PrintTextView alloc] initWithFrame:NSMakeRect(leftPage?[printInfo rightMargin]:origin.x,origin.y,
                                                                I_textContainerSize.width,I_textContainerSize.height)
                                                  textContainer:textContainer];
        [textview setHorizontallyResizable:NO];
        [textview setVerticallyResizable:NO];
        [textview setBackgroundColor:[I_document documentBackgroundColor]];
        [I_layoutManager addTextContainer:textContainer];
        [self addSubview:textview];
        NSRange glyphRange=[I_layoutManager glyphRangeForTextContainer:textContainer];
        if (lastGlyphRange.location!=NSNotFound &&
            NSMaxRange(glyphRange)!=NSMaxRange(lastGlyphRange)) {
            overflew=YES;
        }
        [textContainer release];
        [textview release];
        
        origin.y+=I_pageSize.height;
        I_pageCount+=1;
        NSRect frame=[self frame];
        frame.size.height+=I_pageSize.height;
        [self setFrame:frame];
    } while (overflew);

    range->location = 1;
    range->length = I_pageCount;
    return YES;
}

- (void)beginPageInRect:(NSRect)aRect atPlacement:(NSPoint)location {
    // NSLog(@"- (void)beginPageInRect:%@ atPlacement:%@",NSStringFromRect(aRect),NSStringFromPoint(location));
    [super beginPageInRect:aRect atPlacement:NSMakePoint(0.,0.)];
}

- (void)drawRect:(NSRect)rect {
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    NSDictionary *printInfoDictionary = [printInfo dictionary];


    if ([[printInfoDictionary objectForKey:@"SEEPageHeader"] boolValue]) {
        int currentPage=(int)(rect.origin.y/I_pageSize.height)+1;
        BOOL leftPage=currentPage%2 && [[printInfoDictionary objectForKey:@"SEEFacingPages"] boolValue];

        // Drawing code here.
        // NSLog(@"drawRect: %@", NSStringFromRect(rect));
        // move header to current location
        NSRect headerFrame=[I_headerTextView frame];
        headerFrame.origin.y=rect.origin.y+[printInfo topMargin];
        headerFrame.origin.x=leftPage?[printInfo rightMargin]:[printInfo leftMargin];
        [I_headerTextView setFrame:headerFrame];
    
        // replace the page text
        NSTextStorage *textStorage=[I_headerTextView textStorage];
        [textStorage replaceCharactersInRange:NSMakeRange(0,[textStorage length]) withString:
            [NSString stringWithFormat:[self headerFormatString],
                [NSString stringWithFormat:NSLocalizedString(@"PrintPage %d of %d",@"Page Information in Print Header"),
                            currentPage,I_pageCount]
            ]
        ];
        [textStorage addAttributes:[self headerAttributes] range:NSMakeRange(0,[textStorage length])];

        
    
        [[NSColor blackColor] set];
        NSPoint basePoint=I_textContainerOrigin;
        basePoint.y+=rect.origin.y-4;
        [NSBezierPath strokeLineFromPoint:NSMakePoint(basePoint.x,basePoint.y) toPoint:NSMakePoint(basePoint.x+I_textContainerSize.width,basePoint.y)];
    }

//    [[NSColor redColor] set];
//    NSRectFill(rect);
//    [[NSColor greenColor] set];
//    NSFrameRect(NSMakeRect(rect.origin.x+[printInfo leftMargin],rect.origin.y+[printInfo topMargin],I_textContainerSize.width,I_textContainerSize.height));
}

- (NSRect)rectForPage:(int)page {
    NSRect result=NSMakeRect(0.,I_pageSize.height*(page-1),
                             I_pageSize.width,I_pageSize.height);
    // NSLog(@"rectForPage %d: %@",page,NSStringFromRect(result));
    return result;
}

- (BOOL)isFlipped {
    return YES;
}

@end