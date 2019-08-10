//  SEEToggleRecentDocumentListItem.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06.03.14.

#import <Cocoa/Cocoa.h>
#import "SEEDocumentListItemProtocol.h"

@interface SEEToggleRecentDocumentListItem : NSObject <SEEDocumentListItem>

@property (nonatomic) BOOL showRecentDocuments;

- (IBAction)openRecentDocumentForItem:(id)sender; // used by the context menu

@end
