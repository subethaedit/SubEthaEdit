//
//  TCMBEEPListener.m
//  TCMBEEP
//
//  Created by Martin Ott on Mon Feb 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPListener.h"
#import "TCMBEEPSession.h"

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <sys/socket.h>


static void acceptConnection(CFSocketRef aSocketRef, CFSocketCallBackType aType, CFDataRef anAddress, const void* aData, void* aContext);

#pragma mark -

@interface TCMBEEPListener (TCMBEEPListenerPrivateAdditions)

- (void)TCM_acceptSocket:(CFSocketNativeHandle)aSocketHandle withAddressData:(NSData *)inAddress;

@end

#pragma mark -

@implementation TCMBEEPListener

- (id)initWithPort:(unsigned int)aPort
{
    self = [super init];
    
    if (self) {
        I_port = aPort;
        
        CFSocketContext socketContext;
        bzero(&socketContext, sizeof(CFSocketContext));
        socketContext.info = self;
        
        int yes = 1;
        I_listeningSocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 
                                           kCFSocketAcceptCallBack, acceptConnection, &socketContext);
        if (I_listeningSocket) {
            int result = setsockopt(CFSocketGetNative(I_listeningSocket), SOL_SOCKET, 
                                    SO_REUSEADDR, &yes, sizeof(int));
            if (result == -1) {
                DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Could not setsockopt to reuseaddr: %@ / %s", errno, strerror(errno));
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
                DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"Could not setsockopt to reuseaddr: %@ / %s", errno, strerror(errno));
            }
        } else {
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"Could not create listening socket for IPv6");
        }        
        
    }
    
    return self;
}

- (void)dealloc
{
    I_delegate = nil;
    CFRelease(I_listeningSocket);
    CFRelease(I_listeningSocket6);
    [super dealloc];
}

- (void)setDelegate:(id)aDelegate
{
    I_delegate = aDelegate;
}

- (id)delegate
{
    return I_delegate;
}

- (BOOL)listen
{
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
        
        return YES;
    } while (0);
    
    
    if (addressData)
        CFRelease(addressData);
        
    if (addressData6)
        CFRelease(addressData6);
    
    return NO;
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
    
    if ([I_delegate respondsToSelector:@selector(BEEPListener:shouldAcceptBEEPSession:)]) {
        BOOL shouldAccept = [I_delegate BEEPListener:self shouldAcceptBEEPSession:session];
        
        if (shouldAccept) {
            if ([I_delegate respondsToSelector:@selector(BEEPListener:didAcceptBEEPSession:)]) {
                [I_delegate BEEPListener:self didAcceptBEEPSession:session];
            }
        }
    }
    
    [session release];
}

#pragma mark -

void acceptConnection(CFSocketRef aSocketRef, CFSocketCallBackType aType, CFDataRef anAddress, const void* aData, void* aContext)
{
    TCMBEEPListener *listener = (TCMBEEPListener *)aContext;
    [listener TCM_acceptSocket:*(CFSocketNativeHandle*)aData withAddressData:(NSData *)anAddress];
}

@end
