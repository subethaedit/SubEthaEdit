//
//  TCMBEEPManagementProfile.m
//  TCMBEEP
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPManagementProfile.h"
#import "TCMBEEPMessage.h"
#import "TCMBEEPChannel.h"
#import "TCMBEEPSession.h"
#import <CoreFoundation/CoreFoundation.h>


@interface TCMBEEPManagementProfile (TCMBEEPManagementProfilePrivateAdditions)

- (BOOL)TCM_processGreeting:(TCMBEEPMessage *)aMessage XMLTree:(CFXMLTreeRef)aContentTree;
- (BOOL)TCM_proccessStartMessage:(TCMBEEPMessage *)aMessage XMLSubTree:(CFXMLTreeRef)aSubTree;
- (BOOL)TCM_processProfileMessage:(TCMBEEPMessage *)aMessage XMLSubTree:(CFXMLTreeRef)aSubTree;
- (BOOL)TCM_proccessCloseMessage:(TCMBEEPMessage *)aMessage XMLSubTree:(CFXMLTreeRef)aSubTree;
- (BOOL)TCM_processOKMessage:(TCMBEEPMessage *)aMessage;

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
    NSEnumerator *profileURIs = [anArray objectEnumerator];
    NSString *profileURI = nil;
    while ((profileURI = [profileURIs nextObject])) {
        [payloadString appendFormat:@"<profile uri=\"%@\" />", profileURI];
    }
    [payloadString appendString:@"</greeting>\r\n"];
    NSData *payload = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[[self channel] nextMessageNumber] payload:payload];
    [[self channel] sendMessage:[message autorelease]];
    
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

#pragma mark -

- (BOOL)TCM_processGreeting:(TCMBEEPMessage *)aMessage XMLTree:(CFXMLTreeRef)aContentTree 
{
    BOOL result = NO;
                    
    int childCount = CFTreeGetChildCount(aContentTree);
    int index;
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aContentTree, index);
        CFXMLNodeRef node = CFXMLTreeGetNode(xmlTree);
        if (CFXMLNodeGetTypeCode(node) == kCFXMLNodeTypeElement) {
            if ([@"greeting" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Was greeting....");
                CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(node);
                NSDictionary *attributes = (NSDictionary *)info->attributes;
                //NSLog (@"Attributes: %@", [attributes description]);

                NSMutableArray *profileURIs = [NSMutableArray array];
                int profileCount = CFTreeGetChildCount(xmlTree);
                int profileIndex;
                for (profileIndex = 0; profileIndex < profileCount; profileIndex++) {
                    CFXMLTreeRef profileSubTree = CFTreeGetChildAtIndex(xmlTree,profileIndex);
                    CFXMLNodeRef profileNode = CFXMLTreeGetNode(profileSubTree);
                    if (CFXMLNodeGetTypeCode(profileNode) == kCFXMLNodeTypeElement) {
                        if ([@"profile" isEqualToString:(NSString *)CFXMLNodeGetString(profileNode)]) {
                            CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(profileNode);
                            NSDictionary *attributes = (NSDictionary *)info->attributes;
                            NSString *URI;
                            if ((URI = [attributes objectForKey:@"uri"]))
                                [profileURIs addObject:URI];
                        }
                    }
                }                        
                [[self delegate] didReceiveGreetingWithProfileURIs:profileURIs 
                    featuresAttribute:[attributes objectForKey:@"features"] 
                    localizeAttribute:[attributes objectForKey:@"localize"]];
                result = YES;
            }
        }
    } 
                   
    return result;
}

- (BOOL)TCM_proccessStartMessage:(TCMBEEPMessage *)aMessage XMLSubTree:(CFXMLTreeRef)aSubTree
{
    CFXMLNodeRef startNode = CFXMLTreeGetNode(aSubTree);
    CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(startNode);
    NSDictionary *attributes = (NSDictionary *)info->attributes;
    int32_t channelNumber = -1;
    if ([attributes objectForKey:@"number"]) {
        channelNumber = [[attributes objectForKey:@"number"] intValue];
    } else {
        return NO;
    }
    NSMutableArray *profileURIs = [NSMutableArray array];
    NSMutableArray *dataArray = [NSMutableArray array];
    int profileCount = CFTreeGetChildCount(aSubTree);
    int profileIndex;
    for (profileIndex = 0; profileIndex < profileCount; profileIndex++) {
        CFXMLTreeRef profileSubTree = CFTreeGetChildAtIndex(aSubTree,profileIndex);
        CFXMLNodeRef profileNode = CFXMLTreeGetNode(profileSubTree);
        if (CFXMLNodeGetTypeCode(profileNode) == kCFXMLNodeTypeElement) {
            if ([@"profile" isEqualToString:(NSString *)CFXMLNodeGetString(profileNode)]) {
                CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(profileNode);
                NSDictionary *attributes = (NSDictionary *)info->attributes;
                NSString *URI;
                if ((URI = [attributes objectForKey:@"uri"])) {
                    [profileURIs addObject:URI];
                    int profileContentCount = CFTreeGetChildCount(profileSubTree);
                    int profileContentIndex=0;
                    NSData *contentData = [NSData data];
                    for (profileContentIndex = 0; profileContentIndex < profileContentCount; profileContentIndex++) {
                        CFXMLTreeRef profileContentSubTree = CFTreeGetChildAtIndex(profileSubTree, profileContentIndex);
                        CFXMLNodeRef profileContentNode    = CFXMLTreeGetNode(profileContentSubTree);
                        if (CFXMLNodeGetTypeCode(profileContentNode) == kCFXMLNodeTypeCDATASection) {
                            NSString *profileContent = (NSString *)CFXMLNodeGetString(profileContentNode);
                            contentData = [profileContent dataUsingEncoding:NSUTF8StringEncoding];
                        }
                    }
                    [dataArray addObject:contentData];
                }
            }
        }
    }                        
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"possible profile URIs are: %@", [profileURIs description]);
    NSDictionary *reply = [[self delegate] preferedAnswerToAcceptRequestForChannel:channelNumber withProfileURIs:profileURIs andData:dataArray]; 
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"reply is:%@",[reply description]);
    if (reply) {
        // juhuh... send accept
        NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        
        if ([(NSData *)[reply objectForKey:@"Data"] length]) {
            [payload appendData:[[NSString stringWithFormat:@"<profile uri='%@'><![CDATA[", [reply objectForKey:@"ProfileURI"]] dataUsingEncoding:NSUTF8StringEncoding]];
            [payload appendData:[reply objectForKey:@"Data"]];
            [payload appendData:[@"]]></profile>" dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            [payload appendData:[[NSString stringWithFormat:@"<profile uri='%@' />", [reply objectForKey:@"ProfileURI"]] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:payload];
        [[self channel] sendMessage:[message autorelease]];
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"juhuhh... sent accept: %@",message);
        [[self delegate] initiateChannelWithNumber:channelNumber profileURI:[reply objectForKey:@"ProfileURI"] data:[reply objectForKey:@"Data"] asInitiator:NO];
    } else {
        NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<error code='501'>channel request denied</error>"] dataUsingEncoding:NSUTF8StringEncoding]];
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:payload];
        [[self channel] sendMessage:[message autorelease]];
    }
    
    return YES;
}

- (BOOL)TCM_processProfileMessage:(TCMBEEPMessage *)aMessage XMLSubTree:(CFXMLTreeRef)aSubTree
{
    CFXMLNodeRef startNode = CFXMLTreeGetNode(aSubTree);
    CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(startNode);
    NSDictionary *attributes = (NSDictionary *)info->attributes;
    
    int profileContentCount = CFTreeGetChildCount(aSubTree);
    int profileContentIndex = 0;
    NSData *contentData = [NSData data];
    for (profileContentIndex = 0; profileContentIndex < profileContentCount; profileContentIndex++) {
        CFXMLTreeRef profileContentSubTree = CFTreeGetChildAtIndex(aSubTree, profileContentIndex);
        CFXMLNodeRef profileContentNode    = CFXMLTreeGetNode(profileContentSubTree);
        if (CFXMLNodeGetTypeCode(profileContentNode) == kCFXMLNodeTypeCDATASection) {
            NSString *profileContent = (NSString *)CFXMLNodeGetString(profileContentNode);
            contentData = [profileContent dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    NSString *URI;
    if ((URI = [attributes objectForKey:@"uri"])) {
        [[self delegate] didReceiveAcceptStartRequestForChannel:[[I_pendingChannelRequestMessageNumbers objectForLong:[aMessage messageNumber]] longValue] withProfileURI:URI andData:contentData];
    } else {
        return NO;
    }
                
    return YES;
}

- (BOOL)TCM_proccessCloseMessage:(TCMBEEPMessage *)aMessage XMLSubTree:(CFXMLTreeRef)aSubTree
{
    CFXMLNodeRef closeNode = CFXMLTreeGetNode(aSubTree);
    CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(closeNode);
    NSDictionary *attributes = (NSDictionary *)info->attributes;
    NSNumber *number = [attributes objectForKey:@"number"];
    NSNumber *code = [attributes objectForKey:@"code"];
    
    if (number && code) {
        // close request for a specific channel
        int32_t channelNumber = [number intValue];
        [I_channelNumbersByCloseRequests setObject:[NSNumber numberWithLong:channelNumber] forLong:[aMessage messageNumber]];
        [I_messageNumbersOfCloseRequestsByChannelsNumbers setObject:[NSNumber numberWithLong:[aMessage messageNumber]] forLong:channelNumber];
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Close requested for channel number: %d", channelNumber);
        [[self session] closeRequestedForChannelWithNumber:channelNumber];
    } else if ((number == nil || [number intValue] == 0) && code) {
        // close request for the session
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Close requested for session");
        NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<ok />"] dataUsingEncoding:NSUTF8StringEncoding]];
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:payload];
        [[self channel] sendMessage:[message autorelease]];
        [[self session] terminate];
    } else {
        // invalid close request
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Received invalid close request");
        return NO;
    }
    
    return YES;
}

- (BOOL)TCM_processOKMessage:(TCMBEEPMessage *)aMessage
{
    int32_t channelNumber = [[I_channelNumbersByCloseRequests objectForLong:[aMessage messageNumber]] longValue];
    [[self delegate] closedChannelWithNumber:channelNumber];
    return YES;
}

- (BOOL)TCM_processErrorMessage:(TCMBEEPMessage *)aMessage
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
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, [NSString stringWithCString:[[aMessage payload] bytes] length:[[aMessage payload] length]]);
    // Parse XML
    CFXMLTreeRef contentTree = NULL;
    NSDictionary *errorDict;
    
    // create XML tree from payload
    contentTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,
                                (CFDataRef)contentData,
                                NULL, //sourceURL
                                kCFXMLParserSkipWhitespace | kCFXMLParserSkipMetaData,
                                kCFXMLNodeCurrentVersion,
                                (CFDictionaryRef *)&errorDict);
    if (!contentTree) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"nixe baum: %@", [errorDict description]);
        [[self session] terminate]; 
        return;
    }        
    
    // extract top level element from tree
    CFXMLNodeRef node = NULL;
    CFXMLTreeRef xmlTree = NULL;
    int childCount = CFTreeGetChildCount(contentTree);
    int index;
    for (index = 0; index < childCount; index++) {
        xmlTree = CFTreeGetChildAtIndex(contentTree, index);
        node = CFXMLTreeGetNode(xmlTree);
        if (CFXMLNodeGetTypeCode(node) == kCFXMLNodeTypeElement) {
            break;
        }
    }
    if (!xmlTree || !node || CFXMLNodeGetTypeCode(node) != kCFXMLNodeTypeElement) {
        [[self session] terminate];
        return;
    }


    if ([aMessage isMSG]) {
        if (I_firstMessage) {
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Error: First message was from type MSG");
            [[self session] terminate];
        } else {
            if ([@"start" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found start element...");
                [self TCM_proccessStartMessage:aMessage XMLSubTree:xmlTree];
            } else if ([@"close" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found close element...");
                [self TCM_proccessCloseMessage:aMessage XMLSubTree:xmlTree];
            } else {
                [[self session] terminate];
            }
        }
    } else if ([aMessage isRPY]) {
        if (I_firstMessage) {
            if ([aMessage messageNumber] == 0) { 
                if (![self TCM_processGreeting:aMessage XMLTree:contentTree]) {
                    [[self session] terminate];
                }
            } else {
                [[self session] terminate];
            }
            I_firstMessage = NO;
        } else {
            if ([@"profile" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found profile element...");
                if (![self TCM_processProfileMessage:aMessage XMLSubTree:xmlTree]) {
                    [[self session] terminate];
                }                
            } else if ([@"ok" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found ok element...");
                if (![self TCM_processOKMessage:aMessage]) {
                    [[self session] terminate];
                }
            }  else {
                [[self session] terminate];
            }
        }
    } else if ([aMessage isERR]) {
        if ([@"error" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Found error element...");
            if (![self TCM_processErrorMessage:aMessage]) {
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

    CFRelease(contentTree);
}

@end
