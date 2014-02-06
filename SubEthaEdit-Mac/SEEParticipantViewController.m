//
//  SEEParticipantViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEParticipantViewController.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "PlainTextEditor.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

@interface SEEParticipantViewController ()
@property (nonatomic, readwrite, strong) TCMMMUser *participant;
@property (nonatomic, readwrite, weak) PlainTextDocument *document;

@property (nonatomic, strong) IBOutlet NSView *participantViewOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *nameLabelOutlet;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *userViewButtonLeftConstraintOutlet;
@property (nonatomic, weak) IBOutlet NSButton *userViewButtonOutlet;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *connectingProgressIndicatorOutlet;

@property (nonatomic, strong) IBOutlet NSView *participantActionOverlayOutlet;
@property (nonatomic, weak) IBOutlet NSButton *closeConnectionButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *toggleEditModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *toggleFollowButtonOutlet;

@property (nonatomic, strong) IBOutlet NSView *pendingUserActionOverlayOutlet;
@property (nonatomic, weak) IBOutlet NSButton *pendingUserKickButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *chooseEditModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *chooseReadOnlyModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *pendingUserQuestionMarkOutlet;

@end

@implementation SEEParticipantViewController

- (id)initWithParticipant:(TCMMMUser *)aParticipant inDocument:(PlainTextDocument *)document
{
    self = [super initWithNibName:@"SEEParticipantView" bundle:nil];
    if (self) {
		self.participant = aParticipant;
		self.document = document;
    }
    return self;
}

- (void)loadView {
	[super loadView];

	NSButton *userViewButton = self.userViewButtonOutlet;
	NSRect userViewButtonFrame = userViewButton.frame;
	NSImage *userImage = self.participant.image;
	if (userImage) {
		userViewButton.image = self.participant.image;
	}
	userViewButton.layer.cornerRadius = NSHeight(userViewButtonFrame) / 2.0;
	userViewButton.layer.borderWidth = 3.0;

	CGFloat hueValue = [[self.participant.properties objectForKey:@"Hue"] doubleValue] / 255.0;
	userViewButton.layer.borderColor = [[NSColor colorWithCalibratedHue:hueValue saturation:0.8 brightness:1.0 alpha:0.8] CGColor];

	NSTextField *nameLabel = self.nameLabelOutlet;
	nameLabel.stringValue = self.participant.name;

	// participant users action overlay
	{
		NSButton *button = self.closeConnectionButtonOutlet;
		button.image = [NSImage pdfBasedImageNamed:@"SharingIconCloseCross"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	}
	{
		NSButton *button = self.toggleEditModeButtonOutlet;
		button.image = [NSImage pdfBasedImageNamed:@"SharingIconReadOnly"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
		button.alternateImage = [NSImage pdfBasedImageNamed:@"SharingIconWrite"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	}
	{
		NSButton *button = self.toggleFollowButtonOutlet;
		button.image = [NSImage pdfBasedImageNamed:@"SharingIconEye"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
		button.alternateImage = [NSImage pdfBasedImageNamed:@"SharingIconEye"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_SELECTED];
	}


	// pending users action overlay
	{
		NSButton *button = self.pendingUserKickButtonOutlet;
		button.image = [NSImage pdfBasedImageNamed:@"SharingIconCloseCross"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	}
	{
		NSButton *button = self.chooseEditModeButtonOutlet;
		button.image = [NSImage pdfBasedImageNamed:@"SharingIconWrite"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	}
	{
		NSButton *button = self.chooseReadOnlyModeButtonOutlet;
		button.image = [NSImage pdfBasedImageNamed:@"SharingIconReadOnly"TCM_PDFIMAGE_SEP@"16"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	NSView *userView = self.participantViewOutlet;
	NSView *overlayView = self.participantActionOverlayOutlet;
	overlayView.hidden = NO;
//	overlayView.layer.borderWidth = 1.0;
//	overlayView.layer.borderColor = [[NSColor redColor] CGColor];
	[self.view addSubview:overlayView];

	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:overlayView
																  attribute:NSLayoutAttributeRight
																  relatedBy:NSLayoutRelationEqual
																	 toItem:userView
																  attribute:NSLayoutAttributeRight
																 multiplier:1
																   constant:-5];

	NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintWithItem:overlayView
																		  attribute:NSLayoutAttributeTop
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:userView
																		  attribute:NSLayoutAttributeTop
																		 multiplier:1
																		   constant:0];
	[userView addConstraints:@[constraint, verticalConstraint]];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[self.participantActionOverlayOutlet removeFromSuperview];
	self.participantActionOverlayOutlet.hidden = YES;
}

- (IBAction)closeConnection:(id)sender {
	TCMMMSession *documentSession = self.document.session;
	if (documentSession.isServer) {
		NSDictionary *participants = documentSession.participants;
        NSDictionary *invitedUsers = documentSession.invitedUsers;
		NSArray *pendingUsers = documentSession.pendingUsers;
		TCMMMUser *user = self.participant;

		if ([pendingUsers containsObject:user]) {
			[documentSession denyPendingUser:user];
		} else if ([[invitedUsers objectForKey:TCMMMSessionReadWriteGroupName] containsObject:user] || [[invitedUsers objectForKey:TCMMMSessionReadOnlyGroupName] containsObject:user]) {
			[documentSession cancelInvitationForUserWithID:[user userID]];
		} else if ([[participants objectForKey:TCMMMSessionReadWriteGroupName] containsObject:user] || [[participants objectForKey:TCMMMSessionReadOnlyGroupName] containsObject:user]) {
			[documentSession setGroup:TCMMMSessionPoofGroupName forParticipantsWithUserIDs:@[[user userID]]];
		}
	}
}

- (IBAction)userViewButtonDoubleClicked:(id)sender {
	NSEvent *event = [NSApp currentEvent];
	if (event.clickCount == 2) {
		[self toggleFollow:sender];
	}
}

- (IBAction)toggleEditMode:(id)sender {
	TCMMMSession *documentSession = self.document.session;
	if (documentSession.isServer) {
		NSDictionary *participants = documentSession.participants;
		TCMMMUser *user = self.participant;

		if ([[participants objectForKey:TCMMMSessionReadWriteGroupName] containsObject:user]) {
			[documentSession setGroup:TCMMMSessionReadOnlyGroupName forParticipantsWithUserIDs:@[[user userID]]];
		} else if ([[participants objectForKey:TCMMMSessionReadOnlyGroupName] containsObject:user]) {
			[documentSession setGroup:TCMMMSessionReadWriteGroupName forParticipantsWithUserIDs:@[[user userID]]];
		}
	}
}

- (IBAction)toggleFollow:(id)sender {
	TCMMMUser *user = self.participant;
	if (! user.isMe) {
		PlainTextWindowController *windowController = self.view.window.windowController;
		PlainTextEditor *activeEditor = windowController.activePlainTextEditor;

		if ([activeEditor.followUserID isEqualToString:user.userID]) {
			[activeEditor setFollowUserID:nil];
		} else {
			[activeEditor setFollowUserID:user.userID];
		}
	}
}

- (IBAction)chooseReadOnlyMode:(id)sender {
	TCMMMSession *documentSession = self.document.session;
	if (documentSession.isServer) {
		NSDictionary *participants = documentSession.participants;
		NSArray *pendingUsers = documentSession.pendingUsers;
		TCMMMUser *user = self.participant;

		if ([pendingUsers containsObject:user]) {
			[documentSession addPendingUser:user toGroup:TCMMMSessionReadOnlyGroupName];
		} else if ([[participants objectForKey:TCMMMSessionReadWriteGroupName] containsObject:user]) {
			[documentSession setGroup:TCMMMSessionReadOnlyGroupName forParticipantsWithUserIDs:@[[user userID]]];
		}
	}
}

- (IBAction)chooseReadWriteMode:(id)sender {
	TCMMMSession *documentSession = self.document.session;
	if (documentSession.isServer) {
		NSDictionary *participants = documentSession.participants;
		NSArray *pendingUsers = documentSession.pendingUsers;
		TCMMMUser *user = self.participant;

		if ([pendingUsers containsObject:user]) {
			[documentSession addPendingUser:user toGroup:TCMMMSessionReadWriteGroupName];
		} else if ([[participants objectForKey:TCMMMSessionReadOnlyGroupName] containsObject:user]) {
			[documentSession setGroup:TCMMMSessionReadWriteGroupName forParticipantsWithUserIDs:@[[user userID]]];
		}
	}
}

- (void)updateForParticipantUserState {
	if (self.participant.isMe) {
		self.participantActionOverlayOutlet = nil;
	} else {
		// install tracking for action overlay
		[self.participantViewOutlet addTrackingArea:[[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow|NSTrackingInVisibleRect owner:self userInfo:nil]];

		// add double click target for follow action
		[self.userViewButtonOutlet setAction:@selector(userViewButtonDoubleClicked:)];
		[self.userViewButtonOutlet setTarget:self];

		if (! self.document.session.isServer) {
			[self.closeConnectionButtonOutlet removeFromSuperview];
			[self.toggleEditModeButtonOutlet removeFromSuperview];
		}
	}
}

- (void)updateForPendingUserState {
	if (self.document.session.isServer) {
		NSView *userView = self.participantViewOutlet;
		NSView *overlayView = self.pendingUserActionOverlayOutlet;
		overlayView.hidden = NO;
//		overlayView.layer.borderWidth = 1.0;
//		overlayView.layer.borderColor = [[NSColor redColor] CGColor];
		[userView addSubview:overlayView];

		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:overlayView
																	  attribute:NSLayoutAttributeRight
																	  relatedBy:NSLayoutRelationEqual
																		 toItem:userView
																	  attribute:NSLayoutAttributeRight
																	 multiplier:1
																	   constant:-5];

		NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintWithItem:overlayView
																	  attribute:NSLayoutAttributeTop
																	  relatedBy:NSLayoutRelationEqual
																		 toItem:userView
																	  attribute:NSLayoutAttributeTop
																	 multiplier:1
																	   constant:0];
		[userView addConstraints:@[constraint, verticalConstraint]];
		self.userViewButtonLeftConstraintOutlet.constant = 16;
	}

	self.pendingUserQuestionMarkOutlet.hidden = NO;
	self.userViewButtonOutlet.enabled = NO;
}

- (void)updateForInvitationState {
	self.connectingProgressIndicatorOutlet.usesThreadedAnimation = YES;
	[self.connectingProgressIndicatorOutlet startAnimation:self];
	self.nameLabelOutlet.alphaValue = 0.8;
	self.userViewButtonOutlet.alphaValue = 0.6;
	self.userViewButtonOutlet.enabled = NO;

	[self.toggleEditModeButtonOutlet removeFromSuperview];
	[self.toggleFollowButtonOutlet removeFromSuperview];

	if (! self.document.session.isServer) {
		[self.closeConnectionButtonOutlet removeFromSuperview];
	} else {
		[self.participantViewOutlet addTrackingArea:[[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow|NSTrackingInVisibleRect owner:self userInfo:nil]];
	}
}

@end
