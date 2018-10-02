//
//  NSOperationQueue+TCMAdditions.h
//  ZickeZacke
//
//  Created by Dominik Wagner on 01.07.13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOperationQueue (TCMAdditions)

/*!
 Performs aBlock on the main Thread after the given delay. Not cancellable. You can simulate cancel by checking a condition at the start of your block, and doing nothing otherwise. Uses dispatch_after directly, not using NSOperationQueue.
 @param aBlock the block to be performed
 @param aDelay the delay in seconds
 */
+ (void)TCM_performBlockOnMainQueue:(dispatch_block_t)aBlock afterDelay:(NSTimeInterval)aDelay;

/*!
 Ensures the execution of the aBlock given to be on the main thread. Useful for convenience if you are in callbacks that might not be on the main thread but need to crossover. Uses dispatch_async on dispatch_get_main_queue().
 @param aBlock the block to be performed
 @return NO if called from the main thread, and the block was executed synchronously. YES otherwise
 */
+ (BOOL)TCM_performBlockOnMainThreadIsAsynchronous:(dispatch_block_t)aBlock;

@end
