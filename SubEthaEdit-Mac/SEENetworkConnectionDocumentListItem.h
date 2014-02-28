//
//  SEENetworkConnectionRepresentation.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 26.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEEDocumentListItemProtocol.h"

@class SEEConnection, TCMMMUser;

@interface SEENetworkConnectionDocumentListItem : NSObject <SEEDocumentListItem>
@property (nonatomic, weak) SEEConnection *connection; // also overrides user
@property (nonatomic, weak) TCMMMUser *user;
@end
