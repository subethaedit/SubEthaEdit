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
    int I_pageCount;
    NSTextStorage *I_textStorage;
    NSLayoutManager *I_layoutManager;
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
        float contributorNameWidth;
        float contributorAIMWidth;
        float contributorEmailWidth;
        float visitorNameWidth;
        float visitorAIMWidth;
        float visitorEmailWidth;
        float emailAIMLabelWidth;
        float contributorWidth;
        float visitorWidth;
    } I_measures;
    
    int I_visitorIndex;
    int I_contributorIndex;
    int I_visitorCount;
    int I_contributorCount;
    
    int I_pagesWithLegend;
    int I_pagesWithFullLegend;
}

- (void)setHeaderFormatString:(NSString *)aString;
- (NSString *)headerFormatString;
- (void)setHeaderAttributes:(NSDictionary *)aHeaderAttributes;
- (NSDictionary *)headerAttributes;
- (id)initWithFrame:(NSRect)frame document:(PlainTextDocument *)aDocument;

@end
