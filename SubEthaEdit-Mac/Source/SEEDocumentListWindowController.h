//  SEEDocumentListWindowController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.

#import <Cocoa/Cocoa.h>
#import "SEEDocumentListItemProtocol.h"

@interface SEEDocumentListWindowController : NSWindowController <NSTableViewDelegate, NSMenuDelegate>
@property (nonatomic, strong) NSMutableArray *availableItems;
@property (nonatomic) BOOL shouldCloseWhenOpeningDocument;

- (NSInteger)runModal;

- (void)reloadAllListItems;
// strange place but code reuse - use the my document list item
- (void)writeMyReachabiltyToPasteboard:(NSPasteboard *)aPasteboard;
@end
