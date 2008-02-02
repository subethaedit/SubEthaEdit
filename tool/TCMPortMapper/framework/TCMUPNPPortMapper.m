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
    [pool release];
}

@end
