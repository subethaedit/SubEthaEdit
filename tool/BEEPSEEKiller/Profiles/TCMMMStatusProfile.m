//
//  TCMMMStatusProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMStatusProfile.h"
#import <TCMFoundation/TCMBencodingUtilities.h>


@implementation TCMMMStatusProfile

- (NSDictionary *)notification {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"Strunzenöder Testbenutzer",@"name",
            [NSNumber numberWithLongLong:(long long)[NSDate timeIntervalSinceReferenceDate]],@"cnt",
            [NSData dataWithUUIDString:[[AppController sharedInstance] userID]],@"uID",
        nil];
}

- (void)sendVisibility:(BOOL)isVisible {
    NSData *data=nil;
    if (isVisible) {
        data=[NSData dataWithBytes:"STAVIS" length:6];
    } else {
        data=[NSData dataWithBytes:"STAINV" length:6];
    }
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)sendUserDidChangeNotification {
    NSMutableData *data=[NSMutableData dataWithBytes:"USRCHG" length:6];
    [data appendData:TCM_BencodedObject([self notification])];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)requestUser {
    NSMutableData *data=[NSMutableData dataWithBytes:"USRREQ" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
}
/*

- (void)announceSession:(TCMMMSession *)aSession {
    NSMutableData *data=[NSMutableData dataWithBytes:"DOCANN" length:6];
    [data appendData:[aSession sessionBencoded]];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)concealSession:(TCMMMSession *)aSession {
    NSMutableData *data=[NSMutableData dataWithBytes:"DOCCON" length:6];
    [data appendData:TCM_BencodedObject([aSession sessionID])];
    [[self channel] sendMSGMessageWithPayload:data];
}
*/
- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage {
    if ([aMessage isRPY]) {
        if ([[aMessage payload] length]>=6) {
            unsigned char *bytes=(unsigned char *)[[aMessage payload] bytes];
            if (strncmp(bytes,"USRFUL",6)==0) {
                // TODO: validate userID
                DEBUGLOG(@"StatusDomain",AlwaysLogLevel,@"USRFUL: %@",TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]) );
            }
        } else if ([[aMessage payload] length]==0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", AllLogLevel,@"Status Profile Received Ack");
        } else {
            DEBUGLOG(@"MillionMonkeysLogDomain", AllLogLevel,@"Status Profile Received Bullshit");
        }
    } else if ([aMessage isMSG]) {
        if ([[aMessage payload] length]<6) {
            DEBUGLOG(@"MillionMonkeysLogDomain", SimpleLogLevel, @"StatusProfile MSG with payload less than 6 bytes is not allowed");
        } else {
            unsigned char *bytes=(unsigned char *)[[aMessage payload] bytes];
            if (strncmp(bytes,"USRCHG",6)==0) {
                [self requestUser];
            } else if (strncmp(bytes,"USRREQ",6)==0) {
                if ([[AppController sharedInstance] testNumber]==3) {
                    NSMutableData *data=[NSMutableData dataWithBytes:"USRFUL" length:6];
                    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
                    dictionary = [self notification];
                    [data appendData:TCM_BencodedObject(dictionary)];
                    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:data];
                    [[self channel] sendMessage:[message autorelease]];
                    return;
                }
            } else if (strncmp(bytes,"STA",3)==0){
                if (strncmp(&bytes[3],"VIS",3)==0) {
                    [[self delegate] profile:self didReceiveVisibilityChange:YES];
                } else if (strncmp(&bytes[3],"INV",3)==0) {
                    [[self delegate] profile:self didReceiveVisibilityChange:NO];
                }
            }

            // ACK
            TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
            [[self channel] sendMessage:[message autorelease]];
        }
    }
}

@end
