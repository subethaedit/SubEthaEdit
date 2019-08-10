//  DocumentProxyWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Apr 29 2004.

#import <AppKit/AppKit.h>

@class DocumentProxyWindowController;
#import "SEEAvatarImageView.h"

@class TCMMMSession;

@interface DocumentProxyWindowController : NSWindowController {

    IBOutlet NSImageView *O_documentImageView;
    IBOutlet NSTextField *O_documentTitleTextField;
    IBOutlet NSTextField *O_userNameTextField;
    IBOutlet NSTextField *O_statusBarTextField;
    IBOutlet NSView *O_bottomCustomView;
    IBOutlet NSView *O_bottomStatusView;
    IBOutlet NSView *O_bottomDecisionView;
    IBOutlet NSButton *O_acceptButton;
    IBOutlet NSButton *O_declineButton;

    NSWindow *I_targetWindow;
    TCMMMSession *I_session;
    NSRect I_dissolveToFrame;
}

@property (nonatomic, strong) IBOutlet SEEAvatarImageView *userAvatarImageView;

- (instancetype)initWithSession:(TCMMMSession *)aSession;


- (BOOL)isPendingInvitation;
- (IBAction)acceptAction:(id)aSender;

- (void)update;

- (void)setSession:(TCMMMSession *)aSession;
- (void)dissolveToWindow:(NSWindow *)aWindow;
- (void)joinRequestWasDenied;
- (void)didLoseConnection;
- (void)invitationWasCanceled;

@end
