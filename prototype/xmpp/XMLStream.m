//
//  XMLStream.m
//  xmpp
//
//  Created by Martin Ott on Wed Nov 12 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "XMLStream.h"
#import "XMLParser.h"
#import "Node.h"

@implementation XMLStream

- (id)init
{
    self = [super init];
    
    if (self) {
        I_readBuffer = [[NSMutableData alloc] init];
        I_writeBuffer = [[NSMutableData alloc] init];
        I_parser = [[XMLParser alloc] init];
        [I_parser setDelegate:self];
        I_node = nil;
        I_depth = 0;
    }
    
    return self;
}

- (void)dealloc
{
    [I_readBuffer release];
    [I_writeBuffer release];
    [I_inputStream release];
    [I_outputStream release];
    [I_parser release];
    [super dealloc];
}

- (void)connectToHost:(NSHost *)aHost
{
    [NSStream getStreamsToHost:aHost
                          port:5222
                   inputStream:&I_inputStream
                  outputStream:&I_outputStream];
                  
    [I_inputStream setDelegate:self];
    [I_outputStream setDelegate:self];
    
    [I_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                             forMode:NSDefaultRunLoopMode];
    [I_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
    
    [I_inputStream open];
    [I_outputStream open];
}

- (void)disconnect
{
    NSString *endElement = @"</stream>";
    [self writeData:[endElement dataUsingEncoding:NSUTF8StringEncoding]];
    
    [I_outputStream close];
    [I_inputStream close];
}

- (void)writeData:(NSData *)aData
{
    if ([aData length] == 0)
        return;
        
    [I_writeBuffer appendData:aData];
    
    if ([I_outputStream hasSpaceAvailable]) {
        [self writeBytes];
    }
}

- (void)readBytes
{
    UInt8 buffer[8192];

    int bytesRead = [I_inputStream read:buffer maxLength:sizeof(buffer)];
    
    if (bytesRead > 0) {
        [I_readBuffer appendBytes:buffer length:bytesRead];
        
        [I_parser parseData:I_readBuffer moreComing:YES];
        [I_readBuffer setLength:0];
        //NSString *string = [[NSString alloc] initWithBytes:&buffer length:bytesRead encoding:NSUTF8StringEncoding];
        //[string autorelease];
        //fprintf(stdout, [string UTF8String]);
        //fflush(stdout);
    }
}

- (void)writeBytes
{
    if (!([I_writeBuffer length] > 0))
        return;
        
    int bytesWritten = [I_outputStream write:[I_writeBuffer bytes] maxLength:[I_writeBuffer length]];

    if (bytesWritten > 0) {
        [I_writeBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
    } else if (bytesWritten < 0) {
        NSLog(@"Error occurred while writing bytes.");
    } else {
        NSLog(@"Stream has reached its capacity");
    }
}

- (void)handleInputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            NSLog(@"Input stream open completed.");
            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"Input stream has bytes available.");
            [self readBytes];
            break;
        case NSStreamEventErrorOccurred: {
                NSError *error = [I_inputStream streamError];
                NSLog(@"An error occurred on the input stream: %@", [error localizedDescription]);
                NSLog(@"Domain: %@, Code: %d", [error domain], [error code]);
            }
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"Input stream end encountered.");
            break;
        default:
            NSLog(@"Input stream not handling this event: %d", streamEvent);
            break;
    }
}

- (void)handleOutputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            NSLog(@"Output stream open completed.");
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Output stream has space available.");
            [self writeBytes];
            break;
        case NSStreamEventErrorOccurred: {
                NSError *error = [I_outputStream streamError];
                NSLog(@"An error occurred on the output stream: %@", [error localizedDescription]);
                NSLog(@"Domain: %@, Code: %d", [error domain], [error code]);
            }
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"Output stream end encountered.");
            break;
        default:
            NSLog(@"Output stream not handling this event: %d", streamEvent);
            break;
    }
}

#pragma mark -

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    if (theStream == I_inputStream) {
        [self handleInputStreamEvent:streamEvent];
    } else if (theStream == I_outputStream) {
        [self handleOutputStreamEvent:streamEvent];
    }
}

#pragma mark -

- (void)streamParser:(XMLParser *)parser didStartElement:(NSString *)elementName 
        namespaceURI:(NSString *)namespaceURI attributes:(NSDictionary *)attributeDict
{
    NSLog(@"streamParser:%@ didStartElement:%@ namespaceURI:%@ attributes:%@", parser, elementName, namespaceURI, attributeDict);
    
    if (I_depth == 0) {
        I_streamNode = [[Node alloc] init];
        [I_streamNode setName:elementName];
        [I_streamNode setNamespaceURI:namespaceURI];
        [I_streamNode setAttributes:attributeDict];
        [I_streamNode setParent:nil];
        I_node = I_streamNode;
    } else if (I_depth == 1) {
        I_stanzaNode = [[Node alloc] init];
        [I_stanzaNode setName:elementName];
        [I_stanzaNode setNamespaceURI:namespaceURI];
        [I_stanzaNode setAttributes:attributeDict];
        [I_stanzaNode setParent:nil];
        I_node = I_stanzaNode;
    } else if (I_depth > 1) {
        Node *node = [[Node alloc] init];
        [node setName:elementName];
        [node setNamespaceURI:namespaceURI];
        [node setAttributes:attributeDict];
        [node setParent:I_node];
        [I_node addChild:node];
        I_node = node;
    }
    
    I_depth++;
}

- (void)streamParser:(XMLParser *)parser didEndElement:(NSString *)elementName 
        namespaceURI:(NSString *)namespaceURI
{
    NSLog(@"streamParser:%@ didEndElement:%@ namespaceURI:%@", parser, elementName, namespaceURI);
    
    if (I_depth > 2) {
        I_node = [I_node parent];
    } else if (I_depth == 2) {
        I_node = I_streamNode;
        NSLog(@"Parsed stanza: %@", I_stanzaNode);
    } else if (I_depth == 1) {
        I_node = nil;
    }
    
    I_depth--;
}

- (void)streamParser:(XMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI
{
    NSLog(@"streamParser:%@ didStartMappingPrefix:%@ toURI:%@", parser, prefix, namespaceURI);
}

- (void)streamParser:(XMLParser *)parser didEndMappingPrefix:(NSString *)prefix
{
    NSLog(@"streamParser:%@ didEndMappingPrefix:%@", parser, prefix);
}

- (void)streamParser:(XMLParser *)parser foundCharacters:(NSString *)string
{
    NSLog(@"streamParser:%@ foundCharacters:%@", parser, string);
}

- (void)streamParser:(XMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    NSLog(@"streamParser:%@ foundCDATA:%@", parser, CDATABlock);
}

- (void)streamParser:(XMLParser *)parser didFailWithReason:(NSString *)errorString
{
    NSLog(@"streamParser:%@ didFailWithReason:%@", parser, errorString);
}

@end
