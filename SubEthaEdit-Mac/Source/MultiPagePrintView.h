//  MultiPagePrintView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.08.04.

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
    __weak NSTextView *I_headerTextView;
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

@property (nonatomic, copy) NSString *headerFormatString;
@property (nonatomic, copy) NSDictionary *headerAttributes;

- (instancetype)initWithFrame:(NSRect)frame document:(PlainTextDocument *)aDocument;

@end
