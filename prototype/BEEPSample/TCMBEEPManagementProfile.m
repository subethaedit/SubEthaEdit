//
//  TCMBEEPManagementProfile.m
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPManagementProfile.h"
#import "TCMBEEPMessage.h"
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
}

#pragma mark -
#pragma mark ### Accessors ####

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
            [aMessage messageNumber]==0) {
            // Parse
            NSData *contentData=[aMessage payload];
            NSLog(@"Payload of Message was: %@",[[[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding] autorelease]);
            // find "\r\n\r\n"
            int i;
            uint8_t *bytes=(uint8_t *)[contentData bytes];
            for (i=0;i<[contentData length]-4;i++) {
                if (bytes[i]=='\r') {
                    if (strncmp(&bytes[i],"\r\n\r\n",4)==0) {
                        break;
                    }
                }
            }
            if (i<[contentData length]) {
                contentData=[NSData dataWithBytesNoCopy:&bytes[i+4] length:[contentData length]-i-4 freeWhenDone:NO];
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
            // Print the data string for each top-level node.
            for (index = 0; index < childCount; index++) {
                CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(cfXMLTree, index);
                CFXMLNodeRef node = CFXMLTreeGetNode(xmlTree);
                if (CFXMLNodeGetTypeCode(node) == kCFXMLNodeTypeElement) {
                    NSLog(@"node: %@",(NSString *)CFXMLNodeGetString(node));
                }
            }
            
            CFRelease(cfXMLTree);
            
            NSLog(@"Content of Message was: %@",[[[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding] autorelease]);
            
            
        } else {
            // ERROR
        }
    
        I_firstMessage=NO;
    } else {
        // teardown session
    }
        
}

@end
