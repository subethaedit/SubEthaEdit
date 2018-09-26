//  TCMPortMapper.h
//  Establishes port mapping via upnp or natpmp
//
//  Some rights reserved: <http://opensource.org/licenses/mit-license.php>

@import Foundation;
#import <errno.h>
#import <string.h>
#import <unistd.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const TCMPortMapperExternalIPAddressDidChange;

extern NSString * const TCMPortMapperWillStartSearchForRouterNotification;
extern NSString * const TCMPortMapperDidFinishSearchForRouterNotification;

extern NSString * const TCMPortMapperDidStartWorkNotification;
extern NSString * const TCMPortMapperDidFinishWorkNotification;

extern NSString * const TCMPortMapperDidReceiveUPNPMappingTableNotification;

extern NSString * const TCMPortMappingDidChangeMappingStatusNotification;


extern NSString * const TCMNATPMPPortMapProtocol;
extern NSString * const TCMUPNPPortMapProtocol;  
extern NSString * const TCMNoPortMapProtocol;

typedef NS_ENUM(uint8_t, TCMPortMappingStatus) {
    TCMPortMappingStatusUnmapped = 0,
    TCMPortMappingStatusTrying   = 1,
    TCMPortMappingStatusMapped   = 2
};

typedef NS_ENUM(uint8_t, TCMPortMappingTransportProtocol)  {
    TCMPortMappingTransportProtocolUDP  = 1,
    TCMPortMappingTransportProtocolTCP  = 2,
    TCMPortMappingTransportProtocolBoth = 3
};

@interface TCMPortMapping : NSObject
+ (instancetype)portMappingWithLocalPort:(uint16_t)privatePort desiredExternalPort:(uint16_t)publicPort transportProtocol:(TCMPortMappingTransportProtocol)transportProtocol userInfo:(id)userInfo;
- (instancetype)initWithLocalPort:(uint16_t)privatePort desiredExternalPort:(uint16_t)publicPort transportProtocol:(TCMPortMappingTransportProtocol)transportProtocol userInfo:(id)userInfo;

@property (nonatomic) uint16_t desiredExternalPort;
@property (nonatomic) uint16_t localPort;
@property (nonatomic) uint16_t externalPort;
@property (nonatomic) TCMPortMappingTransportProtocol transportProtocol;
@property (nonatomic) TCMPortMappingStatus mappingStatus;

@property (nonatomic, strong) id userInfo;
@end

@interface NSString (TCMPortMapper_IPAdditions)
/**
 @return YES if the string is representing an IPv4 Address.
 */
- (BOOL)isIPv4Address;
/**
 @return YES if the String represents an IPv4 Address and it is in one of the private or self assigned subnetranges. NO otherwise.
 */
- (BOOL)IPv4AddressIsInPrivateSubnet;
@end

@interface TCMPortMapper : NSObject
+ (instancetype)sharedInstance;
+ (nullable NSString *)manufacturerForHardwareAddress:(NSString *)aMACAddress;
+ (NSString *)sizereducableHashOfString:(NSString *)inString;

- (NSSet *)portMappings;
- (NSMutableSet *)removeMappingQueue;
- (void)addPortMapping:(TCMPortMapping *)aMapping;
- (void)removePortMapping:(TCMPortMapping *)aMapping;
- (void)refresh;

- (BOOL)isAtWork;
- (BOOL)isRunning;
- (void)start;
- (void)stop;
- (void)stopBlocking;

// will request the complete UPNPMappingTable and deliver it using a TCMPortMapperDidReceiveUPNPMappingTableNotification with "mappingTable" in the userInfo Dictionary (if current router is a UPNP router)
- (void)requestUPNPMappingTable;
// this is mainly for Port Map.app and can remove any mappings that can be removed using UPNP (including mappings from other hosts). aMappingList is an Array of Dictionaries with the key @"protocol" and @"publicPort".
- (void)removeUPNPMappings:(NSArray *)aMappingList;

// needed for generating a UPNP port mapping description that differs for each user
@property (nonatomic, strong) NSString *userID;
// we provide a half length md5 has for convenience
// we could use full length but the description field of the routers might be limited
- (void)hashUserID:(NSString *)aUserIDToHash;

@property (nonatomic, readonly, nullable) NSString *externalIPAddress;
@property (nonatomic, readonly) NSString *localIPAddress;
@property (nonatomic, readonly, nullable) NSString *localBonjourHostName;

@property (nonatomic, strong, nullable) NSString *mappingProtocol;
@property (nonatomic, copy, nullable) NSString *routerName;
@property (nonatomic, readonly, nullable) NSString *routerIPAddress;
@property (nonatomic, readonly, nullable) NSString *routerHardwareAddress;
@end

NS_ASSUME_NONNULL_END
