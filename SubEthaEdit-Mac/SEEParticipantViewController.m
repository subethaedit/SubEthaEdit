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
#import "TCMHoverButton.h"

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

@property (nonatomic, strong) IBOutlet TCMHoverButton *kickUserButtonOutlet;
@property (nonatomic, strong) IBOutlet TCMHoverButton *followUserButtonOutlet;
@property (nonatomic, strong) IBOutlet TCMHoverButton *readWriteUserButtonOutlet;

@property (nonatomic, strong) IBOutlet NSPopover *pendingUserPopoverOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *pendingUserActionPopoverTitle;
@property (nonatomic, weak) IBOutlet NSTextField *pendingUserActionPopoverDescription;
@property (nonatomic, weak) IBOutlet NSButton *pendingUserKickButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *chooseEditModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSButton *chooseReadOnlyModeButtonOutlet;
@property (nonatomic, weak) IBOutlet NSTextField *pendingUserQuestionMarkOutlet;

@property (nonatomic, weak) id plainTextEditorFollowUserNotificationHandler;
@property (nonatomic, weak) id participantsScrollingNotificationHandler;
@property (nonatomic, weak) id popoverShownNotificationHandler;

@property (nonatomic) BOOL isShowingUIOverlay;

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

- (void)dealloc {
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
	[avatarView bind:@"borderColor" toObject:user withKeyPath:@"changeColor" options:nil];

	NSTextField *nameLabel = self.nameLabelOutlet;
	nameLabel.stringValue = user.name;

	// configure overlay buttons
	[@{@"ParticipantKick" : self.kickUserButtonOutlet,
	   @"ParticipantFollowTurnOn" : self.followUserButtonOutlet,
	   @"ParticipantReadOnlyTurnOn" : self.readWriteUserButtonOutlet,} enumerateKeysAndObjectsUsingBlock:^(NSString *imagesPrefix, TCMHoverButton *button, __unused BOOL *stop) {
		   [button setImagesByPrefix:imagesPrefix];
		   button.alphaValue = 0.0;
	   }];
	

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
	NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect;
	NSView *view = self.participantViewOutlet;
	NSPoint mouseLocationInBounds = [view convertPoint:[self.view.window mouseLocationOutsideOfEventStream] fromView:nil];
	BOOL mouseIsInside = NSMouseInRect(mouseLocationInBounds, view.bounds, view.isFlipped);
	if (mouseIsInside) {
		options |= NSTrackingAssumeInside;
	}

	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
																options:options
																  owner:self
															   userInfo:nil];
	
	[view addTrackingArea:trackingArea];

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

- (void)showUIOverlay {
	self.isShowingUIOverlay = YES;
	switch (self.viewMode) {
		case SEEParticipantViewModeParticipant:
		{
			if (! self.participant.isMe) {
				[self updateParticipantFollowed];
				[self updateParticipantReadOnly];
				self.readWriteUserButtonOutlet.animator.alphaValue = 1.0;
				self.followUserButtonOutlet.animator.alphaValue = 1.0;
			}
		} // falling through purposefully!
		case SEEParticipantViewModeInvited:
		{
			self.kickUserButtonOutlet.animator.alphaValue = 1.0;
			
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


- (void)hideUIOverlay {
	self.isShowingUIOverlay = NO;
	self.kickUserButtonOutlet.animator.alphaValue = 0.0;

	TCMHoverButton *button;
	button = self.readWriteUserButtonOutlet.animator;
	if (self.isParticipantReadOnly) {
		[button setAllImages:[NSImage imageNamed:@"ParticipantReadOnlyStatusOn"]];
	} else {
		button.alphaValue = 0.0;
	}
	
	button = self.followUserButtonOutlet.animator;
	if (self.isParticipantFollowed) {
		[button setAllImages:[NSImage imageNamed:@"ParticipantFollowStatusOn"]];
	} else {
		button.alphaValue = 0.0;
	}

	[self.nameLabelPopoverOutlet close];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	[self showUIOverlay];
}

- (void)mouseExited:(NSEvent *)theEvent {
	switch (self.viewMode) {
		case SEEParticipantViewModeInvited:
		case SEEParticipantViewModeParticipant:
			[self hideUIOverlay];
			break;
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
		} else if ([[invitedUsers objectForKey:TCMMMSessionReadWriteGroupName] containsObject:user] ||
				   [[invitedUsers objectForKey:TCMMMSessionReadOnlyGroupName]  containsObject:user]) {
			[documentSession cancelInvitationForUserWithID:[user userID]];
		} else if ([[participants objectForKey:TCMMMSessionReadWriteGroupName] containsObject:user] ||
				   [[participants objectForKey:TCMMMSessionReadOnlyGroupName]  containsObject:user]) {
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
		if (self.isShowingUIOverlay) {
			[self hideUIOverlay];
		}
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
	BOOL isServer = self.tabContext.document.session.isServer;
	if (self.participant.isMe) {
		// remove all buttons
		self.readWriteUserButtonOutlet.hidden = isServer;
		self.kickUserButtonOutlet.hidden = YES;
		self.followUserButtonOutlet.hidden = YES;
		if (!isServer) {
			[self updateParticipantReadOnly];
		}
	} else {
		if (isServer) {
			self.kickUserButtonOutlet.hidden = NO;
			self.readWriteUserButtonOutlet.hidden = NO;
		} else {
			self.kickUserButtonOutlet.hidden = YES;
			self.readWriteUserButtonOutlet.hidden = YES;
		}

		[self updateParticipantFollowed];
		[self updateParticipantReadOnly];

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
	TCMHoverButton *followButton = self.followUserButtonOutlet.animator;
	if (self.isShowingUIOverlay) {
		if (self.isParticipantFollowedInActiveEditor) {
			[followButton setImagesByPrefix:@"ParticipantFollowTurnOff"];
		} else {
			[followButton setImagesByPrefix:@"ParticipantFollowTurnOn"];
		}
	} else {
		if (self.isParticipantFollowed) {
			[self.followUserButtonOutlet setAllImages:[NSImage imageNamed:@"ParticipantFollowStatusOn"]];
			followButton.alphaValue = 1.0;
		} else {
			followButton.alphaValue = 0.0;
		}
	}
}

- (void)updateParticipantReadOnly {
	BOOL isReadOnly = [self isParticipantReadOnly];
	TCMHoverButton *readWriteButton = self.readWriteUserButtonOutlet;
	if (self.isShowingUIOverlay) {
		if (isReadOnly) {
			[readWriteButton setImagesByPrefix:@"ParticipantReadOnlyTurnOff"];
		} else {
			[readWriteButton setImagesByPrefix:@"ParticipantReadOnlyTurnOn"];
		}
	} else {
		if (isReadOnly) {
			[self.readWriteUserButtonOutlet setAllImages:[NSImage imageNamed:@"ParticipantReadOnlyStatusOn"]];
			readWriteButton.alphaValue = 1.0;
		} else {
			readWriteButton.alphaValue = 0.0;
		}
	}
	
}

- (BOOL)isParticipantFollowedInActiveEditor {
	// update action button state
	PlainTextWindowController *windowController = self.view.window.windowController;
	PlainTextEditor *activeEditor = windowController.activePlainTextEditor;
	TCMMMUser *user = self.participant;
	
	BOOL activeEditorIsFollowing = [activeEditor.followUserID isEqualToString:user.userID];
	return activeEditorIsFollowing;
}

- (BOOL)isParticipantReadOnly {
	BOOL result = NO;
	TCMMMSession *documentSession = self.tabContext.document.session;
	NSDictionary *participants = documentSession.participants;
	NSDictionary *invitedUsers = documentSession.invitedUsers;
	//	NSArray *pendingUsers = documentSession.pendingUsers;
	TCMMMUser *user = self.participant;
	result = ([[participants objectForKey:TCMMMSessionReadOnlyGroupName] containsObject:user] ||
			  [[invitedUsers objectForKey:TCMMMSessionReadOnlyGroupName] containsObject:user]);
	return result;
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
/*
	if (! self.tabContext.document.session.isServer) {
		self.participantActionOverlayOutlet = nil;
	} else {
		//		[self.toggleEditModeButtonOutlet removeFromSuperview];
		//[self.toggleFollowButtonOutlet removeFromSuperview];
		
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
 */
}

@end
