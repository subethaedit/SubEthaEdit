//
//  InternetController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "InternetController.h"
#import "TCMMMUser.h"
#import "TCMMMUserManager.h"
#import "TCMHost.h"


@implementation InternetController

- (id)init
{
    self = [super initWithWindowNibName:@"Internet"];
    if (self) {
    
    }
    return self;    
}

- (void)windowDidLoad
{
    [[self window] setFrameAutosaveName:@"Internet"];
    TCMMMUser *me = [TCMMMUserManager me];
    [O_myNameTextField setStringValue:[me name]];
    [O_imageView setImage:[[me properties] objectForKey:@"Image"]];
    [((NSPanel *)[self window]) setFloatingPanel:NO];
    [[self window] setHidesOnDeactivate:NO];
}

- (IBAction)connect:(id)aSender
{
    NSString *address = [aSender objectValue];
    NSLog(@"connect to peer: %@", address);

    TCMHost *host = [[TCMHost hostWithName:address] retain];
    [host resolve];
}

@end

