//
//  BEEPSession.m
//  BEEPSample
//
//  Created by Martin Ott on Mon Feb 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "BEEPSession.h"

#import <netinet/in.h>
#import <sys/socket.h>

NSString * const kBEEPFrameTrailer=@"END\r\n";


@interface BEEPSession (BEEPSessionPrivateAdditions)
- (void)handleInputStreamEvent:(NSStreamEvent)streamEvent;
- (void)handleOutputStreamEvent:(NSStreamEvent)streamEvent;
- (void)writeData:(NSData *)aData;
- (void)readBytes;
- (void)writeBytes;
@end

#pragma mark -

@implementation BEEPSession

- (id)initWithSocket:(CFSocketNativeHandle)aSocketHandle addressData:(NSData *)aData
{
    self = [super init];
    if (self) {
        [self setPeerAddressData:aData];
        
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, aSocketHandle, (CFReadStreamRef *)&I_inputStream, (CFWriteStreamRef *)&I_outputStream);
        [I_inputStream  setDelegate:self];
        [I_outputStream setDelegate:self];
        
        NSLog(@"guckst du streams: %@, %@",[I_inputStream description],[I_outputStream description]);
        
        I_readBuffer  = [[NSMutableData alloc] init];
        I_writeBuffer = [[NSMutableData alloc] init];
    }
    
    return self;
}

- (id)initWithAddressData:(NSData *)aData
{
    self = [super init];
    if (self) {
        [self setPeerAddressData:aData];
        CFSocketSignature signature = {PF_INET, SOCK_STREAM, IPPROTO_TCP, (CFDataRef)aData};
        CFStreamCreatePairWithPeerSocketSignature(kCFAllocatorDefault, &signature, (CFReadStreamRef *)&I_inputStream, (CFWriteStreamRef *)&I_outputStream);
        [I_inputStream  setDelegate:self];
        [I_outputStream setDelegate:self];
        
        I_readBuffer  = [[NSMutableData alloc] init];
        I_writeBuffer = [[NSMutableData alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [I_readBuffer release];
    [I_writeBuffer release];
    [I_inputStream release];
    [I_outputStream release];
    [super dealloc];
}

- (NSString *)description
{    
    return [NSString stringWithFormat:@"BEEPSession with address: %@",[NSString stringWithAddressData:I_peerAddressData]];
}

- (void)setDelegate:(id)aDelegate
{
    I_delegate = aDelegate;
}

- (id)delegate
{
    return I_delegate;
}

- (void)setPeerAddressData:(NSData *)aData
{
    [I_peerAddressData autorelease];
     I_peerAddressData = [aData copy];
}

- (NSData *)peerAddressData
{
    return I_peerAddressData;
}

- (void)setFeaturesAttribute:(NSString *)anAttribute
{
    [I_featuresAttribute autorelease];
     I_featuresAttribute = [anAttribute copy];
}

- (NSString *)featuresAttribute
{
    return I_featuresAttribute;
}

- (void)setPeerFeaturesAttribute:(NSString *)anAttribute
{
    [I_peerFeaturesAttribute autorelease];
     I_peerFeaturesAttribute = [anAttribute copy];
}

- (NSString *)peerFeaturesAttribute
{
    return I_peerFeaturesAttribute;
}

- (void)setLocalizeAttribute:(NSString *)anAttribute
{
    [I_localizeAttribute autorelease];
     I_localizeAttribute = [anAttribute copy];
}

- (NSString *)localizeAttribute
{
    return I_peerLocalizeAttribute;
}

- (void)setPeerLocalizeAttribute:(NSString *)anAttribute
{
    [I_peerLocalizeAttribute autorelease];
     I_peerLocalizeAttribute = [anAttribute copy];
}

- (NSString *)peerLocalizeAttribute
{
    return I_peerLocalizeAttribute;
}

- (BOOL)isInitiator
{
    return I_isInitiator;
}


- (void)open
{
    [I_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                             forMode:NSDefaultRunLoopMode];
    [I_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
    
    [I_inputStream open];
    [I_outputStream open];
    
    NSString *greeting=@"Content-Type: application/beep+xml\r\n\r\n<greeting><profile uri='http://codingmonkeys.de/beep/BEEPBLEEP' /></greeting>";
    greeting=[NSString stringWithFormat:@"RPY 0 0 . 0 %d\r\n%@%@",[greeting length],greeting,kBEEPFrameTrailer];
    NSData *greetingData=[greeting dataUsingEncoding:NSASCIIStringEncoding];
    [self writeData:greetingData];
}

- (void)close
{
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
        
        [I_readBuffer setLength:0];
        NSString *string = [[NSString alloc] initWithBytes:&buffer length:bytesRead encoding:NSUTF8StringEncoding];
        [string autorelease];
        fprintf(stdout, [string UTF8String]);
        fflush(stdout);
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

@end
