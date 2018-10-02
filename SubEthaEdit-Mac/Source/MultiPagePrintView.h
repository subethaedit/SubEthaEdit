//
//  MultiPagePrintView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.08.04.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PlainTextDocument.h"


@interface MultiPagePrintView : NSView {
    NSTextStorage *I_textStorage;
    NSLayoutManager *I_layoutManager;
    NSInteger I_pageCount;
    NSSize I_pageSize;
    NSSize I_textContainerSize;
    NSPoint I_textContainerOrigin;
    PlainTextDocument *I_document;
    NSTextView *I_headerTextView;
    NSString *I_headerFormatString;
    NSDictionary *I_headerAttributes;
    NSMutableArray *I_contributorArray,
                   *I_visitorArray;
    NSFont *I_baseFont;
    NSMutableDictionary *I_styleCacheDictionary;
    
    struct {
        CGFloat contributorNameWidth;
        CGFloat contributorAIMWidth;
        CGFloat contributorEmailWidth;
        CGFloat visitorNameWidth;
        CGFloat visitorAIMWidth;
        CGFloat visitorEmailWidth;
        CGFloat emailAIMLabelWidth;
        CGFloat contributorWidth;
        CGFloat visitorWidth;
    } I_measures;
    
    NSInteger I_visitorIndex;
    NSInteger I_contributorIndex;
    NSInteger I_visitorCount;
    NSInteger I_contributorCount;
    
    NSInteger I_pagesWithLegend;
    NSInteger I_pagesWithFullLegend;
}

- (void)setHeaderFormatString:(NSString *)aString;
- (NSString *)headerFormatString;
- (void)setHeaderAttributes:(NSDictionary *)aHeaderAttributes;
- (NSDictionary *)headerAttributes;
- (id)initWithFrame:(NSRect)frame document:(PlainTextDocument *)aDocument;

@end
