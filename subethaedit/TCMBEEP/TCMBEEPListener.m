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
                NSLog(@"Could not setsockopt to reuseaddr: %@ / %s", errno, strerror(errno));
            }
        } else {
            NSLog(@"Could not create listening socket");
        }
    }
    
    return self;
}

- (void)dealloc
{
    CFRelease(I_listeningSocket);
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
    struct sockaddr_in socketAddress;
    
    bzero(&socketAddress, sizeof(struct sockaddr_in));
    socketAddress.sin_len = sizeof(struct sockaddr_in);
    socketAddress.sin_family = PF_INET;
    socketAddress.sin_port = htons(I_port);
    socketAddress.sin_addr.s_addr = htonl(INADDR_ANY);
    
    CFDataRef addressData = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&socketAddress, sizeof(struct sockaddr_in));
    
    CFSocketError err = CFSocketSetAddress(I_listeningSocket, addressData);
    if (err != kCFSocketSuccess) {
        return NO;
    }
    
    CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, I_listeningSocket, 0);
    CFRunLoopRef currentRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
    CFRelease(runLoopSource);
    CFRelease(addressData);
    
    return YES;
}

- (void)close
{
    CFSocketInvalidate(I_listeningSocket);
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
