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
#import "PlainTextWindowControllerTabContext.h"
#import "PlainTextDocument.h"
#import "SEEOverlayView.h"

@interface SEEParticipantsOverlayViewController ()
@property (nonatomic, weak) IBOutlet NSView *participantsContainerView;
@property (nonatomic, weak) IBOutlet NSView *topLineView;

@property (nonatomic, weak) PlainTextWindowControllerTabContext *tabContext;

@property (nonatomic, strong) NSMutableArray *participantSubviewControllers;
@property (nonatomic, strong) NSMutableArray *inviteeSubviewControllers;
@property (nonatomic, strong) NSMutableArray *pendingSubviewControllers;

@property (nonatomic, weak) id scrollerStyleObserver;
@property (nonatomic, strong) NSDate *lastScrollerFlashDate;

@end

@implementation SEEParticipantsOverlayViewController

- (id)initWithTabContext:(PlainTextWindowControllerTabContext *)aTabContext
{
    self = [super initWithNibName:@"SEEParticipantsOverlay" bundle:[NSBundle mainBundle]];
    if (self) {
		self.tabContext = aTabContext;

		[self sessionDidChange:nil];
		
		PlainTextDocument *document = self.tabContext.document;
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(sessionWillChange:) name:PlainTextDocumentSessionWillChangeNotification object:document];
		[center addObserver:self selector:@selector(sessionDidChange:) name:PlainTextDocumentSessionDidChangeNotification object:document];

		__weak __typeof__(self) weakSelf = self;
		self.scrollerStyleObserver = [center addObserverForName:NSPreferredScrollerStyleDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			__typeof__(self) strongSelf = weakSelf;

			if ([NSScroller preferredScrollerStyle] == NSScrollerStyleLegacy) {
				NSScrollView *participantScrollView = strongSelf.participantsContainerView.enclosingScrollView;
				participantScrollView.scrollerStyle = NSScrollerStyleOverlay;
			}
		}];
		
		self.participantSubviewControllers = [NSMutableArray array];
		self.inviteeSubviewControllers = [NSMutableArray array];
		self.pendingSubviewControllers = [NSMutableArray array];
	}
    return self;
}


- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self.scrollerStyleObserver];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)loadView {
	[super loadView];

	NSView *view = self.view;
	view.layer.backgroundColor = [[NSColor brightOverlayBackgroundColorBackgroundIsDark:NO] CGColor];
	self.topLineView.layer.backgroundColor = [[NSColor brightOverlaySeparatorColorBackgroundIsDark:NO] CGColor];

	if ([NSScroller preferredScrollerStyle] == NSScrollerStyleLegacy) {
		NSScrollView *participantScrollView = self.participantsContainerView.enclosingScrollView;
		participantScrollView.scrollerStyle = NSScrollerStyleOverlay;
	}
	
	[self.view addTrackingArea:[[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect owner:self userInfo:nil]];

	[self update];
}


#pragma mark - Mouse Tracking

- (void)mouseEntered:(NSEvent *)theEvent {
	if ([NSScroller preferredScrollerStyle] == NSScrollerStyleLegacy) {
		NSDate *currentDate = [NSDate date]; // avoid to many calls to flashScrollers, behaviour is confusing...
		if (! self.lastScrollerFlashDate || [currentDate timeIntervalSinceDate:self.lastScrollerFlashDate] > 1.0) {
			NSScrollView *participantScrollView = self.participantsContainerView.enclosingScrollView;
			[participantScrollView flashScrollers];
			self.lastScrollerFlashDate = currentDate;
		}
	}
}

#pragma mark
- (void)sessionWillChange:(NSNotification *)aNotification {
	TCMMMSession *documentSession = self.tabContext.document.session;
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center removeObserver:self name:TCMMMSessionParticipantsDidChangeNotification object:documentSession];
	[center removeObserver:self name:TCMMMSessionPendingInvitationsDidChange object:documentSession];
	[center removeObserver:self name:TCMMMSessionPendingUsersDidChangeNotification object:documentSession];
}

- (void)sessionDidChange:(NSNotification *)aNotification {
	TCMMMSession *documentSession = self.tabContext.document.session;
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(documentSessionDidChange:) name:TCMMMSessionParticipantsDidChangeNotification object:documentSession];
	[center addObserver:self selector:@selector(documentSessionDidChange:) name:TCMMMSessionPendingInvitationsDidChange object:documentSession];
	[center addObserver:self selector:@selector(documentSessionDidChange:) name:TCMMMSessionPendingUsersDidChangeNotification object:documentSession];

	if (self.tabContext.document == aNotification.object) {
		[self update];
	}
}

#pragma mark
- (void)documentSessionDidChange:(NSNotification *)notification {
	if (self.tabContext.document.session == notification.object) {
		[self update];
	}
}


- (void)update {
	NSView *view = self.participantsContainerView;

	// cleanup old view hierachy
	NSArray *subviews = [view.subviews copy];
	NSView *topLineView = self.topLineView;
	for (NSView *subview in subviews) {
		if (subview != topLineView) {
			[subview removeFromSuperview];
		}
	}
	[self.participantSubviewControllers removeAllObjects];
	[self.inviteeSubviewControllers removeAllObjects];
	[self.pendingSubviewControllers removeAllObjects];

	// install new subviews for all allContributors
	TCMMMSession *session = self.tabContext.document.session;

	// Participants working on the document
	{
		NSMutableArray *allParticipants = [[session.participants objectForKey:TCMMMSessionReadWriteGroupName] mutableCopy];
		[allParticipants addObjectsFromArray:[session.participants objectForKey:TCMMMSessionReadOnlyGroupName]];

//		// code to test scrollview... 
//		for (NSInteger index = 0; index < 20; index++) {
//			[allParticipants addObject:allParticipants.lastObject];
//		}

		for (TCMMMUser *user in allParticipants) {
			SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user tabContext:self.tabContext inMode:SEEParticipantViewModeParticipant];

			NSView *lastUserView = [self.participantSubviewControllers.lastObject view];
			NSLayoutAttribute lastUserViewLayoutAttribute = NSLayoutAttributeRight;
			if (!lastUserView) {
				lastUserView = view;
				lastUserViewLayoutAttribute = NSLayoutAttributeLeft;
			}
			[self.participantSubviewControllers addObject:participantViewController];

			NSView *participantView = participantViewController.view;
//			participantView.layer.borderColor = [[NSColor redColor] CGColor];
//			participantView.layer.borderWidth = 1.0;
			[view addSubview:participantView];

			NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:participantViewController.view
																					attribute:NSLayoutAttributeLeft
																					relatedBy:NSLayoutRelationEqual
																					   toItem:lastUserView
																					attribute:lastUserViewLayoutAttribute
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
	witdhConstraint.priority = NSLayoutPriorityRequired;
	[view addConstraints:@[verticalConstraint, heightConstraint, horizontalConstraint, witdhConstraint]];

//	spacerView.layer.borderWidth = 1;
//	spacerView.layer.borderColor = [[NSColor redColor] CGColor];

	// Invited user waiting to be accepted
	{
		NSMutableArray *allInvitees = [[session.invitedUsers objectForKey:TCMMMSessionReadWriteGroupName] mutableCopy];
		[allInvitees addObjectsFromArray:[session.invitedUsers objectForKey:TCMMMSessionReadOnlyGroupName]];
		for (TCMMMUser *user in allInvitees) {
			NSString *stateOfInvitee = [session stateOfInvitedUserById:user.userID];
			if ([stateOfInvitee isEqualToString:TCMMMSessionInvitedUserStateAwaitingResponse]) {
				SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user tabContext:self.tabContext inMode:SEEParticipantViewModeInvited];

				NSView *lastUserView = [self.inviteeSubviewControllers.lastObject view];
				if (!lastUserView) {
					lastUserView = spacerView;
				}
				[self.inviteeSubviewControllers addObject:participantViewController];

				NSView *participantView = participantViewController.view;
//				participantView.layer.borderColor = [[NSColor redColor] CGColor];
//				participantView.layer.borderWidth = 1.0;
				[view addSubview:participantView];

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
			} else {
				// Move invited user to
				NSUserNotification *userNotification = [[NSUserNotification alloc] init];
				userNotification.hasActionButton = NO;
				userNotification.title = NSLocalizedString(@"User declined invitation.", @"User Notification title if a invited user declines your invitation.");
				userNotification.subtitle = [NSString stringWithFormat:NSLocalizedString(@"%@ did not join %@.", @"User Notification subtitle if a invited user declines your invitation."), user.name, self.tabContext.document.displayName];
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
	witdhConstraint.priority = NSLayoutPriorityRequired;
	[view addConstraints:@[verticalConstraint, heightConstraint, horizontalConstraint, witdhConstraint]];

//	secondSpacerView.layer.borderWidth = 1;
//	secondSpacerView.layer.borderColor = [[NSColor redColor] CGColor];

	// Pending users to be accepted
	{
		NSArray *allPendingUsers = session.pendingUsers;
		for (TCMMMUser *user in allPendingUsers) {
			SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user tabContext:self.tabContext inMode:SEEParticipantViewModePending];

			NSView *lastUserView = [self.pendingSubviewControllers.lastObject view];
			if (!lastUserView) {
				lastUserView = secondSpacerView;
			}
			[self.pendingSubviewControllers addObject:participantViewController];

			NSView *participantView = participantViewController.view;
//			participantView.layer.borderColor = [[NSColor redColor] CGColor];
//			participantView.layer.borderWidth = 1.0;
			[view addSubview:participantView];

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


- (void)updateColorsForIsDarkBackground:(BOOL)isDark {
	for (SEEParticipantViewController *controller in self.participantSubviewControllers) {
		[controller updateColorsForIsDarkBackground:isDark];
	}

	for (SEEParticipantViewController *controller in self.inviteeSubviewControllers) {
		[controller updateColorsForIsDarkBackground:isDark];
	}

	for (SEEParticipantViewController *controller in self.pendingSubviewControllers) {
		[controller updateColorsForIsDarkBackground:isDark];
	}
}

@end
