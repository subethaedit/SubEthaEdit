//
//  TCMBEEPProfile.m
//  SubEthaEdit
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
    }
    return self;
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

- (void)cleanup
{
    NSLog(@"cleanup profile");
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(profile:didFailWithError:)]) {
        NSError *error = [NSError errorWithDomain:@"BEEPDomain" code:451 userInfo:nil];
        [delegate profile:self didFailWithError:error];
    }
}

@end
