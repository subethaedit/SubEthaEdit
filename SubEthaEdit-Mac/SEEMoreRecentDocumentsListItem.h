//
//  SEEMoreRecentDocumentsListItem.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 22.05.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEEDocumentListItemProtocol.h"

@interface SEEMoreRecentDocumentsListItem : NSObject <SEEDocumentListItem>

@property (nonatomic, weak) NSMenu *moreMenu;

@end
