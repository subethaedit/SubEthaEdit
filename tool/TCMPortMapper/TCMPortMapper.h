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
#import "TCMNATPMPPortMapper.h"

extern NSString * const TCMPortMapperExternalIPAddressDidChange;

extern NSString * const TCMPortMapperWillSearchForRouterNotification;
extern NSString * const TCMPortMapperDidFindRouterNotification;

extern NSString * const TCMPortMappingDidChangeMappingStatusNotification;

extern NSString * const TCMNATPMPProtocol;
extern NSString * const TCMUPNPProtocol;  

typedef enum {
    TCMPortMappingStatusUnmapped = 0,
    TCMPortMappingStatusTrying = 1,
    TCMPortMappingStatusMapped = 2
} TCMPortMappingStatus;

typedef enum {
    UDP = 0,
    TCP = 1,
    Both = 2
} TCMPortMappingTransportProtocol;


@interface TCMPortMapping : NSObject {
    uint16_t _privatePort;
    uint16_t _publicPort;
    uint16_t _desiredPublicPort;
    id  _userInfo;
    TCMPortMappingStatus _mappingStatus;
    TCMPortMappingTransportProtocol _transportProtocol;
}
+ (id)portMappingWithPrivatePort:(uint16_t)aPrivatePort desiredPublicPort:(uint16_t)aPublicPort userInfo:(id)aUserInfo;
- (id)initWithPrivatePort:(uint16_t)aPrivatePort desiredPublicPort:(uint16_t)aPublicPort userInfo:(id)aUserInfo;
- (uint16_t)desiredPublicPort;
- (id)userInfo;
- (TCMPortMappingStatus)mappingStatus;
- (void)setMappingStatus:(TCMPortMappingStatus)aStatus;
- (TCMPortMappingTransportProtocol)transportProtocol;
- (void)setTransportProtocol:(TCMPortMappingTransportProtocol)aProtocol;
- (uint16_t)publicPort;
- (uint16_t)privatePort;

@end

@class IXSCNotificationManager;
@class TCMNATPMPPortMapper;
@class TCMUPNPPortMapper;
@interface TCMPortMapper : NSObject {
    TCMNATPMPPortMapper *_NATPMPPortMapper;
    TCMUPNPPortMapper *_UPNPPortMapper;
    NSMutableSet *_portMappings;
    NSMutableSet *_removeMappingQueue;
    IXSCNotificationManager *_systemConfigNotificationManager;
    BOOL _isRunning;
    NSString *_externalIPAddress;
}

+ (TCMPortMapper *)sharedInstance;
- (NSSet *)portMappings;
- (NSMutableSet *)removeMappingQueue;
- (void)addPortMapping:(TCMPortMapping *)aMapping;
- (void)removePortMapping:(TCMPortMapping *)aMapping;
- (void)refresh;

- (void)start;
- (void)stop;

- (NSString *)externalIPAddress;
- (NSString *)mappingProtocol;
- (NSString *)routerName; // UPNP name or IP address
- (NSString *)routerIPAddress;
- (NSString *)routerHardwareAddress;

@end
