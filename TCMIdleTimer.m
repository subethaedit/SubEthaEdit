//
//  TCMIdleTimer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.11.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMIdleTimer.h"
#import <Carbon/Carbon.h>

static void IdleTimerProc(EventLoopTimerRef aTimer,EventLoopIdleTimerMessage aMessage, void *anIdleTimer);

static EventLoopIdleTimerUPP S_timerUPP = NULL;

@implementation TCMIdleTimer
+ (void)initialize {
        S_timerUPP = NewEventLoopIdleTimerUPP(IdleTimerProc);
}

- (id)initWithBeginInterval:(NSTimeInterval)aBeginInterval repeatInterval:(NSTimeInterval)aRepeatInterval {
    self = [super init];
    if (self) {
        I_isIdling=NO;
        if( InstallEventLoopIdleTimer( GetCurrentEventLoop(),
                                    kEventDurationSecond * aBeginInterval,
                                    kEventDurationSecond * aRepeatInterval,
                                    S_timerUPP,
                                    self, &I_timerRef) != noErr ) {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)setDelegate:(id)aDelegate {
    I_delegate=aDelegate;
}

- (id)delegate {
    return I_delegate;
}

- (BOOL)isIdling {
    return I_isIdling;
}

- (void)setIsIdling:(BOOL)aFlag {
    I_isIdling=aFlag;
}

-(void)dealloc {
    RemoveEventLoopTimer(I_timerRef);
    [super dealloc];
}

@end

@interface TCMIdleTimer (PrivateAdditions)
-(void)setIsIdling:(BOOL)aFlag;
@end

static void IdleTimerProc(EventLoopTimerRef aTimer,EventLoopIdleTimerMessage aMessage, void *anIdleTimer)
{
    TCMIdleTimer *timer=(TCMIdleTimer *)anIdleTimer;
    id delegate=[timer delegate];
    switch(aMessage)
    {
        case kEventLoopIdleTimerStarted:
            [timer setIsIdling:YES];
            if ([delegate respondsToSelector:@selector(idleTimerDidFire:)])
                [delegate idleTimerDidFire:timer];
            break;
        
        case kEventLoopIdleTimerIdling:
            [timer setIsIdling:YES];
            if ([delegate respondsToSelector:@selector(idleTimerDidRepeat:)])
                [delegate idleTimerDidRepeat:timer];
            break;
    
        case kEventLoopIdleTimerStopped:
            [timer setIsIdling:NO];
            if ([delegate respondsToSelector:@selector(idleTimerDidStop:)])
                [delegate idleTimerDidStop:timer];
            break;
    }
}
