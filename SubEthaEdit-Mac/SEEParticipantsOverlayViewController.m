//
//  SEEParticipantsOverlayViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 28.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//


// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


#import "SEEParticipantsOverlayViewController.h"
#import "SEEParticipantViewController.h"
#import "PlainTextDocument.h"

@interface SEEParticipantsOverlayViewController ()
@property (nonatomic, weak) PlainTextDocument *document;
@property (nonatomic, strong) NSMutableArray *subviewControllers;
@end

@implementation SEEParticipantsOverlayViewController

- (id)initWithDocument:(PlainTextDocument *)document
{
    self = [super initWithNibName:@"SEEParticipantsOverlay" bundle:[NSBundle mainBundle]];
    if (self) {
		self.document = document;

		TCMMMSession *documentSession = document.session;

		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(documentSessionDidChange:) name:TCMMMSessionParticipantsDidChangeNotification object:documentSession];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(documentSessionDidChange:) name:TCMMMSessionPendingInvitationsDidChange object:documentSession];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(documentSessionDidChange:) name:TCMMMSessionPendingUsersDidChangeNotification object:documentSession];

		self.subviewControllers = [NSMutableArray array];
	}
    return self;
}


- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)loadView {
	[super loadView];

	NSView *view = self.view;
	view.layer.borderColor = [[NSColor lightGrayColor] CGColor];
	view.layer.borderWidth = 0.5;

	[self update];
}


- (void)documentSessionDidChange:(NSNotification *)notification {
	if (self.document.session == notification.object) {
		[self update];
	}
}


- (void)update {
	// cleanup old view hierachy
	NSArray *subviews = [self.view.subviews copy];
	[subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[self.subviewControllers removeAllObjects];

	// install new subviews for all allContributors
	NSView *view = self.view;
	TCMMMSession *session = self.document.session;
	TCMMMUser *me = [TCMMMUserManager me];

	{
		SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:me];
		[self.subviewControllers addObject:participantViewController];
		[view addSubview:participantViewController.view];
		NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																				attribute:NSLayoutAttributeLeading
																				relatedBy:NSLayoutRelationEqual
																				   toItem:view
																				attribute:NSLayoutAttributeLeft
																			   multiplier:1
																				 constant:6];

		NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																			  attribute:NSLayoutAttributeTop
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:view
																			  attribute:NSLayoutAttributeTop
																			 multiplier:1
																			   constant:0];

		[view addConstraints:@[horizontalConstraint, verticalConstraint]];
		[participantViewController updateForParticipantUserState];
	}
	{
		NSMutableArray *allParticipants = [[session.participants objectForKey:TCMMMSessionReadWriteGroupName] mutableCopy];
		[allParticipants addObjectsFromArray:[session.participants objectForKey:TCMMMSessionReadOnlyGroupName]];
		for (TCMMMUser *user in allParticipants) {
			if (user == me) continue;

			SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user];

			NSView *lastUserView = [self.subviewControllers.lastObject view];
			[self.subviewControllers addObject:participantViewController];
			[view addSubview:participantViewController.view];
			NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																					attribute:NSLayoutAttributeLeft
																					relatedBy:NSLayoutRelationEqual
																					   toItem:lastUserView
																					attribute:NSLayoutAttributeRight
																				   multiplier:1
																					 constant:6];

			NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																				  attribute:NSLayoutAttributeTop
																				  relatedBy:NSLayoutRelationEqual
																					 toItem:view
																				  attribute:NSLayoutAttributeTop
																				 multiplier:1
																				   constant:0];

			[view addConstraints:@[horizontalConstraint, verticalConstraint]];
			[participantViewController updateForParticipantUserState];
		}
	}
	{
		NSMutableArray *allInvitees = [[session.invitedUsers objectForKey:TCMMMSessionReadWriteGroupName] mutableCopy];
		[allInvitees addObjectsFromArray:[session.invitedUsers objectForKey:TCMMMSessionReadOnlyGroupName]];
		for (TCMMMUser *user in allInvitees) {
			if (user == me) continue;

			NSString *stateOfInvitee = [session stateOfInvitedUserById:user.userID];
			if ([stateOfInvitee isEqualToString:TCMMMSessionInvitedUserStateAwaitingResponse]) {
				SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user];

				NSView *lastUserView = [self.subviewControllers.lastObject view];
				[self.subviewControllers addObject:participantViewController];
				[view addSubview:participantViewController.view];
				NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																						attribute:NSLayoutAttributeLeft
																						relatedBy:NSLayoutRelationEqual
																						   toItem:lastUserView
																						attribute:NSLayoutAttributeRight
																					   multiplier:1
																						 constant:6];

				NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																					  attribute:NSLayoutAttributeTop
																					  relatedBy:NSLayoutRelationEqual
																						 toItem:view
																					  attribute:NSLayoutAttributeTop
																					 multiplier:1
																					   constant:0];

				[view addConstraints:@[horizontalConstraint, verticalConstraint]];
				[participantViewController updateForInvitationState];
			} else {
				// TODO: remove declined users here
				NSUserNotification *userNotification = [[NSUserNotification alloc] init];
				userNotification.hasActionButton = NO;
				userNotification.title = [NSString stringWithFormat:NSLocalizedString(@"%@ declined your invitation.", @"User Notification title if a invited user declines your invitation."), user.name];
				[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];

				// add user too poof group...
			}
		}
	}
	{
		NSArray *allPendingUsers = session.pendingUsers;
		for (TCMMMUser *user in allPendingUsers) {
			if (user == me) continue;

			SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user];

			NSView *lastUserView = [self.subviewControllers.lastObject view];
			[self.subviewControllers addObject:participantViewController];
			[view addSubview:participantViewController.view];
			NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																					attribute:NSLayoutAttributeLeft
																					relatedBy:NSLayoutRelationEqual
																					   toItem:lastUserView
																					attribute:NSLayoutAttributeRight
																				   multiplier:1
																					 constant:6];

			NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																				  attribute:NSLayoutAttributeTop
																				  relatedBy:NSLayoutRelationEqual
																					 toItem:view
																				  attribute:NSLayoutAttributeTop
																				 multiplier:1
																				   constant:0];

			[view addConstraints:@[horizontalConstraint, verticalConstraint]];
			[participantViewController updateForPendingUserState];
		}
	}
}

@end
