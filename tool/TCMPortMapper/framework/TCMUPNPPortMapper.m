
#import "TCMUPNPPortMapper.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/SCSchemaDefinitions.h>
#import "NSNotificationCenterThreadingAdditions.h"

//static void PrintHeader(void)
//    // Prints an explanation of the flag coding.
//{
//    fprintf(stdout, "t = kSCNetworkFlagsTransientConnection\n");
//    fprintf(stdout, "r = kSCNetworkFlagsReachable\n");
//    fprintf(stdout, "c = kSCNetworkFlagsConnectionRequired\n");
//    fprintf(stdout, "C = kSCNetworkFlagsConnectionAutomatic\n");
//    fprintf(stdout, "i = kSCNetworkFlagsInterventionRequired\n");
//    fprintf(stdout, "l = kSCNetworkFlagsIsLocalAddress\n");
//    fprintf(stdout, "d = kSCNetworkFlagsIsDirect\n");
//    fprintf(stdout, "\n");
//}

NSString * const TCMUPNPPortMapperDidFailNotification = @"TCMNATPMPPortMapperDidFailNotification";
NSString * const TCMUPNPPortMapperDidGetExternalIPAddressNotification = @"TCMNATPMPPortMapperDidGetExternalIPAddressNotification";
// these notifications come in pairs. TCMPortmapper must reference count them and unify them to a notification pair that does not need to be reference counted
NSString * const TCMUPNPPortMapperDidBeginWorkingNotification =@"TCMUPNPPortMapperDidBeginWorkingNotification";
NSString * const TCMUPNPPortMapperDidEndWorkingNotification   =@"TCMUPNPPortMapperDidEndWorkingNotification";

@implementation TCMUPNPPortMapper

- (id)init {
    if ((self=[super init])) {
        _threadIsRunningLock = [NSLock new];
        if ([_threadIsRunningLock respondsToSelector:@selector(setName:)]) 
            [_threadIsRunningLock performSelector:@selector(setName:) withObject:@"UPNP-ThreadRunningLock"];

    }
    return self;
}

- (void)dealloc {
    [_threadIsRunningLock release];
    [_latestUPNPPortMappingsList release];
    [super dealloc];
}

- (void)setLatestUPNPPortMappingsList:(NSArray *)aLatestList {
    if (aLatestList != _latestUPNPPortMappingsList) {
        id tmp = _latestUPNPPortMappingsList;
        _latestUPNPPortMappingsList = [aLatestList retain];
        [tmp autorelease];
    }
}

- (NSArray *)latestUPNPPortMappingsList {
    return [[_latestUPNPPortMappingsList retain] autorelease];
}


- (void)refresh {
    if ([_threadIsRunningLock tryLock]) {
        refreshThreadShouldQuit=NO;
        UpdatePortMappingsThreadShouldQuit = NO;
        runningThreadID = TCMExternalIPThreadID;
        [NSThread detachNewThreadSelector:@selector(refreshInThread) toTarget:self withObject:nil];
        [_threadIsRunningLock unlock];
#ifdef DEBUG
        NSLog(@"%s detachedThread",__FUNCTION__);
#endif
    } else {
        if (runningThreadID == TCMExternalIPThreadID) {
            refreshThreadShouldQuit=YES;
#ifdef DEBUG
            NSLog(@"%s thread should quit",__FUNCTION__);
#endif
        } else if (runningThreadID == TCMUpdatingMappingThreadID) {
            UpdatePortMappingsThreadShouldQuit = YES;
        }
    }
}

- (NSString *)portMappingDescription {
    static NSString *description = nil;
    if (!description) {
        NSMutableArray *descriptionComponents=[NSMutableArray arrayWithObject:@"TCMPM"];
        NSString *component = [[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension];
        if (component) [descriptionComponents addObject:component];
        NSString *userID = [[TCMPortMapper sharedInstance] userID];
        if (userID) [descriptionComponents addObject:userID];
        description = [[descriptionComponents componentsJoinedByString:@"/"] retain];
    }
    return description;
}

- (void)postDidEndWorkingNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMUPNPPortMapperDidEndWorkingNotification object:self];
}

- (void)postDelayedDidEndWorkingNotification {
    [self performSelector:@selector(postDidEndWorkingNotification) withObject:nil afterDelay:0.5];
}
// example device description root urls:
// FritzBox: http://192.168.178.1:49000/igddesc.xml - desc: http://192.168.178.1:49000/fboxdesc.xml
// Linksys: http://10.0.1.1:49152/gateway.xml
// we need to cache these for better response time of the update mappings thread

- (void)refreshInThread {
    [_threadIsRunningLock lock];
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMUPNPPortMapperDidBeginWorkingNotification object:self];
    struct UPNPDev * devlist = 0;
    const char * multicastif = 0;
    const char * minissdpdpath = 0;
    char lanaddr[16];   /* my ip address on the LAN */
    char externalIPAddress[16];
    BOOL didFail=NO;
    NSString *errorString = nil;
    if (( devlist = upnpDiscover(2000, multicastif, minissdpdpath) )) {
        if(devlist) {
        
            // let us check all of the devices for reachability
            BOOL foundIDGDevice = NO;
            struct UPNPDev * device;
#ifdef DEBUG
            NSLog(@"List of UPNP devices found on the network :\n");
#endif
            NSMutableArray *URLsToTry = [NSMutableArray array];
            NSMutableSet *triedURLSet = [NSMutableSet set];
            for(device = devlist; device && !foundIDGDevice; device = device->pNext) {
                NSURL *descURL = [NSURL URLWithString:[NSString stringWithUTF8String:device->descURL]];
                SCNetworkConnectionFlags status;
                Boolean success = SCNetworkCheckReachabilityByName([[descURL host] UTF8String], &status); 
#ifndef NDEBUG
                NSLog(@"UPnP: %@ %c%c%c%c%c%c%c host:%s st:%s",
                    success ? @"YES" : @" NO",
                    (status & kSCNetworkFlagsTransientConnection)  ? 't' : '-',
                    (status & kSCNetworkFlagsReachable)            ? 'r' : '-',
                    (status & kSCNetworkFlagsConnectionRequired)   ? 'c' : '-',
                    (status & kSCNetworkFlagsConnectionAutomatic)  ? 'C' : '-',
                    (status & kSCNetworkFlagsInterventionRequired) ? 'i' : '-',
                    (status & kSCNetworkFlagsIsLocalAddress)       ? 'l' : '-',
                    (status & kSCNetworkFlagsIsDirect)             ? 'd' : '-',
                    device->descURL,
                    device->st
                );
#endif
                // only connect to directly reachable hosts which we haven't tried yet (if you are multihoming then you get all of the announcement twice
                if (success && (status & kSCNetworkFlagsIsDirect)) {
                    if (![triedURLSet containsObject:descURL]) {
                        [triedURLSet addObject:descURL];
                        if ([[descURL host] isEqualToString:[[TCMPortMapper sharedInstance] routerIPAddress]]) {
                            [URLsToTry insertObject:descURL atIndex:0];
                        } else {
                            [URLsToTry addObject:descURL];
                        }
                    }
                }
            }
            NSEnumerator *URLEnumerator = [URLsToTry objectEnumerator];
            NSURL *descURL = nil;
            while ((descURL = [URLEnumerator nextObject])) {
#ifndef NDEBUG
                NSLog(@"UPnP: trying URL:%@",descURL);
#endif
                if (UPNP_GetIGDFromUrl([[descURL absoluteString] UTF8String],&_urls,&_igddata,lanaddr,sizeof(lanaddr))) {
                    int r = UPNP_GetExternalIPAddress(_urls.controlURL,
                                              _igddata.servicetype,
                                              externalIPAddress);
                    if(r != UPNPCOMMAND_SUCCESS) {
                        didFail = YES;
                        errorString = [NSString stringWithFormat:@"GetExternalIPAddress() returned %d", r];
                    } else {
                        if(externalIPAddress[0]) {
                            NSString *ipString = [NSString stringWithUTF8String:externalIPAddress];
                            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:ipString forKey:@"externalIPAddress"];
                            NSString *routerName = [NSString stringWithUTF8String:_igddata.modeldescription];
                            if (routerName) [userInfo setObject:routerName forKey:@"routerName"];
                            [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMUPNPPortMapperDidGetExternalIPAddressNotification object:self userInfo:userInfo]];
                            foundIDGDevice = YES;
                            didFail = NO;
                            break;
                        } else {
                            didFail = YES;
                            errorString = @"No external IP address!";
                        }
                    }
                }
            }
            if (!foundIDGDevice) {
                didFail = YES;
                errorString = @"No IDG Device found on the network!";
            }
        } else {
            didFail = YES;
            errorString = @"No IDG Device found on the network!";
        }
        freeUPNPDevlist(devlist); devlist = 0;
    } else {
        didFail = YES;
        errorString = @"No IDG Device found on the network!";
    }
    [_threadIsRunningLock unlock];
    if (refreshThreadShouldQuit) {
#ifdef DEBUG
        NSLog(@"%s thread quit prematurely",__FUNCTION__);
#endif
        [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:0];
    } else {
        if (didFail) {
#ifdef DEBUG
            NSLog(@"%s didFailWithError: %@",__FUNCTION__, errorString);
#endif
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMUPNPPortMapperDidFailNotification object:self]];
        } else {
            [self performSelectorOnMainThread:@selector(updatePortMappings) withObject:nil waitUntilDone:0];
        }
    }
    // the delaying bridges the small time gap between this thread and the update thread
    [self performSelectorOnMainThread:@selector(postDelayedDidEndWorkingNotification) withObject:nil waitUntilDone:NO];
    [pool release];
}

- (void)updatePortMappings {
    if ([_threadIsRunningLock tryLock]) {
        UpdatePortMappingsThreadShouldRestart=NO;
        runningThreadID = TCMUpdatingMappingThreadID;
        [NSThread detachNewThreadSelector:@selector(updatePortMappingsInThread) toTarget:self withObject:nil];
        [_threadIsRunningLock unlock];
#ifdef DEBUG
        NSLog(@"%s detachedThread",__FUNCTION__);
#endif
    } else  {
        if (runningThreadID == TCMUpdatingMappingThreadID) {
            UpdatePortMappingsThreadShouldRestart = YES;
        }
    }
}

- (BOOL)applyPortMapping:(TCMPortMapping *)aPortMapping remove:(BOOL)shouldRemove UPNPURLs:(struct UPNPUrls *)aURLs IGDDatas:(struct IGDdatas *)aIGDData reservedExternalPortNumbers:(NSIndexSet *)aExternalPortSet {
    BOOL didFail = NO;
    //NSLog(@"%s %@",__FUNCTION__,aPortMapping);
    [aPortMapping setMappingStatus:TCMPortMappingStatusTrying];
    if (shouldRemove) {
        if ([aPortMapping transportProtocol] & TCMPortMappingTransportProtocolTCP) {
            UPNP_DeletePortMapping(aURLs->controlURL, aIGDData->servicetype,[[NSString stringWithFormat:@"%d",[aPortMapping externalPort]] UTF8String], "TCP");
        }
        if ([aPortMapping transportProtocol] & TCMPortMappingTransportProtocolUDP) {
            UPNP_DeletePortMapping(aURLs->controlURL, aIGDData->servicetype,[[NSString stringWithFormat:@"%d",[aPortMapping externalPort]] UTF8String], "UDP");
        }
        [aPortMapping setMappingStatus:TCMPortMappingStatusUnmapped];
        return YES;
    } else { // We should add it
        int mappedPort = [aPortMapping desiredExternalPort];
        int protocol = TCMPortMappingTransportProtocolUDP;
        for (protocol = TCMPortMappingTransportProtocolUDP; protocol <= TCMPortMappingTransportProtocolTCP; protocol++) {
            if ([aPortMapping transportProtocol] & protocol) {
                int r = 0;
                do {
                    while ([aExternalPortSet containsIndex:mappedPort] && mappedPort<[aPortMapping desiredExternalPort]+40) {
                        mappedPort++;
                    }
                    r = UPNP_AddPortMapping(aURLs->controlURL, aIGDData->servicetype,[[NSString stringWithFormat:@"%d",mappedPort] UTF8String],[[NSString stringWithFormat:@"%d",[aPortMapping localPort]] UTF8String], [[[TCMPortMapper sharedInstance] localIPAddress] UTF8String], [[self portMappingDescription] UTF8String], protocol==TCMPortMappingTransportProtocolUDP?"UDP":"TCP");
                    if (r!=UPNPCOMMAND_SUCCESS) {
                        NSString *errorString = [NSString stringWithFormat:@"%d",r];
                        switch (r) {
                            case 718: 
                                errorString = [errorString stringByAppendingString:@": ConflictInMappingEntry"];
#ifdef DEBUG
                                NSLog(@"%s mapping of external port %d failed, trying %d next",__FUNCTION__,mappedPort,mappedPort+1);
#endif
                                if (protocol == TCMPortMappingTransportProtocolTCP && ([aPortMapping transportProtocol] & TCMPortMappingTransportProtocolUDP)) {
                                    UPNP_DeletePortMapping(aURLs->controlURL, aIGDData->servicetype,[[NSString stringWithFormat:@"%d",mappedPort] UTF8String], "UDP");
                                    protocol = TCMPortMappingTransportProtocolUDP;
                                }
                                mappedPort++;
                                break;
                            case 724: errorString = [errorString stringByAppendingString:@": SamePortValuesRequired"]; break;
                            case 725: errorString = [errorString stringByAppendingString:@": OnlyPermanentLeasesSupported"]; break;
                            case 727: errorString = [errorString stringByAppendingString:@": ExternalPortOnlySupportsWildcard"]; break;
                        }
                        if (r!=718) NSLog(@"%s error occured while mapping: %@",__FUNCTION__, errorString);
                    }
                } while (r!=UPNPCOMMAND_SUCCESS && r==718 && mappedPort<=[aPortMapping desiredExternalPort]+40);
                              
                if (r!=UPNPCOMMAND_SUCCESS) {
                   didFail = YES;
                   [aPortMapping setMappingStatus:TCMPortMappingStatusUnmapped];
                } else {
#ifndef DEBUG
#ifndef NDEBUG
                    NSLog(@"UPnP: mapped local %@ port %d to external port %d",protocol==TCMPortMappingTransportProtocolUDP?@"UDP":@"TCP",[aPortMapping localPort],mappedPort);
#endif
#endif
#ifdef DEBUG
                    NSLog(@"%s mapping successful: %@ - %d %@",__FUNCTION__,aPortMapping,mappedPort,protocol==TCMPortMappingTransportProtocolUDP?@"UDP":@"TCP");
#endif
                   [aPortMapping setExternalPort:mappedPort];
                   [aPortMapping setMappingStatus:TCMPortMappingStatusMapped];
                }
            }
        }
    }
    return !didFail;
}

- (void)updatePortMappingsInThread {
    [_threadIsRunningLock lock];
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMUPNPPortMapperDidBeginWorkingNotification object:self];
    BOOL didFail=NO;
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    NSMutableSet *mappingsSet = [pm removeMappingQueue];
    NSSet *mappingsToAdd = [pm portMappings];
    // we need to safeguard mappings that others might have made 
    // (upnp is quite generous in giving us what we want, even if 
    //  other mappings are there, especially when from the same local IP)
    NSMutableIndexSet *reservedPortNumbers = [[NSMutableIndexSet new] autorelease];
    // get port mapping list as reference first
    NSMutableArray *latestUPNPPortMappingsList = [NSMutableArray array];
{
    int r;
    int i = 0;
    char index[6];
    char intClient[16];
    char intPort[6];
    char extPort[6];
    char protocol[4];
    char desc[80];
    char enabled[6];
    char rHost[64];
    char duration[16];
    /*unsigned int num=0;
    UPNP_GetPortMappingNumberOfEntries(urls->controlURL, data->servicetype, &num);
    printf("PortMappingNumberOfEntries : %u\n", num);*/
    do {
        snprintf(index, 6, "%d", i);
        rHost[0] = '\0'; enabled[0] = '\0';
        duration[0] = '\0'; desc[0] = '\0';
        extPort[0] = '\0'; intPort[0] = '\0'; intClient[0] = '\0';
        r = UPNP_GetGenericPortMappingEntry(_urls.controlURL, _igddata.servicetype,
                                       index,
                                       extPort, intClient, intPort,
                                       protocol, desc, enabled,
                                       rHost, duration);
        if(r==UPNPCOMMAND_SUCCESS) {
#ifndef NDEBUG
            NSLog(@"UPnP: %2d %s %5s->%s:%-5s '%s' '%s'",
                   i, protocol, extPort, intClient, intPort,
                   desc, rHost);
#endif
            NSString *ipAddress = [NSString stringWithUTF8String:intClient];
            NSString *portMappingDescription = [NSString stringWithUTF8String:desc];
            int localPort = atoi(intPort);
            int publicPort = atoi(extPort);
            [latestUPNPPortMappingsList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    ipAddress,@"ipAddress",
                    [NSNumber numberWithInt:localPort],@"localPort",
                    [NSNumber numberWithInt:publicPort],@"publicPort",
                    [NSString stringWithUTF8String:protocol],@"protocol",
                    portMappingDescription,@"description",
                nil]
            ];
            if ([portMappingDescription isEqualToString:[self portMappingDescription]] && 
                [ipAddress isEqualToString:[pm localIPAddress]]) {
                NSString *transportProtocol = [NSString stringWithUTF8String:protocol];
                // check if we want this mapping, if not remove it, if yes set mapping status
                BOOL isWanted = NO;
                @synchronized (mappingsToAdd) {
                    NSEnumerator *mappings = [mappingsToAdd objectEnumerator];
                    TCMPortMapping *mapping = nil;
                    while ((mapping = [mappings nextObject])) {
                        if ([mapping localPort]==localPort && 
                            ([mapping transportProtocol] & ([transportProtocol isEqualToString:@"UDP"]?TCMPortMappingTransportProtocolUDP:TCMPortMappingTransportProtocolTCP))
                            ) {
                            isWanted = YES;
                            [mapping setExternalPort:publicPort];
                            if ([mapping mappingStatus]!=TCMPortMappingStatusMapped &&
                                [mapping transportProtocol]!=TCMPortMappingTransportProtocolBoth) {
                                [mapping setMappingStatus:TCMPortMappingStatusMapped];
                            }
                            [reservedPortNumbers addIndex:publicPort];
                            break;
                        }
                    }
                }
                if (!isWanted) {
                     r=UPNP_DeletePortMapping(_urls.controlURL, _igddata.servicetype,extPort,protocol);
                     if (r==UPNPCOMMAND_SUCCESS) i--;
                }
            } else {
                // the portmapping is from someone else - so respect it!
                [reservedPortNumbers addIndex:atoi(extPort)];
            }
        }
        
        i++;
    } while(r==UPNPCOMMAND_SUCCESS && 
            !UpdatePortMappingsThreadShouldQuit && 
            !UpdatePortMappingsThreadShouldRestart);
    [self setLatestUPNPPortMappingsList:latestUPNPPortMappingsList];
}


    while (!UpdatePortMappingsThreadShouldQuit && !UpdatePortMappingsThreadShouldRestart) {
        TCMPortMapping *mappingToRemove=nil;
        
        @synchronized (mappingsSet) {
            mappingToRemove = [mappingsSet anyObject];
        }
        
        if (!mappingToRemove) break;
        
        if ([mappingToRemove mappingStatus] == TCMPortMappingStatusMapped) {
            [mappingToRemove setMappingStatus:TCMPortMappingStatusUnmapped];
            // the actual unmapping took place above already
        }
        
        @synchronized (mappingsSet) {
            [mappingsSet removeObject:mappingToRemove];
        }
        
    }    

    // in this section we can also remove port mappings from others - this is mainly for Port Map.app to clean up stale mappings from other apps
    NSMutableSet *upnpRemoveSet = [pm _upnpPortMappingsToRemove];
    
    while (!UpdatePortMappingsThreadShouldQuit && !UpdatePortMappingsThreadShouldRestart) {
        NSDictionary *mappingToRemove=nil;
        
        @synchronized (upnpRemoveSet) {
            mappingToRemove = [upnpRemoveSet anyObject];
        }
        
        if (!mappingToRemove) break;
        
        char *publicPort = (char *)[[NSString stringWithFormat:@"%d",[[mappingToRemove objectForKey:@"publicPort"] intValue]] UTF8String];
        char *protocol = (char *)[[mappingToRemove objectForKey:@"protocol"] UTF8String];
        UPNP_DeletePortMapping(_urls.controlURL,_igddata.servicetype,publicPort,protocol);
        
        @synchronized (upnpRemoveSet) {
            [upnpRemoveSet removeObject:mappingToRemove];
        }
        
    }    

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
        
        if (![self applyPortMapping:mappingToApply remove:[pm isRunning]?NO:YES UPNPURLs:&_urls IGDDatas:&_igddata reservedExternalPortNumbers:reservedPortNumbers]) {
            didFail = YES;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMUPNPPortMapperDidFailNotification object:self]];
            break;
        };
    }

    [_threadIsRunningLock unlock];
    if (UpdatePortMappingsThreadShouldQuit) {
        [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:YES];
    } else if (UpdatePortMappingsThreadShouldRestart) {
        [self performSelectorOnMainThread:@selector(updatePortMappings) withObject:nil waitUntilDone:YES];
    }
    
    // this tiny delay should take account of the cases where we restart the loop (e.g. removing a port mapping and then stopping the portmapper)
    [self performSelectorOnMainThread:@selector(postDelayedDidEndWorkingNotification) withObject:nil waitUntilDone:NO];

    [pool release];
}

- (void)stop {
    [self updatePortMappings];
}

- (void)stopBlocking {
    refreshThreadShouldQuit=YES;
    UpdatePortMappingsThreadShouldQuit = YES;
    [_threadIsRunningLock lock];
    NSSet *mappingsToStop = [[TCMPortMapper sharedInstance] portMappings];
    @synchronized (mappingsToStop) {
        NSEnumerator *mappings = [mappingsToStop objectEnumerator];
        TCMPortMapping *mapping = nil;
        while ((mapping = [mappings nextObject])) {
            if ([mapping mappingStatus] == TCMPortMappingStatusMapped) {
                UPNP_DeletePortMapping(_urls.controlURL, _igddata.servicetype, 
                                       [[NSString stringWithFormat:@"%d",[mapping externalPort]] UTF8String], 
                                       ([mapping transportProtocol]==TCMPortMappingTransportProtocolUDP)?"UDP":"TCP");
                [mapping setMappingStatus:TCMPortMappingStatusUnmapped];
            }
        }
    }
    [_threadIsRunningLock unlock];
}


@end
