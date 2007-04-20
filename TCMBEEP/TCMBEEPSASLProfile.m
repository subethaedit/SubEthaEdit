//
//  TCMBEEPSASLProfile.m
//  SubEthaEdit
//
//  Created by Martin Ott on 4/19/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPSASLProfile.h"


@implementation TCMBEEPSASLProfile

- (id)initWithChannel:(TCMBEEPChannel *)aChannel
{
    self = [super initWithChannel:aChannel];
    if (self) {
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"Initialized TCMBEEPSASLProfile");
    }
    return self;
}

@end
