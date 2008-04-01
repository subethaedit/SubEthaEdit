
#import "TCMPortMappingAdditions.h"


@implementation TCMPortMapping (TCMPortMappingAdditions)

+ (TCMPortMapping*)portMappingWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    TCMPortMapping *mapping = [TCMPortMapping portMappingWithLocalPort:[[aDictionary objectForKey:@"privatePort"] intValue] desiredExternalPort:[[aDictionary objectForKey:@"desiredPublicPort"] intValue] transportProtocol:TCMPortMappingTransportProtocolTCP userInfo:[aDictionary objectForKey:@"userInfo"]];
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
