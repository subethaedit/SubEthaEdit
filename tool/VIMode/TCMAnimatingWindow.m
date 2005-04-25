//
//  TCMAnimatingWindow.m
//  VIMode
//
//  Created by Martin Pittenauer on 25.04.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "TCMAnimatingWindow.h"

#define STEP 0.10
#define DELAY 0.01

@implementation TCMAnimatingWindow

- (void)orderFront:(id)sender {
    [super orderFront:sender];

    if (I_timer) {
        [I_timer invalidate];
        [I_timer autorelease];
        I_timer = nil;
    }
    
    float alpha = [self alphaValue]+STEP;
    [self setAlphaValue:alpha];
    
    if (alpha<1) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(orderFront:)]];  
        [invocation setTarget:self];  
        [invocation setSelector:@selector(orderFront:)];  
        [invocation setArgument:&sender atIndex:2];  
        I_timer = [[NSTimer scheduledTimerWithTimeInterval:DELAY invocation:invocation repeats:NO] retain];  
    } 
}

- (void)orderOut:(id)sender {
    if (I_timer) {
        [I_timer invalidate];
        [I_timer autorelease];
        I_timer = nil;
    }

    float alpha = [self alphaValue]-STEP;
    [self setAlphaValue:alpha];

    if (alpha>0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(orderOut:)]];  
        [invocation setTarget:self];  
        [invocation setSelector:@selector(orderOut:)];  
        [invocation setArgument:&sender atIndex:2];  
        I_timer = [[NSTimer scheduledTimerWithTimeInterval:DELAY invocation:invocation repeats:NO] retain];  
    } else {
        [super orderOut:sender];
    }
}


@end
