//
//  TCMPortMappingAdditions.m
//  Port Map
//
//  Created by Dominik Wagner on 07.02.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortMappingAdditions.h"


@implementation TCMPortMapping (TCMPortMappingAdditions)

+ (TCMPortMapping*)portMappingWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    TCMPortMapping *mapping = [TCMPortMapping portMappingWithLocalPort:[[aDictionary objectForKey:@"privatePort"] intValue] desiredExternalPort:[[aDictionary objectForKey:@"desiredPublicPort"] intValue] userInfo:[aDictionary objectForKey:@"userInfo"]];
    [mapping setTransportProtocol:[[aDictionary objectForKey:@"transportProtocol"] intValue]];
    return mapping;
}
- (NSDictionary *)dictionaryRepresentation {
    return [NSDictionary dictionaryWithObjectsAndKeys:
    [self userInfo],@"userInfo",
    [NSNumber numberWithInt:_localPort],@"privatePort",
    [NSNumber numberWithInt:_desiredExternalPort],@"desiredPublicPort",
    [NSNumber numberWithInt:_transportProtocol],@"transportProtocol",
    nil];
}


@end
