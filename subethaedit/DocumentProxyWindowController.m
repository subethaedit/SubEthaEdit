//
//  DocumentProxyWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Apr 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentProxyWindowController.h"
#import "TCMMMSession.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMUserManager.h"
#import "PlainTextDocument.h"

@implementation DocumentProxyWindowController

- (id)initWithSession:(TCMMMSession *)aSession {
    self = [super initWithWindowNibName:@"DocumentProxy"];
    if (self) {
        [self setSession:aSession];
    }
    return self;
}

- (void)dealloc {
    [I_targetWindow release];
    [I_session release];
    [super dealloc];
}


- (void)windowDidLoad {
    NSWindow *window=[self window];
//    [((NSPanel *)window) setFloatingPanel:NO];
    [window setHidesOnDeactivate:NO];
    TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[I_session hostID]];
    [O_userImageView setImage:[[user properties] objectForKey:@"Image32"]];
    [O_userNameTextField setStringValue:[user name]];
    NSString *filename=[I_session filename];
    [O_documentTitleTextField setStringValue:filename];
    [O_documentImageView setImage:[[NSWorkspace sharedWorkspace] iconForFileType:[filename pathExtension]]];
    [window setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ (joining...)",@"Proxy window title for joining documents"),filename]];
}

- (void)setSession:(TCMMMSession *)aSession {
    [I_session autorelease];
    I_session=[aSession retain];
}

- (void)dissolveToWindow:(NSWindow *)aWindow {
    I_targetWindow=[aWindow retain];
    [[self window] setFrame:[I_targetWindow frame] display:YES animate:YES];
}

- (void)windowDidResize:(NSNotification *)aNotification {
    if (I_targetWindow && NSEqualRects([[self window] frame],[I_targetWindow frame])) {
        [I_targetWindow orderWindow:NSWindowBelow relativeTo:[[self window] windowNumber]];
        [[self window] orderOut:self];
        [[I_targetWindow drawers] makeObjectsPerformSelector:@selector(open)];
        [(PlainTextDocument *)[self document] killProxyWindowController];
    }
}

@end
