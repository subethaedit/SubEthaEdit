//
//  PortMapper.h
//  PortMapper
//
//  Created by Martin Pittenauer on 30.11.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "transmission.h"


@interface PortMapper : NSObject {
    tr_fd_t *i_fdlimit;
    tr_natpmp_t *i_natpmp;
    tr_upnp_t *i_upnp;
}

+ (PortMapper *)sharedInstance;

@end
