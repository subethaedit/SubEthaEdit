//
//  TCMBEEPSession.m
//  TCMBEEP
//
//  Created by Martin Ott on Mon Feb 16 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPSession.h"
#import "TCMBEEPChannel.h"
#import "TCMBEEPFrame.h"
#import "TCMBEEPManagementProfile.h"
#import "TCMBEEPAuthenticationClient.h"
#import "TCMBEEPAuthenticationServer.h"
#import <Security/Security.h>

#import <netinet/in.h>
#import <sys/socket.h>
#import <sys/sockio.h>  // SIOCGIFMTU
#import <sys/ioctl.h> // ioctl()
#import <net/if.h> // struct ifreq
#import <sys/param.h>

NSString * const NetworkTimeoutPreferenceKey = @"NetworkTimeout";
NSString * const kTCMBEEPFrameTrailer = @"END\r\n";
NSString * const kTCMBEEPManagementProfile = @"http://www.codingmonkeys.de/BEEP/Management.profile";
NSString * const TCMBEEPTLSProfileURI = @"http://iana.org/beep/TLS";
NSString * const TCMBEEPSASLProfileURIPrefix = @"http://iana.org/beep/SASL/";
NSString * const TCMBEEPSASLANONYMOUSProfileURI = @"http://iana.org/beep/SASL/ANONYMOUS";
NSString * const TCMBEEPSASLPLAINProfileURI = @"http://iana.org/beep/SASL/PLAIN";
NSString * const TCMBEEPSASLCRAMMD5ProfileURI = @"http://iana.org/beep/SASL/CRAM-MD5";
NSString * const TCMBEEPSASLDIGESTMD5ProfileURI = @"http://iana.org/beep/SASL/DIGEST-MD5";
NSString * const TCMBEEPSASLGSSAPIProfileURI = @"http://iana.org/beep/SASL/GSSAPI";
NSString * const TCMMMBEEPSessionDidReceiveGreetingNotification = @"TCMMMBEEPSessionDidReceiveGreetingNotification";

static void callBackReadStream(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo);
static void callBackWriteStream(CFWriteStreamRef stream, CFStreamEventType type, void *clientCallBackInfo);

#pragma mark -

@interface TCMBEEPSession (TCMBEEPSessionPrivateAdditions)
- (void)TCM_initHelper;
- (void)TCM_handleStreamOpenEvent;
- (void)TCM_handleStreamHasBytesAvailableEvent;
- (void)TCM_handleStreamCanAcceptBytesEvent;
- (void)TCM_handleStreamErrorOccurredEvent:(NSError *)error;
- (void)TCM_handleStreamAtEndEvent;
- (void)TCM_fillBufferInRoundRobinFashion;
- (void)TCM_readBytes;
- (void)TCM_writeBytes;
- (void)TCM_cleanup;
- (void)TCM_triggerTerminator;
@end

#pragma mark -

@implementation TCMBEEPSession

#ifndef TCM_NO_DEBUG
    static unsigned numberOfLogs = 0;
    static NSString *logDirectory = nil;
#endif

- (void)TCM_initHelper
{
    I_flags.hasSentTLSProceed = NO;
    I_flags.isWaitingForTLSProceed = NO;
    CFStreamClientContext context = {0, self, NULL, NULL, NULL};
    CFOptionFlags readFlags =  kCFStreamEventOpenCompleted |
        kCFStreamEventHasBytesAvailable |
        kCFStreamEventErrorOccurred |
        kCFStreamEventEndEncountered;
    CFOptionFlags writeFlags = kCFStreamEventOpenCompleted |
        kCFStreamEventCanAcceptBytes |
        kCFStreamEventErrorOccurred |
        kCFStreamEventEndEncountered;
        
    if (!CFReadStreamSetClient(I_readStream, readFlags,
                               (CFReadStreamClientCallBack)&callBackReadStream,
                               &context)) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Error connecting readStream to callback.");
        return;
    }

    if (!CFWriteStreamSetClient(I_writeStream, writeFlags,
                                (CFWriteStreamClientCallBack)&callBackWriteStream,
                                &context)) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Error connecting writeStream to callback.");
        return;
    }
    
    if (!CFReadStreamSetProperty(I_readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue)) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Failed to set kCFStreamPropertyShouldCloseNativeSocket on inputStream");
    }
    
    if (!CFWriteStreamSetProperty(I_writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue)) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Failed to set kCFStreamPropertyShouldCloseNativeSocket on outputStream");
    }
    
    I_profileURIs = [NSMutableArray new];
    I_peerProfileURIs = [NSMutableArray new];
        
    I_readBuffer = [NSMutableData new];
    I_currentReadState=frameHeaderState;
    I_writeBuffer = [NSMutableData new];
    I_activeChannels = [NSMutableDictionary new];
    I_currentReadFrame = nil;

    I_userInfo = [NSMutableDictionary new];
    I_channelRequests = [NSMutableDictionary new];
    I_channels = [NSMutableArray new];
    I_sessionStatus = TCMBEEPSessionStatusNotOpen;
    
    // RFC 879 - The TCP Maximum Segment Size and Related Topics
    // MSS: 1500 - 60 - 20 = 1420
    // 2/3 MSS: 946
    I_maximumFrameSize = 946;
    I_timeout = [[NSUserDefaults standardUserDefaults] floatForKey:NetworkTimeoutPreferenceKey];
    
    _authClient = nil;
    _authServer = nil;
    I_flags.amReading = NO;
    I_flags.needsToReadAgain = NO;
    
#ifndef TCM_NO_DEBUG
	isLogging = [[NSUserDefaults standardUserDefaults] boolForKey:@"EnableBEEPLogging"];
	if (!isLogging) {
		return;
	}
    	
    if (!logDirectory) {
        NSString *appName = [[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension];
        NSString *appDir = [[@"~/Library/Logs/" stringByExpandingTildeInPath] stringByAppendingPathComponent:appName];
        [[NSFileManager defaultManager] createDirectoryAtPath:appDir attributes:nil];
        NSString *beepDir = [appDir stringByAppendingPathComponent:@"TCMBEEP"];
        [[NSFileManager defaultManager] createDirectoryAtPath:beepDir attributes:nil];
        NSString *origPath = [beepDir stringByAppendingPathComponent:@"Session"];
        
        static int sequenceNumber = 0;
        NSString *name;
        do {
            sequenceNumber++;
            name = [NSString stringWithFormat:@"%d-%d-%d", (int)[NSDate timeIntervalSinceReferenceDate], [[NSProcessInfo processInfo] processIdentifier], sequenceNumber];
            name = [[origPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
        } while ([[NSFileManager defaultManager] fileExistsAtPath:logDirectory]);

        logDirectory = [name retain];
        [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory attributes:nil];    
    }
    
    int fileNumber = numberOfLogs++;

    NSString *headerString = [NSString stringWithFormat:@"[%@] %@\n\n", [[NSCalendarDate calendarDate] description], [NSString stringWithAddressData:[self peerAddressData]]];
    NSData *headerData = [headerString dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *logBase = [logDirectory stringByAppendingFormat:@"/%02d", fileNumber];
    NSString *logIn = [logBase stringByAppendingString:@"in.log"];
    [[NSFileManager defaultManager] createFileAtPath:logIn contents:[NSData data] attributes:nil];
    I_rawLogInHandle = [[NSFileHandle fileHandleForWritingAtPath:logIn] retain];
    [I_rawLogInHandle writeData:headerData];

    NSString *logOut = [logBase stringByAppendingString:@"out.log"];
    [[NSFileManager defaultManager] createFileAtPath:logOut contents:[NSData data] attributes:nil];
    I_rawLogOutHandle = [[NSFileHandle fileHandleForWritingAtPath:logOut] retain];
    [I_rawLogOutHandle writeData:headerData];
    
    NSString *frameLogFileName = [logBase stringByAppendingString:@"frames.log"];
    [[NSFileManager defaultManager] createFileAtPath:frameLogFileName contents:[NSData data] attributes:nil];
    I_frameLogHandle = [[NSFileHandle fileHandleForWritingAtPath:frameLogFileName] retain];
    [I_frameLogHandle writeData:headerData];
#endif
}

- (id)initWithSocket:(CFSocketNativeHandle)aSocketHandle addressData:(NSData *)aData
{
    self = [super init];
    if (self) {
        [self setPeerAddressData:aData];
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, aSocketHandle, &I_readStream, &I_writeStream);
        I_flags.isInitiator = NO;
        I_nextChannelNumber = 0;
        [self TCM_initHelper];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"EnableTLS"])
            [self addProfileURIs:[NSArray arrayWithObject:TCMBEEPTLSProfileURI]];
        _authServer = [[TCMBEEPAuthenticationServer alloc] initWithSession:self addressData:[self addressData] peerAddressData:aData];
    }
    
    return self;
}

- (id)initWithAddressData:(NSData *)aData
{
    self = [super init];
    if (self) {
        [self setPeerAddressData:aData];
        struct sockaddr *address = (struct sockaddr *)[aData bytes];
        CFSocketSignature signature = {address->sa_family, SOCK_STREAM, IPPROTO_TCP, (CFDataRef)aData};
        CFStreamCreatePairWithPeerSocketSignature(kCFAllocatorDefault, &signature, &I_readStream, &I_writeStream);
        I_flags.isInitiator = YES;
        I_flags.isProhibitingInboundInternetSessions = NO;
        I_nextChannelNumber = -1;
        [self TCM_initHelper];
    }
    
    return self;
}

- (void)dealloc
{
    I_delegate = nil;
    CFReadStreamSetClient(I_readStream, 0, NULL, NULL);
    CFWriteStreamSetClient(I_writeStream, 0, NULL, NULL);
    
    [I_readBuffer release];
    [I_writeBuffer release];
    CFRelease(I_readStream);
    CFRelease(I_writeStream);
    [I_userInfo release];
    [I_managementChannel cleanup];
    [I_managementChannel release];
    [I_activeChannels release];
    [I_peerAddressData release];
    [I_profileURIs release];
    [I_peerProfileURIs release];
    [I_featuresAttribute release];
    [I_localizeAttribute release];
    [I_peerFeaturesAttribute release];
    [I_peerLocalizeAttribute release];
    [I_channelRequests release];
    [I_channels release];
    [I_currentReadFrame release];
    [I_terminateTimer invalidate];
    [I_terminateTimer release];
    
    [_authClient release];
    [_authServer release];
#ifndef TCM_NO_DEBUG
	if (isLogging) {
		NSString *trailerString = [NSString stringWithFormat:@"\n\n[%@] dealloc\n\n", [[NSCalendarDate calendarDate] description]];
		NSData *trailerData = [trailerString dataUsingEncoding:NSASCIIStringEncoding];
		[I_rawLogInHandle writeData:trailerData];
		[I_rawLogInHandle closeFile];
		[I_rawLogInHandle release];
		[I_rawLogOutHandle writeData:trailerData];
		[I_rawLogOutHandle closeFile];
		[I_rawLogOutHandle release];
		[I_frameLogHandle writeData:trailerData];
		[I_frameLogHandle closeFile];
		[I_frameLogHandle release];
	}
#endif
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"BEEPSession deallocated");
    [super dealloc];
}

- (NSString *)description
{    
    return [NSString stringWithFormat:@"BEEPSession with address: %@ andInfo: %@ andChannels: %@", [NSString stringWithAddressData:I_peerAddressData], [[self userInfo] description], [I_activeChannels description]];
}

- (void)startTerminator {
    if (!I_terminateTimer && I_timeout) {
        I_terminateTimer = [[NSTimer timerWithTimeInterval:I_timeout
                                                    target:self 
                                                  selector:@selector(terminate)
                                                 userInfo:nil repeats:NO] retain];
        [[NSRunLoop currentRunLoop] addTimer:I_terminateTimer forMode:NSDefaultRunLoopMode];
    } 
}

- (void)triggerTerminator {
    if ([I_terminateTimer isValid]) {
        [I_terminateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:I_timeout]];
    } 
}

- (void)invalidateTerminator {
    [I_terminateTimer invalidate];
}

#pragma mark -

- (unsigned int)countOfChannels {
    return [I_channels count];
}

- (TCMBEEPChannel *)objectInChannelsAtIndex:(unsigned int)index {
     return [I_channels objectAtIndex:index];
}

- (void)insertObject:(TCMBEEPChannel *)channel inChannelsAtIndex:(unsigned int)index {
    [I_channels insertObject:channel atIndex:index];
}


- (void)removeObjectFromChannelsAtIndex:(unsigned int)index {
    [I_channels removeObjectAtIndex:index];
}

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

- (void)addProfileURIs:(NSArray *)anArray
{
    if (!I_profileURIs) I_profileURIs = [[NSMutableArray alloc] init];
    [I_profileURIs addObjectsFromArray:anArray];
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

- (void)setIsProhibitingInboundInternetSessions:(BOOL)flag
{
    I_flags.isProhibitingInboundInternetSessions = flag;
}

- (BOOL)isProhibitingInboundInternetSessions
{
    return I_flags.isProhibitingInboundInternetSessions;
}

- (TCMBEEPAuthenticationClient *)authenticationClient
{
    return _authClient;
}

- (TCMBEEPAuthenticationServer *)authenticationServer
{
    return _authServer;
}

- (BOOL)isInitiator
{
    return I_flags.isInitiator;
}

- (NSMutableDictionary *)activeChannels
{
    return I_activeChannels;
}

- (NSData *)addressData
{
    if (!I_readStream)
        return nil;
        
    NSData *addressData = nil;
    CFDataRef socketHandleData = CFReadStreamCopyProperty(I_readStream, kCFStreamPropertySocketNativeHandle);
	if (socketHandleData != NULL) {
        CFSocketNativeHandle socketHandle;
        CFDataGetBytes (socketHandleData, CFRangeMake(0, CFDataGetLength(socketHandleData)), (UInt8 *)&socketHandle);
        CFRelease (socketHandleData);
        struct sockaddr name;
        socklen_t namelen = sizeof(struct sockaddr);
        int result = getsockname(socketHandle, &name, &namelen);
        if (result == 0) {
            addressData = [NSData dataWithBytes:&name length:namelen];
        } else if (result == -1) {
            DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"getsockname failed: %@ / %s", errno, strerror(errno));
        }
    }
    
    return addressData;
}

- (BOOL)isAuthenticated
{
    if (_authClient) return [_authClient isAuthenticated];
    else if (_authServer) return [_authServer isAuthenticated];
    else return NO;
}

- (NSArray *)channels
{
    return I_channels;
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

- (TCMBEEPSessionStatus)sessionStatus
{
    return I_sessionStatus;
}

- (void)activateChannel:(TCMBEEPChannel *)aChannel
{
    [I_activeChannels setObject:aChannel forLong:[aChannel number]];
}

- (void)authenticate
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"");
    
    [_authClient startAuthentication];
}

- (void)open
{
    CFRunLoopRef runLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];

    CFReadStreamScheduleWithRunLoop(I_readStream, runLoop, kCFRunLoopCommonModes);
    CFWriteStreamScheduleWithRunLoop(I_writeStream, runLoop, kCFRunLoopCommonModes);
    
    if (!CFReadStreamOpen(I_readStream)) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Invalid Read Stream on Open");
        return;
    }
    
    if (!CFWriteStreamOpen(I_writeStream)) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Invalid Write Stream on Open");
        return;
    }

    
    CFDataRef socketHandleData = CFReadStreamCopyProperty(I_readStream, kCFStreamPropertySocketNativeHandle);
	if (socketHandleData != NULL) {
        CFSocketNativeHandle socketHandle;
        CFDataGetBytes (socketHandleData, CFRangeMake(0, CFDataGetLength(socketHandleData)), (UInt8 *)&socketHandle);
        CFRelease (socketHandleData);
        int yes = 1;
        int result = setsockopt(socketHandle, IPPROTO_TCP, 
                                TCP_NODELAY, &yes, sizeof(int));
        if (result == -1) {
            DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Could not setsockopt to TCP_NODELAY: %@ / %s", errno, strerror(errno));
        }
    }
    
    if ([self isInitiator]) {
        // SASL setup for client
        CFStringRef remoteHostName = CFReadStreamCopyProperty(I_readStream, kCFStreamPropertySocketRemoteHostName);
        DEBUGLOG(@"SASLLogDomain", DetailedLogLevel, @"remoteHostName: %@", (NSString *)remoteHostName);
        _authClient = [[TCMBEEPAuthenticationClient alloc] initWithSession:self addressData:[self addressData] peerAddressData:[self peerAddressData] serverFQDN:(NSString *)remoteHostName];
        if (remoteHostName) CFRelease(remoteHostName);
    }
    
    I_sessionStatus = TCMBEEPSessionStatusOpening;
    
    I_managementChannel = [[TCMBEEPChannel alloc] initWithSession:self number:0 profileURI:kTCMBEEPManagementProfile asInitiator:[self isInitiator]];
    
    [self insertObject:I_managementChannel inChannelsAtIndex:[self countOfChannels]];
    
    TCMBEEPManagementProfile *profile = (TCMBEEPManagementProfile *)[I_managementChannel profile];
    [profile setDelegate:self];

    [self activateChannel:I_managementChannel];

    [profile sendGreetingWithProfileURIs:[self profileURIs] featuresAttribute:nil localizeAttribute:nil];
}

- (void)terminate
{
    [self invalidateTerminator];
    I_sessionStatus = TCMBEEPSessionStatusError;
    
    CFReadStreamClose(I_readStream);
    CFWriteStreamClose(I_writeStream);
    
    CFRunLoopRef runLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    CFReadStreamUnscheduleFromRunLoop(I_readStream, runLoop, kCFRunLoopCommonModes);
    CFWriteStreamUnscheduleFromRunLoop(I_writeStream, runLoop, kCFRunLoopCommonModes);
    
    CFReadStreamSetClient(I_readStream, 0, NULL, NULL);
    CFWriteStreamSetClient(I_writeStream, 0, NULL, NULL);
    
    NSEnumerator *activeChannels = [I_activeChannels objectEnumerator];  
    TCMBEEPChannel *channel;
    while ((channel = [activeChannels nextObject])) {
        [channel cleanup];
    }
    [I_activeChannels removeAllObjects];
    
    int index;
    for (index = [self countOfChannels] - 1; index >= 0; index--) {
        [self removeObjectFromChannelsAtIndex:index];
    }

    [I_managementChannel cleanup];
    [I_managementChannel release];
    I_managementChannel = nil;
        
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(BEEPSession:didFailWithError:)]) {
        NSError *error = [NSError errorWithDomain:@"BEEPDomain" code:451 userInfo:nil];
        [delegate BEEPSession:self didFailWithError:error];
    }
}

#define kWriteBufferThreshold 65535

- (void)TCM_fillBufferInRoundRobinFashion
{
    // ask each channel to write frames in writeBuffer until maximumFrameSize or windowSize is reached
    // repeat until writeBufferThreshold has been reached or no more frames are available
    
    BOOL hasFramesAvailable = YES;
    while ([I_writeBuffer length] < kWriteBufferThreshold && hasFramesAvailable) {
        hasFramesAvailable = NO;
        NSEnumerator *channels = [[self activeChannels] objectEnumerator];
        TCMBEEPChannel *channel = nil;
        while ((channel = [channels nextObject])) {
            if ([channel hasFramesAvailable]) {
                hasFramesAvailable = YES;
                NSEnumerator *frames = [[channel availableFramesFittingInCurrentWindow] objectEnumerator];
                TCMBEEPFrame *frame;
                while ((frame = [frames nextObject])) {
                    [frame appendToMutableData:I_writeBuffer];
#ifndef TCM_NO_DEBUG
					if (isLogging) {
						[I_frameLogHandle writeData:[frame descriptionInLogFileFormatIncoming:NO]];
					}
#endif
                    DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Sending Frame: %@", [frame description]);
                }
            }
        }
    }
}

- (void)TCM_readBytes
{
    if (!I_flags.amReading) {
        I_flags.amReading = YES;
        uint8_t buffer[8192];
        int bytesParsed = 0;
        CFIndex bytesRead = CFReadStreamRead(I_readStream, buffer, sizeof(buffer));
         
    #ifndef TCM_NO_DEBUG
        if (isLogging && bytesRead > 0) {
            [I_rawLogInHandle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
    //        [I_rawLogInHandle writeData:[@"|" dataUsingEncoding:NSASCIIStringEncoding]];
        }
    #endif
        
        //NSLog(@"bytesRead: %@", [NSString stringWithCString:buffer length:bytesRead]);
        while (bytesRead > 0 && (bytesRead - bytesParsed > 0)) {
            int remainingBytes = bytesRead - bytesParsed;
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
                    //NSLog(@"Header String: %s", (char *)[I_readBuffer bytes]);
                    I_currentReadFrame = [[TCMBEEPFrame alloc] initWithHeader:(char *)[I_readBuffer bytes]];
                    if ([I_currentReadFrame isSEQ]) {
                        TCMBEEPChannel *channel = [[self activeChannels] objectForLong:[I_currentReadFrame channelNumber]];
                        if (channel) {
                            BOOL didAccept = [channel acceptFrame:I_currentReadFrame];
                            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"channel did accept frame: %@",  didAccept ? @"YES" : @"NO");
                            if (!didAccept) {
                                [I_currentReadFrame release];
                                I_currentReadFrame = nil;
                                [self terminate];
                                break;
                            } else {
    #ifndef TCM_NO_DEBUG
                                if (isLogging) {
                                    [I_frameLogHandle writeData:[I_currentReadFrame descriptionInLogFileFormatIncoming:YES]];
                                }
    #endif  
                            }
                            [I_currentReadFrame release];
                        } else {
                            [I_currentReadFrame release];
                            I_currentReadFrame = nil;
                            [self terminate];
                            break;
                        }
                        I_currentReadFrame = nil;                    
                        [I_readBuffer setLength:0];
                        I_currentReadState = frameHeaderState;
                        bytesParsed = i + 1;
                        continue;
                    }
                    
                    if (!I_currentReadFrame) {
                        [self terminate];
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
                    int localbytesread = 5 - [I_readBuffer length];
                    [I_readBuffer appendBytes:&buffer[bytesParsed] length:5 - [I_readBuffer length]];
                    if (strncmp((char *)[I_readBuffer bytes], "END\r\n", 5) != 0) {
                        [I_currentReadFrame release];
                        I_currentReadFrame = nil;
                        [self terminate];
                        break;
                    }

    #ifndef TCM_NO_DEBUG
                    if (isLogging) {
                        [I_frameLogHandle writeData:[I_currentReadFrame descriptionInLogFileFormatIncoming:YES]];
                    }
    #endif                
                    // dispatch frame!
                    TCMBEEPChannel *channel = [[self activeChannels] objectForLong:[I_currentReadFrame channelNumber]];
                    if (channel) {
                        BOOL didAccept = [channel acceptFrame:I_currentReadFrame];
                        DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"channel did accept frame: %@",  didAccept ? @"YES" : @"NO");
                        [I_currentReadFrame release];
                        I_currentReadFrame = nil;
                        if (!didAccept) {
                            [self terminate];
                            break;
                        }
                    } else {
                        [I_currentReadFrame release];
                        I_currentReadFrame = nil;
                        [self terminate];
                        break;
                    }
                    I_currentReadState = frameHeaderState;
                    [I_readBuffer setLength:0];
                    bytesParsed += localbytesread;
                } else {
                    [I_readBuffer appendBytes:&buffer[bytesParsed] length:remainingBytes];
                    bytesParsed = bytesRead;
                }
            }
        }
        if (I_flags.needsToReadAgain) {
            I_flags.needsToReadAgain = NO;
            [self performSelector:@selector(TCM_readBytes) withObject:nil afterDelay:0];
        }
        I_flags.amReading = NO;
    } else {
        I_flags.needsToReadAgain = YES;
        NSLog(@"%s was already reading",__FUNCTION__);
    }
}

#define KC_DB_PATH		"Library/Keychains"	
CFArrayRef getSslCerts(
	const char 		*kcName,				// may be NULL, i.e., use default
	CSSM_BOOL		encryptOnly,
	SecKeychainRef	*pKcRef)				// RETURNED
{
	char 				kcPath[MAXPATHLEN + 1];
	UInt32 				kcPathLen = MAXPATHLEN + 1;
	SecKeychainRef 		kcRef = nil;
	OSStatus			ortn;
	
	/* pick a keychain */
	if(kcName) {
		char *userHome = getenv("HOME");
	
		if(userHome == NULL) {
			/* well, this is probably not going to work */
			userHome = "";
		}
		sprintf(kcPath, "%s/%s/%s", userHome, KC_DB_PATH, kcName);
	}
	else {
		/* use default keychain */
		ortn = SecKeychainCopyDefault(&kcRef);
		if(ortn) {
			printf("SecKeychainCopyDefault returned %d; aborting.\n", 
				(int)ortn);
			return nil;
		}
		ortn = SecKeychainGetPath(kcRef, &kcPathLen, kcPath);
		if(ortn) {
			printf("SecKeychainGetPath returned %d; aborting.\n", 
				(int)ortn);
			return nil;
		}
		
		/* 
		 * OK, we have a path, we have to release the first KC ref, 
		 * then get another one by opening it 
		 */
		CFRelease(kcRef);
	}
	ortn = SecKeychainOpen(kcPath, &kcRef);
	if(ortn) {
		printf("SecKeychainOpen returned %d.\n", 
			(int)ortn);
		printf("Cannot open keychain at %s. Aborting.\n", kcPath);
		return nil;
	}
	*pKcRef = kcRef;
	
	/* search for "any" identity matching specified key use; 
	 * in this app, we expect there to be exactly one. */
	 
	SecIdentitySearchRef srchRef = nil;
	ortn = SecIdentitySearchCreate(kcRef, 
		encryptOnly ? CSSM_KEYUSE_DECRYPT : CSSM_KEYUSE_SIGN,
		&srchRef);
	if(ortn) {
		printf("SecIdentitySearchCreate returned %d.\n", (int)ortn);
		printf("Cannot find signing key in keychain at %s. Aborting.\n", 
			kcPath);
		return nil;
	}
	SecIdentityRef identity = nil;
	ortn = SecIdentitySearchCopyNext(srchRef, &identity);
	if(ortn) {
		printf("SecIdentitySearchCopyNext returned %d.\n", (int)ortn);
		printf("Cannot find signing key in keychain at %s. Aborting.\n", 
			kcPath);
		return nil;
	}
	if(CFGetTypeID(identity) != SecIdentityGetTypeID()) {
		printf("SecIdentitySearchCopyNext CFTypeID failure!\n");
		return nil;
	}

	/* 
	 * Found one. Place it in a CFArray. 
	 * TBD: snag other (non-identity) certs from keychain and add them
	 * to array as well.
	 */
	CFArrayRef ca = CFArrayCreate(NULL,
		(const void **)&identity,
		1,
		NULL);
	if(ca == nil) {
		printf("CFArrayCreate error\n");
	}
	return ca;
}

- (void)_listenForTLSHandshake
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"%s", __FUNCTION__);
    Boolean resultReadStream, resultWriteStream;
    
    CFArrayRef certificates = NULL;
	SecKeychainRef serverKc = nil;
    certificates = getSslCerts("certkc.keychain", CSSM_FALSE, &serverKc);
    if (certificates == NULL) DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Didn't find necessary certificates!");
    
    CFMutableDictionaryRef settings = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(settings, kCFStreamSSLLevel, kCFStreamSocketSecurityLevelTLSv1);
    CFDictionaryAddValue(settings, kCFStreamSSLAllowsExpiredRoots, kCFBooleanTrue);
    CFDictionaryAddValue(settings, kCFStreamSSLAllowsAnyRoot, kCFBooleanTrue);
    CFDictionaryAddValue(settings, kCFStreamSSLIsServer, kCFBooleanTrue);
    CFDictionaryAddValue(settings, kCFStreamSSLCertificates, certificates);

    resultReadStream = CFReadStreamSetProperty(I_readStream, kCFStreamPropertySSLSettings, settings);
    resultWriteStream = CFWriteStreamSetProperty(I_writeStream, kCFStreamPropertySSLSettings, settings);
    CFRelease(settings);
    if (resultReadStream && resultWriteStream) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"successfully set kCFStreamPropertySSLSettings");
    } else {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"failed to set kCFStreamPropertySSLSettings");
    }
	//if(serverKc) {
	//	CFRelease(serverKc);
	//}
}

- (void)TCM_writeBytes
{
    if (!([I_writeBuffer length] > 0)) {
        if (![self isInitiator] && I_flags.hasSentTLSProceed) {
            [self _listenForTLSHandshake];
            I_flags.hasSentTLSProceed = NO;
        }
        return;
    }
        
    CFIndex bytesWritten = CFWriteStreamWrite(I_writeStream, [I_writeBuffer bytes], [I_writeBuffer length]);

#ifndef TCM_NO_DEBUG
    if (isLogging && bytesWritten > 0) [I_rawLogOutHandle writeData:[NSData dataWithBytesNoCopy:(void *)[I_writeBuffer bytes] length:bytesWritten freeWhenDone:NO]];
#endif

    if (bytesWritten > 0) {
        DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"bytesWritten: %d", bytesWritten);
        [I_writeBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
    } else if (bytesWritten < 0) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Error occurred while writing bytes.");
    } else {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Stream has reached its capacity");
    }
}

- (void)TCM_handleStreamOpenEvent
{
    if (CFWriteStreamGetStatus(I_writeStream) == kCFStreamStatusOpen &&
        CFReadStreamGetStatus(I_readStream) == kCFStreamStatusOpen) {
        I_sessionStatus = TCMBEEPSessionStatusOpen;
        [self startTerminator];
    }   
}

- (void)TCM_handleStreamHasBytesAvailableEvent
{
    [self triggerTerminator];
    [self TCM_readBytes];
}

- (void)TCM_handleStreamCanAcceptBytesEvent
{
    // fill write buffer
    [self TCM_fillBufferInRoundRobinFashion];

    // when writeBuffer is not empty write bytes to stream
    [self TCM_writeBytes];
}

- (void)TCM_handleStreamAtEndEvent
{
}

- (void)TCM_handleStreamErrorOccurredEvent:(NSError *)error
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"%@", error);
    [self terminate];
}

#pragma mark -

- (void)channelHasFramesAvailable:(TCMBEEPChannel *)aChannel
{
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"channelHasFramesAvailable: %@", aChannel);
    
    // fill writeBuffer in round robin fashion until threshold is reached or no more frames are to sent
    // when flag is set and stream hasSpaceAvailable write bytes to stream when it has space available
    
    [self TCM_fillBufferInRoundRobinFashion];
    
    if ((CFWriteStreamCanAcceptBytes(I_writeStream) == true) && (CFWriteStreamGetStatus(I_writeStream) == kCFStreamStatusOpen)) {
        [self TCM_writeBytes];
    }
}

#pragma mark -

- (void)didReceiveGreetingWithProfileURIs:(NSArray *)profileURIs featuresAttribute:(NSString *)aFeaturesAttribute localizeAttribute:(NSString *)aLocalizeAttribute
{
    [self setPeerLocalizeAttribute:aLocalizeAttribute];
    [self setPeerFeaturesAttribute:aFeaturesAttribute];
    [self setPeerProfileURIs:profileURIs];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMBEEPSessionDidReceiveGreetingNotification object:self];
    
    if ([self isInitiator] && [profileURIs containsObject:TCMBEEPTLSProfileURI]) {
        NSData *data = [@"<ready />" dataUsingEncoding:NSUTF8StringEncoding];
        [self startChannelWithProfileURIs:[NSArray arrayWithObject:TCMBEEPTLSProfileURI]
                                  andData:[NSArray arrayWithObject:data]
                                   sender:self];
        I_flags.isWaitingForTLSProceed = YES;
    } else {
        if ([[self delegate] respondsToSelector:@selector(BEEPSession:didReceiveGreetingWithProfileURIs:)]) {
            [[self delegate] BEEPSession:self didReceiveGreetingWithProfileURIs:profileURIs];
        }
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
        NSString *profileURI = [aProfileURIArray objectAtIndex:i];
        if ([[self profileURIs] containsObject:profileURI]) {
            [requestArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:profileURI, @"ProfileURI", [aDataArray objectAtIndex:i], @"Data", nil]];
            if (!preferedAnswer)  {
                NSData *answerData = [NSData data];
                if ([profileURI hasPrefix:TCMBEEPSASLProfileURIPrefix]) {
                    answerData = [_authServer answerDataForChannelStartProfileURI:profileURI data:[aDataArray objectAtIndex:i]];
                } else if ([profileURI isEqualToString:TCMBEEPTLSProfileURI]) {
                    // parse data for 'ready' element, may have attributes
                    answerData = [@"<proceed />" dataUsingEncoding:NSUTF8StringEncoding];
                    #warning Sent last message before TLS negotiation
                    I_flags.hasSentTLSProceed = YES;
                }
                
                preferedAnswer = [NSMutableDictionary dictionaryWithObjectsAndKeys:profileURI, @"ProfileURI", 
                                                                                   answerData, @"Data",
                                                                                   nil];
            }
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

- (void)initiateChannelWithNumber:(int32_t)aChannelNumber profileURI:(NSString *)aProfileURI data:(NSData *)inData asInitiator:(BOOL)isInitiator
{
    TCMBEEPChannel *channel = [[TCMBEEPChannel alloc] initWithSession:self number:aChannelNumber profileURI:aProfileURI asInitiator:isInitiator];
    [self insertObject:channel inChannelsAtIndex:[self countOfChannels]];
    [channel release];
    
    [self activateChannel:channel];
    if (!isInitiator) {
        if ([aProfileURI hasPrefix:TCMBEEPSASLProfileURIPrefix]) {
            [_authServer setProfile:[channel profile]];
        }
        id delegate = [self delegate];
        if ([delegate respondsToSelector:@selector(BEEPSession:didOpenChannelWithProfile:data:)])
            [delegate BEEPSession:self didOpenChannelWithProfile:[channel profile] data:inData];
    } else {
        if ([aProfileURI isEqualToString:TCMBEEPTLSProfileURI]) {
            // parse associated data for 'error' or 'proceed' elements, 'error' may contain attributes?
            
            I_flags.isWaitingForTLSProceed = NO;
            
            Boolean resultReadStream, resultWriteStream;
            
            resultReadStream = CFReadStreamSetProperty(I_readStream, kCFStreamPropertySocketSecurityLevel, kCFStreamSocketSecurityLevelTLSv1);
            resultWriteStream = CFWriteStreamSetProperty(I_writeStream, kCFStreamPropertySocketSecurityLevel, kCFStreamSocketSecurityLevelTLSv1);
            if (resultReadStream && resultWriteStream) {
                DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"successfully set kCFStreamPropertySocketSecurityLevel");
            } else {
                DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"failed to set kCFStreamPropertySocketSecurityLevel");
            }
                                
            CFMutableDictionaryRef settings = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionaryAddValue(settings, kCFStreamSSLLevel, kCFStreamSocketSecurityLevelTLSv1);
            CFDictionaryAddValue(settings, kCFStreamSSLAllowsExpiredCertificates, kCFBooleanTrue);
            CFDictionaryAddValue(settings, kCFStreamSSLAllowsExpiredRoots, kCFBooleanTrue);
            CFDictionaryAddValue(settings, kCFStreamSSLAllowsAnyRoot, kCFBooleanTrue);
            CFDictionaryAddValue(settings, kCFStreamSSLValidatesCertificateChain, kCFBooleanFalse);
            CFDictionaryAddValue(settings, kCFNull, kCFStreamSSLPeerName);
        
            resultReadStream = CFReadStreamSetProperty(I_readStream, kCFStreamPropertySSLSettings, settings);
            resultWriteStream = CFWriteStreamSetProperty(I_writeStream, kCFStreamPropertySSLSettings, settings);
            CFRelease(settings);
            if (resultReadStream && resultWriteStream) {
                DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"successfully set kCFStreamPropertySSLSettings");
            } else {
                DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"failed to set kCFStreamPropertySSLSettings");
            }
        }
        
        // sender rausfinden
        NSNumber *channelNumber = [NSNumber numberWithInt:aChannelNumber];
        id aSender = [I_channelRequests objectForKey:channelNumber];
        [I_channelRequests removeObjectForKey:channelNumber]; 
        // sender profile geben
        if ([aSender respondsToSelector:@selector(BEEPSession:didOpenChannelWithProfile:data:)]) {
            [aSender BEEPSession:self didOpenChannelWithProfile:[channel profile] data:inData];
        } else {
            NSLog(@"WARNING: Object requested channel doesn't respond to BEEPSession:didOpenChannelWithProfile:data:");
        }
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
    [self initiateChannelWithNumber:aNumber profileURI:aProfileURI data:aData asInitiator:YES];
}

- (void)closeChannelWithNumber:(int32_t)aChannelNumber code:(int)aReplyCode
{
    // verify existance of the referenced channel
    
    [[I_managementChannel profile] closeChannelWithNumber:aChannelNumber code:aReplyCode];
}

- (void)closeRequestedForChannelWithNumber:(int32_t)aChannelNumber
{
    TCMBEEPChannel *channel = [I_activeChannels objectForLong:aChannelNumber];
    [channel closeRequested];
}

- (void)closedChannelWithNumber:(int32_t)aChannelNumber
{
    TCMBEEPChannel *channel = [I_activeChannels objectForLong:aChannelNumber];
    [[channel retain] autorelease];
    [channel closed];
    [channel cleanup];
    
    int indexOfChannel = [I_channels indexOfObject:channel];
    if (indexOfChannel!=NSNotFound) {
        [self removeObjectFromChannelsAtIndex:indexOfChannel];
    
        [I_activeChannels removeObjectForLong:aChannelNumber];
    }
    if (aChannelNumber == 0) {
        [self terminate];
    }
}

- (void)acceptCloseRequestForChannelWithNumber:(int32_t)aChannelNumber
{
    [[I_managementChannel profile] acceptCloseRequestForChannelWithNumber:aChannelNumber];
}

@end

#pragma mark -

void callBackReadStream(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo)
{
    NSAutoreleasePool *pool=nil;
    if (floor(NSFoundationVersionNumber)>NSFoundationVersionNumber10_3) pool=[NSAutoreleasePool new];
    TCMBEEPSession *session = (TCMBEEPSession *)clientCallBackInfo;

    switch(type)
    {
        case kCFStreamEventOpenCompleted:
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFReadStream kCFStreamEventOpenCompleted");
            [session TCM_handleStreamOpenEvent];
            break;

        case kCFStreamEventHasBytesAvailable:
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFReadStream kCFStreamEventHasBytesAvailable");
            [session TCM_handleStreamHasBytesAvailableEvent];
            break;

        case kCFStreamEventErrorOccurred:
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFReadStream kCFStreamEventErrorOccurred");
            CFStreamError myErr = CFReadStreamGetError(stream);
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%d", myErr.domain] code:myErr.error userInfo:nil];
            [session TCM_handleStreamErrorOccurredEvent:error];
            break;

        case kCFStreamEventEndEncountered:
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFReadStream kCFStreamEventEndEncountered");
            [session TCM_handleStreamErrorOccurredEvent:nil];
            break;

        default:
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFReadStream ??");
            break;
    }
    if (floor(NSFoundationVersionNumber)>NSFoundationVersionNumber10_3) [pool release];
}

void callBackWriteStream(CFWriteStreamRef stream, CFStreamEventType type, void *clientCallBackInfo)
{
    NSAutoreleasePool *pool=nil;
    if (floor(NSFoundationVersionNumber)>NSFoundationVersionNumber10_3) pool=[NSAutoreleasePool new];
    TCMBEEPSession *session = (TCMBEEPSession *)clientCallBackInfo;

    switch(type)
    {
        case kCFStreamEventOpenCompleted: {
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFWriteStream kCFStreamEventOpenCompleted");
            [session TCM_handleStreamOpenEvent];
        } break;

        case kCFStreamEventCanAcceptBytes: {
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFWriteStream kCFStreamEventCanAcceptBytes");
            [session TCM_handleStreamCanAcceptBytesEvent];
        } break;

        case kCFStreamEventErrorOccurred:
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFWriteStream kCFStreamEventErrorOccurred");
            CFStreamError myErr = CFWriteStreamGetError(stream);
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%d", myErr.domain] code:myErr.error userInfo:nil];
            [session TCM_handleStreamErrorOccurredEvent:error];
            break;

        case kCFStreamEventEndEncountered:
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFWriteStream kCFStreamEventEndEncountered");
            [session TCM_handleStreamErrorOccurredEvent:nil];
            break;

        default:
            DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"CFWriteStream ??");
            break;
    }
    if (floor(NSFoundationVersionNumber)>NSFoundationVersionNumber10_3) [pool release];
}

