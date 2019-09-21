//  NSOperationQueue+TCMAdditions.h
//  ZickeZacke
//
//  Created by Dominik Wagner on 01.07.13.

#import <Foundation/Foundation.h>

@interface NSOperationQueue (TCMAdditions)

/*!
 Performs aBlock on the main Thread after the given delay. Not cancellable. You can simulate cancel by checking a condition at the start of your block, and doing nothing otherwise. Uses dispatch_after directly, not using NSOperationQueue.
 @param block the block to be performed
 @param delay the delay in seconds
 */
+ (void)TCM_performBlockOnMainQueue:(dispatch_block_t)block afterDelay:(NSTimeInterval)delay;

/*!
 Ensures the execution of the block given to be on the main thread. Useful for convenience if you are in callbacks that might not be on the main thread but need to crossover. Uses dispatch_async on dispatch_get_main_queue().
 @param block the block to be performed
 @return NO if called from the main thread, and the block was executed synchronously. YES otherwise
 */
+ (BOOL)TCM_performBlockOnMainThreadIsAsynchronous:(dispatch_block_t)block;


/*!
 Ensures the execution of the block given to be on the main thread. Useful for convenience if you are in callbacks that might not be on the main thread but need to crossover. Uses dispatch_sync on dispatch_get_main_queue() if necessary. Always synchronous.
 @param block the block to be performed
 */
+ (void)TCM_performBlockOnMainThreadSynchronously:(dispatch_block_t)block;

@end
