//  TCMBEEPListener.m
//  TCMBEEP
//
//  Created by Martin Ott on Mon Feb 16 2004.

#import "TCMBEEPListener.h"
#import "TCMBEEPSession.h"

#import <netinet/tcp.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <sys/socket.h>

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

static void acceptConnection(CFSocketRef aSocketRef, CFSocketCallBackType aType, CFDataRef anAddress, const void* aData, void* aContext);

#pragma mark -

@interface TCMBEEPListener (TCMBEEPListenerPrivateAdditions)

- (void)TCM_acceptSocket:(CFSocketNativeHandle)aSocketHandle withAddressData:(NSData *)inAddress;

@end

#pragma mark -

@implementation TCMBEEPListener

- (instancetype)initWithPort:(unsigned int)aPort
{
    self = [super init];
    
    if (self) {
        I_port = aPort;
        
        CFSocketContext socketContext;
        bzero(&socketContext, sizeof(CFSocketContext));
        socketContext.info = (__bridge void *)(self);
        
        int yes = 1;
        I_listeningSocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 
                                           kCFSocketAcceptCallBack, acceptConnection, &socketContext);
        if (I_listeningSocket) {
            int result = setsockopt(CFSocketGetNative(I_listeningSocket), SOL_SOCKET, 
                                    SO_REUSEADDR, &yes, sizeof(int));
            if (result == -1) {
                DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Could not setsockopt to reuseaddr: %i / %s", errno, strerror(errno));
            }
            
            result = setsockopt(CFSocketGetNative(I_listeningSocket), IPPROTO_TCP, 
                                    TCP_NODELAY, &yes, sizeof(int));
            if (result == -1) {
                DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Could not setsockopt to TCP_NODELAY: %i / %s", errno, strerror(errno));
            }
        } else {
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Could not create listening socket for IPv4");
        }

        I_listeningSocket6 = CFSocketCreate(kCFAllocatorDefault, PF_INET6, SOCK_STREAM, IPPROTO_TCP, 
                                           kCFSocketAcceptCallBack, acceptConnection, &socketContext);
        if (I_listeningSocket6) {
            int result = setsockopt(CFSocketGetNative(I_listeningSocket6), SOL_SOCKET, 
                                    SO_REUSEADDR, &yes, sizeof(int));
            if (result == -1) {
                DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Could not setsockopt to reuseaddr: %i / %s", errno, strerror(errno));
            }
            
            result = setsockopt(CFSocketGetNative(I_listeningSocket6), IPPROTO_TCP, 
                                    TCP_NODELAY, &yes, sizeof(int));
            if (result == -1) {
                DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Could not setsockopt to TCP_NODELAY: %i / %s", errno, strerror(errno));
            }
        } else {
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Could not create listening socket for IPv6");
        }        
        
    }
    
    return self;
}

- (void)dealloc
{
    
    CFRelease(I_listeningSocket);
    CFRelease(I_listeningSocket6);
}

- (BOOL)listen
{
	BOOL success = NO;
    CFDataRef addressData = NULL;
    CFDataRef addressData6 = NULL;
    
    do {
        struct sockaddr_in socketAddress;
        
        bzero(&socketAddress, sizeof(struct sockaddr_in));
        socketAddress.sin_len = sizeof(struct sockaddr_in);
        socketAddress.sin_family = PF_INET;
        socketAddress.sin_port = htons(I_port);
        socketAddress.sin_addr.s_addr = htonl(INADDR_ANY);
        
        addressData = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&socketAddress, sizeof(struct sockaddr_in));
        if (addressData == NULL)
            break;
            
        CFSocketError err = CFSocketSetAddress(I_listeningSocket, addressData);
        if (err != kCFSocketSuccess) {
            break;
        }
        
        CFRelease(addressData);
        addressData = NULL;
        
        
        struct sockaddr_in6 socketAddress6;
        
        bzero(&socketAddress6, sizeof(struct sockaddr_in6));
        socketAddress6.sin6_len = sizeof(struct sockaddr_in6);
        socketAddress6.sin6_family = PF_INET6;
        socketAddress6.sin6_port = htons(I_port);
        memcpy(&(socketAddress6.sin6_addr), &in6addr_any, sizeof(socketAddress6.sin6_addr));
        
        addressData6 = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&socketAddress6, sizeof(struct sockaddr_in6));
        if (addressData6 == NULL)
            break;
        
        err = CFSocketSetAddress(I_listeningSocket6, addressData6);
        if (err != kCFSocketSuccess) {
            break;
        }
        
        CFRelease(addressData6);
        addressData6 = NULL;
        
        
        CFRunLoopRef currentRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];

        CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, I_listeningSocket, 0);
        CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
        
        CFRunLoopSourceRef runLoopSource6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, I_listeningSocket6, 0);
        CFRunLoopAddSource(currentRunLoop, runLoopSource6, kCFRunLoopCommonModes);
        CFRelease(runLoopSource6);
        
        success = YES;
    } while (0);
    
    // The 'CFSocketSetAddress listen failure: 102' log seems to be expected and harmless. See https://forums.developer.apple.com/thread/106590
    // CFSocket will also log all unsuccessful port attempts, if the port is already taken (which is expected here as well, as we increment the port until we have a free one)
    
    if (addressData)
        CFRelease(addressData);
        
    if (addressData6)
        CFRelease(addressData6);
    
    return success;
}

- (void)close
{
    CFSocketInvalidate(I_listeningSocket);
    CFSocketInvalidate(I_listeningSocket6);
}

#pragma mark -

- (void)TCM_acceptSocket:(CFSocketNativeHandle)aSocketHandle withAddressData:(NSData *)inAddress
{
    TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithSocket:aSocketHandle addressData:inAddress];
    
    if ([_delegate respondsToSelector:@selector(BEEPListener:shouldAcceptBEEPSession:)]) {
        BOOL shouldAccept = [_delegate BEEPListener:self shouldAcceptBEEPSession:session];
        
        if (shouldAccept) {
            if ([_delegate respondsToSelector:@selector(BEEPListener:didAcceptBEEPSession:)]) {
                [_delegate BEEPListener:self didAcceptBEEPSession:session];
            }
        }
    }
}

#pragma mark -

void acceptConnection(CFSocketRef aSocketRef, CFSocketCallBackType aType, CFDataRef anAddress, const void* aData, void* aContext)
{
    @autoreleasepool {
        TCMBEEPListener *listener = (__bridge TCMBEEPListener *)aContext;
        [listener TCM_acceptSocket:*(CFSocketNativeHandle*)aData withAddressData:(__bridge NSData *)anAddress];
    }
}

@end
