//
//  TCMBEEPManagementProfile.m
//  TCMBEEP
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPManagementProfile.h"
#import "TCMBEEPMessage.h"
#import "TCMBEEPMessageXMLPayloadParser.h"
#import "TCMBEEPChannel.h"
#import "TCMBEEPSession.h"
#import <CoreFoundation/CoreFoundation.h>


@interface TCMBEEPManagementProfile ()

- (BOOL)processBEEPGreeting:(TCMBEEPMessage *)aMessage dataParser:(TCMBEEPMessageXMLPayloadParser *)dataParser;
- (BOOL)processBEEPStartMessage:(TCMBEEPMessage *)aMessage dataParser:(TCMBEEPMessageXMLPayloadParser *)dataParser;
- (BOOL)processBEEPProfileMessage:(TCMBEEPMessage *)aMessage dataParser:(TCMBEEPMessageXMLPayloadParser *)dataParser;
- (BOOL)processBEEPCloseMessage:(TCMBEEPMessage *)aMessage dataParser:(TCMBEEPMessageXMLPayloadParser *)dataParser;
- (BOOL)processBEEPOKMessage:(TCMBEEPMessage *)aMessage;
- (BOOL)processBEEPErrorMessage:(TCMBEEPMessage *)aMessage;

@end

# pragma mark -

@implementation TCMBEEPManagementProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super initWithChannel:aChannel];
    if (self) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Initialized TCMBEEPManagmentProfile");
        I_firstMessage = YES;
        I_pendingChannelRequestMessageNumbers = [NSMutableDictionary new];
        I_channelNumbersByCloseRequests = [NSMutableDictionary new];
        I_messageNumbersOfCloseRequestsByChannelsNumbers = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [I_keepBEEPTimer release];
    [I_pendingChannelRequestMessageNumbers release];
    [I_channelNumbersByCloseRequests release];
    [I_messageNumbersOfCloseRequestsByChannelsNumbers release];
    [super dealloc];
}

- (void)setDelegate:(id <TCMBEEPProfileDelegate, TCMBEEPManagementProfileDelegate>)aDelegate
{
	[super setDelegate:aDelegate];
}
- (id <TCMBEEPProfileDelegate, TCMBEEPManagementProfileDelegate>)delegate
{
	return (id <TCMBEEPProfileDelegate, TCMBEEPManagementProfileDelegate>)[super delegate];
}


- (void)sendGreetingWithProfileURIs:(NSArray *)anArray featuresAttribute:(NSString *)aFeaturesString localizeAttribute:(NSString *)aLocalizeString
{
    // compose Greeting
    
    NSMutableString *payloadString = [NSMutableString stringWithString:@"Content-Type: application/beep+xml\r\n\r\n<greeting"];
    
    if (aFeaturesString) {
        [payloadString appendFormat:@" features=\"%@\"", aFeaturesString];
    }
    if (aLocalizeString) {
        [payloadString appendFormat:@" localize=\"%@\"", aLocalizeString];
    }
    [payloadString appendString:@">"];
    NSString *profileURI = nil;
    for (profileURI in anArray) {
        [payloadString appendFormat:@"<profile uri=\"%@\" />", profileURI];
    }
    [payloadString appendString:@"</greeting>\r\n"];
    NSData *payload = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[[self channel] nextMessageNumber] payload:payload];
    [[self channel] sendMessage:[message autorelease]];
    DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Sending Greeting: %@", payloadString);
   
    NSTimeInterval timeout=[[NSUserDefaults standardUserDefaults] floatForKey:NetworkTimeoutPreferenceKey]/3.0;
    if (!timeout) timeout=20.;
    I_keepBEEPTimer = [[NSTimer timerWithTimeInterval:timeout
                                               target:self 
                                             selector:@selector(sendKeepBEEP:)
                                             userInfo:nil
                                              repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:I_keepBEEPTimer forMode:(NSString *)kCFRunLoopCommonModes];
}

- (void)startChannelNumber:(int32_t)aChannelNumber withProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray
{
    // compose start message
    NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<start number='%d'>", aChannelNumber] dataUsingEncoding:NSUTF8StringEncoding]];
    int i = 0;
    for (i = 0; i < [aProfileURIArray count]; i++) {
        if (aDataArray && i<[aDataArray count] && [(NSData *)[aDataArray objectAtIndex:i] length]) {
            [payload appendData:[[NSString stringWithFormat:@"<profile uri='%@'><![CDATA[", [aProfileURIArray objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
            [payload appendData:[aDataArray objectAtIndex:i]];
            [payload appendData:[@"]]></profile>" dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            [payload appendData:[[NSString stringWithFormat:@"<profile uri='%@' />", [aProfileURIArray objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    [payload appendData:[@"</start>" dataUsingEncoding:NSUTF8StringEncoding]];
    int32_t messageNumber = [[self channel] nextMessageNumber];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"MSG" messageNumber:messageNumber payload:payload];
    [I_pendingChannelRequestMessageNumbers setObject:[NSNumber numberWithLong:aChannelNumber] forLong:messageNumber];
    [[self channel] sendMessage:[message autorelease]];
}

- (void)closeChannelWithNumber:(int32_t)aChannelNumber code:(int)aReplyCode
{
    // compose close message
    NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<close number='%d' code='%d' />", aChannelNumber, aReplyCode] dataUsingEncoding:NSUTF8StringEncoding]];
    int32_t messageNumber = [[self channel] nextMessageNumber];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"MSG" messageNumber:messageNumber payload:payload];
    [I_channelNumbersByCloseRequests setObject:[NSNumber numberWithLong:aChannelNumber] forLong:messageNumber];
    [[self channel] sendMessage:[message autorelease]];    
}

- (void)acceptCloseRequestForChannelWithNumber:(int32_t)aChannelNumber
{
    NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<ok />"] dataUsingEncoding:NSUTF8StringEncoding]];
    int32_t messageNumber = [[I_messageNumbersOfCloseRequestsByChannelsNumbers objectForLong:aChannelNumber] intValue];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:messageNumber payload:payload];
    [[self channel] sendMessage:[message autorelease]];
    [I_messageNumbersOfCloseRequestsByChannelsNumbers removeObjectForLong:aChannelNumber];
    [[self session] closedChannelWithNumber:aChannelNumber];
}

#pragma mark -

- (void)sendKeepBEEP:(NSTimer *)aTimer {
    [[self channel] sendSEQFrame];
}

- (void)cleanup {
    [I_keepBEEPTimer invalidate];
}

#pragma mark - BEEP Management Channel

- (BOOL)processBEEPGreeting:(TCMBEEPMessage *)aMessage dataParser:(TCMBEEPMessageXMLPayloadParser *)dataParser
{
    BOOL result = NO;

	if ([dataParser.messageType isEqualToString:TCMBEEPMessageXMLElementGreeting])
	{
		NSDictionary *attributes = dataParser.messageAttributeDict;
		NSArray *profileURIs = dataParser.profileURIs;

		[[self delegate] didReceiveGreetingWithProfileURIs:profileURIs
										 featuresAttribute:[attributes objectForKey:TCMBEEPMessageXMLAttributeFeatures]
										 localizeAttribute:[attributes objectForKey:TCMBEEPMessageXMLAttributeLocalize]];
		result = YES;
	}
    return result;
}

- (BOOL)processBEEPStartMessage:(TCMBEEPMessage *)aMessage dataParser:(TCMBEEPMessageXMLPayloadParser *)dataParser
{
	BOOL result = NO;
	if ([dataParser.messageType isEqualToString:TCMBEEPMessageXMLElementStart])
	{
		NSDictionary *attributeDict = dataParser.messageAttributeDict;
		int32_t channelNumber = [[attributeDict objectForKey:TCMBEEPMessageXMLAttributeChannelNumber] intValue];
		if (channelNumber > 0)
		{
			// see beepcore standard 2.3.1.2 - initators request odd channel numbers, listeners only even channel numbers
			BOOL channelNumberIsOdd = (channelNumber % 2 == 1);
			BOOL isOwnChannelRequest = (self.session.isInitiator ? channelNumberIsOdd : !channelNumberIsOdd);
			
			if (!isOwnChannelRequest)
			{
				NSArray *profileURIs = dataParser.profileURIs;
				NSArray *profileDataBlocks = dataParser.profileDataBlocks;

				DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"possible profile URIs are: %@", [profileURIs description]);
				NSDictionary *replyDict = [[self delegate] preferedAnswerToAcceptRequestForChannel:channelNumber withProfileURIs:profileURIs andData:profileDataBlocks];
				DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"reply is:%@",[replyDict description]);
				if (replyDict) {
					// juhuh... send accept
					NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

					if ([(NSData *)[replyDict objectForKey:@"Data"] length]) {
						[payload appendData:[[NSString stringWithFormat:@"<profile uri='%@'><![CDATA[", [replyDict objectForKey:@"ProfileURI"]] dataUsingEncoding:NSUTF8StringEncoding]];
						[payload appendData:[replyDict objectForKey:@"Data"]];
						[payload appendData:[@"]]></profile>" dataUsingEncoding:NSUTF8StringEncoding]];
					} else {
						[payload appendData:[[NSString stringWithFormat:@"<profile uri='%@' />", [replyDict objectForKey:@"ProfileURI"]] dataUsingEncoding:NSUTF8StringEncoding]];
					}

					TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:payload];
					[[self channel] sendMessage:[message autorelease]];
					DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"juhuhh... sent accept: %@",message);
					// find the correct data
					NSString *preferredURIString = [replyDict objectForKey:@"ProfileURI"];
					NSUInteger index = [profileURIs indexOfObject:preferredURIString];
					NSData *recievedData = index==NSNotFound?[NSData data]:[profileDataBlocks objectAtIndex:index];
					[[self delegate] initiateChannelWithNumber:channelNumber profileURI:preferredURIString data:recievedData asInitiator:NO];

					result = YES;
				} else {
					NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<error code='501'>channel request denied</error>"] dataUsingEncoding:NSUTF8StringEncoding]];
					TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:payload];
					[[self channel] sendMessage:[message autorelease]];
				}
			}
		}
	}
    return result;
}

- (BOOL)processBEEPProfileMessage:(TCMBEEPMessage *)aMessage dataParser:(TCMBEEPMessageXMLPayloadParser *)dataParser
{
	BOOL result = NO;
    if ([dataParser.messageType isEqualToString:TCMBEEPMessageXMLElementProfile]) {
        NSString *profileURI = [dataParser.messageAttributeDict objectForKey:TCMBEEPMessageXMLAttributeURI];
        if (profileURI) {
            int32_t messageNumber = [aMessage messageNumber];
            int32_t channelNumber = [[I_pendingChannelRequestMessageNumbers objectForKey:@(messageNumber)] intValue];

            [[self delegate] didReceiveAcceptStartRequestForChannel:channelNumber
													 withProfileURI:profileURI
															andData:dataParser.messageData];
			result = YES;
        }
    }
    return result;
}

- (BOOL)processBEEPCloseMessage:(TCMBEEPMessage *)aMessage dataParser:(TCMBEEPMessageXMLPayloadParser *)dataParser
{
	BOOL result = NO;
    if ([dataParser.messageType isEqualToString:TCMBEEPMessageXMLElementClose]) {
		NSDictionary *attributesDict = dataParser.messageAttributeDict;
		NSNumber *number = [attributesDict objectForKey:TCMBEEPMessageXMLAttributeChannelNumber];
		NSNumber *code = [attributesDict objectForKey:TCMBEEPMessageXMLAttributeCode];

		if (number && code) {
			// close request for a specific channel
			int32_t channelNumber = [number intValue];
			[I_channelNumbersByCloseRequests setObject:[NSNumber numberWithLong:channelNumber] forLong:[aMessage messageNumber]];
			[I_messageNumbersOfCloseRequestsByChannelsNumbers setObject:[NSNumber numberWithLong:[aMessage messageNumber]] forLong:channelNumber];
			DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Close requested for channel number: %d", channelNumber);
			[[self session] closeRequestedForChannelWithNumber:channelNumber];
			result = YES;
		} else if ((number == nil || [number intValue] == 0) && code) {
			// close request for the session
			DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Close requested for session");
			NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<ok />"] dataUsingEncoding:NSUTF8StringEncoding]];
			TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:payload];
			[[self channel] sendMessage:[message autorelease]];
			[[self session] terminate];
			result = YES;
		} else {
			// invalid close request
			DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Received invalid close request");
		}
	}
    return result;
}

- (BOOL)processBEEPOKMessage:(TCMBEEPMessage *)aMessage
{
    int32_t channelNumber = [[I_channelNumbersByCloseRequests objectForLong:[aMessage messageNumber]] longValue];
    [[self delegate] closedChannelWithNumber:channelNumber];
    return YES;
}

- (BOOL)processBEEPErrorMessage:(TCMBEEPMessage *)aMessage
{
    return YES;
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    // remove MIME Header
    NSData *contentData = [aMessage payload];
    // find "\r\n\r\n"
    int i;
    char *bytes = (char *)[contentData bytes];
    for (i = 0; i < [contentData length] - 4; i++) {
        if (bytes[i] == '\r') {
            if (strncmp(&bytes[i], "\r\n\r\n", 4) == 0) {
                break;
            }
        }
    }
    if (i < [contentData length]) {
        contentData = [NSData dataWithBytesNoCopy:&bytes[i+4] length:[contentData length]-i-4 freeWhenDone:NO];
    }
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"%@", [[[NSString alloc] initWithBytes:[[aMessage payload] bytes] length:[[aMessage payload] length] encoding:NSISOLatin1StringEncoding] autorelease]);

	TCMBEEPMessageXMLPayloadParser *dataParser = [[[TCMBEEPMessageXMLPayloadParser alloc] initWithXMLData:contentData] autorelease];
	if (dataParser) {
		if ([aMessage isMSG]) {
			if (I_firstMessage) {
				DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Error: First message was from type MSG");
				[[self session] terminate];
			} else {
				if ([@"start" isEqualToString:dataParser.messageType]) {
					DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found start element...");
					[self processBEEPStartMessage:aMessage dataParser:dataParser];
				} else if ([@"close" isEqualToString:dataParser.messageType]) {
					DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found close element...");
					[self processBEEPCloseMessage:aMessage dataParser:dataParser];
				} else {
					[[self session] terminate];
				}
			}
		} else if ([aMessage isRPY]) {
			if (I_firstMessage) {
				if ([aMessage messageNumber] == 0) {
					if ([@"greeting" isEqualToString:dataParser.messageType]) {
						if (![self processBEEPGreeting:aMessage dataParser:dataParser]) {
							[[self session] terminate];
						}
					}
				} else {
					[[self session] terminate];
				}
				I_firstMessage = NO;
			} else {
				if ([@"profile" isEqualToString:dataParser.messageType]) {
					DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found profile element...");
					if (![self processBEEPProfileMessage:aMessage dataParser:dataParser]) {
						[[self session] terminate];
					}
				} else if ([@"ok" isEqualToString:dataParser.messageType]) {
					DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found ok element...");
					if (![self processBEEPOKMessage:aMessage]) {
						[[self session] terminate];
					}
				}  else {
					[[self session] terminate];
				}
			}
		} else if ([aMessage isERR]) {
			if ([@"error" isEqualToString:dataParser.messageType]) {
				DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found error element...");
				if (![self processBEEPErrorMessage:aMessage]) {
					[[self session] terminate];
				}
			} else {
				[[self session] terminate];
			}

			if (I_firstMessage) {
				[[self session] terminate];
			}
		} else {
			[[self session] terminate];
		}
	}
}

@end
