//
//  TCMBEEPSession.m
//  TCMBEEP
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
#import <sys/sockio.h>  // SIOCGIFMTU
#import <sys/ioctl.h> // ioctl()
#import <net/if.h> // struct ifreq

NSString * const kTCMBEEPFrameTrailer = @"END\r\n";
NSString * const kTCMBEEPManagementProfile = @"http://www.codingmonkeys.de/Beep/Management.profile";


#ifdef TCMBEEP_DEBUG
    static int sInitLogCount = 0;
    static int sListenLogCount = 0;
    static unsigned sNumberOfLogs = 0;
#endif


@interface TCMBEEPSession (TCMBEEPSessionPrivateAdditions)
- (void)TCM_initHelper;
- (void)TCM_handleInputStreamEvent:(NSStreamEvent)streamEvent;
- (void)TCM_handleOutputStreamEvent:(NSStreamEvent)streamEvent;
- (void)TCM_writeData:(NSData *)aData;
- (void)TCM_readBytes;
- (void)TCM_writeBytes;
- (void)TCM_cleanup;
@end

#pragma mark -

@implementation TCMBEEPSession

- (void)TCM_initHelper
{
    [I_inputStream setDelegate:self];
    [I_outputStream setDelegate:self];
    
    // Enable TCP keep alive
    NSData *socketNativeHandleData = [I_inputStream propertyForKey:(NSString *)kCFStreamPropertySocketNativeHandle];
    if (socketNativeHandleData) {
        CFSocketNativeHandle socketNativeHandle;
        [socketNativeHandleData getBytes:&socketNativeHandle length:sizeof(CFSocketNativeHandle)];
        int yes = 1;
        int result = setsockopt(socketNativeHandle, SOL_SOCKET, SO_KEEPALIVE, &yes, sizeof(int));
        if (result == -1) {
            NSLog(@"Failed to enable TCP keep alive!");
        }
    }
                        
    I_profileURIs = [NSMutableArray new];
    I_peerProfileURIs = [NSMutableArray new];
    
    I_readBuffer = [NSMutableData new];
    I_currentReadState=frameHeaderState;
    I_writeBuffer = [NSMutableData new];
    I_requestedChannels = [NSMutableDictionary new];
    I_activeChannels = [NSMutableDictionary new];
    I_currentReadFrame = nil;

    I_userInfo = [NSMutableDictionary new];
    I_channelRequests = [NSMutableDictionary new];
    
    // RFC 879 - The TCP Maximum Segment Size and Related Topics
    // MSS: 1500 - 60 - 20 = 1420
    // 2/3 MSS: 946
    I_maximumFrameSize = 946;
    
#ifdef TCMBEEP_DEBUG  
    int fileNumber;
    if ([self isInitiator]) {
        fileNumber = sInitLogCount++;
    } else {
        fileNumber = sListenLogCount++;
    }

    NSString *appName = [[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension];
    NSString *appDir = [[@"~/Library/Logs/" stringByExpandingTildeInPath] stringByAppendingPathComponent:appName];
    [[NSFileManager defaultManager] createDirectoryAtPath:appDir attributes:nil];
    NSString *logDir = [appDir stringByAppendingPathComponent:@"TCMBEEP"];
    [[NSFileManager defaultManager] createDirectoryAtPath:logDir attributes:nil];
    
    NSData *header = [[[NSString stringWithAddressData:[self peerAddressData]] stringByAppendingString:@"\n"] dataUsingEncoding:NSASCIIStringEncoding];
        
    NSString *logBase = [logDir stringByAppendingFormat:@"/%02d", fileNumber];
    NSString *logIn = [logBase stringByAppendingString:@"In.log"];
    [[NSFileManager defaultManager] createFileAtPath:logIn contents:[NSData data] attributes:nil];
    I_rawLogInHandle = [[NSFileHandle fileHandleForWritingAtPath:logIn] retain];
    [I_rawLogInHandle writeData:header];

    NSString *logOut = [logBase stringByAppendingString:@"Out.log"];
    [[NSFileManager defaultManager] createFileAtPath:logOut contents:[NSData data] attributes:nil];
    I_rawLogOutHandle = [[NSFileHandle fileHandleForWritingAtPath:logOut] retain];
    [I_rawLogOutHandle writeData:header];
    
    NSString *frameLogFileName = [logDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Frames%02d.log",     sNumberOfLogs++]];
    [[NSFileManager defaultManager] createFileAtPath:frameLogFileName contents:[NSData data] attributes:nil];
    I_frameLogHandle = [[NSFileHandle fileHandleForWritingAtPath:frameLogFileName] retain];
    [I_frameLogHandle writeData:header];
#endif
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

- (id)initWithAddressData:(NSData *)aData {
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
    I_delegate = nil;
    [I_readBuffer release];
    [I_writeBuffer release];
    [I_inputStream release];
    [I_outputStream release];
    [I_userInfo release];
    [I_managementChannel release];
    [I_requestedChannels release];
    [I_activeChannels release];
    [I_peerAddressData release];
    [I_profileURIs release];
    [I_peerProfileURIs release];
    [I_featuresAttribute release];
    [I_localizeAttribute release];
    [I_peerFeaturesAttribute release];
    [I_peerLocalizeAttribute release];
    [I_channelRequests release];    
    [I_currentReadFrame release];
#ifdef TCMBEEP_DEBUG
    [I_rawLogInHandle closeFile];
    [I_rawLogInHandle release];
    [I_rawLogOutHandle closeFile];
    [I_rawLogOutHandle release];
    [I_frameLogHandle closeFile];
    [I_frameLogHandle release];
#endif
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"TCMBEEPSession dealloced");
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

- (void)setUserInfo:(NSMutableDictionary *)aUserInfo
{
    [I_userInfo autorelease];
    I_userInfo = [aUserInfo copy];
}

- (NSMutableDictionary *)userInfo
{
    return I_userInfo;
}


- (void)setProfileURIs:(NSArray *)anArray
{
    [I_profileURIs autorelease];
    I_profileURIs = [anArray copy];
}

- (NSArray *)profileURIs {
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

- (int32_t)nextChannelNumber
{
    I_nextChannelNumber += 2;
    return I_nextChannelNumber;
}

- (int)maximumFrameSize
{
    return I_maximumFrameSize;
}

- (void)activateChannel:(TCMBEEPChannel *)aChannel
{
    [I_activeChannels setObject:aChannel forLong:[aChannel number]];
}

- (void)open
{
    [I_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                             forMode:(NSString *)kCFRunLoopCommonModes];
    [I_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                              forMode:(NSString *)kCFRunLoopCommonModes];
    
    [I_inputStream open];
    [I_outputStream open];
    
    I_managementChannel = [[TCMBEEPChannel alloc] initWithSession:self number:0 profileURI:kTCMBEEPManagementProfile asInitiator:[self isInitiator]];
    TCMBEEPManagementProfile *profile=(TCMBEEPManagementProfile *)[I_managementChannel profile];
    [profile setDelegate:self];

    [self activateChannel:I_managementChannel];

    [profile sendGreetingWithProfileURIs:[self profileURIs] featuresAttribute:nil localizeAttribute:nil];
}

- (void)close
{
    if ([I_outputStream streamStatus] != NSStreamStatusClosed) {
        [I_outputStream close];
    }
    if ([I_inputStream streamStatus] != NSStreamStatusClosed) {
        [I_inputStream close];
    }
    [self TCM_cleanup];
}

- (void)TCM_cleanup
{
    BOOL informDelegate = (I_activeChannels != nil);
    NSEnumerator *activeChannels = [I_activeChannels objectEnumerator];  
    TCMBEEPChannel *channel;
    while ((channel = [activeChannels nextObject])) {
        [channel cleanup];
    }
    [I_activeChannels release];
    I_activeChannels = nil;
    
    if (informDelegate) {
        id delegate = [self delegate];
        if ([delegate respondsToSelector:@selector(BEEPSession:didFailWithError:)]) {
            NSError *error = [NSError errorWithDomain:@"BEEPDomain" code:451 userInfo:nil];
            [delegate BEEPSession:self didFailWithError:error];
        }
    }
    
    // cleanup requested channels
    // cleanup managment channel
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
    int bytesParsed = 0;
    int bytesRead = [I_inputStream read:buffer maxLength:sizeof(buffer)];
    
#ifdef TCMBEEP_DEBUG
    if (bytesRead) [I_rawLogInHandle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
#endif
    
    // NSLog(@"bytesRead: %@", [NSString stringWithCString:buffer length:bytesRead]);
    while (bytesRead > 0 && (bytesRead - bytesParsed > 0)) {
        int remainingBytes = bytesRead-bytesParsed;
        if (I_currentReadState == frameHeaderState) {
            int i;
            // search for 0x0a (LF)
            for (i = bytesParsed; i < bytesRead; i++) {
                if (buffer[i] == 0x0a) {
                    buffer[i] = 0x00;
                    break;
                }
            }
            if (i < bytesRead) {
                // found LF
                [I_readBuffer appendBytes:&buffer[bytesParsed] length:(i - bytesParsed + 1)];
                I_currentReadFrame = [[TCMBEEPFrame alloc] initWithHeader:(char *)[I_readBuffer bytes]];
                if ([I_currentReadFrame isSEQ]) {
                    TCMBEEPChannel *channel = [[self activeChannels] objectForLong:[I_currentReadFrame channelNumber]];
                    if (channel) {
                        BOOL didAccept = [channel acceptFrame:[I_currentReadFrame autorelease]];
                        DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"channel did accept frame: %@",  didAccept ? @"YES" : @"NO");
                    } else {
                        [self close];
                        break;
                    }
                    I_currentReadFrame = nil;                    
                    [I_readBuffer setLength:0];
                    I_currentReadState = frameHeaderState;
                    bytesParsed = i + 1;
                    continue;
                }
                
                if (!I_currentReadFrame) {
                    [self close];
                    break;
                } else {
                    I_currentReadState = frameContentState;
                    I_currentReadFrameRemainingContentSize = [I_currentReadFrame length];
                    [I_readBuffer setLength:0];
                    bytesParsed = i + 1;
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
                DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"Received Frame: %@", [I_currentReadFrame description]);
                [I_readBuffer setLength:0];
                bytesParsed += I_currentReadFrameRemainingContentSize;
                I_currentReadState = frameEndState;
                continue;
            }
        } else if (I_currentReadState == frameEndState) {
            if (remainingBytes + [I_readBuffer length] >= 5) {
                [I_readBuffer appendBytes:&buffer[bytesParsed] length:5 - [I_readBuffer length]];
                // I_readBuffer == "END\r\n" ?
                // dispatch frame!

#ifdef TCMBEEP_DEBUG
                [I_frameLogHandle writeData:[I_currentReadFrame descriptionInLogFileFormatIncoming:YES]];
#endif                

                TCMBEEPChannel *channel = [[self activeChannels] objectForLong:[I_currentReadFrame channelNumber]];
                if (channel) {
                    BOOL didAccept = [channel acceptFrame:[I_currentReadFrame autorelease]];
                    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"channel did accept frame: %@",  didAccept ? @"YES" : @"NO");
                    I_currentReadFrame = nil;
                } else {
                    [self close];
                    break;
                }
                [I_readBuffer setLength:0];
                I_currentReadState = frameHeaderState;
                bytesParsed += 5 - [I_readBuffer length];
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

#ifdef TCMBEEP_DEBUG
    if (bytesWritten) [I_rawLogOutHandle writeData:[NSData dataWithBytesNoCopy:(void *)[I_writeBuffer bytes] length:bytesWritten freeWhenDone:NO]];
#endif

    if (bytesWritten > 0) {
        [I_writeBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
    } else if (bytesWritten < 0) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Error occurred while writing bytes.");
    } else {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Stream has reached its capacity");
    }
}

- (void)TCM_handleInputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Input stream open completed.");
            break;
        case NSStreamEventHasBytesAvailable:
            [self TCM_readBytes];
            break;
        case NSStreamEventErrorOccurred: {
                NSError *error = [I_inputStream streamError];
                DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"An error occurred on the input stream: %@, Domain: %@, Code: %d", [error localizedDescription], [error domain], [error code]);
                [self TCM_cleanup];
            }
            break;
        case NSStreamEventEndEncountered:
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Input stream end encountered.");
            [self TCM_cleanup];
            break;
        default:
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Input stream not handling this event: %d", streamEvent);
            break;
    }
}

- (void)TCM_handleOutputStreamEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Output stream open completed.");
                /*
                NSData *socketNativeHandleData = [I_inputStream propertyForKey:(NSString *)kCFStreamPropertySocketNativeHandle];
                if (socketNativeHandleData) {
                    CFSocketNativeHandle socketNativeHandle;
                    [socketNativeHandleData getBytes:&socketNativeHandle length:sizeof(CFSocketNativeHandle)];
                    struct ifreq request;
                    memset(&request, 0, sizeof( struct ifreq));
                    strncpy(request.ifr_name, "en0", IFNAMSIZ);
                    int result = ioctl(socketNativeHandle, SIOCGIFMTU, (char *)&request);
                    if (result != -1) {
                        int mtu = request.ifr_mtu;
                        NSLog(@"MTU: %d", mtu);
                    } else {
                        NSLog(@"ioctl failed: %s", strerror(errno));
                    }
                }   
                */         
            }
            break;
        case NSStreamEventHasSpaceAvailable:
            [self TCM_writeBytes];
            break;
        case NSStreamEventErrorOccurred: {
                NSError *error = [I_outputStream streamError];
                DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"An error occurred on the output stream: %@, Domain: %@, Code: %d", [error localizedDescription], [error domain], [error code]);
                [self TCM_cleanup];
            }
            break;
        case NSStreamEventEndEncountered:
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Output stream end encountered.");
            [self TCM_cleanup];
            break;
        default:
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Output stream not handling this event: %d", streamEvent);
            break;
    }
}

#pragma mark - 

- (void)sendRoundRobin
{
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"sendRoundRobin");
    NSEnumerator *channels = [[self activeChannels] objectEnumerator];
    TCMBEEPChannel *channel = nil;
    BOOL didSend = NO;
    while ((channel = [channels nextObject])) {
        if ([channel hasFramesAvailable]) {
            didSend = YES;
            NSEnumerator *frames = [[channel availableFramesFittingInCurrentWindow] objectEnumerator];
            TCMBEEPFrame *frame;
            while ((frame = [frames nextObject])) {
                [frame appendToMutableData:I_writeBuffer];
#ifdef TCMBEEP_DEBUG
                [I_frameLogHandle writeData:[frame descriptionInLogFileFormatIncoming:NO]];
#endif
                DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Sending Frame: %@", [frame description]);
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
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"sendRoundrobin didSend: %@", (didSend ? @"YES" : @"NO"));
}

- (void)channelHasFramesAvailable:(TCMBEEPChannel *)aChannel
{
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"TriggeredSending %@", (I_flags.isSending ? @"NO" : @"YES"));
    if (!I_flags.isSending) {
        [self performSelector:@selector(sendRoundRobin) withObject:nil afterDelay:0.01];
        I_flags.isSending = YES;
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
    // Profile URIs ausduennen 
    NSMutableArray *requestArray = [NSMutableArray array];
    NSMutableDictionary *preferedAnswer = nil;
    //NSLog(@"profileURIs: %@ selfProfileURIs:%@ peerProfileURIs:%@\n\nSession:%@", aProfileURIArray, [self profileURIs], [self peerProfileURIs], self);
    int i;
    for (i = 0; i < [aProfileURIArray count]; i++) {
        if ([[self profileURIs] containsObject:[aProfileURIArray objectAtIndex:i]]) {
            [requestArray addObject:[NSDictionary dictionaryWithObjectsAndKeys: [aProfileURIArray objectAtIndex:i], @"ProfileURI", [aDataArray objectAtIndex:i], @"Data", nil]];
            if (!preferedAnswer) 
                preferedAnswer = [NSMutableDictionary dictionaryWithObjectsAndKeys: [aProfileURIArray objectAtIndex:i], @"ProfileURI", [NSData data], @"Data", nil];
        }
    }
    // prefered Profile URIs raussuchen
    if (!preferedAnswer) return nil;
    // if channel exists 
    if ([I_activeChannels objectForLong:channelNumber]) return nil;
    // delegate fragen, falls er gefragt werden will
    if ([[self delegate] respondsToSelector:@selector(BEEPSession:willSendReply:forChannelRequests:)]) {
        preferedAnswer = [[self delegate] BEEPSession:self willSendReply:preferedAnswer forChannelRequests:requestArray];
    }
    return preferedAnswer;
}

- (void)initiateChannelWithNumber:(int32_t)aChannelNumber profileURI:(NSString *)aProfileURI asInitiator:(BOOL)isInitiator
{
    TCMBEEPChannel *channel = [[TCMBEEPChannel alloc] initWithSession:self number:aChannelNumber profileURI:aProfileURI asInitiator:isInitiator];
    [self activateChannel:[channel autorelease]];
    if (!isInitiator) {
        id delegate = [self delegate];
        if ([delegate respondsToSelector:@selector(BEEPSession:didOpenChannelWithProfile:)])
            [delegate BEEPSession:self didOpenChannelWithProfile:[channel profile]];
    } else {
        // sender rausfinden
        NSNumber *channelNumber = [NSNumber numberWithInt:aChannelNumber];
        id aSender = [I_channelRequests objectForKey:channelNumber];
        [I_channelRequests removeObjectForKey:channelNumber]; 
        // sender profile geben
        [aSender BEEPSession:self didOpenChannelWithProfile:[channel profile]];
    }
}

- (void)startChannelWithProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray sender:(id)aSender
{
    NSNumber *channelNumber = [NSNumber numberWithInt:[self nextChannelNumber]];
    [I_channelRequests setObject:aSender forKey:channelNumber];
    [[I_managementChannel profile] startChannelNumber:[channelNumber intValue] withProfileURIs:aProfileURIArray andData:aDataArray];
}

- (void)didReceiveAcceptStartRequestForChannel:(int32_t)aNumber withProfileURI:(NSString *)aProfileURI andData:(NSData *)aData
{
    [self initiateChannelWithNumber:aNumber profileURI:aProfileURI asInitiator:YES];
}

@end
