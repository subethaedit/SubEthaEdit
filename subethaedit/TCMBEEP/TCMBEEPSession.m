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
#import "GenericSASLProfile.h"
#import <Security/Security.h>
#import "PreferenceKeys.h"

#import <netinet/tcp.h>
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
NSString * const TCMBEEPTLSAnonProfileURI = @"http://www.codingmonkeys.de/BEEP/TLS/Anon";
NSString * const TCMBEEPSASLProfileURIPrefix = @"http://iana.org/beep/SASL/";
NSString * const TCMBEEPSASLANONYMOUSProfileURI = @"http://iana.org/beep/SASL/ANONYMOUS";
NSString * const TCMBEEPSASLPLAINProfileURI = @"http://iana.org/beep/SASL/PLAIN";
NSString * const TCMBEEPSASLCRAMMD5ProfileURI = @"http://iana.org/beep/SASL/CRAM-MD5";
NSString * const TCMBEEPSASLDIGESTMD5ProfileURI = @"http://iana.org/beep/SASL/DIGEST-MD5";
NSString * const TCMBEEPSASLGSSAPIProfileURI = @"http://iana.org/beep/SASL/GSSAPI";
NSString * const TCMBEEPSessionDidReceiveGreetingNotification = @"TCMBEEPSessionDidReceiveGreetingNotification";
NSString * const TCMBEEPSessionDidEndNotification = @"TCMBEEPSessionDidEndNotification";

NSString * const TCMBEEPSessionAuthenticationInformationDidChangeNotification = @"TCMBEEPSessionAuthenticationInformationDidChangeNotification";

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
- (void)TCM_closeChannelsImplicitly;
- (void)TCM_createManagementChannelAndSendGreeting;
- (void)TCM_startTLSHandshake;
- (void)TCM_listenForTLSHandshake;
- (void)TCM_checkForCompletedTLSHandshakeAndRestartManagementChannel;
- (CFArrayRef)TCM_sslCertificatesFromKeychain:(const char *)kcName encryptOnly:(CSSM_BOOL)encryptOnly usedKeychain:(SecKeychainRef*)pKcRef;
- (BOOL)TCM_parseData:(NSData *)data forElement:(NSString **)element attributes:(NSDictionary **)attributes content:(NSString **)content;
@end

#pragma mark -

@implementation TCMBEEPSession

#ifndef TCM_NO_DEBUG
    static unsigned numberOfLogs = 0;
    static NSString *logDirectory = nil;
#endif

static NSString *certKeychainPath = nil;
static CFArrayRef certArrayRef = NULL;
static SecKeychainRef kcRef;
static NSString *pathToTempKeyAndCert = nil;
static NSString *dhparamKeyPath = nil;
static NSDate *launchDate;
static NSString *keychainPassword = nil;
static NSData *dhparamData = nil;

+ (void)removeTemporaryKeychain {
    [[NSFileManager defaultManager] removeFileAtPath:certKeychainPath handler:nil];
}

+ (void)prepareDiffiHellmannParameters {
    NSString *path = nil;
    NSArray *userDomainPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSEnumerator *enumerator = [userDomainPaths objectEnumerator];
    if ((path = [enumerator nextObject])) {
        NSString *fullPath = [path stringByAppendingPathComponent:[[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:nil]) {
             [[NSFileManager defaultManager] createDirectoryAtPath:fullPath attributes:nil];
        }
        dhparamKeyPath = [[fullPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dhparams-%@.des",[NSString UUIDString]]] retain];

       NSTask *opensslTask = [[[NSTask alloc] init] autorelease];
        [opensslTask setStandardError:[NSPipe pipe]];
        [opensslTask setStandardOutput:[NSPipe pipe]];
        [opensslTask setLaunchPath:@"/usr/bin/openssl"]; 
        [opensslTask setArguments:[NSArray arrayWithObjects:
            @"dhparam",
            @"-outform",
            @"DER",
            @"-out",
            dhparamKeyPath,
            @"512",
            nil]];
//         NSLog(@"%s %@",__FUNCTION__,dhparamKeyPath);
        [opensslTask launch];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dhparamsTaskDidFinish:) name:NSTaskDidTerminateNotification object:opensslTask];
	}
}

+ (void)prepareTemporaryCertificate {
    NSString *path;
    
    //create Directories
    NSArray *userDomainPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSEnumerator *enumerator = [userDomainPaths objectEnumerator];
    if ((path = [enumerator nextObject])) {
        NSString *fullPath = [path stringByAppendingPathComponent:[[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:nil]) {
             [[NSFileManager defaultManager] createDirectoryAtPath:fullPath attributes:nil];
        }
        certKeychainPath = [[fullPath stringByAppendingPathComponent:[NSString stringWithFormat:@"seetempcerts-%@.keychain",[NSString UUIDString]]] retain];
        
        // we don't want to add this keychain in the default searchlist so we get the list
        CFArrayRef searchList;
        SecKeychainCopySearchList(&searchList);
        
        keychainPassword = [[NSString UUIDString] retain];
        // generate the temporary keychain
        OSStatus status = SecKeychainCreate (
           [certKeychainPath UTF8String],
           [keychainPassword length],
           [keychainPassword UTF8String],
           FALSE,
           NULL,
           &kcRef
        );
        SecKeychainSettings newKeychainSettings =
                      { SEC_KEYCHAIN_SETTINGS_VERS1, FALSE, FALSE, INT_MAX };
        SecKeychainSetSettings(kcRef, &newKeychainSettings);
//        NSLog(@"%s status:%d keychain:%@",__FUNCTION__,status,kcRef);
        
        // remove from Search list
        status=SecKeychainSetSearchList (searchList);
//        NSLog(@"%s status:%d, list:%@",__FUNCTION__,status,searchList);
        CFRelease(searchList);
        searchList = NULL;

        // generate identity

        pathToTempKeyAndCert = [[certKeychainPath stringByAppendingPathExtension:@"cert"] retain];
        NSTask *opensslTask = [[[NSTask alloc] init] autorelease];
        [opensslTask setStandardError:[NSPipe pipe]];
        [opensslTask setStandardOutput:[NSPipe pipe]];
        [opensslTask setLaunchPath:@"/usr/bin/openssl"]; 
        [opensslTask setArguments:[NSArray arrayWithObjects:
            @"req",
            @"-new",
            @"-x509",
            @"-newkey",
            @"rsa:2048",
            @"-keyout",
            pathToTempKeyAndCert,
            @"-out",
            pathToTempKeyAndCert,
            @"-text",
            @"-days",
            @"365",
            @"-nodes",
            @"-batch",
            nil]];
        [opensslTask launch];
        launchDate = [NSDate new];    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openSSLTaskDidTerminate:) name:NSTaskDidTerminateNotification object:opensslTask];
    }
}

+ (CFArrayRef)certArrayRef {
    return certArrayRef;
}

+ (void)openSSLTaskDidTerminate:(NSNotification *)aNotification {
//    NSTask *task=[aNotification object];
//    NSLog(@"%s %@ %@",__FUNCTION__, [[[NSString alloc] initWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease], [[[NSString alloc] initWithData:[[[task standardError] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease]);
//    NSLog(@"%s generation of certificate took: %f seconds",__FUNCTION__,[launchDate timeIntervalSinceNow]*-1.);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:[aNotification object]];
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"TCMBEEPTempCertificateCreationForSSLDidFinish" object:self] postingStyle:NSPostASAP coalesceMask:NSNotificationNoCoalescing forModes:nil];
    
    SecKeychainItemImport (
        (CFDataRef)[NSData dataWithContentsOfFile:pathToTempKeyAndCert],
        NULL,
        kSecFormatUnknown,
        kSecItemTypeUnknown,
        0,
        NULL,
        kcRef,
        NULL
    );

    // delete temp key and cert
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeFileAtPath:pathToTempKeyAndCert handler:nil];
    [pathToTempKeyAndCert release];
    pathToTempKeyAndCert = nil;
    
    OSStatus ortn;
    SecIdentitySearchRef srchRef = nil;
    ortn = SecIdentitySearchCreate(kcRef,CSSM_KEYUSE_SIGN,&srchRef);
    if (ortn) {
        printf("SecIdentitySearchCreate returned %d.\n", (int)ortn);
        printf("Cannot find signing key in temporary keychain. Aborting.\n");
        return;
    }
    SecIdentityRef identity = nil;
    ortn = SecIdentitySearchCopyNext(srchRef, &identity);
    if(ortn) {
        printf("SecIdentitySearchCopyNext returned %d.\n", (int)ortn);
        printf("Cannot find signing key in temporary keychain. Aborting.\n");
        return;
    }
    if(CFGetTypeID(identity) != SecIdentityGetTypeID()) {
        printf("SecIdentitySearchCopyNext CFTypeID failure!\n");
        return;
    }

    certArrayRef = CFArrayCreate(NULL,(const void **)&identity,1,NULL);
        
    if(certArrayRef == nil) {
        printf("CFArrayCreate error\n");
    }
    CFRelease(srchRef);
}

+ (void)dhparamsTaskDidFinish:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:[aNotification object]];

//    NSTask *task=[aNotification object];
//    NSLog(@"%s %@ %@",__FUNCTION__, [[[NSString alloc] initWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease], [[[NSString alloc] initWithData:[[[task standardError] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease]);

	NSError *error = nil;
	dhparamData = [[NSData dataWithContentsOfFile:dhparamKeyPath options:0 error:&error] retain];
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"TCMBEEPTempCertificateCreationForSSLDidFinish" object:self] postingStyle:NSPostASAP coalesceMask:NSNotificationNoCoalescing forModes:nil];
}

+ (void)setAnonCiphersOnStreamData:(CFDataRef)inSocketDataRef dhParams:(BOOL)aFlag{
	CFDataRef data = inSocketDataRef;
	
	// Extract the SSLContextRef from the CFData
	SSLContextRef sslContext;
	CFDataGetBytes(data, CFRangeMake(0, sizeof(SSLContextRef)), (UInt8 *)&sslContext);

	SSLCipherSuite ciphers[] = {TLS_DH_anon_WITH_AES_256_CBC_SHA, TLS_DH_anon_WITH_AES_128_CBC_SHA}; // order does matter - in SL we'll get TLS_ECDH_anon_WITH_AES_256_CBC_SHA as well

	// 	TLS_ECDH_anon_WITH_AES_256_CBC_SHA     =	0xC019, available in snow leopard, but already active here

	OSStatus err = SSLSetEnabledCiphers(sslContext,ciphers,2);
//	printf("set ciphers with error: %d\n",(int)err);
    if (aFlag) {
		err = SSLSetDiffieHellmanParams(sslContext,[dhparamData bytes],[dhparamData length]);
		printf("SSLSetDiffieHellmanParams with error: %d\n",(int)err);
	}
}

- (void)TCM_initHelper
{
    I_flags.hasSentTLSProceed = NO;
    I_flags.isWaitingForTLSProceed = NO;
    I_flags.isTLSHandshaking = NO;
    I_flags.isTLSEnabled = NO;
    I_flags.isTLSAnon = NO;
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
    I_TLSProfileURIs = [NSMutableArray new];
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
            name = [NSString stringWithFormat:@"%@-p%d-s%d", [[NSCalendarDate date] descriptionWithCalendarFormat:@"%Y-%m-%d--%H-%M-%S.%F-"], [[NSProcessInfo processInfo] processIdentifier], sequenceNumber];
            name = [[origPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
        } while ([[NSFileManager defaultManager] fileExistsAtPath:name]);

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
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:EnableTLSKey]) {
        	if ([dhparamData length] > 0) {
//        		NSLog(@"%s added %@",__FUNCTION__,TCMBEEPTLSAnonProfileURI);
				[self addProfileURIs:[NSArray arrayWithObject:TCMBEEPTLSAnonProfileURI]];
			}
        	if ([TCMBEEPSession certArrayRef] && 
            	[(NSArray *)[TCMBEEPSession certArrayRef] count]>0) {
//        		NSLog(@"%s added %@",__FUNCTION__,TCMBEEPTLSProfileURI);
            	[self addProfileURIs:[NSArray arrayWithObject:TCMBEEPTLSProfileURI]];
           	}
        }
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
    [I_authenticationInformation release];
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
    [I_TLSProfileURIs release];
    [I_saslProfileURIs release];
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

- (id)authenticationInformation {
    return I_authenticationInformation;
}

- (void)setAuthenticationInformation:(id)anInformation {
    [I_authenticationInformation autorelease];
     I_authenticationInformation = [anInformation retain];
}

- (void)setAuthenticationDelegate:(id)aDelegate
{
    I_authenticationDelegate = aDelegate;
}

- (id)authenticationDelegate
{
    return I_authenticationDelegate;
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

- (void)addTLSProfileURIs:(NSArray *)anArray {
    if (!I_TLSProfileURIs) I_TLSProfileURIs = [[NSMutableArray alloc] init];
    [I_TLSProfileURIs addObjectsFromArray:anArray];
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

- (BOOL)isAuthenticated {
    return NO;
}

- (BOOL)isTLSEnabled {
    return I_flags.isTLSEnabled;
}

- (BOOL)isTLSAnon {
    return I_flags.isTLSAnon;
}

- (NSArray *)channels {
    return I_channels;
}

- (int32_t)nextChannelNumber {
    I_nextChannelNumber += 2;
    return I_nextChannelNumber;
}

- (int)maximumFrameSize {
    return I_maximumFrameSize;
}

- (TCMBEEPSessionStatus)sessionStatus {
    return I_sessionStatus;
}

- (void)activateChannel:(TCMBEEPChannel *)aChannel
{
    [I_activeChannels setObject:aChannel forLong:[aChannel number]];
}

- (void)TCM_createManagementChannelAndSendGreeting
{
    I_managementChannel = [[TCMBEEPChannel alloc] initWithSession:self number:0 profileURI:kTCMBEEPManagementProfile asInitiator:[self isInitiator]];
    [self insertObject:I_managementChannel inChannelsAtIndex:[self countOfChannels]];
    
    TCMBEEPManagementProfile *profile = (TCMBEEPManagementProfile *)[I_managementChannel profile];
    [profile setDelegate:self];

    [self activateChannel:I_managementChannel];
    
    [profile sendGreetingWithProfileURIs:[self profileURIs] featuresAttribute:nil localizeAttribute:nil];
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
        if (remoteHostName) CFRelease(remoteHostName);
    }
    
    I_sessionStatus = TCMBEEPSessionStatusOpening;
    
    [self TCM_createManagementChannelAndSendGreeting];
}

- (void)TCM_closeChannelsImplicitly
{
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
    
    [self TCM_closeChannelsImplicitly];
        
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(BEEPSession:didFailWithError:)]) {
        NSError *error = [NSError errorWithDomain:@"BEEPDomain" code:451 userInfo:nil];
        [delegate BEEPSession:self didFailWithError:error];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMBEEPSessionDidEndNotification object:self];
}

- (void)TCM_checkForCompletedTLSHandshakeAndRestartManagementChannel
{
    if (I_flags.isTLSHandshaking && !I_flags.isTLSEnabled) {
        // send greeting
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Life after TLS handshake...");

        DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"writeBuffer length: %d, readBuffer length: %d", [I_writeBuffer length], [I_readBuffer length]);

        I_flags.isTLSEnabled = YES;
        [self setProfileURIs:I_TLSProfileURIs];
        [self TCM_createManagementChannelAndSendGreeting];
        I_flags.isTLSHandshaking = NO;
        
        
//		// check the cipher used
//		SSLContextRef sslContext;
//		CFDataGetBytes(CFReadStreamCopyProperty(I_readStream,  kCFStreamPropertySocketSSLContext), CFRangeMake(0, sizeof(SSLContextRef)), (UInt8 *)&sslContext);
//		SSLCipherSuite negotiatedCipher = 0;
//		SSLGetNegotiatedCipher(sslContext, &negotiatedCipher);
//		NSLog(@"%s negotiated Cipher is:%X",__FUNCTION__,negotiatedCipher);
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
- (CFArrayRef)TCM_sslCertificatesFromKeychain:(const char *)kcName	// may be NULL, i.e., use default
	encryptOnly:(CSSM_BOOL)encryptOnly
	usedKeychain:(SecKeychainRef*)pKcRef // RETURNED
{
    SecKeychainStatus keychainStatus;
    OSStatus result = SecKeychainGetStatus(kcRef,&keychainStatus);
//    NSLog(@"%s result was %d, status was %d",__FUNCTION__,result, keychainStatus);
    if (result == noErr && !(keychainStatus && kSecUnlockStateStatus)) {
//        NSLog(@"%s keychain was locked!",__FUNCTION__);
        SecKeychainUnlock(kcRef,[keychainPassword length],[keychainPassword UTF8String],TRUE);
    } else if (result != noErr) {
        return nil;
    }
    return certArrayRef; // shortcut for now
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

- (void)TCM_listenForTLSHandshake
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"%s", __FUNCTION__);
    
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"writeBuffer length: %d, readBuffer length: %d", [I_writeBuffer length], [I_readBuffer length]);
    
    
    Boolean resultReadStream, resultWriteStream;
    
    CFArrayRef certificates = NULL;

    if (!I_flags.isTLSAnon) {
		SecKeychainRef serverKc = nil;
		certificates = [self TCM_sslCertificatesFromKeychain:"certkc.keychain" encryptOnly:CSSM_FALSE usedKeychain:&serverKc];
		if (certificates == NULL) DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Didn't find necessary certificates!");
	}

    
    CFMutableDictionaryRef settings = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(settings, kCFStreamSSLLevel, kCFStreamSocketSecurityLevelTLSv1);
    CFDictionaryAddValue(settings, kCFStreamSSLAllowsExpiredRoots, kCFBooleanTrue);
    CFDictionaryAddValue(settings, kCFStreamSSLAllowsAnyRoot, kCFBooleanTrue);
    CFDictionaryAddValue(settings, kCFStreamSSLIsServer, kCFBooleanTrue);
    if (!I_flags.isTLSAnon) {
	    CFDictionaryAddValue(settings, kCFStreamSSLCertificates, certificates);
	}

    resultReadStream = CFReadStreamSetProperty(I_readStream, kCFStreamPropertySSLSettings, settings);
    resultWriteStream = CFWriteStreamSetProperty(I_writeStream, kCFStreamPropertySSLSettings, settings);
    CFRelease(settings);

    if (I_flags.isTLSAnon) {
		[TCMBEEPSession setAnonCiphersOnStreamData: CFReadStreamCopyProperty(I_readStream,  kCFStreamPropertySocketSSLContext) dhParams:YES];
		[TCMBEEPSession setAnonCiphersOnStreamData:CFWriteStreamCopyProperty(I_writeStream, kCFStreamPropertySocketSSLContext) dhParams:YES];
	}

    if (resultReadStream && resultWriteStream) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"successfully set kCFStreamPropertySSLSettings");
    } else {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"failed to set kCFStreamPropertySSLSettings");
    }
}

- (void)TCM_writeBytes
{
    if (!([I_writeBuffer length] > 0)) {
        return;
    }
    
    CFIndex bytesWritten = 0;
    if ((CFWriteStreamCanAcceptBytes(I_writeStream) == true) && (CFWriteStreamGetStatus(I_writeStream) == kCFStreamStatusOpen)) {
        bytesWritten = CFWriteStreamWrite(I_writeStream, [I_writeBuffer bytes], [I_writeBuffer length]);
    }
    
#ifndef TCM_NO_DEBUG
    if (isLogging && bytesWritten > 0) [I_rawLogOutHandle writeData:[NSData dataWithBytesNoCopy:(void *)[I_writeBuffer bytes] length:bytesWritten freeWhenDone:NO]];
#endif

    if (bytesWritten > 0) {
        DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"bytesWritten: %d", bytesWritten);
        [I_writeBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        
        if (!([I_writeBuffer length] > 0)) {
            if (![self isInitiator] && I_flags.hasSentTLSProceed) {
                DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Start listen for TLS handshake...");
                [self TCM_closeChannelsImplicitly];
                [self TCM_listenForTLSHandshake];
                I_flags.hasSentTLSProceed = NO;
                I_flags.isTLSHandshaking = YES;
            }
            return;
        }
    
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
    [self TCM_checkForCompletedTLSHandshakeAndRestartManagementChannel];

    [self triggerTerminator];
    [self TCM_readBytes];
}

- (void)TCM_handleStreamCanAcceptBytesEvent
{
    [self TCM_checkForCompletedTLSHandshakeAndRestartManagementChannel];

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
    if ([error code] == errSecNoSuchKeychain) {
        certArrayRef = NULL;
    }
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
//    NSLog(@"%s", __FUNCTION__);
    [self setPeerLocalizeAttribute:aLocalizeAttribute];
    [self setPeerFeaturesAttribute:aFeaturesAttribute];
    [self setPeerProfileURIs:profileURIs];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMBEEPSessionDidReceiveGreetingNotification object:self];
    
    // check for tuning profiles and initiate tuning
    if ([self isInitiator] && ([profileURIs containsObject:TCMBEEPTLSProfileURI] || [profileURIs containsObject:TCMBEEPTLSAnonProfileURI])) {
    	NSString *profileURI = TCMBEEPTLSProfileURI;
    	if ([profileURIs containsObject:TCMBEEPTLSAnonProfileURI]) {
    		I_flags.isTLSAnon = YES; // set to anon
    		profileURI = TCMBEEPTLSAnonProfileURI;
    	}
        NSData *data = [@"<ready />" dataUsingEncoding:NSUTF8StringEncoding];
        [self startChannelWithProfileURIs:[NSArray arrayWithObject:profileURI]
                                  andData:[NSArray arrayWithObject:data]
                                   sender:self];
        I_flags.isWaitingForTLSProceed = YES;
    } else { // nothing to tune so let us rock
        if ([[self delegate] respondsToSelector:@selector(BEEPSession:didReceiveGreetingWithProfileURIs:)]) {
            [[self delegate] BEEPSession:self didReceiveGreetingWithProfileURIs:profileURIs];
        }
    }
}

- (BOOL)TCM_parseData:(NSData *)data forElement:(NSString **)element attributes:(NSDictionary **)attributes content:(NSString **)content
{
    BOOL result = YES;
    // Parse XML
    CFXMLTreeRef contentTree = NULL;
    NSDictionary *errorDict;
    
    // create XML tree from payload
    contentTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,
                                (CFDataRef)data,
                                NULL, //sourceURL
                                kCFXMLParserSkipWhitespace | kCFXMLParserSkipMetaData,
                                kCFXMLNodeCurrentVersion,
                                (CFDictionaryRef *)&errorDict);
    if (!contentTree) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"nixe baum: %@", [errorDict description]);
        result = NO;
    }
    
    CFXMLNodeRef node = NULL;
    CFXMLTreeRef xmlTree = NULL;
    if (result) {
        // extract top level element from tree
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
            result = NO;
        }
    }
    
    if (result) {
        *element = [[(NSString *)CFXMLNodeGetString(node) retain] autorelease];
        CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(node);
        *attributes = [[(NSDictionary *)info->attributes retain] autorelease];
        NSMutableString *contentString = [NSMutableString string];
        int childCount = CFTreeGetChildCount(xmlTree);
        int index;
        for (index = 0; index < childCount; index++) {
            CFXMLTreeRef subTree = CFTreeGetChildAtIndex(xmlTree, index);
            CFXMLNodeRef textNode = CFXMLTreeGetNode(subTree);
            if (CFXMLNodeGetTypeCode(textNode) == kCFXMLNodeTypeText) {
                [contentString appendString:(NSString *)CFXMLNodeGetString(textNode)];
            }
        }
        if ([contentString length] > 0)
            *content = contentString;
        else
            *content = nil;
    } else {
        *element = nil;
        *attributes = nil;
        *content = nil;
    }
    
    if (contentTree) CFRelease(contentTree);
    return result;
}

- (NSMutableDictionary *)preferedAnswerToAcceptRequestForChannel:(int32_t)channelNumber withProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray
{
    // Profile URIs ausduennen 
    NSMutableArray *requestArray = [NSMutableArray array];
    NSMutableDictionary *preferedAnswer = nil;
//    NSLog(@"profileURIs: %@ selfProfileURIs:%@ peerProfileURIs:%@\n\nSession:%@", aProfileURIArray, [self profileURIs], [self peerProfileURIs], self);
    int i;
    for (i = 0; i < [aProfileURIArray count]; i++) {
        NSString *profileURI = [aProfileURIArray objectAtIndex:i];
        if ([[self profileURIs] containsObject:profileURI]) {
            NSData *requestData = [aDataArray objectAtIndex:i];
            [requestArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:profileURI, @"ProfileURI", requestData, @"Data", nil]];
            if (!preferedAnswer)  {
                NSData *answerData = [NSData data];
                if ([profileURI isEqualToString:TCMBEEPTLSProfileURI] || [profileURI isEqualToString:TCMBEEPTLSAnonProfileURI]) {
                    // parse data for 'ready' element, may have attribute
                    NSString *element, *content;
                    NSDictionary *attributes;
                    BOOL result = [self TCM_parseData:[aDataArray objectAtIndex:i] forElement:&element attributes:&attributes content:&content];
                    if (result) DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"element: %@, attributes: %@, content: %@", element, attributes, content);
                    if (result && [element isEqualToString:@"ready"]) {
                        BOOL shouldProceed = YES;
                        NSString *version = [attributes objectForKey:@"version"];
                        if (version && ![version isEqualToString:@"1"]) {
                            shouldProceed = NO;
                            answerData = [@"<error code='501'>version attribute poorly formed in &lt;ready&gt; element</error>" dataUsingEncoding:NSUTF8StringEncoding];
//                            #warning Opened TLS channel but there is no TLS
                        }
                        
                        if (shouldProceed) {
                            answerData = [@"<proceed />" dataUsingEncoding:NSUTF8StringEncoding];
                            // implicitly close all channels including channel zero, but proceed frame needs to go through
                            I_flags.hasSentTLSProceed = YES;
                            if ([profileURI isEqualToString:TCMBEEPTLSAnonProfileURI]) {
                            	I_flags.isTLSAnon = YES;
                            }
                        }
                                           
                    } else {
                        // Terminate session?
                    }
                } else if ([profileURI hasPrefix:TCMBEEPSASLProfileURIPrefix]) {
                    preferedAnswer = (NSMutableDictionary *)[GenericSASLProfile replyForChannelRequestWithProfileURI:profileURI andData:requestData inSession:self];
                    break;
                }
                
                preferedAnswer = [NSMutableDictionary dictionaryWithObjectsAndKeys:profileURI, @"ProfileURI", 
                                                                                   answerData, @"Data",
                                                                                   nil];
                break;
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

- (void)TCM_startTLSHandshake
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Start TLS handshake...");
    
    // implicitly close all channels including channel zero and begin underlying negotiation process
    [self TCM_closeChannelsImplicitly];
    
    DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"writeBuffer length: %d, readBuffer length: %d", [I_writeBuffer length], [I_readBuffer length]);

    I_flags.isWaitingForTLSProceed = NO;
    I_flags.isTLSHandshaking = YES;
    
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
    
    if (I_flags.isTLSAnon) {
		[TCMBEEPSession setAnonCiphersOnStreamData: CFReadStreamCopyProperty(I_readStream,  kCFStreamPropertySocketSSLContext) dhParams:NO];
		[TCMBEEPSession setAnonCiphersOnStreamData:CFWriteStreamCopyProperty(I_writeStream, kCFStreamPropertySocketSSLContext) dhParams:NO];
	}
    
    if (resultReadStream && resultWriteStream) {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"successfully set kCFStreamPropertySSLSettings");
    } else {
        DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"failed to set kCFStreamPropertySSLSettings");
    }
}

- (void)initiateChannelWithNumber:(int32_t)aChannelNumber profileURI:(NSString *)aProfileURI data:(NSData *)inData asInitiator:(BOOL)isInitiator
{
    TCMBEEPChannel *channel = [[TCMBEEPChannel alloc] initWithSession:self number:aChannelNumber profileURI:aProfileURI asInitiator:isInitiator];
    [[channel profile] handleInitializationData:inData];
    [self insertObject:channel inChannelsAtIndex:[self countOfChannels]];
    [channel release];
    
    [self activateChannel:channel];
    if (!isInitiator) {
        id delegate = [self delegate];
        if ([delegate respondsToSelector:@selector(BEEPSession:didOpenChannelWithProfile:data:)])
            [delegate BEEPSession:self didOpenChannelWithProfile:[channel profile] data:inData];
    } else {
        if ([aProfileURI isEqualToString:TCMBEEPTLSProfileURI] || [aProfileURI isEqualToString:TCMBEEPTLSAnonProfileURI]) {
            // parse associated data for 'error' or 'proceed' elements, 'error' may contain attributes?
            NSString *element, *content;
            NSDictionary *attributes;
            BOOL result = [self TCM_parseData:inData forElement:&element attributes:&attributes content:&content];
            if (result) {
                DEBUGLOG(@"BEEPLogDomain", AllLogLevel, @"element: %@, attributes: %@, content: %@", element, attributes, content);
                if ([element isEqualToString:@"proceed"] && attributes == nil && content == nil) {
                    [self TCM_startTLSHandshake];
                } else if ([element isEqualToString:@"error"]) {
                    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Received error: %@ (%@)", [attributes objectForKey:@"code"], content);
//                    #warning Opened TLS channel but there is no TLS
                }
            } else {
                // Terminate session?
            }
        } else if ([aProfileURI isEqualToString:TCMBEEPSASLPLAINProfileURI]) {
            NSLog(@"%s",__FUNCTION__);
            // need to close it directly because this one doesn't do anything else
            [GenericSASLProfile processPLAINAnswer:inData inSession:self];
            [[channel profile] close];
        }
        // sender rausfinden
        NSNumber *channelNumber = [NSNumber numberWithInt:aChannelNumber];
        id aSender = [I_channelRequests objectForKey:channelNumber];
        [I_channelRequests removeObjectForKey:channelNumber]; 
        // sender profile geben
        if ([aSender respondsToSelector:@selector(BEEPSession:didOpenChannelWithProfile:data:)]) {
            [aSender BEEPSession:self didOpenChannelWithProfile:[channel profile] data:inData];
        } else if (![aProfileURI isEqualToString:TCMBEEPTLSProfileURI] && ![aProfileURI isEqualToString:TCMBEEPTLSAnonProfileURI]) {
            NSLog(@"WARNING: The Object (%@) that requested the channel with ProfileURI:%@ doesn't respond to BEEPSession:didOpenChannelWithProfile:data:",aSender,aProfileURI);
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

#pragma mark ### Authentication ###

- (NSArray *)availableSASLProfileURIs {
    if (!I_saslProfileURIs) {
        I_saslProfileURIs = [NSMutableArray new];
        NSEnumerator *profiles = [[self peerProfileURIs] objectEnumerator];
        NSString *profileURI = nil;
        while ((profileURI=[profiles nextObject])) {
            if ([profileURI hasPrefix:TCMBEEPSASLProfileURIPrefix]) {
                [I_saslProfileURIs addObject:profileURI];
            }
        }
    }
    return I_saslProfileURIs;
}

- (void)startAuthenticationWithUserName:(NSString *)aUserName password:(NSString *)aPassword profileURI:(NSString *)aProfileURI {
    [self startChannelWithProfileURIs:[NSArray arrayWithObject:aProfileURI]
                              andData:[NSArray arrayWithObject:[GenericSASLProfile initialDataForUserName:aUserName password:aPassword profileURI:aProfileURI]]
                               sender:self];
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

