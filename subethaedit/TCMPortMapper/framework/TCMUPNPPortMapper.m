//
//  TCMUPNPPortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMUPNPPortMapper.h"
#import "NSNotificationAdditions.h"

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
    [super dealloc];
}

- (void)refresh {
    if ([_threadIsRunningLock tryLock]) {
        refreshThreadShouldQuit=NO;
        UpdatePortMappingsThreadShouldQuit = NO;
        runningThreadID = TCMExternalIPThreadID;
        [NSThread detachNewThreadSelector:@selector(refreshInThread) toTarget:self withObject:nil];
        [_threadIsRunningLock unlock];
#ifndef NDEBUG
        NSLog(@"%s detachedThread",__FUNCTION__);
#endif
    } else {
        if (runningThreadID == TCMExternalIPThreadID) {
            refreshThreadShouldQuit=YES;
#ifndef NDEBUG
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
        NSMutableArray *descriptionComponents=[NSMutableArray arrayWithObject:@"TCMPortMapper"];
        NSString *component = [[[NSBundle mainBundle] bundlePath] lastPathComponent];
        if (component) [descriptionComponents addObject:component];
        description = [[descriptionComponents componentsJoinedByString:@"-"] retain];
    }
    return description;
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
#ifndef NDEBUG
            if (YES) {// FIXME:debug switch here
                struct UPNPDev * device;
                NSLog(@"List of UPNP devices found on the network :\n");
                for(device = devlist; device; device = device->pNext) {
                    NSLog(@" desc: %s\n st: %s\n\n",
                           device->descURL, device->st);
                }
            }
#endif
            if (UPNP_GetValidIGD(devlist, &_urls, &_igddata, lanaddr, sizeof(lanaddr))) {
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
                    } else {
                        didFail = YES;
                        errorString = @"No external IP address!";
                    }
                }
            } else {
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
#ifndef NDEBUG
        NSLog(@"%s thread quit prematurely",__FUNCTION__);
#endif
        [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:0];
    } else {
        if (didFail) {
#ifndef NDEBUG
            NSLog(@"%s didFailWithError: %@",__FUNCTION__, errorString);
#endif
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMUPNPPortMapperDidFailNotification object:self]];
        } else {
            [self performSelectorOnMainThread:@selector(updatePortMappings) withObject:nil waitUntilDone:0];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMUPNPPortMapperDidEndWorkingNotification object:self];
    [pool release];
}

- (void)updatePortMappings {
    if ([_threadIsRunningLock tryLock]) {
        UpdatePortMappingsThreadShouldRestart=NO;
        runningThreadID = TCMUpdatingMappingThreadID;
        [NSThread detachNewThreadSelector:@selector(updatePortMappingsInThread) toTarget:self withObject:nil];
        [_threadIsRunningLock unlock];
#ifndef NDEBUG
        NSLog(@"%s detachedThread",__FUNCTION__);
#endif
    } else  {
        if (runningThreadID == TCMUpdatingMappingThreadID) {
            UpdatePortMappingsThreadShouldRestart = YES;
        }
    }
}

- (BOOL)applyPortMapping:(TCMPortMapping *)aPortMapping remove:(BOOL)shouldRemove UPNPURLs:(struct UPNPUrls *)aURLs IGDDatas:(struct IGDdatas *)aIGDData{
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
    } else { // if we should add it and not remove it
        int mappedPort = [aPortMapping desiredExternalPort];
        int protocol = TCMPortMappingTransportProtocolUDP;
        for (protocol = TCMPortMappingTransportProtocolUDP; protocol <= TCMPortMappingTransportProtocolTCP; protocol++) {
            if ([aPortMapping transportProtocol] & protocol) {
                int r = 0;
                do {
                    r = UPNP_AddPortMapping(aURLs->controlURL, aIGDData->servicetype,[[NSString stringWithFormat:@"%d",mappedPort] UTF8String],[[NSString stringWithFormat:@"%d",[aPortMapping localPort]] UTF8String], [[[TCMPortMapper sharedInstance] localIPAddress] UTF8String], [[self portMappingDescription] UTF8String], protocol==TCMPortMappingTransportProtocolUDP?"UDP":"TCP");
                    if (r!=UPNPCOMMAND_SUCCESS) {
                        NSString *errorString = [NSString stringWithFormat:@"%d",r];
                        switch (r) {
                            case 718: 
                                errorString = [errorString stringByAppendingString:@": ConflictInMappingEntry"];
#ifndef NDEBUG
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
                } while (r!=UPNPCOMMAND_SUCCESS && r==718 && mappedPort<=[aPortMapping desiredExternalPort]+20);
                              
                if (r!=UPNPCOMMAND_SUCCESS) {
                   didFail = YES;
                   [aPortMapping setMappingStatus:TCMPortMappingStatusUnmapped];
                } else {
#ifndef NDEBUG
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

    // get port mapping list as reference first
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
            NSLog(@"%2d %s %5s->%s:%-5s '%s' '%s'",
                   i, protocol, extPort, intClient, intPort,
                   desc, rHost);
#endif
            NSString *ipAddress = [NSString stringWithUTF8String:intClient];
            NSString *portMappingDescription = [NSString stringWithUTF8String:desc];
            if ([portMappingDescription isEqualToString:[self portMappingDescription]] && 
                [ipAddress isEqualToString:[pm localIPAddress]]) {
                int localPort = atoi(intPort);
                int publicPort = atoi(extPort);
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
                            break;
                        }
                    }
                }
                if (!isWanted) {
                     r=UPNP_DeletePortMapping(_urls.controlURL, _igddata.servicetype,extPort,protocol);
                     if (r==UPNPCOMMAND_SUCCESS) i--;
                }
            }
        }
        
        i++;
    } while(r==UPNPCOMMAND_SUCCESS && 
            !UpdatePortMappingsThreadShouldQuit && 
            !UpdatePortMappingsThreadShouldRestart);
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
        
        if (![self applyPortMapping:mappingToApply remove:[pm isRunning]?NO:YES UPNPURLs:&_urls IGDDatas:&_igddata]) {
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
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:TCMUPNPPortMapperDidEndWorkingNotification object:self];
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
