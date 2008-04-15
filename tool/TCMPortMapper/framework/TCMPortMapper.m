
#import "TCMPortMapper.h"
#import "TCMNATPMPPortMapper.h"
#import "TCMUPNPPortMapper.h"
#import "IXSCNotificationManager.h"
#import "NSNotificationCenterThreadingAdditions.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/SCSchemaDefinitions.h>
#import <sys/sysctl.h> 
#import <netinet/in.h>
#import <arpa/inet.h>
#import <net/route.h>
#import <netinet/if_ether.h>
#import <net/if_dl.h>
#import <openssl/md5.h>


NSString * const TCMPortMapperExternalIPAddressDidChange             = @"TCMPortMapperExternalIPAddressDidChange";
NSString * const TCMPortMapperWillStartSearchForRouterNotification   = @"TCMPortMapperWillStartSearchForRouterNotification";
NSString * const TCMPortMapperDidFinishSearchForRouterNotification   = @"TCMPortMapperDidFinishSearchForRouterNotification";
NSString * const TCMPortMappingDidChangeMappingStatusNotification    = @"TCMPortMappingDidChangeMappingStatusNotification";
NSString * const TCMPortMapperDidStartWorkNotification               = @"TCMPortMapperDidStartWorkNotification";
NSString * const TCMPortMapperDidFinishWorkNotification              = @"TCMPortMapperDidFinishWorkNotification";

NSString * const TCMPortMapperDidReceiveUPNPMappingTableNotification = @"TCMPortMapperDidReceiveUPNPMappingTableNotification";


NSString * const TCMNATPMPPortMapProtocol = @"NAT-PMP";
NSString * const TCMUPNPPortMapProtocol   = @"UPnP";
NSString * const TCMNoPortMapProtocol   = @"None";


static TCMPortMapper *S_sharedInstance;

enum {
    TCMPortMapProtocolFailed = 0,
    TCMPortMapProtocolTrying = 1,
    TCMPortMapProtocolWorks = 2
};

@interface NSString (IPAdditions)
- (BOOL)IPv4AddressInPrivateSubnet;
@end

@implementation NSString (IPAdditions)

- (BOOL)IPv4AddressInPrivateSubnet {
    in_addr_t myaddr = inet_addr([self UTF8String]);
    // private subnets as defined in http://tools.ietf.org/html/rfc1918
    // loopback addresses 127.0.0.1/8 http://tools.ietf.org/html/rfc3330
    // zeroconf/bonjour self assigned addresses 169.254.0.0/16 http://tools.ietf.org/html/rfc3927
    char *ipAddresses[]  = {"192.168.0.0", "10.0.0.0", "172.16.0.0","127.0.0.1","169.254.0.0"};
    char *networkMasks[] = {"255.255.0.0","255.0.0.0","255.240.0.0","255.0.0.0","255.255.0.0"};
    int countOfAddresses=5;
    int i = 0;
    for (i=0;i<countOfAddresses;i++) {
        in_addr_t subnetmask = inet_addr(networkMasks[i]);
        in_addr_t networkaddress = inet_addr(ipAddresses[i]);
        if ((myaddr & subnetmask) == (networkaddress & subnetmask)) {
            return YES;
        }
    }
    return NO;
}

@end


@implementation TCMPortMapping 

+ (id)portMappingWithLocalPort:(int)aPrivatePort desiredExternalPort:(int)aPublicPort transportProtocol:(int)aTransportProtocol userInfo:(id)aUserInfo {
    NSAssert(aPrivatePort<65536 && aPublicPort<65536 && aPrivatePort>0 && aPublicPort>0, @"Port number has to be between 1 and 65535");
    return [[[self alloc] initWithLocalPort:aPrivatePort desiredExternalPort:aPublicPort transportProtocol:aTransportProtocol userInfo:aUserInfo] autorelease];
}

- (id)initWithLocalPort:(int)aPrivatePort desiredExternalPort:(int)aPublicPort transportProtocol:(int)aTransportProtocol userInfo:(id)aUserInfo {
    if ((self=[super init])) {
        _desiredExternalPort = aPublicPort;
        _localPort = aPrivatePort;
        _userInfo = [aUserInfo retain];
        _transportProtocol = aTransportProtocol;
    }
    return self;
}

- (void)dealloc {
    [_userInfo release];
    [super dealloc];
}

- (int)desiredExternalPort {
    return _desiredExternalPort;
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
            [self setExternalPort:0];
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


- (int)externalPort {
    return _externalPort;
}

- (void)setExternalPort:(int)aPublicPort {
    _externalPort=aPublicPort;
}


- (int)localPort {
    return _localPort;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ privatePort:%u desiredPublicPort:%u publicPort:%u mappingStatus:%@ transportProtocol:%d",[super description], _localPort, _desiredExternalPort, _externalPort, _mappingStatus == TCMPortMappingStatusUnmapped ? @"unmapped" : (_mappingStatus == TCMPortMappingStatusMapped ? @"mapped" : @"trying"),_transportProtocol];
}

@end

@interface TCMPortMapper (Private) 

- (void)setExternalIPAddress:(NSString *)anAddress;
- (void)setLocalIPAddress:(NSString *)anAddress;
- (void)increaseWorkCount:(NSNotification *)aNotification;
- (void)decreaseWorkCount:(NSNotification *)aNotification;
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
        _upnpPortMappingsToRemove = [NSMutableSet new];
        
        [self hashUserID:NSUserName()];
        
        S_sharedInstance = self;

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        [center addObserver:self selector:@selector(increaseWorkCount:) 
                name:  TCMUPNPPortMapperDidBeginWorkingNotification    object:_UPNPPortMapper];
        [center addObserver:self selector:@selector(increaseWorkCount:) 
                name:TCMNATPMPPortMapperDidBeginWorkingNotification    object:_NATPMPPortMapper];

        [center addObserver:self selector:@selector(decreaseWorkCount:) 
                name:  TCMUPNPPortMapperDidEndWorkingNotification    object:_UPNPPortMapper];
        [center addObserver:self selector:@selector(decreaseWorkCount:) 
                name:TCMNATPMPPortMapperDidEndWorkingNotification    object:_NATPMPPortMapper];
        
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
    [_userID release];
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
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    [self refresh];
}

- (NSString *)externalIPAddress {
    return [[_externalIPAddress retain] autorelease];
}

- (NSString *)localBonjourHostName {
    SCDynamicStoreRef dynRef = SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)@"TCMPortMapper", NULL, NULL); 
    NSString *hostname = [(NSString *)SCDynamicStoreCopyLocalHostName(dynRef) autorelease];
    CFRelease(dynRef);
    return [hostname stringByAppendingString:@".local"];
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
            if (ipAddress && subNetMask) {
                in_addr_t myaddr = inet_addr([ipAddress UTF8String]);
                in_addr_t subnetmask = inet_addr([subNetMask UTF8String]);
                in_addr_t routeraddr = inet_addr([routerAddress UTF8String]);
        //            NSLog(@"%s ipNative:%X maskNative:%X",__FUNCTION__,routeraddr,subnetmask);
                if ((myaddr & subnetmask) == (routeraddr & subnetmask)) {
                    [self setLocalIPAddress:ipAddress];
                    _localIPOnRouterSubnet = YES;
                    break;
                }
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

- (NSString *)userID {
    return [[_userID retain] autorelease];
}

- (void)hashUserID:(NSString *)aUserIDToHash {
    // md5 has the username and take the first 8 bytes as hex
    unsigned char digest[16];
    char hashstring[32];
    int i;
    NSData *userNameData = [aUserIDToHash dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    MD5([userNameData bytes],[userNameData length],digest);
    for(i=0;i<8;i++) sprintf(hashstring+i*2,"%02x",digest[i]);
    hashstring[i*2]=0;
    
    [self setUserID:[NSString stringWithUTF8String:hashstring]];
}

- (void)setUserID:(NSString *)aUserID {
    if (_userID != aUserID) {
        NSString *tmp = _userID;
        _userID = [aUserID copy];
        [tmp release];
    }
}

- (NSSet *)portMappings{
    return _portMappings;
}

- (NSMutableSet *)removeMappingQueue {
    return _removeMappingQueue;
}

- (NSMutableSet *)_upnpPortMappingsToRemove {
    return _upnpPortMappingsToRemove;
}

- (void)updatePortMappings {
    NSString *protocol = [self mappingProtocol];
    if ([protocol isEqualToString:TCMNATPMPPortMapProtocol]) {
        [_NATPMPPortMapper updatePortMappings];
    } else if ([protocol isEqualToString:TCMUPNPPortMapProtocol]) {
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
        if (_isRunning) [self updatePortMappings];
    }
}

- (void)refresh {

    [self increaseWorkCount:nil];
    
    [self setRouterName:@"Unknown"];
    [self setMappingProtocol:TCMNoPortMapProtocol];
    [self setExternalIPAddress:nil];
    
    @synchronized(_portMappings) {
       NSEnumerator *portMappings = [_portMappings objectEnumerator];
       TCMPortMapping *portMapping = nil;
       while ((portMapping = [portMappings nextObject])) {
           if ([portMapping mappingStatus]==TCMPortMappingStatusMapped)
               [portMapping setMappingStatus:TCMPortMappingStatusUnmapped];
       }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperWillStartSearchForRouterNotification object:self];   
    
    NSString *routerAddress = [self routerIPAddress];
    if (routerAddress) {
        NSString *manufacturer = [TCMPortMapper manufacturerForHardwareAddress:[self routerHardwareAddress]];
        if (manufacturer) {
            [self setRouterName:manufacturer];
        } else {
            [self setRouterName:@"Unknown"];
        }
        NSString *localIPAddress = [self localIPAddress]; // will always be updated when accessed
        if (localIPAddress && _localIPOnRouterSubnet) {
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
                [self setMappingProtocol:TCMNoPortMapProtocol];
                // set all mappings to be mapped with their local port number being the external one
                @synchronized(_portMappings) {
                   NSEnumerator *portMappings = [_portMappings objectEnumerator];
                   TCMPortMapping *portMapping = nil;
                   while ((portMapping = [portMappings nextObject])) {
                        [portMapping setExternalPort:[portMapping localPort]];
                        [portMapping setMappingStatus:TCMPortMappingStatusMapped];
                   }
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFinishSearchForRouterNotification object:self];
                // we know we have a public address so we are finished - but maybe we should set all mappings to mapped
            }
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFinishSearchForRouterNotification object:self];
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFinishSearchForRouterNotification object:self];
    }

    // add the delay to bridge the gap between the thread starting and this method returning
    [self performSelector:@selector(decreaseWorkCount:) withObject:nil afterDelay:1.0];

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

+ (NSString *)manufacturerForHardwareAddress:(NSString *)aMACAddress {
    static NSDictionary *hardwareManufacturerDictionary = nil;
    if (hardwareManufacturerDictionary==nil) {
        NSString *plistPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"OUItoCompany" ofType:@"plist"];
        if (plistPath) {
            hardwareManufacturerDictionary = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        } else {
            hardwareManufacturerDictionary = [NSDictionary new];
        }
    }
    if ([aMACAddress length]<8) return nil;
	NSString *result = [hardwareManufacturerDictionary objectForKey:[[aMACAddress substringToIndex:8] uppercaseString]];
    return result;
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
                selector:@selector(NATPMPPortMapperDidReceiveBroadcastedExternalIPChange:) 
                name:TCMNATPMPPortMapperDidReceiveBroadcastedExternalIPChangeNotification 
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
        [self setMappingProtocol:TCMNATPMPPortMapProtocol];
        shouldNotify = YES;
    }
    [self setExternalIPAddress:[[aNotification userInfo] objectForKey:@"externalIPAddress"]];
    if (shouldNotify) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFinishSearchForRouterNotification object:self];
    }
}

- (void)NATPMPPortMapperDidFail:(NSNotification *)aNotification {
    if (_NATPMPStatus==TCMPortMapProtocolTrying) {
        _NATPMPStatus =TCMPortMapProtocolFailed;
    } else if (_NATPMPStatus==TCMPortMapProtocolWorks) {
        [self setExternalIPAddress:nil];
    }
    // also mark all port mappings as unmapped if UPNP failed too
    if (_UPNPStatus == TCMPortMapProtocolFailed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFinishSearchForRouterNotification object:self];
    }
}

- (void)UPNPPortMapperDidGetExternalIPAddress:(NSNotification *)aNotification {
    BOOL shouldNotify = NO;
    if (_UPNPStatus==TCMPortMapProtocolTrying) {
        _UPNPStatus =TCMPortMapProtocolWorks;
        [self setMappingProtocol:TCMUPNPPortMapProtocol];
        shouldNotify = YES;
        if (_NATPMPStatus==TCMPortMapProtocolTrying) {
            [_NATPMPPortMapper stop];
            _NATPMPStatus =TCMPortMapProtocolFailed;
        }
    }
    NSString *routerName = [[aNotification userInfo] objectForKey:@"routerName"];
    if (routerName) {
        [self setRouterName:routerName];
    }
    [self setExternalIPAddress:[[aNotification userInfo] objectForKey:@"externalIPAddress"]];
    if (shouldNotify) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFinishSearchForRouterNotification object:self];
    }
}

- (void)UPNPPortMapperDidFail:(NSNotification *)aNotification {
    if (_UPNPStatus==TCMPortMapProtocolTrying) {
        _UPNPStatus =TCMPortMapProtocolFailed;
    } else if (_UPNPStatus==TCMPortMapProtocolWorks) {
        [self setExternalIPAddress:nil];
    }
    // also mark all port mappings as unmapped if NATPMP failed too
    if (_NATPMPStatus == TCMPortMapProtocolFailed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFinishSearchForRouterNotification object:self];
    }
}

- (void)printNotification:(NSNotification *)aNotification {
    NSLog(@"TCMPortMapper received notification: %@", aNotification);
}

- (void)internalStop {
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    [center removeObserver:self name:@"State:/Network/Global/IPv4" object:_systemConfigNotificationManager];
    [center removeObserver:self name:TCMNATPMPPortMapperDidGetExternalIPAddressNotification object:_NATPMPPortMapper];
    [center removeObserver:self name:TCMNATPMPPortMapperDidFailNotification object:_NATPMPPortMapper];
    [center removeObserver:self name:TCMNATPMPPortMapperDidReceiveBroadcastedExternalIPChangeNotification object:_NATPMPPortMapper];
    
    [center removeObserver:self name:TCMUPNPPortMapperDidGetExternalIPAddressNotification object:_UPNPPortMapper];
    [center removeObserver:self name:TCMUPNPPortMapperDidFailNotification object:_UPNPPortMapper];
}

- (void)stop {
    if (_isRunning) {
        [self internalStop];
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
        [self internalStop];
        if (_NATPMPStatus == TCMPortMapProtocolWorks) {
            [_NATPMPPortMapper stopBlocking];
        }
        if (_UPNPStatus   == TCMPortMapProtocolWorks) {
            [_UPNPPortMapper stopBlocking];
        }
        _isRunning = NO;
    }
}

- (void)removeUPNPMappings:(NSArray *)aMappingList {
    if (_UPNPStatus == TCMPortMapProtocolWorks) {
        @synchronized (_upnpPortMappingsToRemove) {
            [_upnpPortMappingsToRemove addObjectsFromArray:aMappingList];
        }
        [_UPNPPortMapper updatePortMappings];
    }
}

- (void)requestUPNPMappingTable {
    if (_UPNPStatus == TCMPortMapProtocolWorks) {
        _sendUPNPMappingTableNotification = YES;
        [_UPNPPortMapper updatePortMappings];
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

- (BOOL)isAtWork {
    return (_workCount > 0);
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

- (void)increaseWorkCount:(NSNotification *)aNotification {
#ifdef DEBUG
    NSLog(@"%s %d %@",__FUNCTION__,_workCount,aNotification);
#endif
    if (_workCount == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidStartWorkNotification object:self];
    }
    _workCount++;
}

- (void)decreaseWorkCount:(NSNotification *)aNotification {
#ifdef DEBUG
    NSLog(@"%s %d %@",__FUNCTION__,_workCount,aNotification);
#endif
    _workCount--;
    if (_workCount == 0) {
        if (_UPNPStatus == TCMPortMapProtocolWorks && _sendUPNPMappingTableNotification) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidReceiveUPNPMappingTableNotification object:self userInfo:[NSDictionary dictionaryWithObject:[_UPNPPortMapper latestUPNPPortMappingsList] forKey:@"mappingTable"]];
            _sendUPNPMappingTableNotification = NO;
        }
    
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMPortMapperDidFinishWorkNotification object:self];
    }
}

- (void)didWake:(NSNotification *)aNotification {
    if (_isRunning) {
        // take some time because on the moment of awakening e.g. airport isn't yet connected
        [self performSelector:@selector(refresh) withObject:nil afterDelay:1.];
    }
}

- (void)willSleep:(NSNotification *)aNotificaiton {
    if (_isRunning) {
        if (_NATPMPStatus == TCMPortMapProtocolWorks) {
            [_NATPMPPortMapper stopBlocking];
        }
        if (_UPNPStatus   == TCMPortMapProtocolWorks) {
            [_UPNPPortMapper stopBlocking];
        }
    }
}

- (void)NATPMPPortMapperDidReceiveBroadcastedExternalIPChange:(NSNotification *)aNotification {
    if (_isRunning) {
        NSDictionary *userInfo = [aNotification userInfo];
        // senderAddress is of the format <ipv4address>:<port>
        NSString *senderIPAddress = [userInfo objectForKey:@"senderAddress"];
        // we have to check if the sender is actually our router - if not disregard
        if ([senderIPAddress isEqualToString:[self routerIPAddress]]) {
            if (![[self externalIPAddress] isEqualToString:[userInfo objectForKey:@"externalIPAddress"]]) {
                NSLog(@"Refreshing because of  NAT-PMP-Device external IP broadcast:%@",userInfo);
                [self refresh];
            }
        } else {
            NSLog(@"Got Information from rogue NAT-PMP-Device:%@",userInfo);
        }
    }
}

@end

