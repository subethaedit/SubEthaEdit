//
//  TCMUPNPPortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMUPNPPortMapper.h"
#import "NSNotificationAdditions.h"
#include "miniwget.h"
#include "miniupnpc.h"
#include "upnpcommands.h"
#include "upnperrors.h"

NSString * const TCMUPNPPortMapperDidFailNotification = @"TCMNATPMPPortMapperDidFailNotification";
NSString * const TCMUPNPPortMapperDidGetExternalIPAddressNotification = @"TCMNATPMPPortMapperDidGetExternalIPAddressNotification";

@implementation TCMUPNPPortMapper

- (id)init {
    if ((self=[super init])) {
        _threadIsRunningLock = [NSLock new];
    }
    return self;
}

- (void)dealloc {
    [_threadIsRunningLock release];
    [super dealloc];
}

- (void)setInternalIPAddress:(NSString *)anIPAddressString {
    if (_internalIPAddress != anIPAddressString) {
        NSString *tmp = _internalIPAddress;
        _internalIPAddress = [anIPAddressString copy];
        [tmp release];
    }
}

- (void)refresh {
    if ([_threadIsRunningLock tryLock]) {
        refreshThreadShouldQuit=NO;
        runningThreadID = TCMExternalIPThreadID;
        [NSThread detachNewThreadSelector:@selector(refreshInThread) toTarget:self withObject:nil];
        NSLog(@"%s detachedThread",__FUNCTION__);
    } else {
        if (runningThreadID == TCMExternalIPThreadID) {
            refreshThreadShouldQuit=YES;
            NSLog(@"%s thread should quit",__FUNCTION__);
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

- (void)refreshInThread {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	struct UPNPDev * devlist = 0;
	const char * multicastif = 0;
	const char * minissdpdpath = 0;
	char lanaddr[16];	/* my ip address on the LAN */
	char externalIPAddress[16];
	BOOL didFail=NO;
	NSString *errorString = nil;
    if (( devlist = upnpDiscover(2000, multicastif, minissdpdpath) )) {
		struct UPNPDev * device;
		struct UPNPUrls urls;
		struct IGDdatas data;
		if(devlist) {
			NSLog(@"List of UPNP devices found on the network :\n");
			for(device = devlist; device; device = device->pNext) {
				NSLog(@" desc: %s\n st: %s\n\n",
					   device->descURL, device->st);
			}
            if (UPNP_GetValidIGD(devlist, &urls, &data, lanaddr, sizeof(lanaddr))) {
                int r = UPNP_GetExternalIPAddress(urls.controlURL,
                                          data.servicetype,
                                          externalIPAddress);
                if(r != UPNPCOMMAND_SUCCESS) {
                    didFail = YES;
                    errorString = [NSString stringWithFormat:@"GetExternalIPAddress() returned %d", r];
                } else {
                    if(externalIPAddress[0]) {
                        NSLog(@"cureltname: %s" ,data.cureltname);
                        NSLog(@"servicetype: %s",data.servicetype);
                        NSLog(@"devicetype: %s" ,data.devicetype);
                        NSLog(@"ExternalIPAddress = %s\n", externalIPAddress);
                        NSString *ipString = [NSString stringWithUTF8String:externalIPAddress];
                        [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMUPNPPortMapperDidGetExternalIPAddressNotification object:self userInfo:[NSDictionary dictionaryWithObject:ipString forKey:@"externalIPAddress"]]];
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
	[_threadIsRunningLock performSelectorOnMainThread:@selector(unlock) withObject:nil waitUntilDone:NO];
    if (refreshThreadShouldQuit) {
        NSLog(@"%s thread quit prematurely",__FUNCTION__);
        [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:0];
    } else {
        if (didFail) {
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMUPNPPortMapperDidFailNotification object:self]];
        } else {
            [self performSelectorOnMainThread:@selector(updatePortMappings) withObject:nil waitUntilDone:0];
        }
    }
    [pool release];
}

- (void)updatePortMappings {
    if ([_threadIsRunningLock tryLock]) {
        UpdatePortMappingsThreadShouldRestart=NO;
        runningThreadID = TCMUpdatingMappingThreadID;
        [NSThread detachNewThreadSelector:@selector(updatePortMappingsInThread) toTarget:self withObject:nil];
        NSLog(@"%s detachedThread",__FUNCTION__);
    } else  {
        if (runningThreadID == TCMUpdatingMappingThreadID) {
            UpdatePortMappingsThreadShouldRestart = YES;
        }
    }
}

- (BOOL)applyPortMapping:(TCMPortMapping *)aPortMapping remove:(BOOL)shouldRemove UPNPURLs:(struct UPNPUrls *)aURLs IGDDatas:(struct IGDdatas *)aIGDData{
    BOOL didFail = NO;
    [aPortMapping setMappingStatus:TCMPortMappingStatusTrying];
    if (shouldRemove) {
        UPNP_DeletePortMapping(aURLs->controlURL, aIGDData->servicetype,[[NSString stringWithFormat:@"%d",[aPortMapping publicPort]] UTF8String], "TCP");
        [aPortMapping setMappingStatus:TCMPortMappingStatusUnmapped];
        return YES;
    } else {
        int mappedPort = [aPortMapping desiredPublicPort];
        int r = UPNP_AddPortMapping(aURLs->controlURL, aIGDData->servicetype,[[NSString stringWithFormat:@"%d",mappedPort] UTF8String],[[NSString stringWithFormat:@"%d",[aPortMapping privatePort]] UTF8String], [_internalIPAddress UTF8String], [[self portMappingDescription] UTF8String], "TCP");
    	if (r!=UPNPCOMMAND_SUCCESS) {
            NSString *errorString = [NSString stringWithFormat:@"%d",r];
            switch (r) {
                case 718: errorString = [errorString stringByAppendingString:@": ConflictInMappingEntry"]; break;
                case 724: errorString = [errorString stringByAppendingString:@": SamePortValuesRequired"]; break;
                case 725: errorString = [errorString stringByAppendingString:@": OnlyPermanentLeasesSupported"]; break;
                case 727: errorString = [errorString stringByAppendingString:@": ExternalPortOnlySupportsWildcard"]; break;
            }
            NSLog(@"%s error occured while mapping: %@",__FUNCTION__, errorString);
    	}
    	
    	if (r!=UPNPCOMMAND_SUCCESS) {
    	   didFail = YES;
    	   [aPortMapping setMappingStatus:TCMPortMappingStatusUnmapped];
    	} else {
    	   [aPortMapping setPublicPort:mappedPort];
    	   [aPortMapping setMappingStatus:TCMPortMappingStatusMapped];
    	}
    }
    return !didFail;
}

- (void)updatePortMappingsInThread {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	struct UPNPDev * devlist = 0;
	const char * multicastif = 0;
	const char * minissdpdpath = 0;
	char lanaddr[16];	/* my ip address on the LAN */
	BOOL didFail=NO;
    if (( devlist = upnpDiscover(2000, multicastif, minissdpdpath) )) {
		struct UPNPUrls urls;
		struct IGDdatas data;
		if (devlist) {
            if (UPNP_GetValidIGD(devlist, &urls, &data, lanaddr, sizeof(lanaddr))) {
                TCMPortMapper *pm=[TCMPortMapper sharedInstance];
                NSMutableSet *mappingsSet = [pm removeMappingQueue];
    
                while (!UpdatePortMappingsThreadShouldQuit && !UpdatePortMappingsThreadShouldRestart) {
                    TCMPortMapping *mappingToRemove=nil;
                    
                    @synchronized (mappingsSet) {
                        mappingToRemove = [mappingsSet anyObject];
                    }
                    
                    if (!mappingToRemove) break;
                    
                    if ([mappingToRemove mappingStatus] == TCMPortMappingStatusMapped) {
                        [self applyPortMapping:mappingToRemove remove:YES UPNPURLs:&urls IGDDatas:&data];
                    }
                    
                    @synchronized (mappingsSet) {
                        [mappingsSet removeObject:mappingToRemove];
                    }
                    
                }    
            
                NSSet *mappingsToAdd = [pm portMappings];
                
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
                    
                    if (![self applyPortMapping:mappingToApply remove:[pm isRunning]?NO:YES UPNPURLs:&urls IGDDatas:&data]) {
                        didFail = YES;
                        [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidFailNotification object:self]];
                        break;
                    };
                }
            }
            freeUPNPDevlist(devlist); devlist = 0;
        }
    }
    [_threadIsRunningLock performSelectorOnMainThread:@selector(unlock) withObject:nil waitUntilDone:YES];
    if (UpdatePortMappingsThreadShouldQuit) {
        [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:NO];
    } else if (UpdatePortMappingsThreadShouldRestart) {
        [self performSelectorOnMainThread:@selector(updatePortMapping) withObject:nil waitUntilDone:NO];
    }
    [pool release];
}


@end
