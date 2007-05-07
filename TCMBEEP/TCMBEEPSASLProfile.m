//
//  TCMBEEPSASLProfile.m
//  SubEthaEdit
//
//  Created by Martin Ott on 4/19/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPSASLProfile.h"
#import "TCMBEEPAuthenticationClient.h"
#import "TCMBEEPAuthenticationServer.h"


@implementation TCMBEEPSASLProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super initWithChannel:aChannel];
    if (self) {
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"Initialized TCMBEEPSASLProfile");
    }
    return self;
}

- (void)startSecondRoundtripWithBlob:(NSData *)inData
{
    NSMutableData *payload = [[NSMutableData alloc] init];
    [payload appendData:[@"Content-Type: application/beep+xml\r\n\r\n<blob>" dataUsingEncoding:NSUTF8StringEncoding]];
    [payload appendData:inData];
    [payload appendData:[@"</blob>" dataUsingEncoding:NSUTF8StringEncoding]];
    
    int32_t messageNumber = [[self channel] nextMessageNumber];
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"MSG" messageNumber:messageNumber payload:payload];
    [payload release];
    [[self channel] sendMessage:message];
    [message release];
}

#pragma mark -

- (BOOL)_processBlobMessage:(TCMBEEPMessage *)message XMLSubTree:(CFXMLTreeRef)subTree
{
    CFXMLNodeRef startNode = CFXMLTreeGetNode(subTree);
    CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(startNode);
    NSDictionary *attributes = (NSDictionary *)info->attributes;
    
    NSString *blobContent = nil;
    int blobContentCount = CFTreeGetChildCount(subTree);
    
    if (blobContentCount == 0 && [[attributes objectForKey:@"status"] isEqualToString:@"complete"]) {
        // Client-only
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"SUCCESSFULLY AUTHENTICATED");
        TCMBEEPAuthenticationClient *authClient = [[self session] authenticationClient];
        [authClient setIsAuthenticated:YES];
    } else {
        int blobContentIndex = 0;
        for (blobContentIndex = 0; blobContentIndex < blobContentCount; blobContentIndex++) {
            CFXMLTreeRef blobContentSubTree = CFTreeGetChildAtIndex(subTree, blobContentIndex);
            CFXMLNodeRef blobContentNode    = CFXMLTreeGetNode(blobContentSubTree);
            if (CFXMLNodeGetTypeCode(blobContentNode) == kCFXMLNodeTypeText) {
                blobContent = (NSString *)CFXMLNodeGetString(blobContentNode);
            }
        }
        
        // Now this is server-only
        if (blobContent) {
            NSData *decodedBase64BlobData = [NSData dataWithBase64EncodedString:blobContent];
            NSString *clientin_string = [NSString stringWithData:decodedBase64BlobData encoding:NSUTF8StringEncoding];
            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"parsed blob: %@", clientin_string);
            
            TCMBEEPAuthenticationServer *authServer = [[self session] authenticationServer];
            [authServer authenticationStepWithBlob:clientin_string message:message];
        }
    }
    
    return YES;
}

- (BOOL)_processErrorMessage:(TCMBEEPMessage *)message XMLSubTree:(CFXMLTreeRef)subTree
{
    CFXMLNodeRef startNode = CFXMLTreeGetNode(subTree);
    CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(startNode);
    NSDictionary *attributes = (NSDictionary *)info->attributes;
    
    int errorContentCount = CFTreeGetChildCount(subTree);
    if (errorContentCount == 1 && [attributes objectForKey:@"code"]) {
        CFXMLTreeRef errorSubTree = CFTreeGetChildAtIndex(subTree, 0);
        CFXMLNodeRef errorTextNode = CFXMLTreeGetNode(errorSubTree);
        if (CFXMLNodeGetTypeCode(errorTextNode) == kCFXMLNodeTypeText) {
            NSString *failureMessage = (NSString *)CFXMLNodeGetString(errorTextNode);
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"Error: %@ (%@)", [attributes objectForKey:@"code"], failureMessage);
        }
    }
    
    return YES;
}

- (void)processBEEPMessage:(TCMBEEPMessage *)message
{
    // remove MIME Header
    NSData *contentData = [message payload];
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
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, [NSString stringWithCString:[[message payload] bytes] length:[[message payload] length]]);
    
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
        //[[self session] terminate];
        #warning Send ERR frame
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
        //[[self session] terminate];
        #warning Send ERR frame
        return;
    }

    if ([message isMSG]) {
        if ([@"blob" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"Found blob element...");
            (void)[self _processBlobMessage:message XMLSubTree:xmlTree];
        }
    } else if ([message isERR]) {
        if ([@"error" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"Found error element...");
            (void)[self _processErrorMessage:message XMLSubTree:xmlTree];
        }
    } else if ([message isRPY]) {
        if ([@"blob" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"Found blob element...");
            (void)[self _processBlobMessage:message XMLSubTree:xmlTree];
        }    
    }
    
    CFRelease(contentTree);
}

@end
