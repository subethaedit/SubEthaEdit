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
extern NSString * const TCMUPNPPortMapperDidBeginWorkingNotification;
extern NSString * const TCMUPNPPortMapperDidEndWorkingNotification;

@interface TCMUPNPPortMapper : NSObject {
    NSLock *_threadIsRunningLock;
    BOOL refreshThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldRestart;
    TCMPortMappingThreadID runningThreadID;
    NSArray *_latestUPNPPortMappingsList;
    struct UPNPUrls _urls;
    struct IGDdatas _igddata;
}

- (void)refresh;
- (void)updatePortMappings;
- (void)stop;
- (void)stopBlocking;
- (NSArray *)latestUPNPPortMappingsList;

@end
