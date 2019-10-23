//  DocumentProxyWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Apr 29 2004.

#import "DocumentProxyWindowController.h"
#import "TCMMMSession.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMUserManager.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "GeneralPreferences.h"
#import "NSScreenTCMAdditions.h"

@interface NSWindow (NSWindowNonBlockingAnimationAdditions) 
- (void)setFrameUsingNonBlockingAnimation:(NSRect)aFrame;
@end

#define linearInterpolation(A,B,P) (A + ((P)*((B)-(A))))

@implementation NSWindow (NSWindowNonBlockingAnimationAdditions) 
- (NSRect)frameAnimatedFrom:(NSRect)aFromRect to:(NSRect)aToRect progress:(float)aProgress {
    if (aProgress >= 1.0) {
        return aToRect;
    } else if (aProgress <= 0) {
        return aFromRect;
    } else {
        aFromRect.origin.x = linearInterpolation(aFromRect.origin.x,aToRect.origin.x,aProgress);
        aFromRect.origin.y = linearInterpolation(aFromRect.origin.y,aToRect.origin.y,aProgress);
        aFromRect.size.width = linearInterpolation(aFromRect.size.width,aToRect.size.width,aProgress);
        aFromRect.size.height = linearInterpolation(aFromRect.size.height,aToRect.size.height,aProgress);

        return aFromRect;
    }
}

- (void)nonBlockingAnimationStep:(NSTimer *)aTimer {
    NSDictionary *userInfo = [aTimer userInfo];
    float progress = [[NSDate date] timeIntervalSinceDate:[userInfo objectForKey:@"startDate"]]/
        [[userInfo objectForKey:@"stopDate"] timeIntervalSinceDate:[userInfo objectForKey:@"startDate"]];
    NSRect newFrame = [self frameAnimatedFrom:[[userInfo objectForKey:@"sourceFrame"] rectValue] to:[[userInfo objectForKey:@"targetFrame"] rectValue] progress:progress];
    BOOL finished = NSEqualRects(newFrame,[self frame]);
    [self setFrame:newFrame display:YES];
    if (finished) {
        [aTimer invalidate];
    }
}

- (void)setFrameUsingNonBlockingAnimation:(NSRect)aFrame {
    if ([self respondsToSelector:@selector(animator)]) {
//        NSLog(@"%s animator present!",__FUNCTION__);
//        [NSClassFromString(@"NSAnimationContext") beginGrouping];
        id currentContext = [NSClassFromString(@"NSAnimationContext") currentContext];
        [currentContext setDuration:0.3];
        id animator = [self performSelector:@selector(animator)];
        [animator setFrame:aFrame display:YES];
//       [NSClassFromString(@"NSAnimationContext") endGrouping];
        return;
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSValue valueWithRect:[self frame]] forKey:@"sourceFrame"];
    [userInfo setObject:[NSValue valueWithRect:aFrame] forKey:@"targetFrame"];
    [userInfo setObject:[NSDate dateWithTimeIntervalSinceNow:[self animationResizeTime:aFrame]] forKey:@"stopDate"];
    [userInfo setObject:[NSDate date] forKey:@"startDate"];
    [NSTimer scheduledTimerWithTimeInterval:(1.0/20.0) target:self selector:@selector(nonBlockingAnimationStep:) userInfo:userInfo repeats:YES];
}
@end


@implementation DocumentProxyWindowController

- (instancetype)initWithSession:(TCMMMSession *)aSession {
    self = [super initWithWindowNibName:@"DocumentProxy"];
    if (self) {
        [self setSession:aSession];
        [self setShouldCascadeWindows:NO];
    }
    return self;
}

- (void)dealloc {
    // Interesting side effect of the arc transition. We now have to close the window explicitly on dealloc to make it go away.
    // Otherwise a window controller less window stays around until the close/cancel button is hit again after the first one.
    [self.window close];
}

- (void)update {
    TCMMMSessionClientState state=[[(PlainTextDocument *)[self document] session] clientState];
    if (state == TCMMMSessionClientJoiningState) {
        if ([O_bottomStatusView isHidden]) {
            [O_bottomDecisionView setHidden:YES];
            [O_bottomStatusView setHidden:NO];
        }
        [O_statusBarTextField setStringValue:NSLocalizedString(@"PROXY_WINDOW_STATUS_WAIT_ANSWER",@"Text while waiting for answer to join request")];
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

	[self.userAvatarImageView setImage:user.image];
	[self.userAvatarImageView setBorderColor:user.changeColor];

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

    [window setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];

    [NSApp addWindowsItem:window title:[window title] filename:NO];
    
    [O_acceptButton setAction:@selector(acceptAction:)];
    [O_acceptButton setTarget:self];
    [O_declineButton setAction:@selector(performClose:)];
    [O_declineButton setTarget:[O_declineButton window]];


	[O_acceptButton setTitle:NSLocalizedString(@"PROXY_WINDOW_ACCEPT", @"")];
	[O_declineButton setTitle:NSLocalizedString(@"PROXY_WINDOW_DECLINE", @"")];
	
    if ([I_session wasInvited]) {
        [window setLevel:NSFloatingWindowLevel];
        [O_bottomStatusView setHidden:YES];
    } else {
        [window setLevel:NSNormalWindowLevel];
        [O_bottomDecisionView setHidden:YES];
    }
    [self update];
    
    // position cascading top left on menubar screen
    NSRect screenRect = [[NSScreen menuBarContainingScreen] visibleFrame];
    NSPoint origin = NSZeroPoint;
    NSRect windowFrame = [window frame];
    origin.x = NSMaxX(screenRect)-windowFrame.size.width-80.;
    origin.y = NSMaxY(screenRect)-40.;
    float cascadingYDifference = windowFrame.size.height+40.;
        // get all existing proxy windows
        NSMutableArray *proxyWindowArray = [NSMutableArray array];
        NSEnumerator *documents = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
        PlainTextDocument *document = nil;
        while ((document = [documents nextObject])) {
			if ([document isKindOfClass:[PlainTextDocument class]]) {
				DocumentProxyWindowController *wc = [document proxyWindowController];
				if (wc) {
					[proxyWindowArray addObject:[wc window]];
				}
			}
        }

        // check current position against windows that are already there
        int maxHitCount = 0;
        
		int currentHitCount = 0;
        while (YES) {
            while (origin.y - windowFrame.size.height > NSMinY(screenRect)) {
                currentHitCount = 0;
                NSEnumerator *windows = [proxyWindowArray objectEnumerator];
                NSWindow *window = nil;
                while ((window = [windows nextObject])) {
                    if (NSPointInRect(origin,NSInsetRect([window frame],-5.,-5.))) {
                        currentHitCount++;
                    }
                }
                if (currentHitCount <= maxHitCount) break;
                origin.y -= cascadingYDifference;
            }
            if (currentHitCount <= maxHitCount) break;
            if (origin.y - windowFrame.size.height <= NSMinY(screenRect)) {
                maxHitCount++;
                origin.y = NSMaxY(screenRect)-40. - currentHitCount * 22.;
                // if we are way out of screenbounds with start then just stick with one location
                if (origin.y - windowFrame.size.height <= NSMinY(screenRect)) {
                    origin.y = NSMaxY(screenRect)-40.; 
                    break;
                }
            }
        }
        
    [window cascadeTopLeftFromPoint:origin];
    if ([I_session wasInvited]) {
        [window orderFrontRegardless];
    }
    NSRect frame = [window frame];
    [window setMinSize:frame.size];
    frame.size.width = 2048;
    [window setMaxSize:frame.size];
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
    I_session = aSession;
}

- (void)dissolveToWindow:(NSWindow *)aWindow {
    I_targetWindow = aWindow;
    NSRect frame=[[self window] frame];
    frame.origin.y=NSMaxY(frame);

    [[self window] setContentView:[[NSView alloc] initWithFrame:frame]];

    I_dissolveToFrame = [[I_targetWindow windowController] dissolveToFrame];
    [[self window] setFrameUsingNonBlockingAnimation:I_dissolveToFrame];
}

- (void)joinRequestWasDenied {
    [O_statusBarTextField setStringValue:NSLocalizedString(@"PROXY_WINDOW_STATUS_DENIED",@"Text in Proxy window")];
}

- (void)invitationWasCanceled {
    [O_bottomStatusView   setHidden:NO];
    [O_bottomDecisionView setHidden:YES];
    [O_statusBarTextField setStringValue:NSLocalizedString(@"PROXY_WINDOW_STATUS_INVITE_CANCELED",@"Text in Proxy window")];
}

- (void)didLoseConnection {
    [O_bottomStatusView   setHidden:NO];
    [O_bottomDecisionView setHidden:YES];
    [O_statusBarTextField setStringValue:NSLocalizedString(@"PROXY_WINDOW_STATUS_CONNECTION_LOST",@"Text in Proxy window")];
}

- (void)windowDidMove:(NSNotification *)aNotification {
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent window]==[self window]) {
        [[self window] setLevel:NSNormalWindowLevel];
    }
}

- (void)removeSelfAndWindow {
    [[self window] orderOut:self];
	[[I_targetWindow windowController] performSelector:@selector(openParticipantsOverlayForDocument:) withObject:self];
    [(PlainTextDocument *)[self document] killProxyWindowController];
}

- (void)windowDidResize:(NSNotification *)aNotification {
    if (I_targetWindow && NSEqualSizes([[self window] frame].size,I_dissolveToFrame.size)) {
        if (![I_targetWindow isVisible]) {
            [I_targetWindow orderWindow:NSWindowBelow relativeTo:[[self window] windowNumber]];
        }
        if ([[self window] respondsToSelector:@selector(animator)]) {
//            NSLog(@"%s animator present!",__FUNCTION__);
//            [NSClassFromString(@"NSAnimationContext") beginGrouping];
            id currentContext = [NSClassFromString(@"NSAnimationContext") currentContext];
            [currentContext setDuration:0.3];
            [[self window] setHasShadow:NO];
            id animator = [[self window] performSelector:@selector(animator)];
            [animator setAlphaValue:0.00];
            [self performSelector:@selector(removeSelfAndWindow) withObject:nil afterDelay:0.5];
//            [NSClassFromString(@"NSAnimationContext") endGrouping];
            return;
        }
        [[self window] orderOut:self];
		[[I_targetWindow windowController] performSelector:@selector(openParticipantsOverlayForDocument:) withObject:self];
        [(PlainTextDocument *)[self document] killProxyWindowController];
    }
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [(PlainTextDocument *)[self document] proxyWindowWillClose];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    NSString *filename=[I_session filename];
    if ([I_session clientState]==TCMMMSessionClientInvitedState) {
        return [NSString stringWithFormat:NSLocalizedString(@"PROXY_WINDOW_TITLE_INVITE",@"Proxy window title for invited documents"),filename];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"PROXY_WINDOW_TITLE_JOIN",@"Proxy window title for joining documents"),filename];
    }
}

@end
