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
#import "SEEAvatarImageView.h"

#import "PlainTextEditor.h"
#import "PlainTextWindowControllerTabContext.h"
#import "PlainTextWindowController.h"
#import "PlainTextDocument.h"

#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

@interface SEEParticipantViewController ()

@property (nonatomic, readwrite, assign) SEEParticipantViewMode viewMode;
@property (nonatomic, readwrite, strong) NSColor *popoverTextColor;

@property (nonatomic, readwrite, strong) TCMMMUser *participant;
@property (nonatomic, readwrite, weak) PlainTextWindowControllerTabContext *tabContext;

@property (nonatomic, strong) IBOutlet NSView *participantViewOutlet;
@property (nonatomic, strong) IBOutlet NSPopover *nameLabelPopoverOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *nameLabelOutlet;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *userViewButtonLeftConstraintOutlet;
@property (nonatomic, weak) IBOutlet NSButton *userViewButtonOutlet;
@property (nonatomic, weak) IBOutlet SEEAvatarImageView *avatarViewOutlet;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *connectingProgressIndicatorOutlet;

@property (nonatomic, strong) IBOutlet NSView *participantActionOverlayOutlet;
@property (nonatomic, weak) IBOutlet NSButton *closeConnectionButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *toggleEditModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *toggleFollowButtonOutlet;

@property (nonatomic, strong) IBOutlet NSPopover *pendingUserPopoverOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *pendingUserActionPopoverTitle;
@property (nonatomic, weak) IBOutlet NSTextField *pendingUserActionPopoverDescription;
@property (nonatomic, weak) IBOutlet NSButton *pendingUserKickButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *chooseEditModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *chooseReadOnlyModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *pendingUserQuestionMarkOutlet;

@property (nonatomic, weak) IBOutlet NSImageView *hasFollowerOverlayImageOutlet;
@property (nonatomic, weak) IBOutlet NSImageView *readOnlyOverlayImageOutlet;

@property (nonatomic, weak) id plainTextEditorFollowUserNotificationHandler;
@property (nonatomic, weak) id participantsScrollingNotificationHandler;
@property (nonatomic, weak) id popoverShownNotificationHandler;

@end

@implementation SEEParticipantViewController

- (id)initWithParticipant:(TCMMMUser *)aParticipant tabContext:(PlainTextWindowControllerTabContext *)aTabContext inMode:(SEEParticipantViewMode)aMode
{
    self = [super initWithNibName:@"SEEParticipantView" bundle:nil];
    if (self) {
		self.viewMode = aMode;
		self.participant = aParticipant;
		self.tabContext = aTabContext;

		__weak __typeof__(self) weakSelf = self;
		self.plainTextEditorFollowUserNotificationHandler =
		[[NSNotificationCenter defaultCenter] addObserverForName:PlainTextEditorDidFollowUserNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			__typeof__(self) strongSelf = weakSelf;
			if ([strongSelf.tabContext.plainTextEditors containsObject:note.object])
				[strongSelf updateParticipantFollowed];
		}];

		// this fixes the popover content vies become first responder on opening
		// store the old responder and set it again after 0.0 delay.
		self.popoverShownNotificationHandler =
		[[NSNotificationCenter defaultCenter] addObserverForName:NSPopoverWillShowNotification
														  object:nil queue:nil usingBlock:^(NSNotification *note) {
															  __typeof__(self) strongSelf = weakSelf;

															  if (note.object == strongSelf.nameLabelPopoverOutlet) {
																  NSWindow *window = strongSelf.view.window;
																  NSResponder *previousFirstResponder = window.firstResponder;
																  [NSOperationQueue TCM_performBlockOnMainQueue:^{
																	  [window makeFirstResponder:previousFirstResponder];
																  } afterDelay:0.0];
															  }
														  }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.plainTextEditorFollowUserNotificationHandler];
    [[NSNotificationCenter defaultCenter] removeObserver:self.participantsScrollingNotificationHandler];
    [[NSNotificationCenter defaultCenter] removeObserver:self.popoverShownNotificationHandler];

	SEEAvatarImageView *avatarView = self.avatarViewOutlet;
	[avatarView unbind:@"image"];
	[avatarView unbind:@"initials"];
	[avatarView unbind:@"borderColor"];

	self.nameLabelPopoverOutlet.delegate = nil;
	self.pendingUserPopoverOutlet.delegate = nil;
}

- (void)loadView {
	[super loadView];

	NSButton *userViewButton = self.userViewButtonOutlet;

	TCMMMUser *user = self.participant;
	SEEAvatarImageView *avatarView = self.avatarViewOutlet;
	[avatarView bind:@"image" toObject:user withKeyPath:@"image" options:nil];
	[avatarView bind:@"initials" toObject:user withKeyPath:@"initials" options:nil];
	[avatarView bind:@"borderColor" toObject:user withKeyPath:@"changeColorDesaturated" options:nil];

	NSTextField *nameLabel = self.nameLabelOutlet;
	nameLabel.stringValue = user.name;

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

	{
		NSImageView *imageView = self.hasFollowerOverlayImageOutlet;
		imageView.image = [NSImage pdfBasedImageNamed:@"SharingIconEye"TCM_PDFIMAGE_SEP@"20"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
	}
	{
		NSImageView *imageView = self.readOnlyOverlayImageOutlet;
		imageView.image = [NSImage pdfBasedImageNamed:@"SharingIconReadOnly"TCM_PDFIMAGE_SEP@"20"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL];
		imageView.hidden = YES;
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

	// add double click target for follow action
	[userViewButton setAction:@selector(userViewButtonClicked:)];
	[userViewButton setTarget:self];

	self.nameLabelPopoverOutlet.delegate = self;
	self.pendingUserPopoverOutlet.delegate = self;

	// add tracking for action buttons overlay and name overlay
	[self.participantViewOutlet addTrackingArea:[[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect owner:self userInfo:nil]];

	switch (self.viewMode) {
		case SEEParticipantViewModeParticipant:
			[self updateForParticipantUserState];
			break;

		case SEEParticipantViewModeInvited:
			[self updateForInvitationState];
			break;

		case SEEParticipantViewModePending:
			[self updateForPendingUserState];
			break;

		default:
			break;
	}

	[self updateColorsForIsDarkBackground:self.tabContext.document.documentBackgroundColor.isDark];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	switch (self.viewMode) {
		case SEEParticipantViewModeParticipant:
		{
			if (! self.participant.isMe) {
				[self updateParticipantFollowed];
				self.participantActionOverlayOutlet.hidden = NO;

				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
					context.duration = 0.1;
					self.userViewButtonLeftConstraintOutlet.animator.constant = 10.0;
				} completionHandler:^{
					NSPopover *popover = self.nameLabelPopoverOutlet;
					if (! popover.isShown) {
						[popover showRelativeToRect:NSZeroRect ofView:self.userViewButtonOutlet preferredEdge:NSMinYEdge];
						self.participantsScrollingNotificationHandler =
						[[NSNotificationCenter defaultCenter] addObserverForName:NSScrollViewDidLiveScrollNotification object:self.view.enclosingScrollView queue:nil usingBlock:^(NSNotification *note) {
							if (popover.isShown) {
								[popover close];
							}
						}];
					}
				}];
			} else {
				NSPopover *popover = self.nameLabelPopoverOutlet;
				if (! popover.isShown) {
					[popover showRelativeToRect:NSZeroRect ofView:self.userViewButtonOutlet preferredEdge:NSMinYEdge];
					self.participantsScrollingNotificationHandler =
					[[NSNotificationCenter defaultCenter] addObserverForName:NSScrollViewDidLiveScrollNotification object:self.view.enclosingScrollView queue:nil usingBlock:^(NSNotification *note) {
						if (popover.isShown) {
							[popover close];
						}
					}];
				}
			}
			break;
		}
		case SEEParticipantViewModeInvited:
		{
			self.participantActionOverlayOutlet.hidden = NO;

			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				context.duration = 0.1;
				self.userViewButtonLeftConstraintOutlet.animator.constant = 10.0;
			} completionHandler:^{
				NSPopover *popover = self.nameLabelPopoverOutlet;
				if (! popover.isShown) {
					[popover showRelativeToRect:NSZeroRect ofView:self.userViewButtonOutlet preferredEdge:NSMinYEdge];
					self.participantsScrollingNotificationHandler =
					[[NSNotificationCenter defaultCenter] addObserverForName:NSScrollViewDidLiveScrollNotification object:self.view.enclosingScrollView queue:nil usingBlock:^(NSNotification *note) {
						if (popover.isShown) {
							[popover close];
						}
					}];
				}
			}];

			break;
		}
		case SEEParticipantViewModePending:
		{
			NSPopover *popover = self.pendingUserPopoverOutlet;
			if (! popover.isShown) {
				[popover showRelativeToRect:NSZeroRect ofView:self.userViewButtonOutlet preferredEdge:NSMinYEdge];

				self.participantsScrollingNotificationHandler =
				[[NSNotificationCenter defaultCenter] addObserverForName:NSScrollViewDidLiveScrollNotification object:self.view.enclosingScrollView queue:nil usingBlock:^(NSNotification *note) {
					if (popover.isShown) {
						[popover close];
					}
				}];
			}
			break;
		}
		default:
			break;
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	switch (self.viewMode) {
		case SEEParticipantViewModeParticipant:
		{
			if (! self.participant.isMe) {
				self.participantActionOverlayOutlet.hidden = YES;

				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
					context.duration = 0.1;
					self.userViewButtonLeftConstraintOutlet.animator.constant = 0.0;
				} completionHandler:^{
					[self.nameLabelPopoverOutlet close];
				}];
			} else {
				[self.nameLabelPopoverOutlet close];
			}
			break;
		}
		case SEEParticipantViewModeInvited:
		{
			self.participantActionOverlayOutlet.hidden = YES;

			[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
				context.duration = 0.1;
				self.userViewButtonLeftConstraintOutlet.animator.constant = 0.0;
			} completionHandler:^{
				[self.nameLabelPopoverOutlet close];
			}];
			break;
		}
		default:
			break;
	}
}


#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)notification {
	if (self.participantsScrollingNotificationHandler) {
		[[NSNotificationCenter defaultCenter] removeObserver:self.participantsScrollingNotificationHandler];
		self.participantsScrollingNotificationHandler = nil;
	}
}


#pragma mark Actions

- (IBAction)closeConnection:(id)sender {
	TCMMMSession *documentSession = self.tabContext.document.session;
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

- (IBAction)userViewButtonClicked:(id)sender {
	switch (self.viewMode) {
		case SEEParticipantViewModeParticipant:
		{
			NSEvent *event = [NSApp currentEvent];
			if (event.clickCount == 2) {
				[self toggleFollow:sender];
			}
			break;
		}
		case SEEParticipantViewModePending:
		{
			NSPopover *popover = self.pendingUserPopoverOutlet;
			if (! popover.isShown) {
				[popover showRelativeToRect:NSZeroRect ofView:self.userViewButtonOutlet preferredEdge:NSMinYEdge];

				self.participantsScrollingNotificationHandler =
				[[NSNotificationCenter defaultCenter] addObserverForName:NSScrollViewDidLiveScrollNotification object:self.view.enclosingScrollView queue:nil usingBlock:^(NSNotification *note) {
					if (popover.isShown) {
						[popover close];
					}
				}];
			}
			break;
		}
		default:
			break;
	}
}

- (IBAction)toggleEditMode:(id)sender {
	TCMMMSession *documentSession = self.tabContext.document.session;
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

		BOOL activeEditorIsFollowing = [activeEditor.followUserID isEqualToString:user.userID];
		if (activeEditorIsFollowing) {
			[activeEditor setFollowUserID:nil];
		} else {
			[activeEditor setFollowUserID:user.userID];
		}

		[self updateParticipantFollowed];
	}
}

- (IBAction)chooseReadOnlyMode:(id)sender {
	TCMMMSession *documentSession = self.tabContext.document.session;
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
	TCMMMSession *documentSession = self.tabContext.document.session;
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

#pragma mark Color Scheme Appearence

- (void)updateColorsForIsDarkBackground:(BOOL)isDark {
	self.nameLabelPopoverOutlet.appearance = isDark ? NSPopoverAppearanceMinimal : NSPopoverAppearanceHUD;
	self.pendingUserPopoverOutlet.appearance = isDark ? NSPopoverAppearanceMinimal:NSPopoverAppearanceHUD;
	self.popoverTextColor = isDark ? [NSColor controlTextColor] : [NSColor alternateSelectedControlTextColor];
}


#pragma mark - Preparing Views

- (void)updateForParticipantUserState {
	if (self.participant.isMe) {
		self.participantActionOverlayOutlet = nil;
	} else {
		TCMMMUser *user = self.participant;

		[self updateParticipantFollowed];

		BOOL userCanEditDocument = [self.tabContext.document.session isEditableByUser:user];
		self.toggleEditModeButtonOutlet.state = userCanEditDocument?NSOffState:NSOnState;
		self.readOnlyOverlayImageOutlet.hidden = userCanEditDocument;

		if (! self.tabContext.document.session.isServer) {
			[self.closeConnectionButtonOutlet removeFromSuperview];
			[self.toggleEditModeButtonOutlet removeFromSuperview];
		}

		// add action overlay to view hierarchy
		NSView *userView = self.participantViewOutlet;
		NSView *overlayView = self.participantActionOverlayOutlet;
		overlayView.hidden = YES;
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
		[userView addSubview:self.participantActionOverlayOutlet];
		[userView addConstraints:@[constraint, verticalConstraint]];
	}
}

- (void)updateParticipantFollowed
{
	// update hidden of status view
	BOOL isFollowing = NO;
	NSArray *editors = self.tabContext.plainTextEditors;
	for (PlainTextEditor *currentEditor in editors) {
		isFollowing = [[currentEditor followUserID] isEqualToString:self.participant.userID];
		if (isFollowing) {
			break;
		}
	}
	self.isParticipantFollowed = isFollowing;

	// update action button state
	PlainTextWindowController *windowController = self.view.window.windowController;
	PlainTextEditor *activeEditor = windowController.activePlainTextEditor;
	TCMMMUser *user = self.participant;

	BOOL activeEditorIsFollowing = [activeEditor.followUserID isEqualToString:user.userID];
	self.toggleFollowButtonOutlet.state = activeEditorIsFollowing?NSOnState:NSOffState;
}


- (void)updateForPendingUserState {
	self.pendingUserQuestionMarkOutlet.hidden = NO;
	self.userViewButtonOutlet.enabled = YES;

	{ // popover alert button titles
		self.pendingUserKickButtonOutlet.title = NSLocalizedStringWithDefaultValue(@"KICK_PENDING_USER_BUTTON_TITLE", nil, [NSBundle mainBundle], @"Reject", @"Button Title for reject button in pending participant action popover");

		self.chooseReadOnlyModeButtonOutlet.title = NSLocalizedStringWithDefaultValue(@"READ_ONLY_PENDING_USER_BUTTON_TITLE", nil, [NSBundle mainBundle], @"Read Only", @"Button Title for read only button in pending participant action popover");

		self.chooseEditModeButtonOutlet.title = NSLocalizedStringWithDefaultValue(@"READ_WRITE_PENDING_USER_BUTTON_TITLE", nil, [NSBundle mainBundle], @"Read/Write", @"Button Title for read-write button in pending participant action popover");
	}
	{ // popover alert title
		self.pendingUserActionPopoverTitle.stringValue = NSLocalizedStringWithDefaultValue(@"PENDING_USER_ALERT_POPUP_TITLE", nil, [NSBundle mainBundle], @"New Participant", @"Pending participant action popover dialog title.");
	}
	{ // popover alert description
		NSString *popoverDescriptionFormatString = NSLocalizedStringWithDefaultValue(@"PENDING_USER_ALERT_POPUP_DESCRIPTION", nil, [NSBundle mainBundle], @"%@ wants to join this document.", @"Pending participant action popover dialog description. First argument represents joining participants name.");
		self.pendingUserActionPopoverDescription.stringValue = [NSString stringWithFormat:popoverDescriptionFormatString, self.participant.name];
	}
}


- (void)updateForInvitationState {
	self.connectingProgressIndicatorOutlet.usesThreadedAnimation = YES;
	[self.connectingProgressIndicatorOutlet startAnimation:self];
	self.nameLabelOutlet.alphaValue = 0.8;
	self.userViewButtonOutlet.alphaValue = 0.6;
	self.userViewButtonOutlet.enabled = NO;

	if (! self.tabContext.document.session.isServer) {
		self.participantActionOverlayOutlet = nil;
	} else {
		[self.toggleEditModeButtonOutlet removeFromSuperview];
		[self.toggleFollowButtonOutlet removeFromSuperview];
		
		// add action overlay to view hierarchy
		NSView *userView = self.participantViewOutlet;
		NSView *overlayView = self.participantActionOverlayOutlet;
		overlayView.hidden = YES;
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
		[userView addSubview:self.participantActionOverlayOutlet];
		[userView addConstraints:@[constraint, verticalConstraint]];
	}
}

@end
