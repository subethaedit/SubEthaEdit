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

@implementation TCMBEEPManagementProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super initWithChannel:aChannel];
    if (self) {
        NSLog(@"Initialized TCMBEEPManagmentProfile");
        I_firstMessage = YES;
        I_pendingChannelRequestMessageNumbers = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [I_pendingChannelRequestMessageNumbers release];
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
}

- (void)startChannelNumber:(int32_t)aChannelNumber withProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray
{
    // compose start message
    NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<start number='%d'>", aChannelNumber] dataUsingEncoding:NSUTF8StringEncoding]];
    int i=0;
    for (i=0; i<[aProfileURIArray count]; i++) {
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

#pragma mark -

- (void)setDelegate:(id)aDelegate
{
    I_delegate = aDelegate;
}

- (id)delegate
{
    return I_delegate;
}

- (void)setChannel:(TCMBEEPChannel *)aChannel
{
    I_channel = aChannel;
}

- (TCMBEEPChannel *)channel
{
    return I_channel;
}

#pragma mark -

- (void)_processGreeting:(TCMBEEPMessage *)aMessage XMLTree:(CFXMLTreeRef) aContentTree 
{
    BOOL malformedGreeting = YES;
    if ([[aMessage messageTypeString] isEqualTo:@"RPY"] &&
        [aMessage messageNumber] == 0) {
                    
        int childCount = CFTreeGetChildCount(aContentTree);
        int index;
        for (index = 0; index < childCount; index++) {
            CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aContentTree, index);
            CFXMLNodeRef node = CFXMLTreeGetNode(xmlTree);
            if (CFXMLNodeGetTypeCode(node) == kCFXMLNodeTypeElement) {
                if ([@"greeting" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                    NSLog (@"Was greeting....");
                    CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(node);
                    NSDictionary *attributes = (NSDictionary *)info->attributes;
                    NSLog (@"Attributes: %@", [attributes description]);

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
                    malformedGreeting = NO;
                }
            }
        }            
    } 
    if (malformedGreeting) {
        // teardown session
        // ERROR
    }
}

- (void)_proccessStartMessage:(TCMBEEPMessage *)aMessage XMLSubTree:(CFXMLTreeRef) aSubTree {
    CFXMLNodeRef startNode = CFXMLTreeGetNode(aSubTree);
    CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(startNode);
    NSDictionary *attributes = (NSDictionary *)info->attributes;
    int32_t channelNumber = -1;
    if ([attributes objectForKey:@"number"]) {
        channelNumber = [[attributes objectForKey:@"number"] intValue];
    } else {
        // nixe number
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
    DEBUGLOG(@"BEEP",7,@"possible profile URIs are:%@",[profileURIs description]);
    NSDictionary *reply = [[self delegate] preferedAnswerToAcceptRequestForChannel:channelNumber withProfileURIs:profileURIs andData:dataArray]; 
    DEBUGLOG(@"BEEP",7,@"reply is:%@",[reply description]);
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
        NSLog(@"juhuhh... sent accept: %@",message);
        [[self delegate] initiateChannelWithNumber:channelNumber profileURI:[reply objectForKey:@"ProfileURI"]];
    } else {
        NSMutableData *payload = [NSMutableData dataWithData:[[NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<error code='501'>channel request denied</error>"] dataUsingEncoding:NSUTF8StringEncoding]];
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:payload];
        [[self channel] sendMessage:[message autorelease]];
    }
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    // remove MIME Header
    NSData *contentData = [aMessage payload];
    // find "\r\n\r\n"
    int i;
    uint8_t *bytes = (uint8_t *)[contentData bytes];
    for (i=0; i<[contentData length]-4; i++) {
        if (bytes[i] == '\r') {
            if (strncmp(&bytes[i], "\r\n\r\n",4) == 0) {
                break;
            }
        }
    }
    if (i < [contentData length]) {
        contentData = [NSData dataWithBytesNoCopy:&bytes[i+4] length:[contentData length]-i-4 freeWhenDone:NO];
    }
    DEBUGLOG(@"BEEP",9,@"%@",[NSString stringWithCString:[[aMessage payload] bytes] length:[[aMessage payload] length]]);
    // Parse XML
    CFXMLTreeRef contentTree = NULL;
    NSDictionary *errorDict;
    
    contentTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,
        (CFDataRef)contentData,
        NULL, //sourceURL
        kCFXMLParserSkipWhitespace | kCFXMLParserSkipMetaData,
        kCFXMLNodeCurrentVersion,
        (CFDictionaryRef *)&errorDict);
    if (!contentTree) {
        NSLog(@"nixe baum: %@", [errorDict description]);
        CFRelease(contentTree);
        return;
    }        
    
    if (I_firstMessage) {
        [self _processGreeting:aMessage XMLTree:contentTree];
        I_firstMessage = NO;
    } else {
        // "Normalbetrieb"        
        int childCount = CFTreeGetChildCount(contentTree);
        int index;
        for (index = 0; index < childCount; index++) {
            CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(contentTree, index);
            CFXMLNodeRef node = CFXMLTreeGetNode(xmlTree);
            if (CFXMLNodeGetTypeCode(node) == kCFXMLNodeTypeElement) {
                if ([@"start" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                    DEBUGLOG(@"BEEP",5,@"Was Start... %@",@"blah");
                    [self _proccessStartMessage:aMessage XMLSubTree:xmlTree];
                } else if ([@"profile" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                    DEBUGLOG(@"BEEP",5,@"Was Profile... %@",@"blah");
                    CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(node);
                    NSDictionary *attributes = (NSDictionary *)info->attributes;
                    NSString *URI;
                    if ((URI = [attributes objectForKey:@"uri"])) {
                        [[self delegate] didReceiveAcceptStartRequestForChannel:[[I_pendingChannelRequestMessageNumbers objectForLong:[aMessage messageNumber]] longValue] withProfileURI:URI andData:[NSData data]];
                    }
                } else {
                    DEBUGLOG(@"BEEP",4,@"%@",@"WARUM?");
                }
            } else {
                // kein kCFXMLNodeTypeElement node
            }
        }
    }
    CFRelease(contentTree);
}

@end
