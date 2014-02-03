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
@property (nonatomic, strong) NSMutableArray *participantSubviewControllers;
@property (nonatomic, strong) NSMutableArray *inviteeSubviewControllers;
@property (nonatomic, strong) NSMutableArray *pendingSubviewControllers;
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

		self.participantSubviewControllers = [NSMutableArray array];
		self.inviteeSubviewControllers = [NSMutableArray array];
		self.pendingSubviewControllers = [NSMutableArray array];
	}
    return self;
}


- (void)dealloc {
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
	[self.participantSubviewControllers removeAllObjects];
	[self.inviteeSubviewControllers removeAllObjects];
	[self.pendingSubviewControllers removeAllObjects];

	// install new subviews for all allContributors
	NSView *view = self.view;
	TCMMMSession *session = self.document.session;
	TCMMMUser *me = [TCMMMUserManager me];

	// me
	{
		SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:me];
		[self.participantSubviewControllers addObject:participantViewController];
		[view addSubview:participantViewController.view];
		NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																				attribute:NSLayoutAttributeLeft
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

	// Participants working on the document
	{
		NSMutableArray *allParticipants = [[session.participants objectForKey:TCMMMSessionReadWriteGroupName] mutableCopy];
		[allParticipants addObjectsFromArray:[session.participants objectForKey:TCMMMSessionReadOnlyGroupName]];
		for (TCMMMUser *user in allParticipants) {
			if (user == me) continue;

			SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user];

			NSView *lastUserView = [self.participantSubviewControllers.lastObject view];
			[self.participantSubviewControllers addObject:participantViewController];
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

	NSView *spacerView = [[NSView alloc] init];
	[spacerView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[view addSubview:spacerView];
	NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintWithItem:spacerView
																		  attribute:NSLayoutAttributeTop
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:view
																		  attribute:NSLayoutAttributeTop
																		 multiplier:1
																		   constant:0];
	NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:spacerView
																		attribute:NSLayoutAttributeHeight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:view
																		attribute:NSLayoutAttributeHeight
																	   multiplier:1
																		 constant:0];

	NSView *lastParticipantView = [[self.participantSubviewControllers lastObject] view];
	if (lastParticipantView == nil) {
		lastParticipantView = view;
	}
	NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:spacerView
																			attribute:NSLayoutAttributeLeft
																			relatedBy:NSLayoutRelationEqual
																			   toItem:lastParticipantView
																			attribute:NSLayoutAttributeRight
																		   multiplier:1
																			 constant:6];
	NSLayoutConstraint *witdhConstraint = [NSLayoutConstraint constraintWithItem:spacerView
																	   attribute:NSLayoutAttributeWidth
																	   relatedBy:NSLayoutRelationGreaterThanOrEqual
																		  toItem:nil
																	   attribute:NSLayoutAttributeNotAnAttribute
																	  multiplier:1
																		constant:0];
	[view addConstraints:@[verticalConstraint, heightConstraint, horizontalConstraint, witdhConstraint]];

	// Invited user waiting to be accepted
	{
		NSMutableArray *allInvitees = [[session.invitedUsers objectForKey:TCMMMSessionReadWriteGroupName] mutableCopy];
		[allInvitees addObjectsFromArray:[session.invitedUsers objectForKey:TCMMMSessionReadOnlyGroupName]];
		for (TCMMMUser *user in allInvitees) {
			if (user == me) continue;

			NSString *stateOfInvitee = [session stateOfInvitedUserById:user.userID];
			if ([stateOfInvitee isEqualToString:TCMMMSessionInvitedUserStateAwaitingResponse]) {
				SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user];

				NSView *lastUserView = [self.inviteeSubviewControllers.lastObject view];
				if (!lastUserView) {
					lastUserView = spacerView;
				}
				[self.inviteeSubviewControllers addObject:participantViewController];
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
				// Move invited user to
				NSUserNotification *userNotification = [[NSUserNotification alloc] init];
				userNotification.hasActionButton = NO;
				userNotification.title = NSLocalizedString(@"User declined invitation.", @"User Notification title if a invited user declines your invitation.");
				userNotification.subtitle = [NSString stringWithFormat:NSLocalizedString(@"%@ did not join %@.", @"User Notification subtitle if a invited user declines your invitation."), user.name, self.document.displayName];
				[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];

				// Let's do it async for now, because the old drawer causes crashes if the user is removed before it updates.
				[session performSelector:@selector(cancelInvitationForUserWithID:) withObject:user.userID afterDelay:0.1];
			}
		}
	}

	NSView *secondSpacerView = [[NSView alloc] init];
	[secondSpacerView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[view addSubview:secondSpacerView];
	verticalConstraint = [NSLayoutConstraint constraintWithItem:secondSpacerView
													  attribute:NSLayoutAttributeTop
													  relatedBy:NSLayoutRelationEqual
														 toItem:view
													  attribute:NSLayoutAttributeTop
													 multiplier:1
													   constant:0];
	heightConstraint = [NSLayoutConstraint constraintWithItem:secondSpacerView
													attribute:NSLayoutAttributeHeight
													relatedBy:NSLayoutRelationEqual
													   toItem:view
													attribute:NSLayoutAttributeHeight
												   multiplier:1
													 constant:0];

	NSView *lastInviteeView = [[self.inviteeSubviewControllers lastObject] view];
	if (lastInviteeView == nil) {
		lastInviteeView = spacerView;
	}
	horizontalConstraint = [NSLayoutConstraint constraintWithItem:secondSpacerView
														attribute:NSLayoutAttributeLeft
														relatedBy:NSLayoutRelationEqual
														   toItem:lastInviteeView
														attribute:NSLayoutAttributeRight
													   multiplier:1
														 constant:6];
	witdhConstraint = [NSLayoutConstraint constraintWithItem:secondSpacerView
												   attribute:NSLayoutAttributeWidth
												   relatedBy:NSLayoutRelationEqual
													  toItem:spacerView
												   attribute:NSLayoutAttributeWidth
												  multiplier:1
													constant:0];
	[view addConstraints:@[verticalConstraint, heightConstraint, horizontalConstraint, witdhConstraint]];

	// Pending users to be accepted
	{
		NSArray *allPendingUsers = session.pendingUsers;
		for (TCMMMUser *user in allPendingUsers) {
			if (user == me) continue;

			SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user];

			NSView *lastUserView = [self.pendingSubviewControllers.lastObject view];
			if (!lastUserView) {
				lastUserView = secondSpacerView;
			}
			[self.pendingSubviewControllers addObject:participantViewController];
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

	// pin last subview to the right edge of its superview
	NSView *lastSubview = [[view subviews] lastObject];
	NSLayoutConstraint *pinToRightConstraint = [NSLayoutConstraint constraintWithItem:lastSubview
																			attribute:NSLayoutAttributeRight
																			relatedBy:NSLayoutRelationEqual
																			   toItem:view
																			attribute:NSLayoutAttributeRight
																		   multiplier:1
																			 constant:-6];
	[view addConstraint:pinToRightConstraint];

}

@end
