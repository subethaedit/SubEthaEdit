//
//  HandshakeProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "HandshakeProfile.h"
#import "TCMBEEPMessage.h"
#import "TCMBEEPChannel.h"

@implementation HandshakeProfile

- (void)shakeHandsWithUserID:(NSString *)aUserID
{
    NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"GRTuserid=%@\001version=2.00\001token=none",aUserID] dataUsingEncoding:NSUTF8StringEncoding]];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"MSG" messageNumber:[[self channel] nextMessageNumber] payload:payload];
    [[self channel] sendMessage:[message autorelease]];
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    // simple message reply model
    if ([aMessage isMSG]) {
       NSLog(@"ShakeHandGreeting was: %@",[NSString stringWithData:[aMessage payload] encoding:NSUTF8StringEncoding]);
        NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"ACK"] dataUsingEncoding:NSUTF8StringEncoding]];
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:payload];
        [[self channel] sendMessage:[message autorelease]];
    } else if ([aMessage isRPY]) {
       NSLog(@"ShakeHandRPY was: %@",[NSString stringWithData:[aMessage payload] encoding:NSUTF8StringEncoding]);
    }
}

@end
