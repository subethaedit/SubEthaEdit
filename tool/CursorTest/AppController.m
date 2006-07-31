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
    
    [[O_textView enclosingScrollView] setDocumentCursor:[NSCursor invertedIBeamCursor]];  // doesn't help anything
    
    [O_scrollView setDocumentCursor:[NSCursor invertedIBeamCursor]]; //works
    
    // Setup    
    [O_textView setInsertionPointColor:[NSColor whiteColor]];
    
    // setting NSCursor attributes does not show the right cursor when pointed to empty area
}

@end
