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
#import "TCMBEEPChannel.h"
#import "TCMBEEPSimpleSendProfile.h"

#import <netdb.h>
#import <netinet/in.h>

NSString * const kSimpleSendProfileURI = @"http://www.codingmonkeys.de/BEEP/SimpleSendProfile";

@implementation Controller

-(id)init {
    if ((self=[super init])) {
        [TCMBEEPChannel setClass:[TCMBEEPSimpleSendProfile class] forProfileURI:kSimpleSendProfileURI];
    }
    return self;
}

-(void)awakeFromNib {
    [O_messageTextField setNextKeyView:O_messageTextField];
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
//    [session setProfileURIs:[NSArray arrayWithObjects:@"http://www.codingmonkeys.de/BEEP/SimpleSendProfile", nil]];
    [session setDelegate:self];
    [session open];
    if (session) {
        I_activeSession=session;
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

- (IBAction)sendMessage:(id)aSender {
    [I_sendProfile sendData:[[NSString stringWithFormat:@"%@\n",[O_messageTextField stringValue]] dataUsingEncoding:NSUTF8StringEncoding]]; 
    [O_messageTextField setStringValue:@""];
}

- (BOOL)BEEPListener:(TCMBEEPListener *)aBEEPListener shouldAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession {
    NSLog(@"somebody talks to our listener: %@",[aBEEPSession description]);
    return YES;
}
- (void)BEEPListener:(TCMBEEPListener *)aBEEPListener didAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession {
    NSLog(@"Got Session %@",aBEEPSession);
    [aBEEPSession setProfileURIs:[NSArray arrayWithObject:kSimpleSendProfileURI]];
    [aBEEPSession open];
    [aBEEPSession setDelegate:self];
    [aBEEPSession retain];
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray
{
    NSLog(@"Got Session %@ with Greeting:%@",aBEEPSession,aProfileURIArray);
    [aBEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:kSimpleSendProfileURI] andData:nil];
}

- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forRequests:(NSArray *)aRequests
{
    return aReply;
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(id <TCMBEEPProfile>)aProfile {
    if (aBEEPSession==I_activeSession) {
        I_sendProfile=(TCMBEEPSimpleSendProfile *)aProfile;
    } else {
        I_receiveProfile=(TCMBEEPSimpleSendProfile *)aProfile;
        [I_receiveProfile setDelegate:self];
    }
        
    NSLog(@"Session: %@ didOpenChannelWithProfile: %@",aBEEPSession,aProfile);
}

- (void)profile:(id <TCMBEEPProfile>)aProfile didReceiveData:(NSData *)aData {
    NSString *aString=[[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    [[[O_receivedTextView textStorage] mutableString] appendString:aString];
}


@end
