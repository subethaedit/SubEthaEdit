//  MultiPagePrintView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.08.04.

#import <Cocoa/Cocoa.h>
#import "PlainTextDocument.h"


@interface MultiPagePrintView : NSView 

@property (nonatomic, copy) NSString *headerFormatString;
@property (nonatomic, copy) NSDictionary *headerAttributes;

- (instancetype)initWithFrame:(NSRect)frame document:(PlainTextDocument *)aDocument;

@end
