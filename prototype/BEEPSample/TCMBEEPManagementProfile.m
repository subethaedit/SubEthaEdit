//
//  TCMBEEPManagementProfile.m
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPManagementProfile.h"
#import "TCMBEEPMessage.h"
#import "TCMBEEPChannel.h"
#import <CoreFoundation/CoreFoundation.h>

@implementation TCMBEEPManagementProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super init];
    if (self) {
        NSLog(@"Initialized TCMBEEPManagmentProfile");
        [self setChannel:aChannel];
        I_firstMessage = YES;
    }
    return self;
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
    TCMBEEPMessage *message=[[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:0 payload:payload];
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

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    if (I_firstMessage) {
        if ([[aMessage messageTypeString] isEqualTo:@"RPY"] &&
            [aMessage messageNumber] == 0) {
            // Parse
            NSData *contentData = [aMessage payload];
            NSLog(@"Payload of Message was: %@", [[[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding] autorelease]);
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
            
            CFXMLTreeRef cfXMLTree = NULL;
            NSDictionary *errorDict;
            
            cfXMLTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,
                (CFDataRef)contentData,
                NULL, //sourceURL
                kCFXMLParserSkipWhitespace | kCFXMLParserSkipMetaData,
                kCFXMLNodeCurrentVersion,
                (CFDictionaryRef *)&errorDict);
            
            if (!cfXMLTree) {
                NSLog(@"nixe baum: %@", [errorDict description]);
            }        
            int childCount = CFTreeGetChildCount(cfXMLTree);
            int index;
            for (index = 0; index < childCount; index++) {
                CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(cfXMLTree, index);
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
                        NSLog(@"Profiles: %@", profileURIs);
                        
                        [[self delegate] didReceiveGreetingWithProfileURIs:profileURIs 
                            featuresAttribute:[attributes objectForKey:@"features"] 
                            localizeAttribute:[attributes objectForKey:@"localize"]];
                    }
                }
            }
            
            CFRelease(cfXMLTree);
            
            NSLog(@"Content of Message was: %@",[[[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding] autorelease]);
            
            
        } else {
            // ERROR
        }
    
        I_firstMessage = NO;
    } else {
        // teardown session
    }
        
}

@end
