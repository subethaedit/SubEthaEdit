//
//  ServerConnectionWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 26.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "ServerConnectionWindowController.h"


@implementation ServerConnectionWindowController

- (id)initWithMMUser:(TCMMMUser *)aUser {
    if ((self=[super init])) {
        _user = [aUser retain];
        _BEEPSession = [[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[aUser userID]];
    }
    return self;
}

- (NSString *)serverAddress {
    [NSString stringWithAddressData: [_BEEPSession peerAddressData]];
}

- (NSString *)windowNibName {
    return @"ServerConnection";
}

@end
