//
//  SessionProfile.m
//  SubEthaEdit
//
//  Created by Martin Ott on Tue Mar 09 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "SessionProfile.h"
#import "TCMBencodingUtilities.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "UserChangeOperation.h"

@implementation SessionProfile

+ (NSData *)defaultInitializationData {
    // optionally send the options here
    static NSData *data=nil;
	//,*historyData= nil;
    if (!data) {
		// sending and requesting of history is deprecated this way
        // historyData = [TCM_BencodedObject([NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"SendHistory",[NSNumber numberWithBool:YES],@"SendSESCHG",nil]) retain];
        data = [TCM_BencodedObject([NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"SendSESCHG",nil]) retain];
    }
    return data;
}

- (NSDictionary *)optionDictionary {
    return I_options;
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel {
    self = [super initWithChannel:aChannel];
    if (self) {
        I_flags.contentHasBeenExchanged=NO;
        I_flags.isClosing=NO;
        I_outgoingMMMessageQueue=[NSMutableArray new];
        I_numberOfUnacknowledgedSessconMSG=-1;
        I_options = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"SendHistory",[NSNumber numberWithBool:NO],@"SendSESCHG",nil];
    }
    return self;
}

- (void)handleInitializationData:(NSData *)aData {
    NSDictionary *options = TCM_BdecodedObjectWithData(aData);
    if (options) {
        [I_options addEntriesFromDictionary:options];
    }
}

- (void)dealloc {
    [I_options release];
    [I_outgoingMMMessageQueue release];
    [super dealloc];
}

- (void)clearOutgoingMMMessageQueue {
    [I_outgoingMMMessageQueue removeAllObjects];
}

- (void)setContentHasBeenExchanged:(BOOL)aFlag {
    if (aFlag==YES) {
        NSData *data=nil;
        for (data in I_outgoingMMMessageQueue) {
            [[self channel] sendMSGMessageWithPayload:data];
        }
        [I_outgoingMMMessageQueue removeAllObjects];
    }
    I_flags.contentHasBeenExchanged=aFlag;
}

- (BOOL)contentHasBeenExchanged {
    return I_flags.contentHasBeenExchanged;
}

- (void)sendInvitationWithSession:(TCMMMSession *)aSession {
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel,@"Sending INVINV");
    NSMutableData *data = [NSMutableData dataWithBytes:"INVINV" length:6];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                            [[TCMMMUserManager me] notification], @"UserNotification",
                            [aSession dictionaryRepresentation], @"Session",
                            nil];
    [data appendData:TCM_BencodedObject(dict)]; 
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)sendJoinRequestForSessionID:(NSString *)aSessionID
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel,@"Sending JONJON");
    NSMutableData *data = [NSMutableData dataWithBytes:"JONJON" length:6];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                            [[TCMMMUserManager me] notification], @"UserNotification",
                            aSessionID, @"SessionID",
                            nil];
    [data appendData:TCM_BencodedObject(dict)]; 
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)sendUserDidChangeNotification:(TCMMMUser *)aUser {
    NSMutableData *data=[NSMutableData dataWithBytes:"USRCHG" length:6];
    [data appendData:[aUser notificationBencoded]];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)sendUserRequest:(NSDictionary *)aUserNotification {
    NSMutableData *data = [NSMutableData dataWithBytes:"USRREQ" length:6];
    if (aUserNotification) {
        [data appendData:TCM_BencodedObject(aUserNotification)];
    }
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)cancelJoin {
    NSMutableData *data = [NSMutableData dataWithBytes:"JONCAN" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
    [self close];
}

- (void)acceptJoin
{
    NSMutableData *data = [NSMutableData dataWithBytes:"JONACK" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)denyJoin {
    NSMutableData *data = [NSMutableData dataWithBytes:"JONDNY" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
    [self close];
}

- (void)acceptInvitation
{
    NSMutableData *data = [NSMutableData dataWithBytes:"INVACK" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)declineInvitation 
{
    NSMutableData *data = [NSMutableData dataWithBytes:"INVDNY" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
    [self close];
}

- (void)cancelInvitation {
    NSMutableData *data = [NSMutableData dataWithBytes:"INVCAN" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
    [self close];
}


- (void)sendSessionInformation:(NSDictionary *)aSessionInformation {
    NSMutableData *data = [NSMutableData dataWithBytes:"SESINF" length:6];
    [data appendData:TCM_BencodedObject(aSessionInformation)];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)sendSessionChange:(TCMMMSession *)aSession {
    if ([[I_options objectForKey:@"SendSESCHG"] boolValue] && [aSession isServer]) {
        NSMutableData *data=[NSMutableData dataWithBytes:"SESCHG" length:6];
        [data appendData:[aSession sessionBencoded]];
        [[self channel] sendMSGMessageWithPayload:data];
    }
}


- (void)sendSessionContent:(NSData *)aSessionContent {
    NSMutableData *data = [NSMutableData dataWithBytes:"SESCON" length:6];
    [data appendData:aSessionContent];
    I_numberOfUnacknowledgedSessconMSG=[[self channel] sendMSGMessageWithPayload:data];
    [self setContentHasBeenExchanged:YES];
}


- (void)sendUser:(TCMMMUser *)aUser {
    NSMutableData *data=[NSMutableData dataWithBytes:"USRFUL" length:6];
    [data appendData:[aUser userBencoded]];
    [[self channel] sendMSGMessageWithPayload:data];
}

#pragma mark -
#pragma mark ### Channel methods ###

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    if ([aMessage isMSG]) {
        I_lastMessageNumber = [aMessage messageNumber];
        if ([[aMessage payload] length] < 6) {
            DEBUGLOG(@"MillionMonkeysLogDomain", SimpleLogLevel, @"Invalid message format. Payload less than 6 bytes.");
            return;
        }
        
        char *type = (char *)[[aMessage payload] bytes];
        if (strncmp(type,"USRREQ",6)==0) {
            TCMMMUser *user=nil;
            if ([[aMessage payload] length]>6) {
                NSDictionary *notification=TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)]);
                if (notification && (user=[TCMMMUser userWithNotification:notification])) {
                    user=[[TCMMMUserManager sharedInstance] userForUserID:[user userID]];
                } else {
                    [[self session] terminate];
                }
            } else {
                user=[TCMMMUserManager me];
            }
            NSMutableData *data;
            if (user) {
                data=[NSMutableData dataWithBytes:"USRFUL" length:6];
                [data appendData:[user userBencoded]];
            } else {
                data=[NSMutableData data];
            }
            TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:data];
            [[self channel] sendMessage:[message autorelease]];
            return;
        } else if (strncmp(type, "JONJON", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received join request.");
            NSData *data = [[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)];
            NSDictionary *dict = TCM_BdecodedObjectWithData(data);
            NSString *sessionID = [dict objectForKey:@"SessionID"];
            TCMMMUser *user = [TCMMMUser userWithNotification:[dict objectForKey:@"UserNotification"]];
            if (!user) {
                [[self session] terminate];
                return;
            }
            if ([[TCMMMUserManager sharedInstance] sender:self shouldRequestUser:user]) {
                NSMutableData *data = [NSMutableData dataWithBytes:"USRREQ" length:6];
                [[self channel] sendMSGMessageWithPayload:data];
            }
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profile:didReceiveJoinRequestForSessionID:)]) {
                [delegate profile:self didReceiveJoinRequestForSessionID:sessionID];
            }
        } else if (strncmp(type, "INVINV", 6) == 0) {
            //TODO: Invitations arrive here, seed should decline them here or in the session

            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received invitation.");
            NSData *data = [[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)];
            NSDictionary *dict = TCM_BdecodedObjectWithData(data);
            TCMMMSession *session=[TCMMMSession sessionWithDictionaryRepresentation:[dict objectForKey:@"Session"]];
            
            TCMMMUser *user = [TCMMMUser userWithNotification:[dict objectForKey:@"UserNotification"]];
            if (!user) {
                [[self session] terminate];
                return;
            }
            if ([[TCMMMUserManager sharedInstance] sender:self shouldRequestUser:user]) {
                NSMutableData *data = [NSMutableData dataWithBytes:"USRREQ" length:6];
                [[self channel] sendMSGMessageWithPayload:data];
            }
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profile:didReceiveInvitationForSession:)]) {
                [delegate profile:self didReceiveInvitationForSession:session];
            }
        } else if (strncmp(type, "JONCAN", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received cancel join. Delegate:%@",[self delegate]);
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profileDidCancelJoinRequest:)]) {
                [delegate profileDidCancelJoinRequest:self];
            }
        } else if (strncmp(type, "JONDNY", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received cancel join.");
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profileDidDenyJoinRequest:)]) {
                [delegate profileDidDenyJoinRequest:self];
            }
        } else if (strncmp(type, "JONACK", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received accepted join.");
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profileDidAcceptJoinRequest:)]) {
                [delegate profileDidAcceptJoinRequest:self];
            }
        } else if (strncmp(type, "INVCAN", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received cancel Invitation.");
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profileDidCancelInvitation:)]) {
                [delegate profileDidCancelInvitation:self];
            }
        } else if (strncmp(type, "INVDNY", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received decline Invitation.");
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profileDidDeclineInvitation:)]) {
                [delegate profileDidDeclineInvitation:self];
            }
        } else if (strncmp(type, "INVACK", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Receive accepted invitation.");
            id delegate=[self delegate];
            if ([delegate respondsToSelector:@selector(profileDidAcceptInvitation:)]) {
                [delegate profileDidAcceptInvitation:self];
            }
        } else if (strncmp(type, "SESCHG", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Receive accepted invitation.");
            id delegate=[self delegate];
            if ([delegate respondsToSelector:@selector(profileDidReceiveSessionChange:)]) {
                [delegate profileDidReceiveSessionChange:TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)])];
            }
        } else if (strncmp(type, "SESINF", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received session information.");
            NSData *data = [[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)];
            NSDictionary *dict = TCM_BdecodedObjectWithData(data);
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profile:userRequestsForSessionInformation:)]) {
                NSArray *userRequests = [delegate profile:self userRequestsForSessionInformation:dict];
                NSMutableData *data = [NSMutableData dataWithBytes:"USRREQ" length:6];
                [data appendData:TCM_BencodedObject(userRequests)];
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:data];
                [[self channel] sendMessage:[message autorelease]];
                I_flags.isTrackingSesConFrames=YES;
                I_numberOfTrackedSesConMSG=0;
                return;
            }
        } else if (strncmp(type, "SESCON", 6) == 0) {
            NSData *data = [[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)];
            id content=TCM_BdecodedObjectWithData(data);
            id delegate = [self delegate];
            if ([delegate respondsToSelector:@selector(profile:didReceiveSessionContent:)]) {
                [delegate profile:self didReceiveSessionContent:content];
            }
            DEBUGLOG(@"MillionMonkeysLogDomain", AllLogLevel, @"content: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
            I_flags.isTrackingSesConFrames=NO;
            TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
            [[self channel] sendMessage:[message autorelease]];
            // do this afterwards, so the MMMessages are sent after the Acknowledging RPY
            [self setContentHasBeenExchanged:YES];
            return;
        } else if (strncmp(type, "USRFUL", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received full user.");
            TCMMMUser *user=[TCMMMUser userWithBencodedUser:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
            if (user) {
                [[TCMMMUserManager sharedInstance] addUser:user];
            } else {
                [[self session] terminate];
            }
        } else if (strncmp(type, "DOCMSG", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received MMMessage.");
            NSDictionary *dict=TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]);
            TCMMMMessage *message=[TCMMMMessage messageWithDictionaryRepresentation:dict];
            TCMMMOperation *operation=[message operation];
            if ([operation isKindOfClass:[UserChangeOperation class]] &&
                [(UserChangeOperation *)operation type]==UserChangeTypeGroupChange &&                                 
                [[operation userID] isEqualToString:[TCMMMUserManager myUserID]] &&
                [[(UserChangeOperation *)operation theNewGroup] isEqualToString:TCMMMSessionReadOnlyGroupName]) {
                id delegate=[self delegate];
                if ([delegate respondsToSelector:@selector(profile:didReceiveUserChangeToReadOnly:)]) {
                    [delegate profile:self didReceiveUserChangeToReadOnly:(UserChangeOperation *)operation];
                }
            }
			if ([I_MMState isKindOfClass:[TCMMMState class]]) {
				[I_MMState handleMessage:message];
			}
        } else if (strncmp(type, "USRCHG",6)==0) {
            TCMMMUser *user=[TCMMMUser userWithBencodedNotification:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
            if (user) {
                if ([[TCMMMUserManager sharedInstance] sender:self shouldRequestUser:user]) {
                    [self sendUserRequest:[user notification]];
                }
            } else {
                [[self session] terminate];
            }
        }
        
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
        [[self channel] sendMessage:[message autorelease]];
        
    } else if ([aMessage isRPY]) {
        if ([[aMessage payload] length] == 0) {
            if (I_numberOfUnacknowledgedSessconMSG==[aMessage messageNumber]) {
                id delegate = [self delegate];
                if ([delegate respondsToSelector:@selector(profileDidAckSessionContent:)]) {
                    [delegate profileDidAckSessionContent:self];
                }
                I_numberOfUnacknowledgedSessconMSG=-1;
            }
            DEBUGLOG(@"MillionMonkeysLogDomain",DetailedLogLevel,@"SessionProfile received Ack");
            return;
        } else if ([[aMessage payload] length] < 6) {
            DEBUGLOG(@"MillionMonkeysLogDomain", SimpleLogLevel, @"SessionProfile: Invalid message format. Payload less than 6 bytes.");
            return;
        }
        
        char *type = (char *)[[aMessage payload] bytes];
        if (strncmp(type, "USRFUL", 6) == 0) {
            // TODO: validate userID
            TCMMMUser *user=[TCMMMUser userWithBencodedUser:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
            if (user) {
                [[TCMMMUserManager sharedInstance] addUser:user];
            } else {
                [[self session] terminate];
            }
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received USRFUL");
        } else if (strncmp(type, "USRREQ", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received USRREQ from Client");

            NSArray *neededUserNotifications=TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]);
            NSMutableArray *neededUsers=[NSMutableArray array];
            NSDictionary *notificationDict=nil;
            for (notificationDict in neededUserNotifications) {
                // backwards compatibility
                if ([notificationDict objectForKey:@"uID"]) {
                    TCMMMUser *user=[TCMMMUser userWithNotification:notificationDict];
                    if (user) [neededUsers addObject:user];
                } else if ([notificationDict objectForKey:@"User"]) {
                    TCMMMUser *user=[TCMMMUser userWithNotification:[notificationDict objectForKey:@"User"]];
                    if (user) [neededUsers addObject:user];
                }
            }
            if ([[self delegate] respondsToSelector:@selector(profile:didReceiveUserRequests:)]) {
                [[self delegate] profile:self didReceiveUserRequests:neededUsers];
            }
        }
    } else if ([aMessage isERR]) {
        //NSLog(@"Error occured! %@",[aMessage description]);
    }
}

- (void)setMMState:(TCMMMState *)aState {
    I_MMState = aState;
}

- (TCMMMState *)MMState {
    return I_MMState;
}

- (void)state:(TCMMMState *)aState handleMessage:(TCMMMMessage *)aMessage {
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"handleMessage");
    // send message via channel
    NSMutableData *data=[NSMutableData dataWithBytes:"DOCMSG" length:6];
    [data appendData:TCM_BencodedObject([aMessage dictionaryRepresentation])];
    if (I_flags.contentHasBeenExchanged) {
        [[self channel] sendMSGMessageWithPayload:data];
    } else {
        [I_outgoingMMMessageQueue addObject:data];
    }
}

- (void)channelDidReceiveFrame:(TCMBEEPFrame *)aFrame startingMessage:(BOOL)aFlag
{
    if (I_flags.isTrackingSesConFrames) {
        if (I_numberOfTrackedSesConMSG==0 && aFlag) {
            NSData *data=[aFrame payload];
            if ([data length]>=6) {
                if (strncmp((char *)[data bytes], "SESCON", 6) == 0) {
                    I_numberOfTrackedSesConMSG=[aFrame messageNumber];
                }
            }
        }
        if (I_numberOfTrackedSesConMSG==[aFrame messageNumber]) {
            id delegate=[self delegate];
            if ([delegate respondsToSelector:@selector(profile:didReceiveSessionContentFrame:)]) {
                [delegate profile:self didReceiveSessionContentFrame:aFrame];
            }
        }
    }
    [super channelDidReceiveFrame:aFrame startingMessage:aFlag];
}


- (void)setDelegate:(id <TCMBEEPProfileDelegate, SessionProfileDelegate>)aDelegate
{
	[super setDelegate:aDelegate];
}

- (id <TCMBEEPProfileDelegate, SessionProfileDelegate>)delegate
{
	return (id <TCMBEEPProfileDelegate, SessionProfileDelegate>)[super delegate];
}

@end
