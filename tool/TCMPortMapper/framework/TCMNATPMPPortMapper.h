//
//  TCMNATPMPPortMapper.h
//  Encapsulates libnatpmp, listens for router changes
//
//  Copyright (c) 2007-2008 TheCodingMonkeys: 
//  Martin Pittenauer, Dominik Wagner, <http://codingmonkeys.de>
//  Some rights reserved: <http://opensource.org/licenses/mit-license.php> 
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
    int IPAddressThreadShouldQuitAndRestart;
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
