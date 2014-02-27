//
//  SEENetworkBrowser.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEENetworkBrowserItem.h"

@interface SEENetworkBrowser : NSWindowController <NSTableViewDelegate>
@property (nonatomic, strong) NSMutableArray *availableItems;
@property (nonatomic, assign) BOOL shouldCloseWhenOpeningDocument;

- (NSInteger)runModal;

@end
