//
//  SEENetworkConnectionRepresentationListItem.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 26.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEEDocumentListItemProtocol.h"

@class SEEConnection, TCMMMUser;

@interface SEENetworkConnectionRepresentationListItem : NSObject <SEEDocumentListItem>
@property (nonatomic, readonly, assign) BOOL showsDisconnect;
@property (nonatomic, strong) SEEConnection *connection; // also overrides user
@property (nonatomic, strong) TCMMMUser *user;
@property (nonatomic, strong) NSString *subline;
- (IBAction)disconnect:(id)sender;


- (void)updateSubline;
@end
