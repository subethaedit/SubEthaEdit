//
//  TCMMMStatusProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMStatusProfile.h"
#import "TCMMMUser.h"


@implementation TCMMMStatusProfile

- (void)sendMyself:(TCMMMUser *)aUser {
    NSString *string=[aUser description];
    [[self channel] sendMSGMessageWithPayload:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage {
    if ([aMessage isMSG]) {
        NSString *string=[NSString stringWithData:[aMessage payload] encoding:NSUTF8StringEncoding];
        NSLog(@"got remote user: %@",string);
        // ACK
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
        [[self channel] sendMessage:[message autorelease]];
    }
}

@end
