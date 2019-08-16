//  TCMMMStatusProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.

#import "TCMMMStatusProfile.h"
#import "TCMMMUser.h"
#import "TCMMMUserManager.h"
#import "TCMBencodingUtilities.h"
#import "TCMMMSession.h"
#import "TCMMMPresenceManager.h"


@interface TCMMMStatusProfile ()
@property (nonatomic, readwrite) BOOL lastSentFriendcastingStatus;
@end
@implementation TCMMMStatusProfile

+ (NSData *)defaultInitializationData {
    // optionally send the options here
    static NSData *data=nil;
    if (!data) {
        data = TCM_BencodedObject([NSDictionary dictionaryWithObjectsAndKeys:@YES,@"SendUSRRCH",nil]);
    }
    return data;
}

- (NSDictionary *)optionDictionary {
    return I_options;
}

- (instancetype)initWithChannel:(TCMBEEPChannel *)aChannel {
    self = [super initWithChannel:aChannel];
    if (self) {
        I_options = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@NO,@"SendUSRRCH",nil];
    }
    return self;
}

- (void)handleInitializationData:(NSData *)aData {
    NSDictionary *options = TCM_BdecodedObjectWithData(aData);
    if (options) {
        [I_options addEntriesFromDictionary:options];
    }
}

- (BOOL)sendToken:(NSString *)aToken {
    if (aToken && [[I_options objectForKey:@"SendUSRRCH"] boolValue]) {
        NSMutableData *data=[NSMutableData dataWithBytes:"INVTOK" length:6];
        [data appendData:TCM_BencodedObject([NSDictionary dictionaryWithObjectsAndKeys:aToken,@"token",nil])];
        [[self channel] sendMSGMessageWithPayload:data];
        return YES;
    } else {
        return NO;
    }
}


- (void)sendReachabilityURLString:(NSString *)anURLString forUserID:(NSString *)aUserID {
    if (aUserID && anURLString && [[I_options objectForKey:@"SendUSRRCH"] boolValue] && [[NSUserDefaults standardUserDefaults] boolForKey:AutoconnectPrefKey]) {
        NSMutableData *data=[NSMutableData dataWithBytes:"USRRCH" length:6];
        [data appendData:TCM_BencodedObject([NSDictionary dictionaryWithObjectsAndKeys:anURLString,@"url",aUserID,@"uid",nil])];
        [[self channel] sendMSGMessageWithPayload:data];
    }
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

- (void)sendIsFriendcasting:(BOOL)isFriendcasting {
    if ([[I_options objectForKey:@"SendUSRRCH"] boolValue]) {
		self.lastSentFriendcastingStatus = isFriendcasting;
        NSData *data=nil;
        if (isFriendcasting) {
            data=[NSData dataWithBytes:"FCAYES" length:6];
        } else {
            data=[NSData dataWithBytes:"FCAOFF" length:6];
        }
        [[self channel] sendMSGMessageWithPayload:data];
    }
}

- (void)sendUserDidChangeNotification:(TCMMMUser *)aUser {
    NSMutableData *data=[NSMutableData dataWithBytes:"USRCHG" length:6];
    [data appendData:[aUser notificationBencoded]];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)requestUser {
    NSMutableData *data=[NSMutableData dataWithBytes:"USRREQ" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)requestReachability {
    //NSLog(@"%s %@",__FUNCTION__,I_options);
    if ([[I_options objectForKey:@"SendUSRRCH"] boolValue]) {
        NSMutableData *data=[NSMutableData dataWithBytes:"RCHREQ" length:6];
        [[self channel] sendMSGMessageWithPayload:data];
    }
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
    if ([aMessage isRPY]) {
        if ([[aMessage payload] length]>=6) {
            char *bytes=(char *)[[aMessage payload] bytes];
            if (strncmp(bytes,"USRFUL",6)==0) {
                TCMMMUser *user=[TCMMMUser userWithBencodedUser:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
				if (user && [[user userID] isEqualToString:[[[self session] userInfo] objectForKey:@"peerUserID"]]) {
					[[TCMMMUserManager sharedInstance] addUser:user];
				} else {
					[[self session] terminate];
				}
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
            char *bytes=(char *)[[aMessage payload] bytes];
            if (strncmp(bytes,"USRCHG",6)==0) {
                TCMMMUser *user=[TCMMMUser userWithBencodedNotification:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
                if (user) {
                    if ([[TCMMMUserManager sharedInstance] sender:self shouldRequestUser:user]) {
                        [self requestUser];
                    }
                } else {
                    [[self session] terminate];
                }
            } else if (strncmp(bytes,"RCHREQ",6)==0) {
                id delegate = [self delegate];
                if ([delegate respondsToSelector:@selector(profileDidReceiveReachabilityRequest:)]) {
                    [delegate profileDidReceiveReachabilityRequest:self];
                }

            } else if (strncmp(bytes,"USRREQ",6)==0) {
                NSMutableData *data=[NSMutableData dataWithBytes:"USRFUL" length:6];
                [data appendData:[[TCMMMUserManager me] userBencoded]];
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:data];
                [[self channel] sendMessage:message];
                return;
            } else if (strncmp(bytes,"USRRCH",6)==0) {
                NSDictionary *dict = TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]);
                //NSLog(@"%s got reachability notice %@",__FUNCTION__,dict);
                id delegate = [self delegate];
                if ([delegate respondsToSelector:@selector(profile:didReceiveReachabilityURLString:forUserID:)]) {
                    [delegate profile:self didReceiveReachabilityURLString:[dict objectForKey:@"url"] forUserID:[dict objectForKey:@"uid"]];
                }
            } else if (strncmp(bytes,"INVTOK",6)==0) {
                NSDictionary *dict = TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]);
                id delegate = [self delegate];
                if ([delegate respondsToSelector:@selector(profile:didReceiveToken:)]) {
                    [delegate profile:self didReceiveToken:[dict objectForKey:@"token"]];
                }
            } else if (strncmp(bytes,"DOC",3)==0) {
                DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received Document");
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
            } else if (strncmp(bytes,"FCA",3)==0){
                if (strncmp(&bytes[3],"YES",3)==0) {
                    [[self delegate] profile:self didReceiveFriendcastingChange:YES];
                } else if (strncmp(&bytes[3],"OFF",3)==0) {
                    [[self delegate] profile:self didReceiveFriendcastingChange:NO];
                }
            }

            // ACK
            TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
            [[self channel] sendMessage:message];
        }
    }
}

- (void)setDelegate:(id <TCMBEEPProfileDelegate, TCMMMStatusProfileDelegate>)aDelegate {
	[super setDelegate:aDelegate];
}

- (id <TCMBEEPProfileDelegate, TCMMMStatusProfileDelegate>)delegate {
	return (id <TCMBEEPProfileDelegate, TCMMMStatusProfileDelegate>)[super delegate];
}

@end
