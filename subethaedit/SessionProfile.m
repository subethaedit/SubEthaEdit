//
//  SessionProfile.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 09 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SessionProfile.h"
#import "TCMBencodingUtilities.h"


@implementation SessionProfile

- (void)sendJoinRequestForSessionID:(NSString *)aSessionID
{
    NSMutableData *data = [NSMutableData dataWithBytes:"JONJON" length:6];
    [data appendData:TCM_BencodedObject(aSessionID)]; 
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)acceptInvitation
{
    NSMutableData *data = [NSMutableData dataWithBytes:"INVACK" length:6];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:I_lastMessageNumber payload:data];
    [[self channel] sendMessage:[message autorelease]];
}

- (void)acceptJoin
{
    NSMutableData *data = [NSMutableData dataWithBytes:"JONACK" length:6];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:I_lastMessageNumber payload:data];
    [[self channel] sendMessage:[message autorelease]];
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    if ([aMessage isMSG]) {
        I_lastMessageNumber = [aMessage messageNumber];
        if ([[aMessage payload] length] < 6) {
            NSLog(@"Invalid message format. Payload less than 6 bytes.");
            return;
        }
        
        unsigned char *type = (unsigned char *)[[aMessage payload] bytes];
        if (strncmp(type, "JONJON", 6) == 0) {
            NSLog(@"Received join request.");
            NSData *bencodedSessionID = [[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)];
            NSString *sessionID = TCM_BdecodedObjectWithData(bencodedSessionID);
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profile:didReceiveJoinRequestForSessionID:)]) {
                [delegate profile:self didReceiveJoinRequestForSessionID:sessionID];
            }
        } else if (strncmp(type, "INVINV", 6) == 0) {
            NSLog(@"Received invitation.");
        }
    } else if ([aMessage isRPY]) {
        if ([[aMessage payload] length] < 6) {
            NSLog(@"Invalid message format. Payload less than 6 bytes.");
            return;
        }
        
        unsigned char *type = (unsigned char *)[[aMessage payload] bytes];
        if (strncmp(type, "JONACK", 6) == 0) {
            NSLog(@"Received accepted join.");
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profileDidAcceptJoinRequest:)]) {
                [delegate profileDidAcceptJoinRequest:self];
            }
        } else if (strncmp(type, "INVACK", 6) == 0) {
            NSLog(@"Receive accepted invitation.");
        }
    }
}

@end
