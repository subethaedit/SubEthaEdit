//
//  TCMAnimatingWindow.h
//  VIMode
//
//  Created by Martin Pittenauer on 25.04.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCMAnimatingWindow : NSWindow {
    NSTimer *I_timer;
    float I_progress;
}


@end
