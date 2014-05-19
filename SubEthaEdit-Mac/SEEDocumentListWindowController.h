//
//  SEEDocumentListWindowController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEEDocumentListItemProtocol.h"

@interface SEEDocumentListWindowController : NSWindowController <NSTableViewDelegate, NSMenuDelegate>
@property (nonatomic, strong) NSMutableArray *availableItems;
@property (nonatomic, assign) BOOL shouldCloseWhenOpeningDocument;

- (NSInteger)runModal;

- (void)reloadAllDocumentDocumentListItems;

@end
