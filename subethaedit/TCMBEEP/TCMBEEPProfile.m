//
//  TCMBEEPProfile.m
//  TCMBEEP
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPProfile.h"


@implementation TCMBEEPProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super init];
    if (self) {
        [self setChannel:aChannel];
        I_isClosing = NO;
    }
    return self;
}
 
- (void)dealloc
{
    I_delegate = nil;
    I_channel = nil;
    [I_profileURI release];
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

- (void)setChannel:(TCMBEEPChannel *)aChannel
{
    I_channel = aChannel;
}

- (TCMBEEPChannel *)channel
{
    return I_channel;
}

- (TCMBEEPSession *)session 
{
    return [[self channel] session];
}

- (BOOL)isServer
{
    return ![[self channel] isInitiator];
}

- (void)setProfileURI:(NSString *)aProfileURI
{
    [I_profileURI autorelease];
    I_profileURI = [aProfileURI copy];
}

- (NSString *)profileURI
{
    return I_profileURI;
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    NSLog(@"You should have overridden this!");
}

- (void)close {
    I_isClosing=YES;
    [[self channel] close];
}

- (void)channelDidReceiveCloseRequest
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"channelDidReceiveCloseRequest: %@", NSStringFromClass([self class]));
}

- (void)channelDidClose
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"channelDidClose: %@", NSStringFromClass([self class]));
    id delegate=[self delegate];
    if ([delegate respondsToSelector:@selector(profileDidClose:)]) {
        [delegate profileDidClose:self];
    }
}

- (void)channelDidNotCloseWithError:(NSError *)error
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"channelDidNotCloseWithError: %@", NSStringFromClass([self class]));
}

- (void)cleanup
{
    DEBUGLOG(@"BEEPLogDomain", DetailedLogLevel, @"cleanup profile");
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(profile:didFailWithError:)]) {
        NSError *error = [NSError errorWithDomain:@"BEEPDomain" code:451 userInfo:nil];
        [delegate profile:self didFailWithError:error];
    }
}

@end
