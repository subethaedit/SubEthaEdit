//
//  AppController.m
//  CursorTest
//
//  Created by Dominik Wagner on 31.07.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"


@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[O_textView enclosingScrollView] setDocumentCursor:[NSCursor invertedIBeamCursor]];
    [O_scrollView setDocumentCursor:[NSCursor invertedIBeamCursor]];
    [O_textView addCursorRect:NSMakeRect(0,0,100,100) cursor:[NSCursor invertedIBeamCursor]];
    [O_textView setInsertionPointColor:[NSColor whiteColor]];
}

@end
