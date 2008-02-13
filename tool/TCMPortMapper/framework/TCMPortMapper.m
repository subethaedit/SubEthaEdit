//
//  TCMPortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 15.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortMapper.h"
#import "TCMNATPMPPortMapper.h"
#import "TCMUPNPPortMapper.h"
#import "IXSCNotificationManager.h"
#import "NSNotificationAdditions.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/SCSchemaDefinitions.h>
#import <sys/sysctl.h> 
#import <netinet/in.h>
#import <arpa/inet.h>
#import <net/route.h>
#import <netinet/if_ether.h>
#import <net/if_dl.h>

NSString * const TCMPortMapperExternalIPAddressDidChange          = @"TCMPortMapperExternalIPAddressDidChange";
NSString * const TCMPortMapperWillSearchForRouterNotification     = @"TCMPortMapperWillSearchForRouterNotification";
NSString * const TCMPortMapperDidFindRouterNotification           = @"TCMPortMapperDidFindRouterNotification";
NSString * const TCMPortMappingDidChangeMappingStatusNotification = @"TCMPortMappingDidChangeMappingStatusNotification";
NSString * const TCMPortMapperDidStartWorkNotification            = @"TCMPortMapperDidStartWorkNotification";
NSString * const TCMPortMapperDidEndWorkNotification              = @"TCMPortMapperDidEndWorkNotification";


NSString * const TCMNATPMPProtocol = @"NAT-PMP";
NSString * const TCMUPNPProtocol   = @"UPnP";
NSString * const TCMPortMapProtocolNone   = @"None";


static TCMPortMapper *S_sharedInstance;

enum {
    TCMPortMapProtocolFailed = 0,
    TCMPortMapProtocolTrying = 1,
    TCMPortMapProtocolWorks = 2
};

@interface NSString (IPAdditions)
- (BOOL)IPv4AddressInPrivateSubnet;
@end

@interface TCMPortMapper (Private) 

- (void)setExternalIPAddress:(NSString *)anAddress;
- (void)setLocalIPAddress:(NSString *)anAddress;
@end

@implementation NSString (IPAdditions)

- (BOOL)IPv4AddressInPrivateSubnet {
    if ([self hasPrefix:@"127.0.0.1"] ||
        [self hasPrefix:@"10."] ||
        [self hasPrefix:@"192.168."] ||
        [self hasPrefix:@"169.254."] ||
        [self hasPrefix:@"172.16."] ||
        [self hasPrefix:@"172.17."] ||
        [self hasPrefix:@"172.18."] ||
        [self hasPrefix:@"172.19."] ||
        [self hasPrefix:@"172.20."] ||
        [self hasPrefix:@"172.21."] ||
        [self hasPrefix:@"172.22."] ||
        [self hasPrefix:@"172.23."] ||
        [self hasPrefix:@"172.24."] ||
        [self hasPrefix:@"172.25."] ||
        [self hasPrefix:@"172.26."] ||
        [self hasPrefix:@"172.27."] ||
        [self hasPrefix:@"172.28."] ||
        [self hasPrefix:@"172.29."] ||
        [self hasPrefix:@"172.30."] ||
        [self hasPrefix:@"172.31."]) {
        return YES;
    } else {
        return NO;
    }
}
@end

@implementation TCMPortMapper

+ (TCMPortMapper *)sharedInstance
{
    if (!S_sharedInstance) {
        S_sharedInstance = [self new];
    }
    return S_sharedInstance;
}

- (id)init {
    if (S_sharedInstance) {
        [self dealloc];
        return S_sharedInstance;
    }
    if ((self=[super init])) {
        _systemConfigNotificationManager = [IXSCNotificationManager new];
        _isRunning = NO;
        _NATPMPPortMapper = [[TCMNATPMPPortMapper alloc] init];
        _UPNPPortMapper = [[TCMUPNPPortMapper alloc] init];
        _portMappings = [NSMutableSet new];
        _removeMappingQueue = [NSMutableSet new];
        S_sharedInstance = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(increaseWorkCount:) name:TCMUPNPPortMapperDidBeginWorkingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(increaseWorkCount:) name:TCMNATPMPPortMapperDidBeginWorkingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decreaseWorkCount:) name:TCMUPNPPortMapperDidEndWorkingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decreaseWorkCount:) name:TCMNATPMPPortMapperDidEndWorkingNotification object:nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didWake:) name:NSWorkspaceDidWakeNotification object:nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(willSleep:) name:NSWorkspaceWillSleepNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [_systemConfigNotificationManager release];
    [_NATPMPPortMapper release];
    [_UPNPPortMapper release];
    [_portMappings release];
    [_removeMappingQueue release];
    [super dealloc];
}

- (BOOL)networkReachable {
    Boolean success; 
    BOOL okay; 
    SCNetworkConnectionFlags status;
    success = SCNetworkCheckReachabilityByName("www.apple.com", &status); 
    okay = success && (status & kSCNetworkFlagsReachable) && !(status & kSCNetworkFlagsConnectionRequired); 
    
    return okay;
}

- (void)networkDidChange:(NSNotification *)aNotification {
    NSLog(@"%s",__FUNCTION__);
    [self refresh];
}

- (NSString *)externalIPAddress {
    return [[_externalIPAddress retain] autorelease];
}

- (void)updateLocalIPAddress {
	NSString *routerAddress = [self routerIPAddress];
    SCDynamicStoreRef dynRef = SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)@"TCMPortMapper", NULL, NULL); 
    NSDictionary *scobjects = (NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)@"State:/Network/Global/IPv4" ); 
    
    NSString *ipv4Key = [NSString stringWithFormat:@"State:/Network/Interface/%@/IPv4", [scobjects objectForKey:(NSString *)kSCDynamicStorePropNetPrimaryInterface]];
    
    CFRelease(dynRef);
    [scobjects release];
    
    dynRef = SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)@"TCMPortMapper", NULL, NULL); 
    scobjects = (NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)ipv4Key); 
    
//        NSLog(@"%s scobjects:%@",__FUNCTION__,scobjects);
    NSArray *IPAddresses = (NSArray *)[scobjects objectForKey:(NSString *)kSCPropNetIPv4Addresses];
    NSArray *subNetMasks = (NSArray *)[scobjects objectForKey:(NSString *)kSCPropNetIPv4SubnetMasks];
//    NSLog(@"%s addresses:%@ masks:%@",__FUNCTION__,IPAddresses, subNetMasks);
    if (routerAddress) {
        NSString *ipAddress = nil;
        int i;
        for (i=0;i<[IPAddresses count];i++) {
            ipAddress = (NSString *) [IPAddresses objectAtIndex:i];
            NSString *subNetMask = (NSString *) [subNetMasks objectAtIndex:i];
 //           NSLog(@"%s ipAddress:%@ subNetMask:%@",__FUNCTION__, ipAddress, subNetMask);
            // Check if local to Host
            
            in_addr_t myaddr = inet_addr([ipAddress UTF8String]);
            in_addr_t subnetmask = inet_addr([subNetMask UTF8String]);
            in_addr_t routeraddr = inet_addr([[self routerIPAddress] UTF8String]);
    //            NSLog(@"%s ipNative:%X maskNative:%X",__FUNCTION__,routeraddr,subnetmask);
            if ((myaddr & subnetmask) == (routeraddr & subnetmask)) {
                [self setLocalIPAddress:ipAddress];
                _localIPOnRouterSubnet = YES;
                break;
            }
            
        }
        // this should never happen - if we have a router then we need to have an IP address on the same subnet to know this...
        if (i==[IPAddresses count]) {
            // we haven't found an IP address that matches - so set the last one
            _localIPOnRouterSubnet = NO;
            [self setLocalIPAddress:ipAddress];
        }
    } else {
        [self setLocalIPAddress:[IPAddresses lastObject]];
        _localIPOnRouterSubnet = NO;
    }
    CFRelease(dynRef);
    [scobjects release];
}

- (NSString *)localIPAddress {
    // make sure it is up to date
    [self updateLocalIPAddress];
    return [[_localIPAddress retain] autorelease];
}


- (NSSet *)portMappings{
	return _portMappings;
}

- (NSMutableSet *)removeMappingQueue {
    return _removeMappingQueue;
}

- (void)updatePortMappings {
    NSString *protocol = [self mappingProtocol];
    if ([protocol isEqualToString:TCMNATPMPProtocol]) {
        [_NATPMPPortMapper updatePortMappings];
    } else if ([protocol isEqualToString:TCMUPNPProtocol]) {
        [_UPNPPortMapper updatePortMappings];
    }
}

- (void)addPortMapping:(TCMPortMapping *)aMapping {
    @synchronized(_portMappings) {
        [_portMappings addObject:aMapping];
    }
    [self updatePortMappings];
}

- (void)removePortMapping:(TCMPortMapping *)aMapping {
    if (aMapping) {
        @synchronized(_portMappings) {
            [[aMapping retain] autorelease];
            [_portMappings removeObject:aMapping];
        }
        @synchronized(_removeMappingQueue) {
            if ([aMapping mappingStatus] != TCMPortMappingStatusUnmapped) {
                [_removeMappingQueue addObject:aMapping];
            }
        }
    [self updatePortMappings];
    }
}

- (void)refresh {
    // reinitialisieren: public ip und router modell auf nil setzen - portmappingsstatus auf unmapped setzen, wenn trying dann upnp/natpimp zurücksetzen
	[self setRouterName:@"..."];
	[self setMappingProtocol:TCMPortMapProtocolNone];
	[self setExternalIPAddress:nil];
	@synchronized(_portMappings) {
	   NSEnumerator *portMappings = [_portMappings objectEnumerator];
	   TCMPortMapping *portMapping = nil;
	   while ((portMapping = [portMappings nextObject])) {
	       if ([portMapping mappingStatus]==TCMPortMappingStatusMapped)
    	       [portMapping setMappingStatus:TCMPortMappingStatusUnmapped];
	   }
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperWillSearchForRouterNotification object:self];	
	
	NSString *routerAddress = [self routerIPAddress];
	if (routerAddress) {
        NSString *localIPAddress = [self localIPAddress]; // will always be updated when accessed
        if (localIPAddress && _localIPOnRouterSubnet) {
            [self setRouterName:[NSString stringWithFormat:@"Generic (%@)",[self routerHardwareAddress]]];
            [self setExternalIPAddress:nil];
            if ([routerAddress IPv4AddressInPrivateSubnet]) {
                _NATPMPStatus = TCMPortMapProtocolTrying;
                _UPNPStatus   = TCMPortMapProtocolTrying;
                [_NATPMPPortMapper refresh];
                [_UPNPPortMapper refresh];
            } else {
                _NATPMPStatus = TCMPortMapProtocolFailed;
                _UPNPStatus   = TCMPortMapProtocolFailed;
                [self setExternalIPAddress:localIPAddress];
                [self setMappingProtocol:TCMPortMapProtocolNone];
                [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFindRouterNotification object:self];
                // we know we have a public address so we are finished - but maybe we should set all mappings to mapped
            }
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFindRouterNotification object:self];
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFindRouterNotification object:self];
    }
}

- (void)setExternalIPAddress:(NSString *)anIPAddress {
    if (_externalIPAddress != anIPAddress) {
        NSString *tmp=_externalIPAddress;
        _externalIPAddress = [anIPAddress retain];
        [tmp release];
    }
    // notify always even if the external IP Address is unchanged so that we get the notification anytime when new information is here
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperExternalIPAddressDidChange object:self];
}

- (void)setLocalIPAddress:(NSString *)anIPAddress {
    if (_localIPAddress != anIPAddress) {
        NSString *tmp=_localIPAddress;
        _localIPAddress = [anIPAddress retain];
        [tmp release];
    }
}

- (NSString *)hardwareAddressForIPAddress: (NSString *) address {
    if (!address) return nil;
	int mib[6];
	size_t needed;
	char *lim, *buf, *next;
	struct sockaddr_inarp blank_sin = {sizeof(blank_sin), AF_INET };
	struct rt_msghdr *rtm;
	struct sockaddr_inarp *sin;
	struct sockaddr_dl *sdl;

	struct sockaddr_inarp sin_m;
	struct sockaddr_inarp *sin2 = &sin_m;

	sin_m = blank_sin;
	sin2->sin_addr.s_addr = inet_addr([address UTF8String]);
	u_long addr = sin2->sin_addr.s_addr;

	mib[0] = CTL_NET;
	mib[1] = PF_ROUTE;
	mib[2] = 0;
	mib[3] = AF_INET;
	mib[4] = NET_RT_FLAGS;
	mib[5] = RTF_LLINFO;
	
	if (sysctl(mib, 6, NULL, &needed, NULL, 0) < 0) err(1, "route-sysctl-estimate");
	if ((buf = malloc(needed)) == NULL) err(1, "malloc");
	if (sysctl(mib, 6, buf, &needed, NULL, 0) < 0) err(1, "actual retrieval of routing table");
	
	lim = buf + needed;
	for (next = buf; next < lim; next += rtm->rtm_msglen) {
		rtm = (struct rt_msghdr *)next;
		sin = (struct sockaddr_inarp *)(rtm + 1);
		sdl = (struct sockaddr_dl *)(sin + 1);
		if (addr) {
			if (addr != sin->sin_addr.s_addr) continue;
		}
			
		if (sdl->sdl_alen) {
			u_char *cp = (u_char *)LLADDR(sdl);
			NSString* result = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]];
        	free(buf);
			return result;
		} else {
        	free(buf);
		  return nil;
        }
	}
	return nil;
}

- (void)start {
    if (!_isRunning) {
        NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
        
        [center addObserver:self 
                selector:@selector(networkDidChange:) 
                name:@"State:/Network/Global/IPv4" 
                object:_systemConfigNotificationManager];
                                        
        
        [center addObserver:self 
                selector:@selector(NATPMPPortMapperDidGetExternalIPAddress:) 
                name:TCMNATPMPPortMapperDidGetExternalIPAddressNotification 
                object:_NATPMPPortMapper];
    
        [center addObserver:self 
                selector:@selector(NATPMPPortMapperDidFail:) 
                name:TCMNATPMPPortMapperDidFailNotification 
                object:_NATPMPPortMapper];
    
        [center addObserver:self 
                selector:@selector(UPNPPortMapperDidGetExternalIPAddress:) 
                name:TCMUPNPPortMapperDidGetExternalIPAddressNotification 
                object:_UPNPPortMapper];
    
        [center addObserver:self 
                selector:@selector(UPNPPortMapperDidFail:) 
                name:TCMUPNPPortMapperDidFailNotification 
                object:_UPNPPortMapper];
    
        _isRunning = YES;
    }
    [self refresh];
}


- (void)NATPMPPortMapperDidGetExternalIPAddress:(NSNotification *)aNotification {
    BOOL shouldNotify = NO;
    if (_NATPMPStatus==TCMPortMapProtocolTrying) {
        _NATPMPStatus =TCMPortMapProtocolWorks;
        [self setMappingProtocol:TCMNATPMPProtocol];
        shouldNotify = YES;
    }
    [self setExternalIPAddress:[[aNotification userInfo] objectForKey:@"externalIPAddress"]];
    if (shouldNotify) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFindRouterNotification object:self];
    }
}

- (void)NATPMPPortMapperDidFail:(NSNotification *)aNotification {
    if (_NATPMPStatus==TCMPortMapProtocolTrying) {
        _NATPMPStatus =TCMPortMapProtocolFailed;
    } else if (_NATPMPStatus==TCMPortMapProtocolWorks) {
        [self setExternalIPAddress:nil];
    }
    // also mark all port mappings as unmapped
    if (_UPNPStatus == TCMPortMapProtocolFailed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFindRouterNotification object:self];
    }
}

- (void)UPNPPortMapperDidGetExternalIPAddress:(NSNotification *)aNotification {
    BOOL shouldNotify = NO;
    if (_UPNPStatus==TCMPortMapProtocolTrying) {
        _UPNPStatus =TCMPortMapProtocolWorks;
        [self setMappingProtocol:TCMUPNPProtocol];
        shouldNotify = YES;
    }
    NSString *routerName = [[aNotification userInfo] objectForKey:@"routerName"];
    if (routerName) {
        [self setRouterName:routerName];
    }
    [self setExternalIPAddress:[[aNotification userInfo] objectForKey:@"externalIPAddress"]];
    if (shouldNotify) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFindRouterNotification object:self];
    }
}

- (void)UPNPPortMapperDidFail:(NSNotification *)aNotification {
    if (_UPNPStatus==TCMPortMapProtocolTrying) {
        _UPNPStatus =TCMPortMapProtocolFailed;
    } else if (_UPNPStatus==TCMPortMapProtocolWorks) {
        [self setExternalIPAddress:nil];
    }
    // also mark all port mappings as unmapped
    if (_NATPMPStatus == TCMPortMapProtocolFailed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFindRouterNotification object:self];
    }
}

- (void)printNotification:(NSNotification *)aNotification {
    NSLog(@"TCMPortMapper received notification: %@", aNotification);
}

- (void)stop {
    if (_isRunning) {
        NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
        [center removeObserver:self name:@"State:/Network/Global/IPv4" object:_systemConfigNotificationManager];
        [center removeObserver:self name:TCMNATPMPPortMapperDidGetExternalIPAddressNotification object:_NATPMPPortMapper];
        [center removeObserver:self name:TCMNATPMPPortMapperDidFailNotification object:_NATPMPPortMapper];
    
        [center removeObserver:self name:TCMUPNPPortMapperDidGetExternalIPAddressNotification object:_UPNPPortMapper];
        [center removeObserver:self name:TCMUPNPPortMapperDidFailNotification object:_UPNPPortMapper];
    
        _isRunning = NO;
        if (_NATPMPStatus != TCMPortMapProtocolFailed) {
            [_NATPMPPortMapper stop];
        }
        if (_UPNPStatus   != TCMPortMapProtocolFailed) {
            [_UPNPPortMapper stop];
        }
    }
}

- (void)stopBlocking {
    if (_isRunning) {
        if (_NATPMPStatus == TCMPortMapProtocolWorks) {
            [_NATPMPPortMapper stopBlocking];
        }
        if (_UPNPStatus   == TCMPortMapProtocolWorks) {
            [_UPNPPortMapper stopBlocking];
        }
        _isRunning = NO;
    }
}

- (void)setMappingProtocol:(NSString *)aProtocol {
    [_mappingProtocol autorelease];
    _mappingProtocol = [aProtocol copy];
}

- (NSString *)mappingProtocol {
	return _mappingProtocol;
}

- (void)setRouterName:(NSString *)aRouterName {
//    NSLog(@"%s %@->%@",__FUNCTION__,_routerName,aRouterName);
    [_routerName autorelease];
    _routerName = [aRouterName copy];
}

- (NSString *)routerName {
	return _routerName;
}

- (BOOL)isRunning {
    return _isRunning;
}

- (NSString *)routerIPAddress {
    SCDynamicStoreRef dynRef = SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)@"TCMPortMapper", NULL, NULL); 
	NSDictionary *scobjects = (NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)@"State:/Network/Global/IPv4" );
    
	NSString *routerIPAddress = (NSString *)[scobjects objectForKey:(NSString *)kSCPropNetIPv4Router];
    routerIPAddress = [[routerIPAddress copy] autorelease];
    
    CFRelease(dynRef);
	[scobjects release];
    return routerIPAddress;
}

- (NSString *)routerHardwareAddress {
	NSString *result = nil;
	NSString *routerAddress = [self routerIPAddress];
	if (routerAddress) {
		result = [self hardwareAddressForIPAddress:routerAddress];
	} 
	
	return result;
}

- (void)increaseWorkCount:(NSNotificationCenter *)aNotification {
    NSLog(@"%s %d",__FUNCTION__,_workCount);
    if (_workCount == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidStartWorkNotification object:self];
    }
    _workCount++;
}

- (void)decreaseWorkCount:(NSNotificationCenter *)aNotification {
    NSLog(@"%s %d",__FUNCTION__,_workCount);
    _workCount--;
    if (_workCount == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidEndWorkNotification object:self];
    }
}

- (void)didWake:(NSNotification *)aNotification {
    NSLog(@"%s",__FUNCTION__);
    if (_isRunning) {
        [self refresh];
    }
}

- (void)willSleep:(NSNotification *)aNotificaiton {
    NSLog(@"%s",__FUNCTION__);
    if (_isRunning) {
        if (_NATPMPStatus == TCMPortMapProtocolWorks) {
            NSLog(@"%s stopping NATPMP",__FUNCTION__);
            [_NATPMPPortMapper stopBlocking];
            NSLog(@"%s NATPMP stopped",__FUNCTION__);
        }
        if (_UPNPStatus   == TCMPortMapProtocolWorks) {
            NSLog(@"%s stopping UPNP",__FUNCTION__);
            [_UPNPPortMapper stopBlocking];
            NSLog(@"%s UPNP stopped",__FUNCTION__);
        }
    }
}


@end


@implementation TCMPortMapping 


+ (id)portMappingWithPrivatePort:(int)aPrivatePort desiredPublicPort:(int)aPublicPort userInfo:(id)aUserInfo {
	NSAssert(aPrivatePort<65536 && aPublicPort<65536 && aPrivatePort>0 && aPublicPort>0, @"Port number has to be between 1 and 65535");
    return [[[self alloc] initWithPrivatePort:aPrivatePort desiredPublicPort:aPublicPort transportProtocol:TCMPortMappingTransportProtocolTCP userInfo:aUserInfo] autorelease];
}

- (id)initWithPrivatePort:(int)aPrivatePort desiredPublicPort:(int)aPublicPort transportProtocol:(int)aTransportProtocol userInfo:(id)aUserInfo {
    if ((self=[super init])) {
        _desiredPublicPort = aPublicPort;
        _privatePort = aPrivatePort;
        _userInfo = [aUserInfo retain];
        _transportProtocol = aTransportProtocol;
    }
    return self;
}

- (void)dealloc {
    [_userInfo release];
    [super dealloc];
}

- (int)desiredPublicPort {
    return _desiredPublicPort;
}


- (id)userInfo {
    return _userInfo;
}


- (TCMPortMappingStatus)mappingStatus {
    return _mappingStatus;
}


- (void)setMappingStatus:(TCMPortMappingStatus)aStatus {
    if (_mappingStatus != aStatus) {
        _mappingStatus = aStatus;
        if (_mappingStatus == TCMPortMappingStatusUnmapped) {
            [self setPublicPort:0];
        }
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMPortMappingDidChangeMappingStatusNotification object:self];
    }
}


- (TCMPortMappingTransportProtocol)transportProtocol {
    return _transportProtocol;
}


- (void)setTransportProtocol:(TCMPortMappingTransportProtocol)aProtocol {
    if (_transportProtocol != aProtocol) {
        _transportProtocol = aProtocol;
    }
}


- (int)publicPort {
    return _publicPort;
}

- (void)setPublicPort:(int)aPublicPort {
    _publicPort=aPublicPort;
}


- (int)privatePort {
    return _privatePort;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ privatePort:%u desiredPublicPort:%u publicPort:%u mappingStatus:%@ transportProtocol:%d",[super description], _privatePort, _desiredPublicPort, _publicPort, _mappingStatus == TCMPortMappingStatusUnmapped ? @"unmapped" : (_mappingStatus == TCMPortMappingStatusMapped ? @"mapped" : @"trying"),_transportProtocol];
}

@end

