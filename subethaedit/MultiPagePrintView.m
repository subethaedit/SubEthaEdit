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
    // Drawing code here.
    NSLog(@"drawRect: %@", NSStringFromRect(rect));
//    [[NSColor redColor] set];
//    NSRectFill(rect);
//    [[NSColor greenColor] set];
//    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
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

    
    NSRange lastGlyphRange=NSMakeRange(NSNotFound,0);
    if ([I_textStorage length]>0) {
        if (YES) {
            NSMutableParagraphStyle *paragraphStyle=[[I_textStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL] mutableCopy];
            [paragraphStyle setHeadIndent:40.];
            [paragraphStyle setFirstLineHeadIndent:0.];
            [paragraphStyle setTabStops:[NSArray array]];
            NSTextTab *tab=[[NSTextTab alloc] initWithType:NSRightTabStopType location:35.];
            [paragraphStyle addTabStop:tab];
            [tab release];
            tab=[[NSTextTab alloc] initWithType:NSLeftTabStopType location:40.];
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
    NSPoint origin=NSMakePoint([printInfo leftMargin],[printInfo topMargin]);
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
