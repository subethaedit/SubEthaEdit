//
//  TCMNATPMPPortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 15.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMNATPMPPortMapper.h"
#import "NSNotificationAdditions.h"

NSString * const TCMNATPMPPortMapperDidFailNotification = @"TCMNATPMPPortMapperDidFailNotification";
NSString * const TCMNATPMPPortMapperDidGetExternalIPAddressNotification = @"TCMNATPMPPortMapperDidGetExternalIPAddressNotification";

static TCMNATPMPPortMapper *S_sharedInstance;

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
    }
    return self;
}

- (void)dealloc {
    [natPMPThreadIsRunningLock release];
    [super dealloc];
}

- (void)refresh {
    // Run externalipAddress in Thread
    
    if ([natPMPThreadIsRunningLock tryLock]) {
        [natPMPThreadIsRunningLock unlock];
        IPAddressThreadShouldQuit=NO;
        [NSThread detachNewThreadSelector:@selector(refreshInThread) toTarget:self withObject:nil];
        NSLog(@"%s detachedThread",__FUNCTION__);
    } else  {
        IPAddressThreadShouldQuit=YES;
        NSLog(@"%s thread should quit",__FUNCTION__);
    }

}

- (void)refreshInThread {
    [natPMPThreadIsRunningLock lock];
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	natpmp_t natpmp;
	natpmpresp_t response;
	int r;
	struct timeval timeout;
	fd_set fds;
	
	r = initnatpmp(&natpmp);
	if(r<0) {
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidFailNotification object:self]];
	} else {
        r = sendpublicaddressrequest(&natpmp);
        if(r<0) {
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidFailNotification object:self]];
        } else {
            
            do {
                if (IPAddressThreadShouldQuit) {
                    NSLog(@"%s thread quit prematurely",__FUNCTION__);
                    [natPMPThreadIsRunningLock unlock];
                    [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:0];
                    closenatpmp(&natpmp);
                    [pool release];
                    return;
                }
                FD_ZERO(&fds);
                FD_SET(natpmp.s, &fds);
                getnatpmprequesttimeout(&natpmp, &timeout);
                select(FD_SETSIZE, &fds, NULL, NULL, &timeout);
                r = readnatpmpresponseorretry(&natpmp, &response);
                NSLog(@"%s:%d",__PRETTY_FUNCTION__,__LINE__);
            } while(r==NATPMP_TRYAGAIN);
        
            if(r<0) {
               [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidFailNotification object:self]];
               NSLog(@"natpmp did time out");
            } else {
                /* TODO : check that response.type == 0 */
            
                NSString *ipString = [NSString stringWithFormat:@"%s", inet_ntoa(response.publicaddress.addr)];
                NSLog(@"%s found ipString:%@",__FUNCTION__,ipString);
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThread:[NSNotification notificationWithName:TCMNATPMPPortMapperDidGetExternalIPAddressNotification object:self]];
            }
        }
    }
	closenatpmp(&natpmp);
    [natPMPThreadIsRunningLock unlock];
    if (IPAddressThreadShouldQuit) {
        NSLog(@"%s thread quit prematurely",__FUNCTION__);
        [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:0];
    }
    [pool release];
}

- (void) mapPublicPort:(uint16_t)aPublicPort toPrivatePort:(uint16_t)aPrivatePort withLifetime:(uint32_t)aLifetime {
#warning replace commented ifs with breaks and NSErrors.
	natpmp_t natpmp;
	natpmpresp_t response;
	int r;
	//int sav_errno;
	struct timeval timeout;
	fd_set fds;
	
	r = initnatpmp(&natpmp);
	//	if(r<0) return 1;
		
	/* TODO : check that response.type == 0 */
	
	r = sendnewportmappingrequest(&natpmp, NATPMP_PROTOCOL_TCP, aPrivatePort, aPublicPort, aLifetime);
	
	//if(r < 0) return 1;
	
	do {
		FD_ZERO(&fds);
		FD_SET(natpmp.s, &fds);
		getnatpmprequesttimeout(&natpmp, &timeout);
		select(FD_SETSIZE, &fds, NULL, NULL, &timeout);
		r = readnatpmpresponseorretry(&natpmp, &response);
	} while(r==NATPMP_TRYAGAIN);
	
	//if(r<0) return 1;
	
	/* TODO : check response.type ! */
	printf("Mapped public port %hu to localport %hu liftime %u\n", response.newportmapping.mappedpublicport, response.newportmapping.privateport, response.newportmapping.lifetime);
	//printf("epoch = %u\n", response.epoch);
	
	r = closenatpmp(&natpmp);
	//	if(r<0) return 1;	
}

@end
