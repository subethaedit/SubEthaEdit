//  NSOperationQueue+TCMAdditions.m
//  ZickeZacke
//
//  Created by Dominik Wagner on 01.07.13.

#import "NSOperationQueue+TCMAdditions.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation NSOperationQueue (TCMAdditions)

+ (void)TCM_performBlockOnMainQueue:(void (^)(void))aBlock afterDelay:(NSTimeInterval)aDelay {
	if (aDelay <= 0.0) {
		dispatch_async(dispatch_get_main_queue(), aBlock);
	} else {
		int64_t delta = (int64_t)(NSEC_PER_SEC * aDelay);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta), dispatch_get_main_queue(), aBlock);
	}
}

+ (BOOL)TCM_performBlockOnMainThreadIsAsynchronous:(dispatch_block_t)aBlock {
	if ([NSThread isMainThread]) {
		aBlock();
		return NO;
	} else {
		dispatch_async(dispatch_get_main_queue(), aBlock);
		return YES;
	}
}

@end
