//
//  TCMUPNPPortMapper.h
//  PortMapper
//
//  Created by Martin Pittenauer on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "TCMPortMapper.h"

@interface TCMUPNPPortMapper : NSObject {
    NSLock *_threadIsRunningLock;
    BOOL refreshThreadShouldQuit;
}


- (void)refresh;
- (void)stop;

@end
