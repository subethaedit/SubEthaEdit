//
//  SessionProfile.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 09 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SessionProfile.h"
#import "TCMBencodingUtilities.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "TCMMMUserSEEAdditions.h"

@implementation SessionProfile

- (void)sendJoinRequestForSessionID:(NSString *)aSessionID
{
    NSMutableData *data = [NSMutableData dataWithBytes:"JONJON" length:6];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                            [[TCMMMUserManager me] notification], @"UserNotification",
                            aSessionID, @"SessionID",
                            nil];
    [data appendData:TCM_BencodedObject(dict)]; 
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)acceptInvitation
{
    NSMutableData *data = [NSMutableData dataWithBytes:"INVACK" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)acceptJoin
{
    NSMutableData *data = [NSMutableData dataWithBytes:"JONACK" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
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
        if (strncmp(type,"USRREQ",6)==0) {
                NSMutableData *data=[NSMutableData dataWithBytes:"USRFUL" length:6];
                [data appendData:[[TCMMMUserManager me] userBencoded]];
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:data];
                [[self channel] sendMessage:[message autorelease]];
                return;
        } else if (strncmp(type, "JONJON", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received join request.");
            NSData *data = [[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)];
            NSDictionary *dict = TCM_BdecodedObjectWithData(data);
            NSString *sessionID = [dict objectForKey:@"SessionID"];
            TCMMMUser *user = [TCMMMUser userWithNotification:[dict objectForKey:@"UserNotification"]];
            if ([[TCMMMUserManager sharedInstance] sender:self shouldRequestUser:user]) {
                NSMutableData *data = [NSMutableData dataWithBytes:"USRREQ" length:6];
                [[self channel] sendMSGMessageWithPayload:data];
            }
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profile:didReceiveJoinRequestForSessionID:)]) {
                [delegate profile:self didReceiveJoinRequestForSessionID:sessionID];
            }
        } else if (strncmp(type, "INVINV", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received invitation.");
        } else if (strncmp(type, "JONACK", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received accepted join.");
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profileDidAcceptJoinRequest:)]) {
                [delegate profileDidAcceptJoinRequest:self];
            }
        } else if (strncmp(type, "INVACK", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Receive accepted invitation.");
        }
        
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
        [[self channel] sendMessage:[message autorelease]];
    } else if ([aMessage isRPY]) {
        if ([[aMessage payload] length] == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain",DetailedLogLevel,@"SessionProfile recieved Ack");
            return;
        } else if ([[aMessage payload] length] < 6) {
            NSLog(@"SessionProfile: Invalid message format. Payload less than 6 bytes.");
            return;
        }
        
        unsigned char *type = (unsigned char *)[[aMessage payload] bytes];
        if (strncmp(type, "USRFUL", 6) == 0) {
            // TODO: validate userID
            TCMMMUser *user=[TCMMMUser userWithBencodedUser:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
            [[TCMMMUserManager sharedInstance] addUser:user];
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received USRFUL");
        }
    }
}

@end
