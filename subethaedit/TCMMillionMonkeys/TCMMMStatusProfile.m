//
//  TCMMMStatusProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMStatusProfile.h"
#import "TCMMMUser.h"
#import "TCMBencodingUtilities.h"


@implementation TCMMMStatusProfile

- (void)sendMyself:(TCMMMUser *)aUser {
    NSMutableData *data=[NSMutableData dataWithBytes:"USRFUL" length:6];
    [data appendData:[aUser userBencoded]];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage {
    if ([aMessage isMSG]) {
        NSString *string=[NSString stringWithData:[aMessage payload] encoding:NSUTF8StringEncoding];
        NSLog(@"got remote user: %@",string);
        NSLog(@"result is: %@",[TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]) description]);
        // ACK
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
        [[self channel] sendMessage:[message autorelease]];
    }
}

@end
