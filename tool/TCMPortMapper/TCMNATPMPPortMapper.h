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


@interface TCMNATPMPPortMapper : NSObject {
    NSLock *natPMPThreadIsRunningLock;
    BOOL IPAddressThreadShouldQuit;
}

- (void)refresh;
	
@end
