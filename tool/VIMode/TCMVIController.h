//
//  TCMVIController.h
//  VIMode
//
//  Created by Martin Pittenauer on 25.04.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMVIBezelWindow.h"
#import "TCMVIBezelView.h"


@interface TCMVIController : NSObject {
    NSTextView* I_textView;
    BOOL I_commandMode;
    NSMutableString *I_command;
    TCMVIBezelWindow *I_window;
    TCMVIBezelView *I_view;
}

- (id) initWithTextView:(NSTextView *) aTextView;
- (void) keyDown:(NSEvent *) event;
- (void) toggleMode;

@end
