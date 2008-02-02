//
//  TCMUPNPPortMapper.h
//  PortMapper
//
//  Created by Martin Pittenauer on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortMapper.h"

extern NSString * const TCMUPNPPortMapperDidFailNotification;
extern NSString * const TCMUPNPPortMapperDidGetExternalIPAddressNotification;


@interface TCMUPNPPortMapper : NSObject {
    NSLock *_threadIsRunningLock;
    BOOL refreshThreadShouldQuit;
}


- (void)refresh;
- (void)updatePortMappings;
- (void)stop;

@end
