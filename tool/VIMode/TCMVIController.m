//
//  TCMVIController.m
//  VIMode
//
//  Created by Martin Pittenauer on 25.04.05.
//  Copyright 2005 TheCodingMonkeys. All rights reserved.
//

#import "TCMVIController.h"
#import "VIMTextView.h"

#define RETURN_KEY 13
#define ENTER_KEY 3
#define BACKSPACE_KEY 127
#define ESCAPE_KEY 27
#define H_KEY 104
#define J_KEY 106
#define K_KEY 107
#define L_KEY 108

@implementation TCMVIController

- (id)initWithTextView:(NSTextView *) aTextView {
    self = [super init];
    if (self) {
        I_textView = aTextView;
        I_commandMode = NO;
        NSRect screen = [[NSScreen mainScreen] visibleFrame];
        NSSize window = NSMakeSize(500,110);
        I_window = [[TCMVIBezelWindow alloc] initWithContentRect:NSMakeRect(screen.origin.x+screen.size.width/2-window.width/2,screen.origin.y+screen.size.height/2-window.height/2,window.width,window.height) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        I_view = [TCMVIBezelView new];
        [I_window setContentView:I_view];
        I_command = [NSMutableString new];
    }

    return self;
}

- (NSEvent *) transposeKeyEvent:(NSEvent *)event toCharacters:(unichar)newCharacter {
    return [NSEvent keyEventWithType:[event type] location:[event locationInWindow] modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] characters:[NSString stringWithCharacters:&newCharacter length:1] charactersIgnoringModifiers:[NSString stringWithCharacters:&newCharacter length:1] isARepeat:NO keyCode:newCharacter];
}

- (void) keyDown:(NSEvent *) event {

    unichar c = [[event characters] characterAtIndex:0];
    NSLog(@"%d",c);
    int commandLength = [I_command length];

    if (I_commandMode) {
        // Emtpy command string -> Instant commands (scrolling etc.) go here
        if (commandLength==0)
        switch (c) {
            case H_KEY:
                event = [self transposeKeyEvent:event toCharacters:NSLeftArrowFunctionKey];
                [(VIMTextView *)I_textView superKeyDown:event];
                break;
            case J_KEY:
                event = [self transposeKeyEvent:event toCharacters:NSDownArrowFunctionKey];
                [(VIMTextView *)I_textView superKeyDown:event];
                break;
            case K_KEY:
                event = [self transposeKeyEvent:event toCharacters:NSUpArrowFunctionKey];
                [(VIMTextView *)I_textView superKeyDown:event];
                break;
            case L_KEY:
                event = [self transposeKeyEvent:event toCharacters:NSRightArrowFunctionKey];
                [(VIMTextView *)I_textView superKeyDown:event];
                break;
            case RETURN_KEY:
            case ENTER_KEY:
            case BACKSPACE_KEY:
                NSBeep();
                break;
            default:
                [I_command appendString:[NSString stringWithCharacters:&c length:1]];
                [I_window orderFront:self];
        } 
        else
        // Commandstring not empty -> aggregated command like "dd" or "5k"
        switch (c) {
            case BACKSPACE_KEY:
                if (commandLength==1) [I_window orderOut:self];
                if (commandLength>0)
                [I_command deleteCharactersInRange:NSMakeRange(commandLength-1,1)]; else NSBeep();
                break;
            case RETURN_KEY:
            case ENTER_KEY:
                [I_window orderOut:self];
                // ... execute Command or NSBEEP. Delete illegal command or not?
                [I_command deleteCharactersInRange:NSMakeRange(0,commandLength)];
                break;
            default:
                [I_command appendString:[NSString stringWithCharacters:&c length:1]];
        }
    } else { // Not in Command Mode.
        [(VIMTextView *)I_textView superKeyDown:event];
    }
    
    [I_view showCommand:I_command withDescription:@"does something"];
}

- (void) toggleMode {
    I_commandMode = !I_commandMode;
    NSLog(I_commandMode?@"CommandMode enabled":@"CommandMode disabled");
}

@end
