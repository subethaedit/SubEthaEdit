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

- (void) mapPublicPort:(uint16_t)aPublicPort toPrivatePort:(uint16_t)aPrivatePort withLifetime:(uint32_t)aLifetime {
	return [[TCMNATPMPPortMapper sharedInstance] mapPublicPort:aPublicPort toPrivatePort:aPrivatePort withLifetime:aLifetime];
}

- (void) mapPublicPort:(uint16_t)aPublicPort toPrivatePort:(uint16_t)aPrivatePort{
	[self mapPublicPort:aPublicPort toPrivatePort:aPrivatePort withLifetime:3600]; // Default lifetime is an hour
}

- (void) mapPort:(uint16_t)aPublicPort {
	[self mapPublicPort:aPublicPort toPrivatePort:aPublicPort]; // Uses same port for external an local by default
}

- (NSArray *)portMappings{
	return nil;
}

- (void)addPortMapping:(TCMPortMapping *)aMapping {
	
}

- (void)removePortMapping:(TCMPortMapping *)aMapping {
	
}

- (void)refreshPortMappings {
	
}

- (void)start {
	
}

- (void)stop {
	
}

- (NSString *)mappingProtocol {
	return nil;
}

- (NSString *)routerName {
	return nil;
}

- (NSString *)routerIPAddress {
	return nil;
}

- (NSString *)routerHardwareAddress {
	return nil;
}

@end
