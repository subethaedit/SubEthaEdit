//
//  DebugController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DebugController.h"


static DebugController * sharedInstance = nil;


@implementation DebugController

+ (DebugController *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    if (sharedInstance) {
        [self release];
    } else if ((self = [super init])) {
        sharedInstance = self;
    }
    return sharedInstance;
}

- (void)enableDebugMenu:(BOOL)flag
{
    NSLog(@"enableDebugMenu");
    int indexOfDebugMenu = [[NSApp mainMenu] indexOfItemWithTitle:@"Debug"];
    
    if (flag && indexOfDebugMenu == -1) {
        NSLog(@"adding debug menu");
        NSMenuItem *debugItem = [[NSMenuItem alloc] initWithTitle:@"Debug" action:nil keyEquivalent:@""];
        //[newItem setSubmenu:oDebugMenu];
        NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        [debugItem setSubmenu:menu];
        [[NSApp mainMenu] addItem:debugItem];
        [debugItem release];
    } else if (flag == NO && indexOfDebugMenu != -1) {
        NSLog(@"remove debug menu");
        [[NSApp mainMenu] removeItemAtIndex:indexOfDebugMenu];
    }
}

@end
