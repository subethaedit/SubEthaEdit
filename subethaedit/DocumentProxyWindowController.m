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
#import "PlainTextWindowController.h"
#import "GeneralPreferences.h"
#import "DWRoundedTransparentView.h"


@implementation DocumentProxyWindowController

- (id)initWithSession:(TCMMMSession *)aSession {
    self = [super initWithWindowNibName:@"DocumentProxy"];
    if (self) {
        [self setSession:aSession];
    }
    return self;
}

- (void)dealloc {
    [[self window] setDelegate:nil];
    [I_targetWindow release];
    [I_session release];
    [super dealloc];
}

- (void)update {
    TCMMMSessionClientState state=[[(PlainTextDocument *)[self document] session] clientState];
    if (state == TCMMMSessionClientJoiningState) {
        if ([O_bottomStatusView isHidden]) {
            [O_bottomDecisionView setHidden:YES];
            [O_bottomStatusView setHidden:NO];
        }
        [O_statusBarTextField setStringValue:NSLocalizedString(@"Awaiting answer...",@"Text while waiting for answer to join request")];
    } else if (state == TCMMMSessionClientInvitedState) {
        if ([O_bottomDecisionView isHidden]) {
            [O_bottomStatusView setHidden:YES];
            [O_bottomDecisionView setHidden:NO];
        }
    }
    [self synchronizeWindowTitleWithDocumentName];
}

- (void)windowDidLoad {
    NSWindow *window=[self window];
//    [((NSPanel *)window) setFloatingPanel:NO];
    [window setHidesOnDeactivate:NO];
    TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[I_session hostID]];
    [O_userImageView setImage:[[user properties] objectForKey:@"Image"]];
    [O_userNameTextField setStringValue:[user name]];
    NSString *filename=[I_session filename];
    [O_documentTitleTextField setStringValue:filename];
    [O_documentImageView setImage:[[NSWorkspace sharedWorkspace] iconForFileType:[filename pathExtension]]];
//    NSLog(@"Session :%@",[I_session description]);
    [O_bottomDecisionView setFrame:[O_bottomCustomView frame]];
    [O_bottomStatusView setFrame:[O_bottomCustomView frame]];
    [O_bottomCustomView removeFromSuperview];
    [[window contentView] addSubview:O_bottomStatusView];
    [[window contentView] addSubview:O_bottomDecisionView];

    [(DWRoundedTransparentView *)[window contentView] setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];
    [window setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];

    [NSApp addWindowsItem:window title:[window title] filename:NO];
    
    [O_acceptButton setAction:@selector(acceptAction:)];
    [O_acceptButton setTarget:self];
    [O_declineButton setAction:@selector(performClose:)];
    [O_declineButton setTarget:[O_declineButton window]];

    [O_acceptButton  setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
    [O_declineButton setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
    [O_acceptButton  setTextColor:[NSColor whiteColor]];
    [O_declineButton setTextColor:[NSColor whiteColor]];
    [O_acceptButton  setTextColor:[NSColor whiteColor]];
    [O_declineButton setTextColor:[NSColor whiteColor]];
    
    [O_declineButton setFrameColor:[NSColor lightGrayColor]];
    [O_acceptButton  setFrameColor:[NSColor lightGrayColor]];


    if ([I_session wasInvited]) {
        [O_bottomStatusView setHidden:YES];
    } else {
        [O_bottomDecisionView setHidden:YES];
    }
    [self update];
    if ([I_session wasInvited]) {
        [[self window] orderFrontRegardless];
    }
}

- (IBAction)acceptAction:(id)aSender {
    [O_bottomStatusView   setHidden:NO];
    [O_bottomDecisionView setHidden:YES];
    [O_statusBarTextField setStringValue:@""];
    [[(PlainTextDocument *)[self document] session] acceptInvitation];
}

- (BOOL)isPendingInvitation {
    return ![O_bottomDecisionView isHidden];
}

- (void)setSession:(TCMMMSession *)aSession {
    [I_session autorelease];
    I_session=[aSession retain];
}

- (void)dissolveToWindow:(NSWindow *)aWindow {
    I_targetWindow=[aWindow retain];
    NSRect frame=[[self window] frame];
    frame.origin.y=NSMaxY(frame);
    if (![[NSUserDefaults standardUserDefaults] boolForKey:OpenNewDocumentInTabKey])
        [I_targetWindow setFrameTopLeftPoint:frame.origin];
    DWRoundedTransparentView *proxyview = [[DWRoundedTransparentView new] autorelease];
    [proxyview setTitle:nil];
    [[self window] setContentView:proxyview];
    [O_containerView setAutoresizingMask:([O_containerView autoresizingMask] & ~NSViewWidthSizable) | NSViewMinXMargin | NSViewMaxXMargin ];

    NSRect targetFrame = [I_targetWindow frame];
    NSScreen *screen=[[self window] screen];
    if (screen) {
        NSPoint origin_offset = NSZeroPoint;
        NSRect visibleFrame=[screen visibleFrame];
        origin_offset.y = MIN(NSMinY(targetFrame) - NSMinY(visibleFrame), 0.);
        origin_offset.x = MIN(NSMaxX(visibleFrame) - NSMaxX(targetFrame), 0.);
        if (!NSEqualPoints(origin_offset, NSZeroPoint)) {
            [I_targetWindow setFrameTopLeftPoint:NSMakePoint(frame.origin.x + origin_offset.x,
                                                             frame.origin.y - origin_offset.y)];
        }
    }
    I_dissolveToFrame = [[I_targetWindow windowController] dissolveToFrame];
    [[self window] setFrame:I_dissolveToFrame display:YES animate:YES];
}

- (void)joinRequestWasDenied {
    [O_statusBarTextField setStringValue:NSLocalizedString(@"Join Request was denied!",@"Text in Proxy window")];
}

- (void)invitationWasCanceled {
    [O_bottomStatusView   setHidden:NO];
    [O_bottomDecisionView setHidden:YES];
    [O_statusBarTextField setStringValue:NSLocalizedString(@"Invitation was canceled!",@"Text in Proxy window")];
}

- (void)didLoseConnection {
    [O_bottomStatusView   setHidden:NO];
    [O_bottomDecisionView setHidden:YES];
    [O_statusBarTextField setStringValue:NSLocalizedString(@"Did lose Connection!",@"Text in Proxy window")];
}

- (void)windowDidResize:(NSNotification *)aNotification {
    if (I_targetWindow && NSEqualRects([[self window] frame],I_dissolveToFrame)) {
        if (![I_targetWindow isVisible]) {
            [I_targetWindow orderWindow:NSWindowBelow relativeTo:[[self window] windowNumber]];
        }
        [[self window] orderOut:self];
        [[I_targetWindow drawers] makeObjectsPerformSelector:@selector(open)];
        [(PlainTextDocument *)[self document] killProxyWindowController];
    }
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [(PlainTextDocument *)[self document] proxyWindowWillClose];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    NSString *filename=[I_session filename];
    if ([I_session clientState]==TCMMMSessionClientInvitedState) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ (invited...)",@"Proxy window title for invited documents"),filename];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ (joining...)",@"Proxy window title for joining documents"),filename];
    }
}

@end
