//
//  SEENetworkBrowser.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEENetworkBrowser.h"
#import "SEENetworkDocumentRepresentation.h"

#import "TCMMMPresenceManager.h"
#import "TCMMMSession.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"

@interface SEENetworkBrowser ()
@property (assign) IBOutlet NSArrayController *collectionViewArrayController;
@property (nonatomic, weak) id userSessionsDidChangeObserver;
@property (nonatomic, weak) id otherWindowsBecomeKeyNotifivationObserver;
@end

@implementation SEENetworkBrowser

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
		self.availableDocumentSessions = [NSMutableArray array];
		[self reloadAllDocumentSessions];

		__weak __typeof__(self) weakSelf = self;
		self.userSessionsDidChangeObserver =
		[[NSNotificationCenter defaultCenter] addObserverForName:TCMMMPresenceManagerUserSessionsDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			__typeof__(self) strongSelf = weakSelf;
			[strongSelf reloadAllDocumentSessions];
		}];

		self.otherWindowsBecomeKeyNotifivationObserver =
		[[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			__typeof__(self) strongSelf = weakSelf;
			if (note.object != strongSelf.window && strongSelf.shouldCloseWhenOpeningDocument) {
				if ([NSApp modalWindow] == strongSelf.window) {
					[NSApp stopModalWithCode:NSModalResponseAbort];
				}
				[self close];
			}
		}];
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.userSessionsDidChangeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.otherWindowsBecomeKeyNotifivationObserver];
}


- (void)windowDidLoad
{
    [super windowDidLoad];
}


- (void)windowWillClose:(NSNotification *)notification {
	if ([NSApp modalWindow] == notification.object) {
		[NSApp stopModalWithCode:NSModalResponseAbort];
	}
}


- (NSInteger)runModal {
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
}


- (void)reloadAllDocumentSessions
{
	[self willChangeValueForKey:@"availableDocumentSessions"];
	{
		[self.availableDocumentSessions removeAllObjects];
		NSArray *allUserStatusDicts = [[TCMMMPresenceManager sharedInstance] allUsers];
		for (NSMutableDictionary *statusDict in allUserStatusDicts) {
			NSArray *sessions = [statusDict objectForKey:TCMMMPresenceOrderedSessionsKey];
			for (TCMMMSession *session in sessions) {
				SEENetworkDocumentRepresentation *documentRepresentation = [[SEENetworkDocumentRepresentation alloc] init];
				documentRepresentation.documentSession = session;
				
				NSString *userID = [statusDict objectForKey:TCMMMPresenceUserIDKey];
				TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:userID];
				documentRepresentation.documentOwner = user;

				documentRepresentation.fileName = session.filename;
				[self.availableDocumentSessions addObject:documentRepresentation];
			}
		}
	}
	[self didChangeValueForKey:@"availableDocumentSessions"];
}


- (IBAction)newDocument:(id)sender {
	if (self.shouldCloseWhenOpeningDocument) {
		if ([NSApp modalWindow] == self.window) {
			[NSApp stopModalWithCode:NSModalResponseCancel];
		}
		[self close];
	}
	[[NSDocumentController sharedDocumentController] newDocument:sender];
}


- (IBAction)joinDocument:(id)sender {
	if (self.shouldCloseWhenOpeningDocument) {
		if ([NSApp modalWindow] == self.window) {
			[NSApp stopModalWithCode:NSModalResponseOK];
		}
		[self close];
	}
	SEENetworkDocumentRepresentation *documentRepresentation = self.collectionViewArrayController.selectedObjects.firstObject;
	[documentRepresentation joinDocument:sender];
}

@end
