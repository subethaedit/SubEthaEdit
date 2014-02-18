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
#import "TCMMMUser.h"

@interface SEENetworkBrowser ()
@property (assign) IBOutlet NSArrayController *collectionViewArrayController;
@property (nonatomic, weak) id userSessionsDidChangeObserver;
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
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.userSessionsDidChangeObserver];
}


- (void)windowDidLoad
{
    [super windowDidLoad];
}


- (void)reloadAllDocumentSessions
{
	[self willChangeValueForKey:@"availableDocumentSessions"];
	{
		[self.availableDocumentSessions removeAllObjects];
		NSArray *allUserStatusDicts = [[TCMMMPresenceManager sharedInstance] allUsers];
		for (NSMutableDictionary *statusDict in allUserStatusDicts) {
			NSArray *sessions = [statusDict objectForKey:@"OrderedSessions"];
			for (TCMMMSession *session in sessions) {
				SEENetworkDocumentRepresentation *documentRepresentation = [[SEENetworkDocumentRepresentation alloc] init];
				documentRepresentation.representedObject = session;
				documentRepresentation.fileName = session.filename;
				[self.availableDocumentSessions addObject:documentRepresentation];
			}
		}
	}
	[self didChangeValueForKey:@"availableDocumentSessions"];
}

- (IBAction)joinSelectedDocument:(id)sender {
	SEENetworkDocumentRepresentation *documentRepresentation = self.collectionViewArrayController.selectedObjects.firstObject;

	if (documentRepresentation) {
		
	}
}
@end
