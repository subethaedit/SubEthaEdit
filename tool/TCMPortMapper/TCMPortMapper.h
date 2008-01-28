//
//  TCMPortMapper.h
//  PortMapper
//
//  Created by Martin Pittenauer on 15.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <errno.h>
#import <string.h>
#import <unistd.h>


extern NSString * const TCMPortMapperWillSearchForRouterNotification;
extern NSString * const TCMPortMapperDidFindRouterNotification;

extern NSString * const TCMPortMappingDidChangeMappingStateNotification;
extern NSString * const TCMNATPMPPortMapperExternalIPAddressDidChange;

typedef enum {
    TCMPortMappingStatusUnmapped = 0,
    TCMPortMappingStatusTrying = 1,
    TCMPortMappingStatusMapped = 2
} TCMPortMappingStatus;


@interface TCMPortMapping : NSObject {
    uint16_t _privatePort;
    uint16_t _publicPort;
    uint16_t _desiredPublicPort;
    id  _userInfo;
    TCMPortMappingStatus _mappingStatus;
}
+ (id)portMappingWithPrivatePort:(uint16_t)aPrivatePort desiredPublicPort:(uint16_t)aPublicPort userInfo:(id)aUserInfo;
- (uint16_t)desiredPublicPort;
- (id)userInfo;
- (TCMPortMappingStatus)mappingStatus;
- (uint16_t)publicPort;
- (uint16_t)privatePort;

@end

@class IXSCNotificationManager;
@interface TCMPortMapper : NSObject {
    NSMutableArray *_portMappings;
    IXSCNotificationManager *_systemConfigNotificationManager;
    BOOL _isRunning;
    NSString *_externalIPAddress;
}

+ (TCMPortMapper *)sharedInstance;
- (NSArray *)portMappings;
- (void)addPortMapping:(TCMPortMapping *)aMapping;
- (void)removePortMapping:(TCMPortMapping *)aMapping;
- (void)refreshPortMappings;

- (void)start;
- (void)stop;

- (NSString *)externalIPAddress;
- (NSString *)mappingProtocol;
- (NSString *)routerName; // UPNP name or IP address
- (NSString *)routerIPAddress;
- (NSString *)routerHardwareAddress;

@end
