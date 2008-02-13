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

extern NSString * const TCMPortMapperExternalIPAddressDidChange;

extern NSString * const TCMPortMapperWillSearchForRouterNotification;
extern NSString * const TCMPortMapperDidFindRouterNotification;

extern NSString * const TCMPortMapperDidStartWorkNotification;
extern NSString * const TCMPortMapperDidEndWorkNotification;

extern NSString * const TCMPortMappingDidChangeMappingStatusNotification;

extern NSString * const TCMNATPMPProtocol;
extern NSString * const TCMUPNPProtocol;  
extern NSString * const TCMPortMapProtocolNone;

typedef enum {
    TCMPortMappingStatusUnmapped = 0,
    TCMPortMappingStatusTrying = 1,
    TCMPortMappingStatusMapped = 2
} TCMPortMappingStatus;

typedef enum {
    TCMPortMappingTransportProtocolUDP = 1,
    TCMPortMappingTransportProtocolTCP = 2,
    TCMPortMappingTransportProtocolBoth = 3
} TCMPortMappingTransportProtocol;


@interface TCMPortMapping : NSObject {
    int _privatePort;
    int _publicPort;
    int _desiredPublicPort;
    id  _userInfo;
    TCMPortMappingStatus _mappingStatus;
    TCMPortMappingTransportProtocol _transportProtocol;
}
+ (id)portMappingWithPrivatePort:(int)aPrivatePort desiredPublicPort:(int)aPublicPort userInfo:(id)aUserInfo;
- (id)initWithPrivatePort:(int)aPrivatePort desiredPublicPort:(int)aPublicPort transportProtocol:(int)aTransportProtocol userInfo:(id)aUserInfo;
- (int)desiredPublicPort;
- (id)userInfo;
- (TCMPortMappingStatus)mappingStatus;
- (void)setMappingStatus:(TCMPortMappingStatus)aStatus;
- (TCMPortMappingTransportProtocol)transportProtocol;
- (void)setTransportProtocol:(TCMPortMappingTransportProtocol)aProtocol;
- (void)setPublicPort:(int)aPublicPort;
- (int)publicPort;
- (int)privatePort;

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
    NSString *_localIPAddress;
    NSString *_externalIPAddress;
    int _NATPMPStatus;
    int _UPNPStatus;
    NSString *_mappingProtocol;
    NSString *_routerName;
    int _workCount;
    BOOL _localIPOnRouterSubnet;
}

+ (TCMPortMapper *)sharedInstance;
- (NSSet *)portMappings;
- (NSMutableSet *)removeMappingQueue;
- (void)addPortMapping:(TCMPortMapping *)aMapping;
- (void)removePortMapping:(TCMPortMapping *)aMapping;
- (void)refresh;

- (BOOL)isRunning;
- (void)start;
- (void)stop;
- (void)stopBlocking;

- (NSString *)externalIPAddress;
- (NSString *)localIPAddress;
- (void)setMappingProtocol:(NSString *)aProtocol;
- (NSString *)mappingProtocol;
- (void)setRouterName:(NSString *)aRouterName;
- (NSString *)routerName; // UPNP name or IP address
- (NSString *)routerIPAddress;
- (NSString *)routerHardwareAddress;

@end
