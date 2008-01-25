//
//  TCMPortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 15.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortMapper.h"
#import "TCMNATPMPPortMapper.h"

static TCMPortMapper *sharedInstance;

@implementation TCMPortMapper

+ (TCMPortMapper *)sharedInstance
{
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (NSString *)externalIPAddress {
	return [[TCMNATPMPPortMapper sharedInstance] externalIPAddress];
}

- (void) mapPublicPort:(int)publicPort toPrivatePort:(int)privatePort withLifetime:(int)seconds {
	return [[TCMNATPMPPortMapper sharedInstance] mapPublicPort:publicPort toPrivatePort:privatePort withLifetime:seconds];
}

- (void) mapPublicPort:(int)publicPort toPrivatePort:(int)privatePort {
	[self mapPublicPort:publicPort toPrivatePort:privatePort withLifetime:3600]; // Default lifetime is an hour
}

- (void) mapPort:(int)publicPort {
	[self mapPublicPort:publicPort toPrivatePort:publicPort]; // Uses same port for external an local by default
}

@end
