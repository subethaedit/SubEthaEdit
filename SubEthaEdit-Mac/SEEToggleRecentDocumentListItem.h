//
//  SEEToggleRecentDocumentListItem.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06.03.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEEDocumentListItemProtocol.h"

@interface SEEToggleRecentDocumentListItem : NSObject <SEEDocumentListItem>

@property (nonatomic, assign) BOOL showRecentDocuments;

- (IBAction)openRecentDocumentForItem:(id)sender; // used by the context menu

@end
