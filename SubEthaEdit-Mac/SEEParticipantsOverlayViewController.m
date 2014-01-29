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
	// cleanup old vie hierachy
	NSArray *subviews = [self.view.subviews copy];
	[subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[self.subviewControllers removeAllObjects];

	// install new subviews for all allContributors
	NSView *view = self.view;
	TCMMMUser *me = [TCMMMUserManager me];
	SEEParticipantViewController *participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:me];
	[self.subviewControllers addObject:participantViewController];
	[participantViewController.view setFrameOrigin:NSMakePoint(6.0, 0.0)];
	[view addSubview:participantViewController.view];

	NSArray *allParticipants = [self.document.session.participants objectForKey:@"ReadWrite"];
	CGFloat userWidth = 12.0 + 100.0;
	CGFloat userXOffset = 6.0 + 100.0 + 6.0;
	for (TCMMMUser *user in allParticipants) {
		if (user == me) continue;

		participantViewController = [[SEEParticipantViewController alloc] initWithParticipant:user];
		[self.subviewControllers addObject:participantViewController];
		[participantViewController.view setFrameOrigin:NSMakePoint(userXOffset + 6.0, 0.0)];
		userXOffset += userWidth;
		[view addSubview:participantViewController.view];
	}
}

@end
