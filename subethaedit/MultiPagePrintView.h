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
}

- (void)setHeaderFormatString:(NSString *)aString;
- (NSString *)headerFormatString;
- (void)setHeaderAttributes:(NSDictionary *)aHeaderAttributes;
- (NSDictionary *)headerAttributes;
- (id)initWithFrame:(NSRect)frame document:(PlainTextDocument *)aDocument;

@end
