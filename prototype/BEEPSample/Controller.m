//
//  Controller.m
//  BEEPSample
//
//  Created by Martin Ott on Tue Feb 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "Controller.h"
#import "TCMBEEPListener.h"
#import "TCMBEEPSession.h"

#import <netdb.h>
#import <netinet/in.h>

@implementation Controller

-(id)init {
    if ((self=[super init])) {
        
    }
    return self;
}

-(void)dealloc {
    [I_listener release];
    [super dealloc];
}

- (IBAction)connect:(id)aSender {
    NSString *address=[O_peerAddressTextField stringValue];
    int portNumber=[O_ports intValue];
    
    struct hostent *hostInfo = gethostbyname([address cString]);
    struct sockaddr_in peerAddress;
    bzero(&peerAddress, sizeof(struct sockaddr_in));
    peerAddress.sin_len = sizeof(struct sockaddr_in);
    peerAddress.sin_family = PF_INET;
    peerAddress.sin_port = htons(portNumber);
    peerAddress.sin_addr = *((struct in_addr *)(hostInfo->h_addr));
    
    NSData *addressData = [NSData dataWithBytes:&peerAddress length:sizeof(struct sockaddr_in)];
    
    NSLog(@"Generated addressdata: %@",[NSString stringWithAddressData:addressData]);
    
    TCMBEEPSession *session = [[TCMBEEPSession alloc] initWithAddressData:addressData];
    [session open];
    if (session) {
        NSLog(@"Session opened: %@",[session description]);
    }
}

- (IBAction)toggleListener:(id)aSender {
    if (!I_listener) {
        I_listener=[[TCMBEEPListener alloc]initWithPort:12347];
        [I_listener setDelegate:self];
        if ([I_listener listen]) {
            [O_listenerControlButton setTitle:@"stop listening"];
        } else {
            NSLog(@"Could not listen (%@)",[I_listener description]);
            [I_listener close];
            [I_listener release];
            I_listener=nil;
        }
        
    } else {
        [I_listener close];
        [I_listener release];
        I_listener=nil;
        [O_listenerControlButton setTitle:@"listen"];
    }
}


- (BOOL)BEEPListener:(TCMBEEPListener *)aBEEPListener shouldAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession {
    NSLog(@"somebody talks to our listener: %@",[aBEEPSession description]);
    return YES;
}
- (void)BEEPListener:(TCMBEEPListener *)aBEEPListener didAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession {
    NSLog(@"Got Session");
    [aBEEPSession open];
    [aBEEPSession setDelegate:self];
    [aBEEPSession retain];
}


@end
