//
//  SEENetworkBrowser.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SEENetworkBrowser : NSWindowController <NSCollectionViewDelegate>
@property (nonatomic, strong) NSMutableArray *availableDocumentSessions;
@property (nonatomic, assign) BOOL shouldCloseWhenOpeningDocument;

- (NSInteger)runModal;

@end
