//
//  TCMBEEPSession.m
//  BEEPSample
//
//  Created by Martin Ott on Mon Feb 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPSession.h"
#import "TCMBEEPChannel.h"
#import "TCMBEEPFrame.h"
#import "TCMBEEPManagementProfile.h"

#import <netinet/in.h>
#import <sys/socket.h>


NSString * const kTCMBEEPFrameTrailer = @"END\r\n";
NSString * const kTCMBEEPManagementProfile = @"http://www.codingmonkeys.de/Beep/Management.profile";


@interface TCMBEEPSession (TCMBEEPSessionPrivateAdditions)
- (void)TCM_initHelper;
- (void)TCM_handleInputStreamEvent:(NSStreamEvent)streamEvent;
- (void)TCM_handleOutputStreamEvent:(NSStreamEvent)streamEvent;
- (void)TCM_writeData:(NSData *)aData;
- (void)TCM_readBytes;
- (void)TCM_writeBytes;
@end

#pragma mark -

@implementation TCMBEEPSession

- (void)TCM_initHelper
{
    [I_inputStream setDelegate:self];
    [I_outputStream setDelegate:self];
    
    I_profileURIs = [NSMutableArray new];
    I_peerProfileURIs = [NSMutableArray new];
    
    I_readBuffer = [NSMutableData new];
    I_currentReadState=frameHeaderState;
    I_writeBuffer = [NSMutableData new];
    I_requestedChannels = [NSMutableDictionary new];
    I_activeChannels = [NSMutableDictionary new];
    I_currentReadFrame = nil;
}

- (id)initWithSocket:(CFSocketNativeHandle)aSocketHandle addressData:(NSData *)aData
{
    self = [super init];
    if (self) {
        [self setPeerAddressData:aData];
        
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, aSocketHandle, (CFReadStreamRef *)&I_inputStream, (CFWriteStreamRef *)&I_outputStream);
        I_flags.isInitiator = NO;
        I_nextChannelNumber = 0;
        [self TCM_initHelper];        
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
        I_flags.isInitiator = YES;
        I_nextChannelNumber = -1;
        [self TCM_initHelper];
    }
    
    return self;
}

- (void)dealloc
{
    [I_readBuffer release];
    [I_writeBuffer release];
    [I_inputStream release];
    [I_outputStream release];
    [I_profileURIs release];
    [I_peerProfileURIs release];
    [I_currentReadFrame release];
    [super dealloc];
}

- (NSString *)description
{    
    return [NSString stringWithFormat:@"BEEPSession with address: %@", [NSString stringWithAddressData:I_peerAddressData]];
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

- (void)setProfileURIs:(NSArray *)anArray
{
    [I_profileURIs autorelease];
    I_profileURIs = [anArray copy];
}

- (NSArray *)profileURIs
{
    return I_profileURIs;
}

- (void)setPeerProfileURIs:(NSArray *)anArray
{
    [I_peerProfileURIs autorelease];
    I_peerProfileURIs = [anArray copy];
}

- (NSArray *)peerProfileURIs
{
    return I_peerProfileURIs;
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
    return I_flags.isInitiator;
}

- (NSMutableDictionary *)activeChannels
{
    return I_activeChannels;
}

- (int32_t)nextChannelNumber {
    I_nextChannelNumber+=2;
    return I_nextChannelNumber;
}

- (void)activateChannel:(TCMBEEPChannel *)aChannel
{
    [I_activeChannels setObject:aChannel forKey:[NSNumber numberWithUnsignedLong:[aChannel number]]];
}

- (void)open
{
    [I_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                             forMode:NSDefaultRunLoopMode];
    [I_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
    
    [I_inputStream open];
    [I_outputStream open];
    
    
    I_managementChannel = [[TCMBEEPChannel alloc] initWithSession:self number:0 profileURI:kTCMBEEPManagementProfile];
    TCMBEEPManagementProfile *profile=(TCMBEEPManagementProfile *)[I_managementChannel profile];
    [profile setDelegate:self];

    [self activateChannel:I_managementChannel];

    [profile sendGreetingWithProfileURIs:[self profileURIs] featuresAttribute:nil localizeAttribute:nil];
    
//    NSString *greeting = @"Content-Type: application/beep+xml\r\n\r\n<greeting features=\"token1 token2\" localize=\"de fr cz\" invalid=\"haha\"><profile uri='http://codingmonkeys.de/beep/BEEPBLEEP' /></greeting>\r\n";
//    greeting = [NSString stringWithFormat:@"RPY 0 0 . 0 %d\r\n%@%@", [greeting length], greeting, kTCMBEEPFrameTrailer];
//    NSData *greetingData = [greeting dataUsingEncoding:NSASCIIStringEncoding];
//    [self TCM_writeData:greetingData];
//    
//    greeting = @"Content-Type: application/beep+xml\r\n\r\n<greeting><profile uri='http://codingmonkeys.de/beep/BEEPBLEEP' /></greeting>\r\n";
//    greeting = [NSString stringWithFormat:@"RPY 0 0 . 0 %d\r\n%@%@", [greeting length], greeting, kTCMBEEPFrameTrailer];
//    greetingData = [greeting dataUsingEncoding:NSASCIIStringEncoding];
//    [self TCM_writeData:greetingData];
}

- (void)close
{
    [I_outputStream close];
    [I_inputStream close];
}

- (void)TCM_writeData:(NSData *)aData
{
    if ([aData length] == 0)
        return;
        
    [I_writeBuffer appendData:aData];
    
    if ([I_outputStream hasSpaceAvailable]) {
        [self TCM_writeBytes];
    }
}

- (void)TCM_readBytes
{
    int8_t buffer[8192];

    int bytesRead = [I_inputStream read:buffer maxLength:sizeof(buffer)];
    int bytesParsed = 0;
    
    NSLog(@"bytesRead: %@", [NSString stringWithCString:buffer length:bytesRead]);
    while (bytesRead > 0 && bytesRead-bytesParsed > 0) {
        int remainingBytes=bytesRead-bytesParsed;
        if (I_currentReadState==frameHeaderState) {
            int i;
            // search for 0x0a (LF)
            for (i=bytesParsed;i<bytesRead;i++) {
                if (buffer[i] == 0x0a) {
                    buffer[i] = 0x00;
                    break;
                }
            }
            if (i < bytesRead) {
                // found LF
                [I_readBuffer appendBytes:&buffer[bytesParsed] length:i-bytesParsed+1];
                I_currentReadFrame = [[TCMBEEPFrame alloc] initWithHeader:(char *)[I_readBuffer bytes]];
                if (!I_currentReadFrame) {
                    // ERRRRRRRRRROR
                } else {
                    I_currentReadState = frameContentState;
                    I_currentReadFrameRemainingContentSize = [I_currentReadFrame length];
                    [I_readBuffer setLength:0];
                    bytesParsed = i+1;
                    continue;
                }
            } else {
                // didn't find LF
                [I_readBuffer appendBytes:&buffer[bytesParsed] length:remainingBytes];
                bytesParsed = bytesRead;
            }
        } else if (I_currentReadState == frameContentState) {
            if (remainingBytes < I_currentReadFrameRemainingContentSize) {
                [I_readBuffer appendBytes:&buffer[bytesParsed] length:remainingBytes];
                I_currentReadFrameRemainingContentSize -= remainingBytes;
                bytesParsed = bytesRead;
            } else {
                [I_readBuffer appendBytes:&buffer[bytesParsed] length:I_currentReadFrameRemainingContentSize];
                [I_currentReadFrame setPayload:I_readBuffer];
                NSLog(@"Found Frame: %@", [I_currentReadFrame description]);
                [I_readBuffer setLength:0];
                bytesParsed += I_currentReadFrameRemainingContentSize;
                I_currentReadState = frameEndState;
                continue;
            }
        } else if (I_currentReadState==frameEndState) {
            if (remainingBytes + [I_readBuffer length] >= 5) {
                [I_readBuffer appendBytes:&buffer[bytesParsed] length:5-[I_readBuffer length]];
                // I_readBuffer == "END\r\n" ?
                // dispatch frame!
                TCMBEEPChannel *channel = [[self activeChannels] objectForLong:[I_currentReadFrame channelNumber]];
                if (channel) {
                    //NSLog(@"channel did Accept: %@", [channel acceptFrame:[I_currentReadFrame autorelease]] ? @"YES" : @"NO");
                    DEBUGLOG(@"network", 9, @"channel did Accept: %@", [channel acceptFrame:[I_currentReadFrame autorelease]] ? @"YES" : @"NO");
                    I_currentReadFrame = nil;
                } else {
                    // ERRRRRRORR
                }
                [I_readBuffer setLength:0];
                I_currentReadState = frameHeaderState;
                bytesParsed += 5-[I_readBuffer length];
            } else {
                [I_readBuffer appendBytes:&buffer[bytesParsed] length:remainingBytes];
                bytesParsed = bytesRead;
            }
        }
    }
}

- (void)TCM_writeBytes
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

- (void)TCM_handleInputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            NSLog(@"Input stream open completed.");
            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"Input stream has bytes available.");
            [self TCM_readBytes];
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

- (void)TCM_handleOutputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            NSLog(@"Output stream open completed.");
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Output stream has space available.");
            [self TCM_writeBytes];
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
#pragma mark ### Channel interaction ###

- (void)sendRoundRobin {
    NSEnumerator *channels = [[self activeChannels] objectEnumerator];
    TCMBEEPChannel *channel=nil;
    BOOL didSend = NO;
    while ((channel = [channels nextObject])) {
        if ([channel hasFramesAvailable]) {
            didSend = YES;
            NSEnumerator *frames = [[channel availableFramesFittingInCurrentWindow] objectEnumerator];
            TCMBEEPFrame *frame;
            while ((frame = [frames nextObject])) {
                [frame appendToMutableData:I_writeBuffer];
                NSLog(@"Sending Frame: %@",[frame description]);
            }
        }
    }
    if (didSend) {
        [self performSelector:@selector(sendRoundRobin) withObject:nil afterDelay:0.1];
        if ([I_outputStream hasSpaceAvailable]) {
            [self TCM_writeBytes];
        }
    } else {
        I_flags.isSending=NO;
    }
}

- (void)channelHasFramesAvailable:(TCMBEEPChannel *)aChannel
{
    if (!I_flags.isSending) {
        [self performSelector:@selector(sendRoundRobin) withObject:nil afterDelay:0.01];
        I_flags.isSending=YES;
    }
}

#pragma mark -

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    if (theStream == I_inputStream) {
        [self TCM_handleInputStreamEvent:streamEvent];
    } else if (theStream == I_outputStream) {
        [self TCM_handleOutputStreamEvent:streamEvent];
    }
}

#pragma mark -

- (void)didReceiveGreetingWithProfileURIs:(NSArray *)profileURIs featuresAttribute:(NSString *)aFeaturesAttribute localizeAttribute:(NSString *)aLocalizeAttribute
{
    [self setPeerLocalizeAttribute:aLocalizeAttribute];
    [self setPeerFeaturesAttribute:aFeaturesAttribute];
    [self setPeerProfileURIs:profileURIs];
    if ([[self delegate] respondsToSelector:@selector(BEEPSession:didReceiveGreetingWithProfileURIs:)]) {
        [[self delegate] BEEPSession:self didReceiveGreetingWithProfileURIs:profileURIs];
    }
}

- (NSMutableDictionary *)preferedAnswerToAcceptRequestForChannel:(int32_t)channelNumber withProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray
{
    // Profile URIs ausdŸnnen 
    NSMutableArray *requestArray=[NSMutableArray array];
    NSMutableDictionary *preferedAnswer=nil;
    int i;
    for (i = 0; i<[aProfileURIArray count]; i++) {
        if ([[self profileURIs] containsObject:[aProfileURIArray objectAtIndex:i]]) {
            [requestArray addObject:[NSDictionary dictionaryWithObjectsAndKeys: [aProfileURIArray objectAtIndex:i], @"ProfileURI", [aDataArray objectAtIndex:i], @"Data", nil]];
            if (!preferedAnswer) 
                preferedAnswer=[NSMutableDictionary dictionaryWithObjectsAndKeys: [aProfileURIArray objectAtIndex:i], @"ProfileURI", [NSData data], @"Data", nil];
        }
    }
    // prefered Profile URIs raussuchen
    if (!preferedAnswer) return nil;
    // if channel exists 
    if ([I_activeChannels objectForLong:channelNumber]) return nil;
    // delegate fragen, falls er gefragt werden will
    if ([[self delegate] respondsToSelector:@selector(BEEPSession:willSendReply:forRequests:)]) {
        preferedAnswer = [[self delegate] BEEPSession:self
                willSendReply:preferedAnswer forRequests:requestArray];
    }
    return preferedAnswer;
}

- (void)startChannelWithProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray
{
    [[I_managementChannel profile] startChannelNumber:[self nextChannelNumber] withProfileURIs:aProfileURIArray andData:aDataArray];
}

- (void)didReceiveAcceptStartRequestForChannel:(int32_t)aNumber withProfileURI:(NSString *)aProfileURI andData:(NSData *)aData
{
    NSLog(@"Established channel: %d", aNumber);
}

@end
