//
//  PortMapper.m
//  PortMapper
//
//  Created by Martin Pittenauer on 30.11.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PortMapper.h"

@implementation PortMapper

+ (PortMapper *)sharedInstance {
    static PortMapper *sharedInstance=nil;
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        i_fdlimit = tr_fdInit();
        i_natpmp = tr_natpmpInit(i_fdlimit);
        i_upnp = tr_upnpInit(i_fdlimit);
    }
    return self;
}

- (int) status {
    int statuses[] = {
        TR_NAT_TRAVERSAL_MAPPED,
        TR_NAT_TRAVERSAL_MAPPING,
        TR_NAT_TRAVERSAL_UNMAPPING,
        TR_NAT_TRAVERSAL_ERROR,
        TR_NAT_TRAVERSAL_NOTFOUND,
        TR_NAT_TRAVERSAL_DISABLED,
        -1,
    };
    int natpmp, upnp, ii;

    natpmp = tr_natpmpStatus(i_natpmp);
    upnp = tr_upnpStatus(i_upnp);

    for( ii = 0; 0 <= statuses[ii]; ii++ )
    {
        if( statuses[ii] == natpmp || statuses[ii] == upnp )
        {
            return statuses[ii];
        }
    }

    return TR_NAT_TRAVERSAL_ERROR;

}

- (void) pulse {
    tr_natpmpPulse(i_natpmp);
    tr_upnpPulse(i_upnp);
    [self performSelector:@selector(pulse) withObject:nil afterDelay:0.5];
}

- (void) mapPort:(int)port {
    
    NSLog(@"Setting up stuff");

    tr_natpmpForwardPort(i_natpmp, port);
    tr_upnpForwardPort(i_upnp, port);
    
    NSLog(@"Forwarding Ports");

    tr_natpmpStart(i_natpmp);
    tr_upnpStart(i_upnp);
    
//    NSLog(@"Status: %d",[self status]);
    [self pulse];
}

@end
