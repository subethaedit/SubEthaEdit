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
#import "SEENetworkBrowserGroupTableRowView.h"
#import "SEENetworkDocumentRepresentation.h"

#import "DocumentController.h"
#import "DocumentModeManager.h"

#import "TCMMMPresenceManager.h"
#import "TCMMMSession.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

extern int const FileMenuTag;
extern int const FileNewMenuItemTag;

@interface SEENetworkBrowser () <NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSImageView *userImageViewPrototype;

@property (nonatomic, weak) IBOutlet NSObjectController *filesOwnerProxy;
@property (nonatomic, weak) IBOutlet NSArrayController *collectionViewArrayController;

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

	[self close];
}


- (void)windowDidLoad
{
    [super windowDidLoad];

	self.filesOwnerProxy.content = self;
}


- (void)windowWillClose:(NSNotification *)notification
{
	if ([NSApp modalWindow] == notification.object) {
		[NSApp stopModalWithCode:NSModalResponseAbort];
	}

	self.filesOwnerProxy.content = nil;
}


- (NSInteger)runModal
{
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
}


#pragma mark Content management

- (void)reloadAllDocumentSessions
{
	[self willChangeValueForKey:@"availableDocumentSessions"];
	{
		[self.availableDocumentSessions removeAllObjects];
		NSArray *allUserStatusDicts = [[TCMMMPresenceManager sharedInstance] allUsers];
		for (NSMutableDictionary *statusDict in allUserStatusDicts) {
			NSString *userID = [statusDict objectForKey:TCMMMPresenceUserIDKey];
			TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:userID];

			// fake document for user...
			SEENetworkDocumentRepresentation *documentRepresentation = [[SEENetworkDocumentRepresentation alloc] init];
			documentRepresentation.documentOwner = user;
			documentRepresentation.fileName = user.name;
			documentRepresentation.fileIcon = user.image;
			[self.availableDocumentSessions addObject:documentRepresentation];

			NSArray *sessions = [statusDict objectForKey:TCMMMPresenceOrderedSessionsKey];
			for (TCMMMSession *session in sessions) {
				SEENetworkDocumentRepresentation *documentRepresentation = [[SEENetworkDocumentRepresentation alloc] init];
				documentRepresentation.documentSession = session;
				documentRepresentation.documentOwner = user;
				documentRepresentation.fileName = session.filename;
				[self.availableDocumentSessions addObject:documentRepresentation];
			}
		}
	}
	[self didChangeValueForKey:@"availableDocumentSessions"];
}


#pragma mark IBActions

- (IBAction)newDocument:(id)sender
{
	if (self.shouldCloseWhenOpeningDocument) {
		if ([NSApp modalWindow] == self.window) {
			[NSApp stopModalWithCode:NSModalResponseCancel];
		}
		[self close];
	}

	NSMenu *menu=[[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
    NSMenuItem *menuItem=[menu itemWithTag:FileNewMenuItemTag];
    menu = [menuItem submenu];
    NSMenuItem *item = (NSMenuItem *)[menu itemWithTag:[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]]];

	[[NSDocumentController sharedDocumentController] newDocumentWithModeMenuItem:item];
}


- (IBAction)joinDocument:(id)sender
{
	if (self.shouldCloseWhenOpeningDocument) {
		if ([NSApp modalWindow] == self.window) {
			[NSApp stopModalWithCode:NSModalResponseOK];
		}
		[self close];
	}

	NSArray *selectedDocuments = self.collectionViewArrayController.selectedObjects;
	[selectedDocuments makeObjectsPerformSelector:@selector(joinDocument:) withObject:sender];
}


#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSView *result = nil;
	if (tableColumn == nil) {
		result = [tableView makeViewWithIdentifier:@"Group" owner:self];
	} else {
		result = [tableView makeViewWithIdentifier:@"Document" owner:self];
	}
	return result;
}

//- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
//{
//	NSTableRowView * rowView = nil;
//	NSArray *availableDocumentSession = self.availableDocumentSessions;
//	SEENetworkDocumentRepresentation *documentRepresentation = [availableDocumentSession objectAtIndex:row];
//	if (documentRepresentation && !documentRepresentation.documentSession) {
//		rowView = [[SEENetworkBrowserGroupTableRowView alloc] init];
////		rowView.backgroundColor = [NSColor yellowColor];
//	}
//	return rowView;
//}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
	NSArray *availableDocumentSession = self.availableDocumentSessions;
	SEENetworkDocumentRepresentation *documentRepresentation = [availableDocumentSession objectAtIndex:row];
	if (documentRepresentation && !documentRepresentation.documentSession) {
		rowView.layer.masksToBounds = NO;
		NSImageView *userImageView = [[[rowView.subviews objectAtIndex:0] subviews] objectAtIndex:1];
		CALayer *userViewLayer = userImageView.layer;
		userViewLayer.borderColor = [[NSColor yellowColor] CGColor];
		userViewLayer.borderWidth = NSHeight(userImageView.frame) / 16.0;
		userViewLayer.cornerRadius = NSHeight(userImageView.frame) / 2.0;
	}
}

- (void)tableView:(NSTableView *)tableView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {

}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
	BOOL result = NO;
	NSArray *availableDocumentSession = self.availableDocumentSessions;
	SEENetworkDocumentRepresentation *documentRepresentation = [availableDocumentSession objectAtIndex:row];
	if (documentRepresentation && !documentRepresentation.documentSession) {
		result = YES;
	}
	return result;
}

- (CGFloat)tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row {
	CGFloat result = 24.0;
	NSArray *availableDocumentSession = self.availableDocumentSessions;
	SEENetworkDocumentRepresentation *documentRepresentation = [availableDocumentSession objectAtIndex:row];
	if (documentRepresentation && !documentRepresentation.documentSession) {
		result = 36.0;
	}
	return result;
}



@end
