//
//  TCMIdleTimer.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.11.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>


@interface TCMIdleTimer : NSObject {
    EventLoopTimerRef I_timerRef;
    id   I_delegate;
    BOOL I_isIdling;
}

- (id)initWithBeginInterval:(NSTimeInterval)aBeginInterval repeatInterval:(NSTimeInterval)aRepeatInterval;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (BOOL)isIdling;

@end

@interface NSObject (TCMIdleTimerDelegation) 

- (void)idleTimerDidFire:(id)aSender;
- (void)idleTimerDidRepeat:(id)aSender;
- (void)idleTimerDidStop:(id)aSender;

@end
