//
//  TCMNATPMPPortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 15.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMNATPMPPortMapper.h"

static TCMNATPMPPortMapper *sharedInstance;

@implementation TCMNATPMPPortMapper
+ (TCMNATPMPPortMapper *)sharedInstance
{
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (NSString *)externalIPAddress {
	natpmp_t natpmp;
	natpmpresp_t response;
	int r;
	struct timeval timeout;
	fd_set fds;
	
	r = initnatpmp(&natpmp);
	if(r<0) return nil;
	
	r = sendpublicaddressrequest(&natpmp);
	if(r<0) return nil;
	
	do {
		FD_ZERO(&fds);
		FD_SET(natpmp.s, &fds);
		getnatpmprequesttimeout(&natpmp, &timeout);
		select(FD_SETSIZE, &fds, NULL, NULL, &timeout);
		r = readnatpmpresponseorretry(&natpmp, &response);
	} while(r==NATPMP_TRYAGAIN);

	if(r<0) return nil;
	
	/* TODO : check that response.type == 0 */
	
	NSString *ipString = [NSString stringWithFormat:@"%s", inet_ntoa(response.publicaddress.addr)];
	closenatpmp(&natpmp);
	return ipString;
}

- (void) mapPublicPort:(int)publicPort toPrivatePort:(int)privatePort withLifetime:(int)seconds {
#warning replace commented ifs with breaks and NSErrors.
	natpmp_t natpmp;
	natpmpresp_t response;
	int r;
	//int sav_errno;
	struct timeval timeout;
	fd_set fds;
	
	r = initnatpmp(&natpmp);
	//	if(r<0) return 1;
	
	r = sendpublicaddressrequest(&natpmp);
	//	if(r<0) return 1;
	
	do {
		FD_ZERO(&fds);
		FD_SET(natpmp.s, &fds);
		getnatpmprequesttimeout(&natpmp, &timeout);
		select(FD_SETSIZE, &fds, NULL, NULL, &timeout);
		r = readnatpmpresponseorretry(&natpmp, &response);
	} while(r==NATPMP_TRYAGAIN);
	
	//if(r<0) return 1;
	
	/* TODO : check that response.type == 0 */
	
	r = sendnewportmappingrequest(&natpmp, NATPMP_PROTOCOL_TCP, privatePort, publicPort,seconds);
	
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
