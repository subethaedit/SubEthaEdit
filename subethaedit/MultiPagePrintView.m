//
//  MultiPagePrintView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.08.04.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "MultiPagePrintView.h"


@implementation MultiPagePrintView

- (id)initWithFrame:(NSRect)frame document:(PlainTextDocument *)aDocument {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        I_textStorage=[[NSTextStorage alloc] initWithAttributedString:[aDocument textStorage]];
        I_document=[aDocument retain];
        I_layoutManager=[NSLayoutManager new];
        [I_textStorage addLayoutManager:I_layoutManager];
    }
    return self;
}

- (void)dealloc {
    [I_textStorage removeLayoutManager:I_layoutManager];
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
    [I_document release];
    [I_layoutManager release];
    [I_textStorage release];
    [super dealloc];
}

- (void)beginPageInRect:(NSRect)aRect atPlacement:(NSPoint)location {
    NSLog(@"- (void)beginPageInRect:%@ atPlacement:%@",NSStringFromRect(aRect),NSStringFromPoint(location));
    [super beginPageInRect:aRect atPlacement:NSMakePoint(0.,0.)];
}

- (NSString *)printJobTitle {
    return [I_document displayName];
}


- (void)drawRect:(NSRect)rect {
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];

    // Drawing code here.
    NSLog(@"drawRect: %@", NSStringFromRect(rect));
    // move header to current location
    NSRect headerFrame=[I_headerTextView frame];
    headerFrame.origin.y=rect.origin.y+[printInfo topMargin];
    [I_headerTextView setFrame:headerFrame];

    // replace the page text
    NSTextStorage *textStorage=[I_headerTextView textStorage];
    [textStorage replaceCharactersInRange:[[textStorage string] lineRangeForRange:NSMakeRange(0,1)] 
                 withString:[NSString stringWithFormat:@"%@\t%@\n",[self printJobTitle],
            [NSString stringWithFormat:NSLocalizedString(@"PrintPage %d of %d",@"Page Information in Print Header"),
                    (int)(rect.origin.y/I_pageSize.height)+1,I_pageCount]] ];
    

    [[NSColor blackColor] set];
    NSPoint basePoint=I_textContainerOrigin;
    basePoint.y+=rect.origin.y-4;
    [NSBezierPath strokeLineFromPoint:NSMakePoint(basePoint.x,basePoint.y) toPoint:NSMakePoint(basePoint.x+I_textContainerSize.width,basePoint.y)];

//    [[NSColor redColor] set];
//    NSRectFill(rect);
//    [[NSColor greenColor] set];
//    NSFrameRect(NSMakeRect(rect.origin.x+[printInfo leftMargin],rect.origin.y+[printInfo topMargin],I_textContainerSize.width,I_textContainerSize.height));
}

- (NSRect)rectForPage:(int)page {
    NSRect result=NSMakeRect(0.,I_pageSize.height*(page-1),
                             I_pageSize.width,I_pageSize.height);
    NSLog(@"rectForPage %d: %@",page,NSStringFromRect(result));
    return result;
}

// Return the number of pages available for printing
- (BOOL)knowsPageRange:(NSRangePointer)range {
    // happy paginating:
    I_pageCount=0;
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    
    I_pageSize=[printInfo paperSize];
    I_textContainerSize=I_pageSize;
    NSLog(@"left:%f, top:%f, right:%f, bottom:%f",[printInfo leftMargin],[printInfo topMargin],[printInfo rightMargin],[printInfo bottomMargin]);
    I_textContainerSize.width  -= [printInfo leftMargin] + [printInfo rightMargin];
    I_textContainerSize.height -= [printInfo topMargin] + [printInfo bottomMargin];

    I_textContainerOrigin.x=[printInfo leftMargin];
    I_textContainerOrigin.y=[printInfo topMargin];

    I_headerTextView =[[NSTextView alloc] initWithFrame:NSMakeRect([printInfo leftMargin],[printInfo rightMargin],I_textContainerSize.width,I_textContainerSize.height)];
    [[I_headerTextView textContainer] setLineFragmentPadding:0.];
    [I_headerTextView setTextContainerInset:NSMakeSize(0.,0.)];
    
    NSTextStorage *textStorage=[I_headerTextView textStorage];
    [textStorage replaceCharactersInRange:NSMakeRange(0,0) withString:
        [NSString stringWithFormat:@"%@\t%@\n%@",[self printJobTitle],
            NSLocalizedString(@"PrintPage %d of %d",@"Page Information in Print Header"),
            [NSString stringWithFormat:NSLocalizedString(@"PrintDate: %@",@"Date Information in Print Header"),[NSCalendarDate date]]] ];


    NSFont *headerFont=[NSFont fontWithName:@"Helvetica" size:10.];
    if (!headerFont) headerFont=[NSFont systemFontOfSize:10.];
    NSMutableDictionary *headerAttributes=[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor],NSForegroundColorAttributeName,headerFont,NSFontAttributeName,nil];
    NSMutableParagraphStyle *paragraphStyle=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setTabStops:[NSArray array]];
    NSTextTab *tab=[[NSTextTab alloc] initWithType:NSRightTabStopType location:I_textContainerSize.width-1.];
    [paragraphStyle addTabStop:tab];
    [tab release];
    [headerAttributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [textStorage addAttributes:headerAttributes range:NSMakeRange(0,[textStorage length])];
    [paragraphStyle release];
    
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
    
    NSRange lastGlyphRange=NSMakeRange(NSNotFound,0);
    if ([I_textStorage length]>0) {
        if (YES) {
            NSMutableParagraphStyle *paragraphStyle=[[I_textStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL] mutableCopy];
            [paragraphStyle setHeadIndent:30.];
            [paragraphStyle setFirstLineHeadIndent:0.];
            [paragraphStyle setTabStops:[NSArray array]];
            NSTextTab *tab=[[NSTextTab alloc] initWithType:NSRightTabStopType location:25.];
            [paragraphStyle addTabStop:tab];
            [tab release];
            tab=[[NSTextTab alloc] initWithType:NSLeftTabStopType location:30.];
            [paragraphStyle addTabStop:tab];
            [tab release];
            NSLog(@"TabStops: %@",[[paragraphStyle tabStops] description]);
            NSMutableDictionary *attributes=[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,[NSFont userFixedPitchFontOfSize:8.],NSFontAttributeName,nil];
            
            [I_textStorage beginEditing];
            int lineNumber=1;
            NSString *lineNumberString=nil;
            NSRange lineRange=NSMakeRange(0,0);
            do {
                lineRange.location=NSMaxRange(lineRange);
                lineRange.length=0;
                lineNumberString=[[NSString alloc] initWithFormat:@"\t%d:\t",lineNumber];
                [I_textStorage replaceCharactersInRange:lineRange withString:lineNumberString];
                lineRange.length=[lineNumberString length]-2;
                lineRange.location=lineRange.location+1;
                [I_textStorage addAttributes:attributes range:lineRange];
                lineRange=[[I_textStorage string] lineRangeForRange:lineRange];
                [lineNumberString release];
                lineNumber++;
            } while (NSMaxRange(lineRange)<[I_textStorage length]);
            [I_textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[I_textStorage length])];
            [paragraphStyle release];
            [I_textStorage endEditing];
        }
        lastGlyphRange=[I_layoutManager glyphRangeForCharacterRange:NSMakeRange([I_textStorage length]-1,1) actualCharacterRange:0];
    }
    BOOL overflew=NO;
    [self setFrame:NSMakeRect(0.,0.,I_pageSize.width,0.)];
    NSPoint origin=I_textContainerOrigin;
    do {
        overflew=NO;
        NSTextContainer *textContainer=[[NSTextContainer alloc] initWithContainerSize:I_textContainerSize];
        NSTextView *textview= [[NSTextView alloc] initWithFrame:NSMakeRect(origin.x,origin.y,
                                                                I_textContainerSize.width,I_textContainerSize.height)
                                                  textContainer:textContainer];
        [textview setHorizontallyResizable:NO];
        [textview setVerticallyResizable:NO];
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

- (BOOL)isFlipped {
    return YES;
}

@end
