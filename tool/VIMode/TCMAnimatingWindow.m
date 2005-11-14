//
//  TCMAnimatingWindow.m
//  VIMode
//
//  Created by Martin Pittenauer on 25.04.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "TCMAnimatingWindow.h"

#define STEP 0.01
#define DELAY 0.005

@implementation TCMAnimatingWindow

+ (float) scurveYForX:(float)x; {
    
    if (x >= 1) return 1; else if (x <= 0) return 0;
    
    return 1.0f / (1 + exp((-x*12)+6)); // magic s-curve formula courtesy of gus.
}

- (void)orderFront:(id)sender {
    [super orderFront:sender];

    if (I_timer) {
        [I_timer invalidate];
        [I_timer autorelease];
        I_timer = nil;
    }
    
    I_progress += STEP;
    [self setAlphaValue:[TCMAnimatingWindow scurveYForX:I_progress]];
    
    if (I_progress<1) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(orderFront:)]];  
        [invocation setTarget:self];  
        [invocation setSelector:@selector(orderFront:)];  
        [invocation setArgument:&sender atIndex:2];  
        I_timer = [[NSTimer scheduledTimerWithTimeInterval:DELAY invocation:invocation repeats:NO] retain];  
    } else {
        I_progress = 1;
    }
}

- (void)orderOut:(id)sender {
    if (I_timer) {
        [I_timer invalidate];
        [I_timer autorelease];
        I_timer = nil;
    }

    I_progress -= STEP;
    [self setAlphaValue:[TCMAnimatingWindow scurveYForX:I_progress]];

    if (I_progress>0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(orderOut:)]];  
        [invocation setTarget:self];  
        [invocation setSelector:@selector(orderOut:)];  
        [invocation setArgument:&sender atIndex:2];  
        I_timer = [[NSTimer scheduledTimerWithTimeInterval:DELAY invocation:invocation repeats:NO] retain];  
    } else {
        [super orderOut:sender];
        I_progress = 0;
    }
}


@end
