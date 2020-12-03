//  SEERecentDocumentListItem.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 03.03.14.

#import <Cocoa/Cocoa.h>
#import "SEEDocumentListItemProtocol.h"

@interface SEERecentDocumentListItem : NSObject <SEEDocumentListItem>

@property (nonatomic, strong) NSURL *fileURL;

- (IBAction)showDocumentInFinder:(id)sender;

@end
