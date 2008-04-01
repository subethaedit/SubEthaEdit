
#import "TCMNATPMPPortMapper.h"
#import "NSNotificationCenterThreadingAdditions.h"

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <net/if.h>
#import <arpa/inet.h>
#import <sys/socket.h>

NSString * const TCMNATPMPPortMapperDidFailNotification = @"TCMNATPMPPortMapperDidFailNotification";
NSString * const TCMNATPMPPortMapperDidGetExternalIPAddressNotification = @"TCMNATPMPPortMapperDidGetExternalIPAddressNotification";
NSString * const TCMNATPMPPortMapperDidReceiveBroadcastedExternalIPChangeNotification = @"TCMNATPMPPortMapperDidReceiveBroadcastedExternalIPChangeNotification";

// these notifications come in pairs. TCMPortmapper must reference count them and unify them to a notification pair that does not need to be reference counted
NSString * const TCMNATPMPPortMapperDidBeginWorkingNotification =@"TCMNATPMPPortMapperDidBeginWorkingNotification";
NSString * const TCMNATPMPPortMapperDidEndWorkingNotification   =@"TCMNATPMPPortMapperDidEndWorkingNotification";

#define PORTMAPREFRESHSHOULDNOTRESTART 2

static TCMNATPMPPortMapper *S_sharedInstance;

static void readData (
   CFSocketRef aSocket,
   CFSocketCallBackType aCallbackType,
   CFDataRef anAddress,
   const void *data,
   void *info
);

@interface NSString (NSStringNATPortMapperAdditions)
+ (NSString *)stringWithAddressData:(NSData *)aData;
@end

@implementation NSString (NSStringNATPortMapperAdditions)
+ (NSString *)stringWithAddressData:(NSData *)aData
{
    struct sockaddr *socketAddress = (struct sockaddr *)[aData bytes];
    
    // IPv6 Addresses are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF" at max, which is 40 bytes (0-terminated)
    // IPv4 Addresses are "255.255.255.255" at max which is smaller
    
    char stringBuffer[MAX(INET6_ADDRSTRLEN,INET_ADDRSTRLEN)];
    NSString *addressAsString = nil;
    if (socketAddress->sa_family == AF_INET) {
        if (inet_ntop(AF_INET, &(((struct sockaddr_in *)socketAddress)->sin_addr), stringBuffer, INET_ADDRSTRLEN)) {
            addressAsString = [NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString = @"IPv4 un-ntopable";
        }
        int port = ntohs(((struct sockaddr_in *)socketAddress)->sin_port);
            addressAsString = [addressAsString stringByAppendingFormat:@":%d", port];
    } else if (socketAddress->sa_family == AF_INET6) {
         if (inet_ntop(AF_INET6, &(((struct sockaddr_in6 *)socketAddress)->sin6_addr), stringBuffer, INET6_ADDRSTRLEN)) {
            addressAsString = [NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString = @"IPv6 un-ntopable";
        }
        int port = ntohs(((struct sockaddr_in6 *)socketAddress)->sin6_port);
        
        // Suggested IPv6 format (see http://www.faqs.org/rfcs/rfc2732.html)
        char interfaceName[IF_NAMESIZE];
        if ([addressAsString hasPrefix:@"fe80"] && if_indextoname(((struct sockaddr_in6 *)socketAddress)->sin6_scope_id,interfaceName)) {
            NSString *zoneID = [NSString stringWithUTF8String:interfaceName];
            addressAsString = [NSString stringWithFormat:@"[%@%%%@]:%d", addressAsString, zoneID, port];
        } else {
            addressAsString = [NSString stringWithFormat:@"[%@]:%d", addressAsString, port];
        }
    } else {
        addressAsString = @"neither IPv6 nor IPv4";
    }
    
    return [[addressAsString copy] autorelease];
}
@end

@implementation TCMNATPMPPortMapper
+ (TCMNATPMPPortMapper *)sharedInstance
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
        natPMPThreadIsRunningLock = [NSLock new];
        if ([natPMPThreadIsRunningLock respondsToSelector:@selector(setName:)]) 
            [(id)natPMPThreadIsRunningLock performSelector:@selector(setName:) withObject:@"NATPMPThreadRunningLock"];
        // add UDP listener for public ip update packets
        //    0                   1                   2                   3
        //    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
        //   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        //   | Vers = 0      | OP = 128 + 0  | Result Code                   |
        //   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        //   | Seconds Since Start of Epoch                                  |
        //   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        //   | Public IP Address (a.b.c.d)                                   |
        //   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        CFSocketContext socketContext;
        bzero(&socketContext, sizeof(CFSocketContext));
        socketContext.info = self;
        CFSocketRef listeningSocket = NULL;
        listeningSocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, 
                                           kCFSocketDataCallBack, readData, &socketContext);
        if (listeningSocket) {
            int yes = 1;
            int result = setsockopt(CFSocketGetNative(listeningSocket), SOL_SOCKET, 
                                    SO_REUSEADDR, &yes, sizeof(int));
            if (result == -1) {
                NSLog(@"Could not setsockopt to reuseaddr: %@ / %s", errno, strerror(errno));
            }
            
            result = setsockopt(CFSocketGetNative(listeningSocket), SOL_SOCKET, 
                                    SO_REUSEPORT, &yes, sizeof(int));
            if (result == -1) {
                NSLog(@"Could not setsockopt to reuseport: %@ / %s", errno, strerror(errno));
            }
            
            CFDataRef addressData = NULL;
            struct sockaddr_in socketAddress;
            
            bzero(&socketAddress, sizeof(struct sockaddr_in));
            socketAddress.sin_len = sizeof(struct sockaddr_in);
            socketAddress.sin_family = PF_INET;
            socketAddress.sin_port = htons(5351);
            socketAddress.sin_addr.s_addr = inet_addr("224.0.0.1");
            
            addressData = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&socketAddress, sizeof(struct sockaddr_in));
            if (addressData == NULL) {
                NSLog(@"Could not create addressData");
            } else {
                    
                CFSocketError err = CFSocketSetAddress(listeningSocket, addressData);
                if (err != kCFSocketSuccess) {
                    NSLog(@"%s could not set address on socket",__FUNCTION__);
                } else {
                    CFRunLoopRef currentRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    
                    CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, listeningSocket, 0);
                    CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
                    CFRelease(runLoopSource);
                }
                
                CFRelease(addressData);
            }
            addressData = NULL;

        } else {
            NSLog(@"Could not create listening socket for IPv4");
        }
    }
    return self;
}

- (void)dealloc {
    [natPMPThreadIsRunningLock release];
    [super dealloc];
}

- (void)stop {
    if ([_updateTimer isValid]) {
        [_updateTimer invalidate];
        [_updateTimer release];
        _updateTimer = nil;
    }
    if (![natPMPThreadIsRunningLock tryLock] && (runningThreadID == TCMExternalIPThreadID)) {
        // stop that one
        IPAddressThreadShouldQuitAndRestart = PORTMAPREFRESHSHOULDNOTRESTART;
    } else {
        [natPMPThreadIsRunningLock unlock];
        // restart update to remove mappings before stopping
        [self updatePortMappings];
    }
}

- (void)refresh {
    // Run externalipAddress in Thread
    if ([natPMPThreadIsRunningLock tryLock]) {
        _updateInterval = 3600 / 2.;
        IPAddressThreadShouldQuitAndRestart=NO;
        UpdatePortMappingsThreadShouldQuit = NO;
        runningThreadID = TCMExternalIPThreadID;
        [NSThread detachNewThreadSelector:@selector(refreshExternalIPInThread) toTarget:self withObject:nil];
        [natPMPThreadIsRunningLock unlock];
    } else  {
        if (runningThreadID == TCMExternalIPThreadID) {
            IPAddressThreadShouldQuitAndRestart=YES;
        } else if (runningThreadID == TCMUpdatingMappingThreadID) {
            UpdatePortMappingsThreadShouldQuit = YES;
        }
    }

}

- (void)adjustUpdateTimer {
    if ([_updateTimer isValid]) {
        [_updateTimer invalidate];
    }
    [_updateTimer autorelease];
    _updateTimer = [[NSTimer scheduledTimerWithTimeInterval:_updateInterval target:self selector:@selector(updatePortMappings) userInfo:nil repeats:NO] retain];
}

/*

Standardablauf:

- refresh -> löst einen Thread mit refreshExternalIPInThread aus -> am erfolgreichen ende dieses threads wird ein updatePortMappings auf dem mainthread aufgerufen
  - Fall 1: nichts läuft bereits -> alles ist gut
  - Fall 2: ein thread mit refreshExternalIPInThread läuft -> dieser Thread wird abgebrochen und danach erneut refresh aufgerufen
  - Fall 3: ein thread mit updatePortMappingsInThread läuft -> der updatePortMappingsInThread sollte abgebrochen werden, und danach ein refresh aufgerufen werden

- updatePortMappings -> löst einen Thread mit updatePortMappings aus -> am erfolgreichen ende dieses Threads wird ein adjustUpdateTimer auf dem mainthread aufgerufen
  - Fall 1: nichts läuft bereits -> alles ist gut
  - Fall 2: ein refreshExternalIPInThread läuft -> alles wird gut, wir tun nix
  - Fall 3: ein thread mit updatePortMappingsInThread läuft -> updatePortMappingsInThread sollte von vorne beginnen

*/

- (void)updatePortMappings {
    if ([natPMPThreadIsRunningLock tryLock]) {
        UpdatePortMappingsThreadShouldRestart=NO;
        runningThreadID = TCMUpdatingMappingThreadID;
        [NSThread detachNewThreadSelector:@selector(updatePortMappingsInThread) toTarget:self withObject:nil];
        [natPMPThreadIsRunningLock unlock];
    } else  {
        if (runningThreadID == TCMUpdatingMappingThreadID) {
            UpdatePortMappingsThreadShouldRestart = YES;
        }
    }
}

- (BOOL)applyPortMapping:(TCMPortMapping *)aPortMapping remove:(BOOL)shouldRemove natpmp:(natpmp_t *)aNatPMPt {
    natpmpresp_t response;
    int r;
    //int sav_errno;
    struct timeval timeout;
    fd_set fds;
    
    if (!shouldRemove) [aPortMapping setMappingStatus:TCMPortMappingStatusTrying];
    TCMPortMappingTransportProtocol protocol = [aPortMapping transportProtocol];

    int i;
    for (i=1;i<=2;i++) {
        if ((i == protocol)||(protocol == TCMPortMappingTransportProtocolBoth)) {
            r = sendnewportmappingrequest(aNatPMPt, (i==TCMPortMappingTransportProtocolUDP)?NATPMP_PROTOCOL_UDP:NATPMP_PROTOCOL_TCP, [aPortMapping localPort],[aPortMapping desiredExternalPort], shouldRemove?0:3600);
        
            do {
                FD_ZERO(&fds);
                FD_SET(aNatPMPt->s, &fds);
                getnatpmprequesttimeout(aNatPMPt, &timeout);
                select(FD_SETSIZE, &fds, NULL, NULL, &timeout);
                r = readnatpmpresponseorretry(aNatPMPt, &response);
            } while(r==NATPMP_TRYAGAIN);
    
            if (r<0) {
               [aPortMapping setMappingStatus:TCMPortMappingStatusUnmapped];
               return NO;
            }
        }
    }

    // update PortMapping
    if (shouldRemove) {
       [aPortMapping setMappingStatus:TCMPortMappingStatusUnmapped];
    } else {
       _updateInterval = MIN(_updateInterval,response.newportmapping.lifetime/2.);
       if (_updateInterval < 60.) {
           NSLog(@"%s caution - new port mapping had a lifetime < 120. : %u - %@",__FUNCTION__,response.newportmapping.lifetime, aPortMapping);
           _updateInterval = 60.;
       }
       [aPortMapping setExternalPort:response.newportmapping.mappedpublicport];
       [aPortMapping setMappingStatus:TCMPortMappingStatusMapped];
    }
    
    /* TODO : check response.type ! */
    // printf("Mapped public port %hu to localport %hu liftime %u\n", response.newportmapping.mappedpublicport, response.newportmapping.privateport, response.newportmapping.lifetime);
    //printf("epoch = %u\n", response.epoch);
    return YES;
}

- (void)updatePortMappingsInThread {
    [natPMPThreadIsRunningLock lock];
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMNATPMPPortMapperDidBeginWorkingNotification object:self];
    
    natpmp_t natpmp;
    initnatpmp(&natpmp);
    
    NSMutableSet *mappingsSet = [[TCMPortMapper sharedInstance] removeMappingQueue];
    
    while (!UpdatePortMappingsThreadShouldQuit && !UpdatePortMappingsThreadShouldRestart) {
        TCMPortMapping *mappingToRemove=nil;
        
        @synchronized (mappingsSet) {
            mappingToRemove = [mappingsSet anyObject];
        }
        
        if (!mappingToRemove) break;
        
        if ([mappingToRemove mappingStatus] == TCMPortMappingStatusMapped) {
            [self applyPortMapping:mappingToRemove remove:YES natpmp:&natpmp];
        }
        
        @synchronized (mappingsSet) {
            [mappingsSet removeObject:mappingToRemove];
        }
        
    }    

    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    NSSet *mappingsToAdd = [pm portMappings];

    // Refresh exisiting mappings
    
    NSSet *existingMappings;
    @synchronized (mappingsToAdd) {
        existingMappings = [[mappingsToAdd copy] autorelease];
    }
    
    NSEnumerator *existingMappingsEnumerator = [existingMappings objectEnumerator];
    TCMPortMapping *mappingToRefresh;
    while ((mappingToRefresh = [existingMappingsEnumerator nextObject])) {
        if ([mappingToRefresh mappingStatus] == TCMPortMappingStatusMapped && [pm isRunning]) {
            if (![self applyPortMapping:mappingToRefresh remove:NO natpmp:&natpmp]) {
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidFailNotification object:self]];
                break;
            }
        }
        if (UpdatePortMappingsThreadShouldQuit || UpdatePortMappingsThreadShouldRestart) break;
    }


    // Add new mapping or remove existing mappings when not running.
    
    while (!UpdatePortMappingsThreadShouldQuit && !UpdatePortMappingsThreadShouldRestart) {
        TCMPortMapping *mappingToApply;
        @synchronized (mappingsToAdd) {
            mappingToApply = nil;
            NSEnumerator *mappings = [mappingsToAdd objectEnumerator];
            TCMPortMapping *mapping = nil;
            BOOL isRunning = [pm isRunning];
            while ((mapping = [mappings nextObject])) {
                if ([mapping mappingStatus] == TCMPortMappingStatusUnmapped && isRunning) {
                    mappingToApply = mapping;
                    break;
                } else if ([mapping mappingStatus] == TCMPortMappingStatusMapped && !isRunning) {
                    mappingToApply = mapping;
                    break;
                }
            }
        }
        
        if (!mappingToApply) break;
        
        if (![self applyPortMapping:mappingToApply remove:[pm isRunning]?NO:YES natpmp:&natpmp]) {
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidFailNotification object:self]];
            break;
        };
    }
    closenatpmp(&natpmp);

    [natPMPThreadIsRunningLock unlock];
    if (UpdatePortMappingsThreadShouldQuit) {
        NSLog(@"%s scheduled refresh",__FUNCTION__);
        [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:NO];
    } else if (UpdatePortMappingsThreadShouldRestart) {
        [self performSelectorOnMainThread:@selector(updatePortMapping) withObject:nil waitUntilDone:NO];
    } else {
        if ([pm isRunning]) {
            [self performSelectorOnMainThread:@selector(adjustUpdateTimer) withObject:nil waitUntilDone:NO];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMNATPMPPortMapperDidEndWorkingNotification object:self];
    [pool release];
}

- (void)refreshExternalIPInThread {
    [natPMPThreadIsRunningLock lock];
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMNATPMPPortMapperDidBeginWorkingNotification object:self];
    natpmp_t natpmp;
    natpmpresp_t response;
    int r;
    struct timeval timeout;
    fd_set fds;
    BOOL didFail=NO;
    r = initnatpmp(&natpmp);
    if(r<0) {
       didFail = YES;
    } else {
        r = sendpublicaddressrequest(&natpmp);
        if(r<0) {
            didFail = YES;
        } else {
#ifdef DEBUG
            int count = 0;
#endif
            do {
                FD_ZERO(&fds);
                FD_SET(natpmp.s, &fds);
                getnatpmprequesttimeout(&natpmp, &timeout);
#ifdef DEBUG
                NSLog(@"NATPMP refreshExternalIP try #%d",++count);
#endif
                select(FD_SETSIZE, &fds, NULL, NULL, &timeout);
                r = readnatpmpresponseorretry(&natpmp, &response);
                if (IPAddressThreadShouldQuitAndRestart) {
#ifdef DEBUG
                    NSLog(@"%s ----------------- thread quit prematurely",__FUNCTION__);
#endif
                    [natPMPThreadIsRunningLock unlock];
                    if (IPAddressThreadShouldQuitAndRestart != PORTMAPREFRESHSHOULDNOTRESTART) {
                        [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:0];
                    }
                    closenatpmp(&natpmp);
                    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMNATPMPPortMapperDidEndWorkingNotification object:self];
                    [pool release];
                    return;
                }
            } while(r==NATPMP_TRYAGAIN);
        
            if(r<0) {
               didFail = YES;
#ifndef NDEBUG
               NSLog(@"NAT-PMP: IP refresh did time out");
#endif
            } else {
                /* TODO : check that response.type == 0 */
            
                NSString *ipString = [NSString stringWithFormat:@"%s", inet_ntoa(response.publicaddress.addr)];
#ifndef NDEBUG
                NSLog(@"NAT-PMP:  found IP:%@",ipString);
#endif
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidGetExternalIPAddressNotification object:self userInfo:[NSDictionary dictionaryWithObject:ipString forKey:@"externalIPAddress"]]];
            }
        }
    }
    closenatpmp(&natpmp);
    [natPMPThreadIsRunningLock unlock];
    if (IPAddressThreadShouldQuitAndRestart) {
#ifndef DEBUG
        NSLog(@"%s thread quit prematurely",__FUNCTION__);
#endif
        if (IPAddressThreadShouldQuitAndRestart != PORTMAPREFRESHSHOULDNOTRESTART) {
            [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:0];
        }
    } else {
        if (didFail) {
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidFailNotification object:self]];
        } else {
            [self performSelectorOnMainThread:@selector(updatePortMappings) withObject:nil waitUntilDone:0];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMNATPMPPortMapperDidEndWorkingNotification object:self];
    [pool release];
}

- (void)stopBlocking {
    UpdatePortMappingsThreadShouldQuit = YES;
    IPAddressThreadShouldQuitAndRestart = YES;
    [natPMPThreadIsRunningLock lock];
    NSSet *mappingsToStop = [[TCMPortMapper sharedInstance] portMappings];
    natpmp_t natpmp;
    initnatpmp(&natpmp);
    @synchronized (mappingsToStop) {
        NSEnumerator *mappings = [mappingsToStop objectEnumerator];
        TCMPortMapping *mapping = nil;
        while ((mapping = [mappings nextObject])) {
            if ([mapping mappingStatus] == TCMPortMappingStatusMapped) {
                [self applyPortMapping:mapping remove:YES natpmp:&natpmp];
                [mapping setMappingStatus:TCMPortMappingStatusUnmapped];
            }
        }
    }
    [natPMPThreadIsRunningLock unlock];
}

- (void)didReceiveExternalIP:(NSString *)anExternalIPAddress fromSenderAddress:(NSString *)aSenderAddressString secondsSinceEpoch:(int)aSecondsSinceEpoch {
    if (anExternalIPAddress!=nil && aSenderAddressString!=nil && 
        (![_lastBroadcastedExternalIP isEqualToString:anExternalIPAddress] || 
         ![_lastExternalIPSenderAddress isEqualToString:aSenderAddressString])) {
        [_lastBroadcastedExternalIP release];
         _lastBroadcastedExternalIP = [anExternalIPAddress copy];
        [_lastExternalIPSenderAddress release];
         _lastExternalIPSenderAddress = [aSenderAddressString copy];
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:TCMNATPMPPortMapperDidReceiveBroadcastedExternalIPChangeNotification 
            object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                        _lastBroadcastedExternalIP,@"externalIP",
                        _lastExternalIPSenderAddress,@"senderAddress",
                        [NSNumber numberWithInt:aSecondsSinceEpoch],@"secondsSinceStartOfEpoch",
                      nil]
        ];
    }
}

@end


static void readData (
   CFSocketRef aSocket,
   CFSocketCallBackType aCallbackType,
   CFDataRef anAddress,
   const void *aData,
   void *anInfo
) {
    NSData *data = (NSData *)aData;
    TCMNATPMPPortMapper *natpmpMapper = (TCMNATPMPPortMapper *)anInfo;
    if ([data length]==12) {
        NSString *senderAddressAndPort = [NSString stringWithAddressData:(NSData *)anAddress];
        NSString *senderAddress = [[senderAddressAndPort componentsSeparatedByString:@":"] objectAtIndex:0];
        // add UDP listener for public ip update packets
        //    0                   1                   2                   3
        //    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
        //   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        //   | Vers = 0      | OP = 128 + 0  | Result Code                   |
        //   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        //   | Seconds Since Start of Epoch                                  |
        //   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        //   | Public IP Address (a.b.c.d)                                   |
        //   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        char buffer[INET_ADDRSTRLEN];
        unsigned char *bytes = (unsigned char *)[data bytes];
        inet_ntop(AF_INET, &(bytes[8]), buffer, INET_ADDRSTRLEN);
        NSString *newIPAddress = [NSString stringWithUTF8String:buffer];
        int secondsSinceEpoch = ntohl(*((int32_t *)&(bytes[4])));
#ifndef NDEBUG
        NSLog(@"%s sender:%@ new:%@ seconds:%d",__FUNCTION__,senderAddressAndPort, newIPAddress, secondsSinceEpoch);
#endif
        [natpmpMapper didReceiveExternalIP:newIPAddress fromSenderAddress:senderAddress secondsSinceEpoch:secondsSinceEpoch];
    }
}


