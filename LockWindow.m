//
//  LockWindow.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 1/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LockWindow.h"
#import "BacktracingException.h"

@implementation LockWindow
- (id)retain {
	//NSLog(@"%s rc:%d\n%@",__FUNCTION__,[self retainCount],[BacktracingException backtraceSkippingFrames:1]);
	return [super retain];
}

- (void)release {
	//NSLog(@"%s rc:%d\n%@",__FUNCTION__,[self retainCount],[BacktracingException backtraceSkippingFrames:1]);
	[super release];
}

- (id)autorelease {
	//NSLog(@"%s rc:%d\n%@",__FUNCTION__,[self retainCount],[BacktracingException backtraceSkippingFrames:1]);
	return [super autorelease];
}
@end
