//
//  TCMBEEPSimpleSendProfile.m
//  BEEPSample
//
//  Created by Dominik Wagner on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPSimpleSendProfile.h"
#import "TCMBEEPMessage.h"
#import "TCMBEEPChannel.h"


@implementation TCMBEEPSimpleSendProfile
- (id)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super init];
    if (self) {
        NSLog(@"Initialized TCMBEEPSimpleSendProfile");
        [self setChannel:aChannel];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark -

- (void)setDelegate:(id)aDelegate
{
    I_delegate = aDelegate;
}

- (id)delegate
{
    return I_delegate;
}

- (void)setChannel:(TCMBEEPChannel *)aChannel
{
    I_channel = aChannel;
}

- (TCMBEEPChannel *)channel
{
    return I_channel;
}

#pragma mark -
#pragma mark ### Simple API ###
- (void)sendData:(NSData *)aData 
{
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"MSG" messageNumber:[[self channel] nextMessageNumber] payload:aData];
    [[self channel] sendMessage:[message autorelease]];
}
- (void)close 
{
    
}

#pragma mark -

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    DEBUGLOG(@"BEEP",5,@"proceessBEEPMessage: %@",aMessage);
    if ([[self delegate] respondsToSelector:@selector(profile:didReceiveData:)]) {
        NSLog(@"Delegate, yeah");
        [[self delegate] profile:self didReceiveData:[aMessage payload]];
    }
    // just ack with an empty rpy
    TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[aMessage messageNumber] payload:nil];
    [[self channel] sendMessage:[message autorelease]];
}

@end
