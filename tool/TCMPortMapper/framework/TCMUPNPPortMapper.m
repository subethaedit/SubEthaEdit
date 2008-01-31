//
//  TCMUPNPPortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMUPNPPortMapper.h"
#include "miniwget.h"
#include "miniupnpc.h"
#include "upnpcommands.h"
#include "upnperrors.h"


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

- (void)refresh {
    if ([_threadIsRunningLock tryLock]) {
        refreshThreadShouldQuit=NO;
        [NSThread detachNewThreadSelector:@selector(refreshInThread) toTarget:self withObject:nil];
        NSLog(@"%s detachedThread",__FUNCTION__);
    } else {
        refreshThreadShouldQuit = YES;
    }
}

- (void)refreshInThread {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	struct UPNPDev * devlist = 0;
	const char * multicastif = 0;
	const char * minissdpdpath = 0;
	char lanaddr[16];	/* my ip address on the LAN */
	char externalIPAddress[16];
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
		}
		if (UPNP_GetValidIGD(devlist, &urls, &data, lanaddr, sizeof(lanaddr))) {
            int r = UPNP_GetExternalIPAddress(urls.controlURL,
                                      data.servicetype,
                                      externalIPAddress);
            if(r != UPNPCOMMAND_SUCCESS) {
                NSLog(@"GetExternalIPAddress() returned %d\n", r);
            }
            if(externalIPAddress[0]) {
                NSLog(@"ExternalIPAddress = %s\n", externalIPAddress);
            } else {
                NSLog(@"GetExternalIPAddress failed.\n");
            }
		}
		freeUPNPDevlist(devlist); devlist = 0;
	} else {
		NSLog(@"No IGD UPnP Device found on the network !");
	}
	[_threadIsRunningLock performSelectorOnMainThread:@selector(unlock) withObject:nil waitUntilDone:NO];
    [pool release];
}

@end
