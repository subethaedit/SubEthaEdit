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

- (id)initWithChannel:(TCMBEEPChannel *)aChannel {
    self = [super initWithChannel:aChannel];
    if (self) {
        I_flags.contentHasBeenExchanged=NO;
        I_flags.isClosing=NO;
        I_outgoingMMMessageQueue=[NSMutableArray new];
        I_numberOfUnacknowledgedSessconMSG=-1;
    }
    return self;
}

- (void)dealloc {
    [I_outgoingMMMessageQueue release];
    [super dealloc];
}

- (void)clearOutgoingMMMessageQueue {
    [I_outgoingMMMessageQueue removeAllObjects];
}

- (void)setContentHasBeenExchanged:(BOOL)aFlag {
    if (aFlag==YES) {
        NSEnumerator *datas=[I_outgoingMMMessageQueue objectEnumerator];
        NSData *data=nil;
        while ((data=[datas nextObject])) {
            [[self channel] sendMSGMessageWithPayload:data];
        }
        [I_outgoingMMMessageQueue removeAllObjects];
    }
    I_flags.contentHasBeenExchanged=aFlag;
}

- (BOOL)contentHasBeenExchanged {
    return I_flags.contentHasBeenExchanged;
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

- (void)denyJoin {
    NSMutableData *data = [NSMutableData dataWithBytes:"JONDNY" length:6];
    [[self channel] sendMSGMessageWithPayload:data];
    [self close];
}

- (void)sendSessionInformation:(NSDictionary *)aSessionInformation {
    NSMutableData *data = [NSMutableData dataWithBytes:"SESINF" length:6];
    [data appendData:TCM_BencodedObject(aSessionInformation)];
    [[self channel] sendMSGMessageWithPayload:data];
}

- (void)sendSessionContent:(NSDictionary *)aSessionContent {
    NSMutableData *data = [NSMutableData dataWithBytes:"SESCON" length:6];
    [data appendData:TCM_BencodedObject(aSessionContent)];
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
            NSLog(@"Invalid message format. Payload less than 6 bytes.");
            return;
        }
        
        unsigned char *type = (unsigned char *)[[aMessage payload] bytes];
        if (strncmp(type,"USRREQ",6)==0) {
            TCMMMUser *user=nil;
            if ([[aMessage payload] length]>6) {
                NSDictionary *notification=TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)]);
                if (notification) {
                    user=[TCMMMUser userWithNotification:notification];
                    user=[[TCMMMUserManager sharedInstance] userForUserID:[user userID]];
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
        } else if (strncmp(type, "JONCAN", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received cancel join.");
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
        } else if (strncmp(type, "INVACK", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Receive accepted invitation.");
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
            [self setContentHasBeenExchanged:YES];
        } else if (strncmp(type, "USRFUL", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received full user.");
            // TODO: validate userID
            TCMMMUser *user=[TCMMMUser userWithBencodedUser:[[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]];
            [[TCMMMUserManager sharedInstance] addUser:user];
        } else if (strncmp(type, "DOCMSG", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received MMMessage.");
            NSDictionary *dict=TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]);
            TCMMMMessage *message=[TCMMMMessage messageWithDictionaryRepresentation:dict];
            [I_MMState handleMessage:message];
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
        } else if (strncmp(type, "USRREQ", 6) == 0) {
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Received USRREQ from Client");

            NSArray *neededUserNotifications=TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6,[[aMessage payload] length]-6)]);
            NSMutableArray *neededUsers=[NSMutableArray array];
            NSEnumerator *notifications=[neededUserNotifications objectEnumerator];
            NSDictionary *notificationDict=nil;
            while ((notificationDict = [notifications nextObject])) {
                [neededUsers addObject:[TCMMMUser userWithNotification:notificationDict]];
            }
            if ([[self delegate] respondsToSelector:@selector(profile:didReceiveUserRequests:)]) {
                [[self delegate] profile:self didReceiveUserRequests:neededUsers];
            }
        }

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

@end
