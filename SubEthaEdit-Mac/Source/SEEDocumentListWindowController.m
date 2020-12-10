//  SEEDocumentListWindowController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.

#import "SEEDocumentListWindowController.h"
#import "SEEDocumentListGroupTableRowView.h"
#import "SEEDividerTableRowView.h"

#import "SEENetworkConnectionRepresentationListItem.h"
#import "SEENetworkDocumentListItem.h"
#import "SEEToggleRecentDocumentListItem.h"
#import "SEEMoreRecentDocumentsListItem.h"
#import "SEERecentDocumentListItem.h"
#import "SEEDividerListItem.h"

#import "SEEAvatarImageView.h"

#import "SEEDocumentController.h"
#import "DocumentModeManager.h"

#import "TCMMMPresenceManager.h"
#import "TCMMMSession.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"

#import "SEEConnectionManager.h"
#import "SEEConnection.h"
#import "SEEConnectionAddingWindowController.h"

#import "AppController.h"

#import "NSWorkspaceTCMAdditions.h"

#import "SEEHoverTableRowView.h"

#import <QuartzCore/QuartzCore.h>


#define SEE_DOCUMENT_HUD_MAX_RECENT_DOCUMENT_ITEMS 5u

extern int const FileMenuTag;
extern int const FileNewMenuItemTag;

static void *SEENetworkDocumentBrowserEntriesObservingContext = (void *)&SEENetworkDocumentBrowserEntriesObservingContext;

@interface SEEDocumentListWindowController () <NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSScrollView *scrollViewOutlet;
@property (nonatomic, weak) IBOutlet NSTableView *tableViewOutlet;
@property (weak) IBOutlet NSLayoutConstraint *tableViewLeadingConstraint;

@property (nonatomic, weak) IBOutlet NSMenu *listItemContextMenuOutlet;

@property (nonatomic, weak) IBOutlet NSObjectController *filesOwnerProxy;
@property (nonatomic, weak) IBOutlet NSArrayController *documentListItemsArrayController;

@property (nonatomic, weak) id otherWindowsBecomeKeyNotifivationObserver;
@property (nonatomic, weak) id recentDocumentsDidChangeNotifivationObserver;
@property (nonatomic, strong) SEEToggleRecentDocumentListItem *toggleRecentItem;

@property (nonatomic, strong) NSArray *cachedRecentDocuments;

@end

@implementation SEEDocumentListWindowController

+ (void)initialize {
	if (self == [SEEDocumentListWindowController class]) {
		[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"DocumentListShowRecent": @(YES)}];
	}
}

- (instancetype)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
		self.availableItems = [NSMutableArray array];

		__weak typeof(self) weakSelf = self;
		self.otherWindowsBecomeKeyNotifivationObserver =
		[[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			typeof(self) strongSelf = weakSelf;
			if (note.object != strongSelf.window && strongSelf.shouldCloseWhenOpeningDocument) {
				if (((NSWindow *)note.object).sheetParent != strongSelf.window) { // this avoids closing of the window when showing the connect sheet

					if ([note.object isKindOfClass:NSClassFromString(@"PlainTextWindow")]) { // but for now we filter by document windows to avoid closing when help menu is opened.
						if ([NSApp modalWindow] == strongSelf.window) {
							[NSApp stopModalWithCode:NSModalResponseAbort];
						}
						[self close];
					}
				}
			}
		}];

		self.recentDocumentsDidChangeNotifivationObserver =
		[[NSNotificationCenter defaultCenter] addObserverForName:RecentDocumentsDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			typeof(self) strongSelf = weakSelf;
			if (note.object == [SEEDocumentController sharedInstance]) {
				if (strongSelf.window.isVisible) {
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						[[self class] cancelPreviousPerformRequestsWithTarget:strongSelf selector:@selector(updateRecentDocumentsCache) object:nil];
						[strongSelf performSelector:@selector(updateRecentDocumentsCache) withObject:self afterDelay:0.1];
					}];
				}
			}
		}];
		
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.otherWindowsBecomeKeyNotifivationObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.recentDocumentsDidChangeNotifivationObserver];

	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateRecentDocumentsCache) object:nil];
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadAllListItems) object:nil];
	[self removeKVO];

	[self close];
}


#pragma mark -

- (void)windowDidLoad {
    [super windowDidLoad];

	NSWindow *window = self.window;
	[window setRestorationClass:NSClassFromString(@"SEEDocumentController")];
    window.title = [NSString stringWithFormat:NSLocalizedString(@"DOCUMENT_LIST_WINDOW_TITLE", nil), AppController.localizedApplicationName];


	NSScrollView *scrollView = self.scrollViewOutlet;
	scrollView.contentView.layer = [CAScrollLayer layer];
	scrollView.contentView.wantsLayer = YES;
	scrollView.contentView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
	scrollView.wantsLayer = YES;

	NSTableView *tableView = self.tableViewOutlet;
	[tableView setTarget:self];
	[tableView setAction:@selector(triggerItemClickAction:)];
	[tableView setDoubleAction:@selector(triggerItemClickAction:)];
	[tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	tableView.allowsMultipleSelection = NO;
    if (@available(macOS 11.0, *)) {
        tableView.style = NSTableViewStyleInset;
        self.tableViewLeadingConstraint.constant = 0;
    } else {
        self.tableViewLeadingConstraint.constant = 10;
    }
}


- (IBAction)showWindow:(id)sender {
	self.filesOwnerProxy.content = self;

	if (! self.window.isVisible) {
		[self updateRecentDocumentsCache];
		[self installKVO];
	}

	// if window is in auto close mode it should not be restored on app restart.
	self.window.restorable = !self.shouldCloseWhenOpeningDocument;

	[super showWindow:sender];
}


- (void)windowWillClose:(NSNotification *)notification
{
	if ([NSApp modalWindow] == notification.object) {
		[NSApp stopModalWithCode:NSModalResponseAbort];
	}

	[self removeKVO];
	self.filesOwnerProxy.content = nil;
}


- (NSInteger)runModal
{
	self.filesOwnerProxy.content = self;
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
}


#pragma mark - KVO

- (void)installKVO {
	[[SEEConnectionManager sharedInstance] addObserver:self forKeyPath:@"entries" options:NSKeyValueObservingOptionInitial context:SEENetworkDocumentBrowserEntriesObservingContext];

	if (self.toggleRecentItem) {
		[self.toggleRecentItem addObserver:self forKeyPath:@"showRecentDocuments" options:0 context:SEENetworkDocumentBrowserEntriesObservingContext];
	}
}

- (void)removeKVO {
	[[SEEConnectionManager sharedInstance] removeObserver:self forKeyPath:@"entries" context:SEENetworkDocumentBrowserEntriesObservingContext];

	if (self.toggleRecentItem) {
		[self.toggleRecentItem removeObserver:self forKeyPath:@"showRecentDocuments"];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEENetworkDocumentBrowserEntriesObservingContext) {
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadAllListItems) object:nil];
		[self reloadAllListItems];

		if (self.toggleRecentItem) {
			[[NSUserDefaults standardUserDefaults] setBool:self.toggleRecentItem.showRecentDocuments forKey:@"DocumentListShowRecent"];
		}
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Recent documents cache

- (void)updateRecentDocumentsCache
{
	NSArray *recentDocuments = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	for (NSURL *documentURL in recentDocuments) {
		[documentURL stopAccessingSecurityScopedResource];
	}
	self.cachedRecentDocuments = recentDocuments;

	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadAllListItems) object:nil];
	[self reloadAllListItems];
}

#pragma mark - Content management

- (void)reloadAllListItems
{
	[self willChangeValueForKey:@"availableItems"];
	{
		NSDictionary *lookupDictionary = [NSDictionary dictionaryWithObjects:self.availableItems forKeys:[self.availableItems valueForKey:@"uid"]];

		[self.availableItems removeAllObjects];

		{
			{
				SEENetworkConnectionRepresentationListItem *me = [[SEENetworkConnectionRepresentationListItem alloc] init];
				me.user = [[TCMMMUserManager sharedInstance] me];
				NSString *cachedItemID = me.uid;
				id <SEEDocumentListItem> cachedItem = [lookupDictionary objectForKey:cachedItemID];
				if (cachedItem) {
					[(SEENetworkConnectionRepresentationListItem *)cachedItem updateSubline];
					[self.availableItems addObject:cachedItem];
				} else {
					[self.availableItems addObject:me];
				}
			}

			{
				NSArray *sessions = [TCMMMPresenceManager sharedInstance].announcedSessions;
				for (TCMMMSession *session in sessions) {
					SEENetworkDocumentListItem *documentRepresentation = [[SEENetworkDocumentListItem alloc] init];
					documentRepresentation.documentSession = session;
					NSString *cachedItemID = documentRepresentation.uid;
					SEENetworkDocumentListItem *cachedItem = [lookupDictionary objectForKey:cachedItemID];
					if (cachedItem) {
						cachedItem.documentSession = session;
						[self.availableItems addObject:cachedItem];
					} else {
						[self.availableItems addObject:documentRepresentation];
					}
				}
			}
		}

		{
			SEEToggleRecentDocumentListItem *toggleRecentDocumentsItem = [[SEEToggleRecentDocumentListItem alloc] init];
			NSString *cachedItemID = toggleRecentDocumentsItem.uid;
			SEEToggleRecentDocumentListItem *cachedItem = [lookupDictionary objectForKey:cachedItemID];
			if (cachedItem) {
				[self.availableItems addObject:cachedItem];
			} else {
				toggleRecentDocumentsItem.showRecentDocuments = [[NSUserDefaults standardUserDefaults] boolForKey:@"DocumentListShowRecent"];
				self.toggleRecentItem = toggleRecentDocumentsItem;
				[self.availableItems addObject:toggleRecentDocumentsItem];
			}
			if (self.toggleRecentItem.showRecentDocuments) {
				NSArray *recentDocumentURLs = self.cachedRecentDocuments;

				NSUInteger addedRecentDocuments = 0;
				for (NSURL *url in recentDocumentURLs) {
					NSString *cachedItemID = url.absoluteString;
					id <SEEDocumentListItem> cachedItem = [lookupDictionary objectForKey:cachedItemID];
					if (cachedItem) {
						[self.availableItems addObject:cachedItem];
					} else {
						SEERecentDocumentListItem *recentDocumentItem = [[SEERecentDocumentListItem alloc] init];
						recentDocumentItem.fileURL = url;
						[self.availableItems addObject:recentDocumentItem];
					}

					addedRecentDocuments++;
					if (addedRecentDocuments >= SEE_DOCUMENT_HUD_MAX_RECENT_DOCUMENT_ITEMS) {
						break;
					}
				}

				if (recentDocumentURLs.count > SEE_DOCUMENT_HUD_MAX_RECENT_DOCUMENT_ITEMS) {
					SEEMoreRecentDocumentsListItem *moreItem = [[SEEMoreRecentDocumentsListItem alloc] init];
					NSString *cachedItemID = moreItem.uid;
					SEEMoreRecentDocumentsListItem *cachedItem = [lookupDictionary objectForKey:cachedItemID];
					if (cachedItem) {
						[self.availableItems addObject:cachedItem];
					} else {
						moreItem.moreMenu = self.listItemContextMenuOutlet;
						[self.availableItems addObject:moreItem];
					}
				}
			}
		}


		{
			NSArray *allConnections = [[SEEConnectionManager sharedInstance] entries];
			
			allConnections = [allConnections sortedArrayUsingComparator:^NSComparisonResult(SEEConnection *connection1, SEEConnection *connection2) {
				NSComparisonResult result = NSOrderedSame;
				char value1 = connection1.announcedSessions.count > 0 ? 0 : 1;
				char value2 = connection2.announcedSessions.count > 0 ? 0 : 1;
				result = TCM_SCALAR_COMPARE(value1, value2);
				if (result == NSOrderedSame) {
					result = [connection1.user.name compare:connection2.user.name options:NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch | NSNumericSearch];
				}
				
				return result;
			}];
			
			for (SEEConnection *connection in allConnections) {
				{
					if (connection.isVisible) {
						SEENetworkConnectionRepresentationListItem *connectionRepresentation = [[SEENetworkConnectionRepresentationListItem alloc] init];
						connectionRepresentation.connection = connection;
						NSString *cachedItemID = connectionRepresentation.uid;
						SEENetworkConnectionRepresentationListItem *cachedItem = [lookupDictionary objectForKey:cachedItemID];
                        [self.availableItems addObject:[SEEDividerListItem new]];
                        if (cachedItem) {
							cachedItem.connection = connection;
							[self.availableItems addObject:cachedItem];
						} else {
							[self.availableItems addObject:connectionRepresentation];
						}
					}

					NSArray *sessions = connection.announcedSessions;
					for (TCMMMSession *session in sessions) {
						SEENetworkDocumentListItem *documentRepresentation = [[SEENetworkDocumentListItem alloc] init];
						documentRepresentation.documentSession = session;
						documentRepresentation.beepSession = connection.BEEPSession;
						NSString *cachedItemID = documentRepresentation.uid;
						SEENetworkDocumentListItem *cachedItem = [lookupDictionary objectForKey:cachedItemID];
						if (cachedItem) {
							cachedItem.documentSession = session;
							cachedItem.beepSession = connection.BEEPSession;
							[self.availableItems addObject:cachedItem];
						} else {
							[self.availableItems addObject:documentRepresentation];
						}
					}
				}
			}
		}
	}
	[self didChangeValueForKey:@"availableItems"];
}


#pragma mark - Actions

- (IBAction)newDocumentToolbarItemAction:(id)sender {
    [[NSDocumentController sharedDocumentController] newDocumentByUserDefault:sender];
}

- (IBAction)openDocumentToolbarItemAction:(id)sender {
    [NSApp sendAction:@selector(openNormalDocument:) to:nil from:sender];
}

- (IBAction)connectToHostAction:(id)sender {
    SEEConnectionAddingWindowController *windowController = [[SEEConnectionAddingWindowController alloc] initWithWindowNibName:@"SEEConnectionAddingWindowController"];
    NSWindow *window = [windowController window];
    NSWindow *parentWindow = self.window;
    [parentWindow beginSheet:window completionHandler:^(NSModalResponse returnCode) {
        [windowController close];
    }];
}

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

- (IBAction)triggerItemClickAction:(id)sender {
	NSTableView *tableView = self.tableViewOutlet;
	id <SEEDocumentListItem> clickedItem = nil;
	if (sender == tableView) {
		NSInteger row = tableView.clickedRow;
		NSInteger column = tableView.clickedColumn;
		if (row > -1) {
			NSTableCellView *tableCell = [tableView viewAtColumn:column row:row makeIfNecessary:NO];
			clickedItem = tableCell.objectValue;
		}
	} else if ([sender conformsToProtocol:@protocol(SEEDocumentListItem)]) {
		clickedItem = sender;
	}

	if (clickedItem) {
		NSArray *selectedDocuments = self.documentListItemsArrayController.selectedObjects;
		if (! [selectedDocuments containsObject:clickedItem]) {
			[clickedItem itemAction:self.tableViewOutlet];
		}
	}
}

- (void)writeMyReachabiltyToPasteboard:(NSPasteboard *)aPasteboard {
	[self tableView:self.tableViewOutlet writeRowsWithIndexes:[NSIndexSet indexSetWithIndex:0] toPasteboard:aPasteboard];
}


#pragma mark - NSTableViewDataSoure - Connection Drag Support

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	__block NSMutableArray *userEntries = [NSMutableArray array];
	NSArray *availableDocumentSession = self.availableItems;

	__block NSString *seeURL = nil;
	TCMMMPresenceManager *presenceManager = [TCMMMPresenceManager sharedInstance];

	__block NSData *imageData = nil;
	__block TCMMMUser *foundUser = nil;
	[rowIndexes enumerateIndexesUsingBlock:^(NSUInteger rowIndex, BOOL *stop) {
		id documentRepresentation = [availableDocumentSession objectAtIndex:rowIndex];
		if ([documentRepresentation isKindOfClass:SEENetworkConnectionRepresentationListItem.class]) {
			SEENetworkConnectionRepresentationListItem *connectionRepresentation = (SEENetworkConnectionRepresentationListItem *)documentRepresentation;
			TCMMMUser *user = connectionRepresentation.user;
			foundUser = user;
			imageData = user.imageData;
			if (connectionRepresentation.connection) {
				SEEConnection *connection = connectionRepresentation.connection;
				NSDictionary *userDescription = @{@"UserID": user.userID,
												  @"PeerAddressData": connection.BEEPSession.peerAddressData};

				[userEntries addObject:userDescription];
			}
			if (connectionRepresentation.user) {
				seeURL = [presenceManager reachabilityURLStringOfUserID:user.userID];
				if (seeURL.length == 0) {
					if ([user isMe]) {
						NSURL *url = [SEEConnectionManager applicationConnectionURL];
						seeURL = url ? url.absoluteString : @"";
					}
				}
			}
		}
	}];

	BOOL result = userEntries.count > 0 || seeURL.length > 0;
	if (result) {
		NSMutableArray *types = [NSMutableArray array];
		NSMutableArray *blocks = [NSMutableArray array];
		[pboard clearContents];
		
		// collect representations
		if (userEntries.count > 0) {
			[types addObject:kSEEPasteBoardTypeConnection];
			[blocks addObject:^{
				[pboard setPropertyList:userEntries forType:kSEEPasteBoardTypeConnection];
			}];
		}
		
		if (seeURL.length > 0) {
			[types addObjectsFromArray:@[NSPasteboardTypeString,@"public.url", @"public.text"]];
			[blocks addObject:^{
			[pboard setString:seeURL forType:NSPasteboardTypeString];
			[pboard setString:seeURL forType:@"public.url"];
			[pboard setString:seeURL forType:@"public.text"];
			}];
		}

		
		/* don't do because it breaks dragging into messages
		{
			if (imageData) {
				[types addObjectsFromArray:@[@"public.jpeg", NSFileContentsPboardType]];
				[blocks addObject:^{
					[pboard setData:imageData forType:@"public.jpeg"];
					[pboard setData:imageData forType:NSFileContentsPboardType];
					//					[pboard setString:[[NSURL fileURLWithPath:[[foundUser name] stringByAppendingPathExtension:@"jpg"]] absoluteString] forType:(NSString *)kPasteboardTypeFileURLPromise];
				}];
			}
		}
		 */
		
		// execute them again in order
		if (types.count > 0) {
			[pboard addTypes:types owner:self];
			for (dispatch_block_t block in blocks) {
				block();
			}
			
		}
	}


	return result;
}


#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSView *result = nil;

	NSArray *rowItems = self.availableItems;
	if (rowItems.count > row) {
		id rowItem = [rowItems objectAtIndex:row];

		if (tableColumn == nil && [rowItem isKindOfClass:SEENetworkConnectionRepresentationListItem.class]) {
			result = [tableView makeViewWithIdentifier:@"Group" owner:self];
        } else if ([rowItem isKindOfClass:SEEToggleRecentDocumentListItem.class]) {
			result = [tableView makeViewWithIdentifier:@"ToggleRecent" owner:self];
		} else if ([rowItem isKindOfClass:SEEMoreRecentDocumentsListItem.class]) {
			result = [tableView makeViewWithIdentifier:@"MoreRecent" owner:self];
		} else if ([rowItem isKindOfClass:SEERecentDocumentListItem.class]) {
			result = [tableView makeViewWithIdentifier:@"Document" owner:self];
		} else if ([rowItem isKindOfClass:SEENetworkDocumentListItem.class]) {
			result = [tableView makeViewWithIdentifier:@"NetworkDocument" owner:self];
		} else {
			result = [tableView makeViewWithIdentifier:@"Document" owner:self];
		}
	}
	return result;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	NSTableRowView * rowView = nil;
	NSArray *availableItems = self.availableItems;
	if (availableItems.count > row) {
		id <SEEDocumentListItem> itemRepresentation = [availableItems objectAtIndex:row];
        if ([itemRepresentation isKindOfClass:[SEENetworkConnectionRepresentationListItem class]]) {
            rowView = [SEEDocumentListGroupTableRowView new];
        } else if ([itemRepresentation isKindOfClass:[SEEDividerListItem class]]) {
			rowView = [SEEDividerTableRowView new];
		} else if ([itemRepresentation isKindOfClass:[SEENetworkDocumentListItem class]] ||
                   [itemRepresentation isKindOfClass:[SEERecentDocumentListItem class]]) {
			rowView = ({
				SEEHoverTableRowView *hoverView = [[SEEHoverTableRowView alloc] init];
				hoverView.TCM_rowIndex = row;
				hoverView;
			});
		}
	}
	return rowView;
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
	NSArray *availableDocumentSession = self.availableItems;
	if (availableDocumentSession.count > row) {
		id documentRepresentation = [availableDocumentSession objectAtIndex:row];
		if ([documentRepresentation isKindOfClass:SEENetworkConnectionRepresentationListItem.class]) {
			SEENetworkConnectionRepresentationListItem *connectionRepresentation = (SEENetworkConnectionRepresentationListItem *)documentRepresentation;
            NSTableCellView *tableCellView =
            [rowView.subviews SEE_firstObjectPassingTest:^(NSView *view) {
                return [view isKindOfClass:[NSTableCellView class]];
            }];

			SEEAvatarImageView *avatarView =
            [tableCellView.subviews SEE_firstObjectPassingTest:^BOOL(NSView *view) {
                return ([view isKindOfClass:[SEEAvatarImageView class]] &&
                        [view.identifier isEqualToString:@"AvatarView"]);
            }];
            
			TCMMMUser *user = connectionRepresentation.user;
			[avatarView bind:@"image" toObject:user withKeyPath:@"image" options:nil];
			[avatarView bind:@"initials" toObject:user withKeyPath:@"initials" options:nil];
			[avatarView bind:@"borderColor" toObject:user withKeyPath:@"changeColor" options:nil];
		}
	}
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
	BOOL result = NO;
	NSArray *availableDocumentSession = self.availableItems;
	if (availableDocumentSession.count > row) {
		id documentRepresentation = [availableDocumentSession objectAtIndex:row];
		if ([documentRepresentation isKindOfClass:SEENetworkConnectionRepresentationListItem.class]) {
			result = YES;
		}
	}
	return result;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSIndexSet *selectedIndices = self.tableViewOutlet.selectedRowIndexes;
	[selectedIndices enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
		NSArray *availableDocumentSession = self.availableItems;
		if (availableDocumentSession.count > row) {
//			id documentRepresentation = [availableDocumentSession objectAtIndex:row];
            [self.tableViewOutlet deselectRow:row];
		}
	}];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	CGFloat rowHeight = 28.0;
    Class connectionRepresentation = SEENetworkConnectionRepresentationListItem.class;
	NSArray *availableDocumentSession = self.availableItems;
	if (availableDocumentSession.count > row) {
		id documentRepresentation = [availableDocumentSession objectAtIndex:row];
		if ([documentRepresentation isKindOfClass:connectionRepresentation]) {
			rowHeight = 56.0;
		} else if ([documentRepresentation isKindOfClass:SEEToggleRecentDocumentListItem.class] ||
                   [documentRepresentation isKindOfClass:SEEMoreRecentDocumentsListItem.class]) {
            rowHeight = 28.0;
		} else if ([documentRepresentation isKindOfClass:SEENetworkDocumentListItem.class] ||
				   [documentRepresentation isKindOfClass:SEERecentDocumentListItem.class]) {
            rowHeight = 42.0;
        } else if ([documentRepresentation isKindOfClass:SEEDividerListItem.class]) {
            rowHeight = 10.0;
        }
	}
	return rowHeight;
}


#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
	NSTableView *tableView = self.tableViewOutlet;
	id <SEEDocumentListItem> clickedItem = nil;
	//    BOOL clickedOnMultipleItems = NO;

	NSInteger row = tableView.clickedRow;
	NSInteger column = tableView.clickedColumn;
	if (row > -1) {
		NSTableCellView *tableCell = [tableView viewAtColumn:column row:row makeIfNecessary:NO];
		clickedItem = tableCell.objectValue;
		// clickedOnMultipleItems = [tableView isRowSelected:row] && ([tableView numberOfSelectedRows] > 1);
	}

    if (menu == self.listItemContextMenuOutlet) {
		[menu removeAllItems];

		if (clickedItem != nil) {
			if ([clickedItem isKindOfClass:[SEENetworkDocumentListItem class]] ||
                [clickedItem isKindOfClass:[SEERecentDocumentListItem class]]) {
                {
                    NSString *menuItemTitle = NSLocalizedStringWithDefaultValue(@"DOCUMENT_LIST_CONTEXT_MENU_OPEN", nil, [NSBundle mainBundle], @"Open", @"MenuItem title in context menu of DocumentList window.");
                    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle action:@selector(itemAction:) keyEquivalent:@""];
                    menuItem.target = clickedItem;
                    menuItem.enabled = YES;
                    [menu addItem:menuItem];
                }
                {
                    [menu addItem:[NSMenuItem separatorItem]];
                }
                {
                    NSString *menuItemTitle = NSLocalizedStringWithDefaultValue(@"DOCUMENT_LIST_CONTEXT_MENU_SHOW_IN_FINDER", nil, [NSBundle mainBundle], @"Show in Finder", @"MenuItem title in context menu of DocumentList window.");
                    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle action:@selector(showDocumentInFinder:) keyEquivalent:@""];
                    menuItem.target = clickedItem;
                    menuItem.enabled = YES;
                    [menu addItem:menuItem];
                }
			} else if ([clickedItem isKindOfClass:[SEENetworkConnectionRepresentationListItem class]]) {
				{
					NSString *menuItemTitle = NSLocalizedStringWithDefaultValue(@"DOCUMENT_LIST_CONTEXT_MENU_COPY_URL", nil, [NSBundle mainBundle], @"Copy Connection URL", @"MenuItem title in context menu of DocumentList window.");
					NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle action:@selector(putConnectionURLOnPasteboard:) keyEquivalent:@""];
					menuItem.target = clickedItem;
					menuItem.enabled = YES;
					[menu addItem:menuItem];
				}
				{
					[menu addItem:[NSMenuItem separatorItem]];
				}
				{
					NSString *menuItemTitle = NSLocalizedStringWithDefaultValue(@"DOCUMENT_LIST_CONTEXT_MENU_DISCONNECT", nil, [NSBundle mainBundle], @"Disconnect", @"MenuItem title in context menu of DocumentList window.");
					NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle action:@selector(disconnect:) keyEquivalent:@""];
					menuItem.target = clickedItem;
					menuItem.enabled = YES;
					[menu addItem:menuItem];
				}
			} else if ([clickedItem isKindOfClass:[SEEToggleRecentDocumentListItem class]] ||
					   [clickedItem isKindOfClass:[SEEMoreRecentDocumentsListItem class]]) {
				for (NSURL *documentURL in self.cachedRecentDocuments) {
					NSString *menuItemTitle = documentURL.lastPathComponent;
					NSImage *image = nil;
					NSString *fileType = nil;
					[documentURL getResourceValue:&fileType forKey:NSURLTypeIdentifierKey error:nil];
					if (fileType) {
						image = [[NSWorkspace sharedWorkspace] iconForFileType:fileType size:16];
					} else {
						image = [[NSWorkspace sharedWorkspace] iconForFileType:(NSString *)kUTTypePlainText size:16];
					}
					NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle action:@selector(openRecentDocumentForItem:) keyEquivalent:@""];
					menuItem.target = clickedItem;
					menuItem.image = image;
					menuItem.representedObject = documentURL;
					menuItem.enabled = YES;
					[menu addItem:menuItem];
				}
				{
					[menu addItem:[NSMenuItem separatorItem]];
				}
				{
					NSString *menuItemTitle = NSLocalizedStringWithDefaultValue(@"DOCUMENT_LIST_CONTEXT_MENU_CLEAR_RECENT", nil, [NSBundle mainBundle], @"Clear Recent Documents", @"MenuItem title in context menu of DocumentList window.");
					NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle action:@selector(clearRecentDocuments:) keyEquivalent:@""];
					menuItem.enabled = YES;
					[menu addItem:menuItem];
				}
			}
		}
    }
}

#pragma mark - NSWindowDelegate (NSWindowController)

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame {
	// just expand the height of the window when zooming
	newFrame.origin = window.frame.origin;
	newFrame.size.width = window.frame.size.width;

	return newFrame;
}

@end
