//  SEEMoreRecentDocumentsListItem.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 22.05.14.

#import <Foundation/Foundation.h>
#import "SEEDocumentListItemProtocol.h"

@interface SEEMoreRecentDocumentsListItem : NSObject <SEEDocumentListItem>

@property (nonatomic, weak) NSMenu *moreMenu;

@end
