//
//  SEENetworkDocumentRepresentation.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEENetworkBrowserItem.h"

@class TCMMMSession, TCMMMUser;

@interface SEENetworkDocumentRepresentation : NSObject <SEENetworkBrowserItem>
@property (nonatomic, weak) TCMMMSession *documentSession;
@end
