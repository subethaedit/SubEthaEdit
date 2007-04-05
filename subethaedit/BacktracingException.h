//
//  BacktracingException.h
//  Fez
//
//  Created by Jens Alfke on Fri Mar 14 2003.
//  Copyright (c) 2003 Apple Computer, Inc.. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import <Foundation/Foundation.h>


typedef void (*SignificantRaiseHandler) ( NSException *exception );


@interface BacktracingException : NSException
{
}

+ (void) install;	// Makes this class replace NSException, causing all raises to dump backtraces to the console.

+ (void) setSignificantRaiseHandler: (SignificantRaiseHandler)handler;

+ (void) logBacktraceWithMessage: (NSString*)message;	 // Manually log a backtrace without any exception being raised
                                                         // Will NSLog the message first if it's non-nil
+ (void) logBacktraceSkippingFrames: (int)n
                        withMessage: (NSString*)message; // Same as above, but skips the top n stack frames

+ (NSString*) backtrace;
+ (NSString*) backtraceSkippingFrames: (int)skip;

- (void) raiseWithoutReporting;			// Just like normal raise: does not call handler or fill in backtrace

- (NSString*) backtrace;			// Backtrace of the stack when I was created

@end


#endif
