//
//  TCMUPNPPortMapper.h
//  PortMapper
//
//  Created by Martin Pittenauer on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortMapper.h"
#import "TCMNATPMPPortMapper.h"
#include "miniwget.h"
#include "miniupnpc.h"
#include "upnpcommands.h"
#include "upnperrors.h"

extern NSString * const TCMUPNPPortMapperDidFailNotification;
extern NSString * const TCMUPNPPortMapperDidGetExternalIPAddressNotification;


@interface TCMUPNPPortMapper : NSObject {
    NSLock *_threadIsRunningLock;
    BOOL refreshThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldRestart;
    NSString *_internalIPAddress;
    TCMPortMappingThreadID runningThreadID;
    struct UPNPUrls _urls;
    struct IGDdatas _igddata;
}

- (void)setInternalIPAddress:(NSString *)anIPAddressString;

- (void)refresh;
- (void)updatePortMappings;
- (void)stop;

@end
