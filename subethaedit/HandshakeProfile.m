//
//  HandshakeProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "HandshakeProfile.h"


@implementation HandshakeProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel {
    self = [super initWithChannel:aChannel];
    if (self) {
        I_remoteInfos=[NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_remoteInfos release];
    [super dealloc];
}

- (NSDictionary *)remoteInfos {
    return I_remoteInfos;
}

- (NSData *)handshakePayloadWithUserID:(NSString *)aUserID {
    NSMutableString *string=[NSMutableString stringWithFormat:@"GRTuserid=%@\001version=2.00",aUserID];
    if ([[[[[self channel] session] userInfo] objectForKey:@"isRendezvous"] boolValue]){
        [string appendString:@"\001rendez=vous"];
    }
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)shakeHandsWithUserID:(NSString *)aUserID
{
    [[self channel] sendMSGMessageWithPayload:[self handshakePayloadWithUserID:aUserID]];
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    // simple message reply model
    if ([aMessage isMSG]) {
        NSString *string=[NSString stringWithData:[aMessage payload] encoding:NSUTF8StringEncoding];
        NSString *type=[string substringToIndex:3];
        if ([type isEqualToString:@"GRT"]) {
            string=[string substringFromIndex:3];
            NSArray *pairsArray=[string componentsSeparatedByString: @"\001"];
            NSEnumerator *pairs=[pairsArray objectEnumerator];
            NSString *pair;
            while ((pair = [pairs nextObject])) {
                NSRange foundRange=[pair rangeOfString:@"="];
                if (foundRange.location!=NSNotFound) {
                    NSString *key = [[pair substringToIndex:foundRange.location] lowercaseString];
                    NSString *value=[pair substringFromIndex:NSMaxRange(foundRange)];
                    [I_remoteInfos setObject:value forKey:key];
                }
            }
            DEBUGLOG(@"BEEPLogDomain",DetailedLogLevel,@"Handshake greeting was: %@",string);
            if ([I_remoteInfos objectForKey:@"rendez"]) {
                [[[[self channel] session] userInfo] setObject:[NSNumber numberWithBool:YES] forKey:@"isRendezvous"];
            }
            NSString *userID=[[self delegate] profile:self shouldProceedHandshakeWithUserID:[I_remoteInfos objectForKey:@"userid"]];
            if (userID) {
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[self handshakePayloadWithUserID:userID]];
                [[self channel] sendMessage:[message autorelease]];        
            } else {
                // brich ab
            }
        } else {
            if ([type isEqualToString:@"ACK"]) {
                [[self delegate] profile:self receivedAckHandshakeWithUserID:[I_remoteInfos objectForKey:@"userid"]];
                // WARNING: No reply is sent for this message!
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
                [[self channel] sendMessage:[message autorelease]];
            }
        }
    } else if ([aMessage isRPY]) {
        if ([[aMessage payload] length] > 0) {
            NSString *string = [NSString stringWithData:[aMessage payload] encoding:NSUTF8StringEncoding];
            DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"ShakeHandRPY was: %@", string);
            string = [string substringFromIndex:3];
            NSArray *pairsArray = [string componentsSeparatedByString: @"\001"];
            NSEnumerator *pairs = [pairsArray objectEnumerator];
            NSString *pair;
            while ((pair = [pairs nextObject])) {
                NSRange foundRange = [pair rangeOfString:@"="];
                if (foundRange.location != NSNotFound) {
                    NSString *key = [[pair substringToIndex:foundRange.location] lowercaseString];
                    NSString *value = [pair substringFromIndex:NSMaxRange(foundRange)];
                    [I_remoteInfos setObject:value forKey:key];
                }
            }
            BOOL shouldAck = NO;
            if ([[self delegate] respondsToSelector:@selector(profile:shouldAckHandshakeWithUserID:)]) {
                shouldAck = [[self delegate] profile:self shouldAckHandshakeWithUserID:[I_remoteInfos objectForKey:@"userid"]];
            }
            if (shouldAck) {
                NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"ACK"] dataUsingEncoding:NSUTF8StringEncoding]];
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"MSG" messageNumber:[[self channel] nextMessageNumber] payload:payload];
                [[self channel] sendMessage:[message autorelease]];
                [[self delegate] profile:self didAckHandshakeWithUserID:[I_remoteInfos objectForKey:@"userid"]];
            } else {
                // brich ab
            }
        } else {
            DEBUGLOG(@"BEEPLogDmain", DetailedLogLevel, @"Got empty reply for ACK message.");
            [[self channel] close];
        }
    }
}

@end
