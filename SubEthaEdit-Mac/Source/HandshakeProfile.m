//
//  HandshakeProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMFoundation.h"
#import "HandshakeProfile.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMPresenceManager.h"

@implementation HandshakeProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel {
    self = [super initWithChannel:aChannel];
    return self;
}

- (void)dealloc {
    [I_remoteInfos release];
    [super dealloc];
}

- (void)setRemoteInfos:(NSDictionary *)aDictionary {
    [I_remoteInfos autorelease];
    NSString *userAgent = [aDictionary objectForKey:@"uag"];
    if (userAgent) {
        [[[self session] userInfo] setObject:userAgent forKey:@"userAgent"];
    }
    I_remoteInfos = [aDictionary mutableCopy];
}

- (NSDictionary *)remoteInfos {
    return I_remoteInfos;
}

- (NSData *)handshakePayloadWithUserID:(NSString *)aUserID {
    NSMutableData *payload = [NSMutableData data];
	if ( aUserID ) {
 	   [payload appendData:[@"GRT" dataUsingEncoding:NSASCIIStringEncoding]];
    
    	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	    [dict setObject:aUserID forKey:@"uid"];
	    [dict setObject:@"200" forKey:@"vers"];
	    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	    NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	    [dict setObject:[NSString stringWithFormat:@"%@/%@ (%@)",bundleName,shortVersion,bundleVersion] forKey:@"uag"];

		NSDictionary *myUserInfo = self.session.userInfo;
		
	    if ([[myUserInfo objectForKey:@"isRendezvous"] boolValue]) {
	        [dict setObject:@"vous" forKey:@"rendez"];
	    } else {
	        NSString *URLString = [myUserInfo objectForKey:@"URLString"];
	        if (URLString) {
	            [dict setObject:URLString forKey:@"url"];
	        }    
	    }
    
    	if ([[self.session.userInfo objectForKey:@"isAutoConnect"] boolValue]) {
			dict[@"isauto"]=@YES;
	    }
    
		NSString *autoidString = myUserInfo[TCMMMPresenceAutoconnectOriginUserIDKey];
		if (autoidString) {
			dict[@"autoid"]=autoidString;
		}
		
    	[payload appendData:TCM_BencodedObject(dict)];
	}
    
    return payload;
}

- (void)shakeHandsWithUserID:(NSString *)aUserID
{
	if ( aUserID )
	    [[self channel] sendMSGMessageWithPayload:[self handshakePayloadWithUserID:aUserID]];
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    // simple message reply model
    if ([aMessage isMSG]) {
        if ([[aMessage payload] length] < 3) {
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Invalid message format. Payload less than 3 bytes.");
            [[self session] terminate];
            return;
        }
        
        char *type = (char *)[[aMessage payload] bytes];
        if (strncmp(type, "GRT", 3) == 0) {    
            NSDictionary *dict = TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(3, [[aMessage payload] length] - 3)]);
            [self setRemoteInfos:dict];
            DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Handshake greeting was: %@", [dict descriptionInStringsFileFormat]);
            if ([[self remoteInfos] objectForKey:@"rendez"]) {
                [[[self session] userInfo] setObject:[NSNumber numberWithBool:YES] forKey:@"isRendezvous"];
            }
            if ([[self remoteInfos] objectForKey:@"isauto"]) {
                [[[self session] userInfo] setObject:[NSNumber numberWithBool:YES] forKey:@"isAutoConnect"];
            }
			if ([self remoteInfos][@"autoid"]) {
				[self.session.userInfo setObject:[self remoteInfos][@"autoid"] forKey:TCMMMPresenceAutoconnectOriginUserIDKey];
			}
            if ([[self remoteInfos] objectForKey:@"url"]) {
                [[[self session] userInfo] setObject:[NSString stringWithAddressData:[[self session] peerAddressData]] forKey:@"URLString"];
            }
            if (![[self remoteInfos] objectForKey:@"uid"] || ![[[self remoteInfos] objectForKey:@"uid"] isKindOfClass:[NSString class]]) {
                [[self session] terminate];
                return;
            }
            
            NSString *userID = [[self delegate] profile:self shouldProceedHandshakeWithUserID:[[self remoteInfos] objectForKey:@"uid"]];
            if (userID) {
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[self handshakePayloadWithUserID:userID]];
                [[self channel] sendMessage:[message autorelease]];        
            } else {
                [[self session] terminate];
            }
        } else if (strncmp(type, "ACK", 3) == 0) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LogConnections"]) {
                TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:[[self remoteInfos] objectForKey:@"uid"]];
                NSLog(@"   Connect: %@ - %@ - %@",[NSString stringWithAddressData:[[self session] peerAddressData]],user?[user shortDescription]:[[self remoteInfos] objectForKey:@"uid"],[[self remoteInfos] objectForKey:@"uag"]);
            }
            BOOL isRendezvous = [[[self session] userInfo] objectForKey:@"isRendezvous"] != nil ? YES : NO;
            if (![[self session] isProhibitingInboundInternetSessions] || isRendezvous) {
                [[self delegate] profile:self receivedAckHandshakeWithUserID:[[self remoteInfos] objectForKey:@"uid"]];
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:[NSData data]];
                [[self channel] sendMessage:[message autorelease]];   
            } else {
                [[self session] terminate];
            }     
        } 
    } else if ([aMessage isRPY]) {
        if ([[aMessage payload] length] > 0) {
            NSDictionary *dict = TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(3, [[aMessage payload] length] - 3)]);
            DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"ShakeHandRPY was: %@", [dict descriptionInStringsFileFormat]);
            [self setRemoteInfos:dict];
            if (![[self remoteInfos] objectForKey:@"uid"]) {
                [[self session] terminate];
                return;
            }
            BOOL shouldAck = NO;
            if ([[self delegate] respondsToSelector:@selector(profile:shouldAckHandshakeWithUserID:)]) {
                shouldAck = [[self delegate] profile:self shouldAckHandshakeWithUserID:[[self remoteInfos] objectForKey:@"uid"]];
            }
            if (shouldAck) {
                NSMutableData *payload = [NSMutableData dataWithData:[@"ACK" dataUsingEncoding:NSUTF8StringEncoding]];
                TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"MSG" messageNumber:[[self channel] nextMessageNumber] payload:payload];
                [[self channel] sendMessage:[message autorelease]];
                [[self delegate] profile:self didAckHandshakeWithUserID:[[self remoteInfos] objectForKey:@"uid"]];            
            } else {
                [[self session] terminate];
            }
        } else {
            DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Got empty reply for ACK message.");
            [[self channel] close];
        }
    }
}


- (void)setDelegate:(id <TCMBEEPProfileDelegate, HandshakeProfileDelegate>)aDelegate
{
	[super setDelegate:aDelegate];
}

- (id <TCMBEEPProfileDelegate, HandshakeProfileDelegate>)delegate
{
	return (id <TCMBEEPProfileDelegate, HandshakeProfileDelegate>)[super delegate];
}


@end
