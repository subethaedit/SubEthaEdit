//
//  SEERecentDocumentListItem.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 03.03.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEEDocumentListItemProtocol.h"

@interface SEERecentDocumentListItem : NSObject <SEEDocumentListItem>

@property (nonatomic, strong) NSURL *fileURL;

@end
