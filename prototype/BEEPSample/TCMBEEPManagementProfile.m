//
//  TCMBEEPManagementProfile.m
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPManagementProfile.h"


@implementation TCMBEEPManagementProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super init];
    if (self) {
        NSLog(@"Initialized TCMBEEPManagmentProfile");
        [self setChannel:aChannel];
    }
    return self;
}

- (void)sendGreetingWithProfileURIs:(NSArray *)anArray featuresAttribute:(NSString *)aFeaturesString localizeAttribute:(NSString *)aLocalizeString
{
}

#pragma mark -
#pragma mark ### Accessors ####

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

@end
