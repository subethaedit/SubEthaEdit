//
//  TCMMMStatusProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMStatusProfile.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMBencodingUtilities.h"
#import "TCMMMSession.h"


@implementation TCMMMStatusProfile

- (void)sendVisibility:(BOOL)isVisible {
    NSData *data=nil;
    if (isVisible) {
        data=[NSData dataWithBytes:"STAVIS" length:6];
    } else {
        data=[NSData dataWithBytes:"STAINV" length:6];
    }
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)sendMyself:(TCMMMUser *)aUser {
    NSMutableData *data=[NSMutableData dataWithBytes:"USRFUL" length:6];
    [data appendData:[aUser userBencoded]];
    [[self channel] sendMSGMessageWithPayload:data];
}

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

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage {
    if ([aMessage isMSG]) {
        if ([[aMessage payload] length]<6) {
            NSLog(@"StatusProfile MSG with payload less than 6 bytes is not allowed");
        } else {
            unsigned char *bytes=(unsigned char *)[[aMessage payload] bytes];
            if (strncmp(bytes,"USRFUL",6)==0) {
                TCMMMUser *user=[TCMMMUser userWithBencodedUser:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
                [[self delegate] profile:self didReceiveUser:user];
            } else if (strncmp(bytes,"DOC",3)==0) {
                NSLog(@"Received Document");
                if (strncmp(&bytes[3],"ANN",3)==0) {
                    TCMMMSession *session=[TCMMMSession sessionWithBencodedSession:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
                    [[self delegate] profile:self didReceiveAnnouncedSession:session];
                } else if (strncmp(&bytes[3],"CON",3)==0) {
                    NSString *sessionID=TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]);
                    if (sessionID) {
                        [[self delegate] profile:self didReceiveConcealedSessionID:sessionID];
                    }
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
