//
//  TCMPortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 15.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortMapper.h"
#import "TCMNATPMPPortMapper.h"
#import "IXSCNotificationManager.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/SCSchemaDefinitions.h>
#import <sys/sysctl.h> 
#import <netinet/in.h>
#import <arpa/inet.h>
#import <net/route.h>
#import <netinet/if_ether.h>
#import <net/if_dl.h>

NSString * const TCMNATPMPPortMapperExternalIPAddressDidChange = @"TCMNATPMPPortMapperExternalIPAddressDidChange";
NSString * const TCMPortMapperWillSearchForRouterNotification = @"TCMPortMapperWillSearchForRouterNotification";
NSString * const TCMPortMapperDidFindRouterNotification = @"TCMPortMapperDidFindRouterNotification";
NSString * const TCMPortMappingDidChangeMappingStateNotification = @"TCMPortMappingDidChangeMappingStateNotification";


static TCMPortMapper *S_sharedInstance;

@interface NSString (IPAdditions)
- (BOOL)IPv4AddressInPrivateSubnet;
@end

@interface TCMPortMapper (Private) 

- (void)setExternalIPAddress:(NSString *)anAddress;

- (void) mapPort:(uint16_t)aPublicPort;
- (void) mapPublicPort:(uint16_t)aPublicPort toPrivatePort:(uint16_t)aPrivatePort;
- (void) mapPublicPort:(uint16_t)aPublicPort toPrivatePort:(uint16_t)aPrivatePort withLifetime:(uint32_t)aLifetime;

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
    
        S_sharedInstance = self;
    }
    return self;
}

- (void)dealloc {
    [_systemConfigNotificationManager release];
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
    [self refreshPortMappings];
}

- (NSString *)externalIPAddress {
    return [NSString stringWithString:_externalIPAddress];
	//return [[TCMNATPMPPortMapper sharedInstance] externalIPAddress];
}

- (void) mapPublicPort:(uint16_t)aPublicPort toPrivatePort:(uint16_t)aPrivatePort withLifetime:(uint32_t)aLifetime {
	return [[TCMNATPMPPortMapper sharedInstance] mapPublicPort:aPublicPort toPrivatePort:aPrivatePort withLifetime:aLifetime];
}

- (void) mapPublicPort:(uint16_t)aPublicPort toPrivatePort:(uint16_t)aPrivatePort{
	[self mapPublicPort:aPublicPort toPrivatePort:aPrivatePort withLifetime:3600]; // Default lifetime is an hour
}

- (void) mapPort:(uint16_t)aPublicPort {
	[self mapPublicPort:aPublicPort toPrivatePort:aPublicPort]; // Uses same port for external and local by default
}

- (NSArray *)portMappings{
	return nil;
}

- (void)addPortMapping:(TCMPortMapping *)aMapping {
	
}

- (void)removePortMapping:(TCMPortMapping *)aMapping {
	
}

- (void)refreshPortMappings {
    // reinitialisieren: public ip und router modell auf nil setzen - portmappingsstatus auf unmapped setzen, wenn trying dann upnp/natpimp zurücksetzen
	// haben wir einen router
	// dann upnp / natpimp starten um zu sehen was geht - internen status auf "trying" setzen.
	[self setExternalIPAddress:nil];
//	[self setRouterName:nil];
//	[self setMappingProtocol:nil];
	
	
	NSString *routerAddress = [self routerIPAddress];
	if (routerAddress) {
        BOOL inPrivateSubnet = [routerAddress IPv4AddressInPrivateSubnet];
        
        SCDynamicStoreRef dynRef = SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)@"TCMPortMapper", NULL, NULL); 
        NSDictionary *scobjects = (NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)@"State:/Network/Global/IPv4" ); 
        
        NSArray *IPAddresses = [scobjects objectForKey:(NSArray *)kSCPropNetIPv4Addresses];
        NSArray *subNetMasks = [scobjects objectForKey:(NSArray *)kSCPropNetIPv4SubnetMasks];
        
        int i;
        for (i=0;i<[IPAddresses count];i++) {
            NSString *ipAddress = (NSString *) [IPAddresses objectAtIndex:i];
            NSString *subNetMask = (NSString *) [subNetMasks objectAtIndex:i];
        
            // Check if local to Host
            
            in_addr_t myaddr = inet_addr([ipAddress UTF8String]);
            in_addr_t subnetmask = inet_addr([subNetMask UTF8String]);
            in_addr_t routeraddr = inet_addr([[self routerIPAddress] UTF8String]);
            
            if ((myaddr & subnetmask) == (routeraddr & subnetmask)) {
                // That's the one
                if (inPrivateSubnet) {
                    // [_NATPMPPortMapper refresh];
                    // [_UPNPPortMapper refresh];
                    [self setExternalIPAddress:routerAddress]; // FIXME that is wrong
                } else {
                    [self setExternalIPAddress:ipAddress];
                    // we know we have a public address so we are finished - but maybe we should set all mappings to mapped
                }
            }
            
        }
    
        CFRelease(dynRef);
        [scobjects release];
    }

}

- (void)setExternalIPAddress:(NSString *)anIPAddress {
    NSLog(@"%s %@",__FUNCTION__,anIPAddress);
    [_externalIPAddress autorelease];
    _externalIPAddress = [anIPAddress copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMNATPMPPortMapperExternalIPAddressDidChange object:self];
}

- (NSString *) hardwareAddressForIPAddress: (NSString *) address {
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
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                    selector:@selector(networkDidChange:) 
                                    name:@"State:/Network/Global/IPv4" 
                                    object:_systemConfigNotificationManager];                          
    [self refreshPortMappings];
}

- (void)stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (NSString *)mappingProtocol {
	return nil;
}

- (NSString *)routerName {
	return nil;
}

- (NSString *)routerIPAddress {
    SCDynamicStoreRef dynRef = SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)@"TCMPortMapper", NULL, NULL); 
	NSDictionary *scobjects = (NSDictionary *)SCDynamicStoreCopyValue(dynRef,(CFStringRef)@"State:/Network/Global/IPv4" ); 

	NSString *routerIPAddress = [NSString stringWithString:[scobjects objectForKey:(NSString *)kSCPropNetIPv4Router]];

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

@end
