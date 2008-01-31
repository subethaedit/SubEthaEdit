//
//  TCMNATPMPPortMapper.h
//  PortMapper
//
//  Created by Martin Pittenauer on 15.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortMapper.h"

#import "natpmp.h"

extern NSString * const TCMNATPMPPortMapperDidFailNotification;
extern NSString * const TCMNATPMPPortMapperDidGetExternalIPAddressNotification;

typedef enum {
    TCMExternalIPThreadID = 0,
    TCMUpdatingMappingThreadID = 1,
} TCMPortMappingThreadID;


@interface TCMNATPMPPortMapper : NSObject {
    NSLock *natPMPThreadIsRunningLock;
    BOOL IPAddressThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldQuit;
    BOOL UpdatePortMappingsThreadShouldRestart;
    TCMPortMappingThreadID runningThreadID;
    NSTimer *_updateTimer;
    NSTimeInterval _updateInterval;
}

- (void)refresh;
- (void)stop;
- (void)updatePortMappings;

@end
