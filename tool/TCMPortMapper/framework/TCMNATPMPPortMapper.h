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
extern NSString * const TCMNATPMPPortMapperDidBeginWorkingNotification;
extern NSString * const TCMNATPMPPortMapperDidEndWorkingNotification  ;
extern NSString * const TCMNATPMPPortMapperDidReceiveBroadcastedExternalIPChangeNotification;

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
    NSString *_lastExternalIPSenderAddress;
    NSString *_lastBroadcastedExternalIP;
}

- (void)refresh;
- (void)stop;
- (void)updatePortMappings;
- (void)stopBlocking;

@end
