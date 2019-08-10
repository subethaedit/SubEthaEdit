//  TCMBEEPProfile.m
//  TCMBEEP
//
//  Created by Dominik Wagner on Fri Feb 27 2004.

#import "TCMBEEPProfile.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation TCMBEEPProfile

- (instancetype)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super init];
    if (self) {
        [self setChannel:aChannel];
        I_isClosing = NO;
        I_isAbortingIncomingMessages = NO;
    }
    return self;
}

- (void)handleInitializationData:(NSData *)aData {
    DEBUGLOG(@"BEEPLogDomain",DetailedLogLevel,@"%s %@ should Handle data:%@",__FUNCTION__,_profileURI,[[NSString alloc] initWithData:aData encoding:NSISOLatin1StringEncoding]);
}

- (TCMBEEPSession *)session 
{
    return [[self channel] session];
}

- (BOOL)isServer
{
    return ![[self channel] isInitiator];
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage
{
    NSLog(@"You should have overridden this!");
}

- (void)close
{
    I_isClosing = YES;
    [[self channel] close];
}

- (void)channelDidReceiveCloseRequest
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"channelDidReceiveCloseRequest: %@", NSStringFromClass([self class]));
}

- (void)channelDidClose
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"channelDidClose: %@ delegate:%@", NSStringFromClass([self class]), [self delegate]);
    id delegate = [self delegate];
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

- (void)abortIncomingMessages
{
    I_isAbortingIncomingMessages = YES;
}

- (void)channelDidReceivePreemptiveReplyForMessageWithNumber:(int32_t)aMessageNumber
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"channelDidReceivePreemptiveReplyForMessageWithNumber: %d", aMessageNumber);
}

- (void)channelDidReceivePreemptedMessage:(TCMBEEPMessage *)aMessage
{
    DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"channelDidReceivePreemptedMessage: %@", aMessage);
}

- (void)channelDidReceiveFrame:(TCMBEEPFrame *)aFrame startingMessage:(BOOL)aFlag
{
    if (I_isAbortingIncomingMessages) {
        [[self channel] preemptFrame:aFrame];
    }
}


@end
